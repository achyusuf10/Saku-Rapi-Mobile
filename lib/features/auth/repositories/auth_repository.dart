import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/auth/datasource/auth_local_data_source.dart';
import 'package:app_saku_rapi/features/auth/datasource/auth_remote_data_source.dart';
import 'package:app_saku_rapi/features/auth/models/account_login_resolve_model.dart';
import 'package:app_saku_rapi/features/auth/models/user_model.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository utama untuk modul autentikasi.
///
/// Mengorkestrasikan [AuthRemoteDataSource] dan [AuthLocalDataSource]
/// sesuai 3-file pattern SakuRapi.
class AuthRepository {
  AuthRepository({
    AuthRemoteDataSource? remoteDataSource,
    AuthLocalDataSource? localDataSource,
  }) : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSource(),
       _localDataSource = localDataSource ?? AuthLocalDataSource();

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  /// Login via Google Sign-In dan sinkronkan profil dengan gerbang hapus-akun (RPC).
  Future<DataState<UserModel>> signInWithGoogle() async {
    final authResult = await _remoteDataSource.signInWithGoogle();

    switch (authResult) {
      case DataStateSuccess(data: final response):
        final userId = response.user?.id;
        if (userId == null) {
          return const DataState<UserModel>.error(
            message: 'User ID tidak ditemukan setelah login',
          );
        }

        final gateBlock = await _evaluateLoginGate();
        switch (gateBlock) {
          case _GateNone():
            break;
          case _GateCooldown(:final daysRemaining):
            return DataState<UserModel>.error(
              message: '',
              errorData: daysRemaining,
            );
          case _GateInvalidSession():
            return const DataState<UserModel>.error(message: 'Sesi tidak valid');
        }

        return _fetchProfileAndCacheSignedIn(userId);
      case DataStateError(
        message: final message,
        exception: final exception,
        stackTrace: final stackTrace,
        errorData: final errorData,
      ):
        AppLogger.logError(
          'Google Sign-In failed: $message',
          runtimeType: AuthRepository,
        );
        return DataState<UserModel>.error(
          message: message,
          exception: exception,
          stackTrace: stackTrace,
          errorData: errorData,
        );
      default:
        throw StateError('Unexpected auth result: ${authResult.runtimeType}');
    }
  }

  /// Sign out dan bersihkan semua data lokal.
  Future<DataState<void>> signOut() async {
    final result = await _remoteDataSource.signOut();

    return result.map(
      success: (_) {
        HiveService.reset();
        AppLogger.logSuccess('Sign-out complete', runtimeType: AuthRepository);
        return const DataState<void>.success(data: null);
      },
      error: (error) {
        AppLogger.logError(
          'Sign-out failed: ${error.message}',
          runtimeType: AuthRepository,
        );
        return DataState<void>.error(
          message: error.message,
          exception: error.exception,
          stackTrace: error.stackTrace,
        );
      },
    );
  }

  /// Restore session untuk splash: gerbang RPC dulu, lalu profil/cached fallback.
  Future<DataState<UserModel?>> restoreSession() async {
    final session = _remoteDataSource.getCurrentSession();

    if (session == null) {
      AppLogger.call(
        '[Auth] [AuthRepository] No active session found',
        colorLog: ColorLog.yellow,
      );
      return const DataState.success(data: null);
    }

    final userId = session.user.id;

    AppLogger.call(
      '[Auth] [AuthRepository] Session found, resolving login gate...',
      colorLog: ColorLog.blue,
    );

    final gateBlock = await _evaluateLoginGate();
    switch (gateBlock) {
      case _GateNone():
        break;
      case _GateCooldown(:final daysRemaining):
        return DataState<UserModel?>.error(
          message: '',
          errorData: daysRemaining,
        );
      case _GateInvalidSession():
        return const DataState<UserModel?>.error(message: 'Sesi tidak valid');
    }

    final profileResult = await _remoteDataSource.getUserProfile(userId);

    switch (profileResult) {
      case DataStateSuccess(data: final profile):
        _localDataSource.cacheUserProfile(profile);
        return DataState<UserModel?>.success(data: profile);
      case DataStateError():
        final cached = _localDataSource.getCachedUserProfile();
        if (cached != null) {
          AppLogger.call(
            '[Auth] [AuthRepository] Using cached profile as fallback',
            colorLog: ColorLog.yellow,
          );
          return DataState<UserModel?>.success(data: cached);
        }

        final authUser = _remoteDataSource.getCurrentAuthUser();
        if (authUser != null) {
          final minimalUser = UserModel(
            id: authUser.id,
            email: authUser.email ?? '',
            fullName: authUser.userMetadata?['full_name'] as String?,
            avatarUrl: authUser.userMetadata?['avatar_url'] as String?,
          );
          _localDataSource.cacheUserProfile(minimalUser);
          return DataState<UserModel?>.success(data: minimalUser);
        }

        return const DataState<UserModel?>.success(data: null);
      default:
        throw StateError(
          'Unexpected profile fetch outcome: ${profileResult.runtimeType}',
        );
    }
  }

  /// Mendapatkan profil user saat ini — cache → remote.
  Future<DataState<UserModel>> getCurrentUserProfile() async {
    final cached = _localDataSource.getCachedUserProfile();
    if (cached != null) {
      return DataState.success(data: cached);
    }

    final authUser = _remoteDataSource.getCurrentAuthUser();
    if (authUser == null) {
      return const DataState.error(message: 'User belum login');
    }

    return _remoteDataSource.getUserProfile(authUser.id);
  }

  /// Update profil user (nama & avatar).
  Future<DataState<UserModel>> updateUserProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
  }) async {
    final result = await _remoteDataSource.updateUserProfile(
      userId: userId,
      fullName: fullName,
      avatarUrl: avatarUrl,
    );

    return result.map(
      success: (success) {
        _localDataSource.cacheUserProfile(success.data);
        return DataState<UserModel>.success(data: success.data);
      },
      error: (error) {
        return DataState<UserModel>.error(
          message: error.message,
          exception: error.exception,
          stackTrace: error.stackTrace,
        );
      },
    );
  }

  /// RPC `soft_delete_own_account` untuk user yang sedang login.
  Future<DataState<void>> softDeleteOwnAccount() async {
    return _remoteDataSource.softDeleteOwnAccount();
  }

  /// Stream auth state change untuk router refresh.
  Stream<AuthState> onAuthStateChange() {
    return _remoteDataSource.onAuthStateChange();
  }

  /// Cached user tanpa remote call.
  UserModel? getCachedUser() {
    return _localDataSource.getCachedUserProfile();
  }

  Future<DataState<UserModel>> _fetchProfileAndCacheSignedIn(String userId) async {
    final profileResult = await _remoteDataSource.getUserProfile(userId);

    switch (profileResult) {
      case DataStateSuccess(data: final profile):
        _localDataSource.cacheUserProfile(profile);
        AppLogger.logSuccess(
          'Sign-in complete: ${profile.email}',
          runtimeType: AuthRepository,
        );
        return DataState<UserModel>.success(data: profile);
      case DataStateError(
        message: final message,
        exception: final exception,
        stackTrace: final stackTrace,
        errorData: final errorData,
      ):
        AppLogger.logError(
          'Failed to fetch profile after sign-in: $message',
          runtimeType: AuthRepository,
        );
        return DataState<UserModel>.error(
          message: message,
          exception: exception,
          stackTrace: stackTrace,
          errorData: errorData,
        );
      default:
        throw StateError(
          'Unexpected profile fetch outcome: ${profileResult.runtimeType}',
        );
    }
  }

  /// Evaluasi [resolve_account_login_state]. Mengosongkan sesi jika blok.
  Future<_GateBlock> _evaluateLoginGate() async {
    final gateResult = await _remoteDataSource.resolveAccountLoginState();

    switch (gateResult) {
      case DataStateSuccess(data: final AccountLoginResolveModel g):
        if (!g.allowed && g.reason == 'account_cooldown') {
          AppLogger.call(
            '[Auth] [AuthRepository] Blocking session (account_cooldown, '
            'days_remaining=${g.daysRemaining})',
            colorLog: ColorLog.yellow,
          );
          await _signOutSilentlyAlwaysResetHive();
          return _GateCooldown(g.daysRemaining ?? 1);
        }

        if (!g.allowed && g.reason == 'not_authenticated') {
          AppLogger.call(
            '[Auth] [AuthRepository] Blocking session (not_authenticated)',
            colorLog: ColorLog.yellow,
          );
          await _signOutSilentlyAlwaysResetHive();
          return const _GateInvalidSession();
        }
        return const _GateNone();
      case DataStateError(message: final m):
        AppLogger.logError(
          'resolve_account_login_state unavailable ($m); continuing without gate',
          runtimeType: AuthRepository,
        );
        return const _GateNone();
      default:
        throw StateError(
          'Unexpected resolve_account_login_state outcome: ${gateResult.runtimeType}',
        );
    }
  }

  Future<void> _signOutSilentlyAlwaysResetHive() async {
    final out = await _remoteDataSource.signOut();
    out.maybeWhen(
      error: (message, exception, stackTrace, errorData) {
        AppLogger.logError(
          'Sign-out during gate failed (ignored): $message',
          runtimeType: AuthRepository,
        );
      },
      orElse: () {},
    );
    HiveService.reset();
  }
}

sealed class _GateBlock {
  const _GateBlock();
}

final class _GateNone extends _GateBlock {
  const _GateNone();
}

final class _GateCooldown extends _GateBlock {
  const _GateCooldown(this.daysRemaining);
  final int daysRemaining;
}

final class _GateInvalidSession extends _GateBlock {
  const _GateInvalidSession();
}
