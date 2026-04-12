import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/auth/datasource/auth_local_data_source.dart';
import 'package:app_saku_rapi/features/auth/datasource/auth_remote_data_source.dart';
import 'package:app_saku_rapi/features/auth/models/user_model.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository utama untuk modul autentikasi.
///
/// Mengorkestrasikan [AuthRemoteDataSource] dan [AuthLocalDataSource]
/// sesuai 3-file pattern SakuRapi.
///
/// Bertanggung jawab atas:
/// - Login via Google → Supabase → cache profil lokal
/// - Logout → hapus session + cache
/// - Pengecekan session untuk splash flow
/// - Read/update profil user
class AuthRepository {
  AuthRepository({
    AuthRemoteDataSource? remoteDataSource,
    AuthLocalDataSource? localDataSource,
  }) : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSource(),
       _localDataSource = localDataSource ?? AuthLocalDataSource();

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  /// Login via Google Sign-In dan sinkronkan profil.
  ///
  /// Flow:
  /// 1. Panggil Google Sign-In → Supabase `signInWithIdToken`.
  /// 2. Setelah berhasil, ambil profil dari `public.users`.
  /// 3. Cache profil ke Hive lokal.
  ///
  /// Returns [DataState<UserModel>] jika seluruh flow sukses.
  Future<DataState<UserModel>> signInWithGoogle() async {
    // Step 1: Sign in ke Supabase via Google
    final authResult = await _remoteDataSource.signInWithGoogle();

    return authResult.map(
      success: (authSuccess) async {
        final userId = authSuccess.data.user?.id;
        if (userId == null) {
          return const DataState<UserModel>.error(
            message: 'User ID tidak ditemukan setelah login',
          );
        }

        // Step 2: Ambil profil dari public.users
        // Trigger handle_new_user() di Supabase sudah membuat record-nya
        final profileResult = await _remoteDataSource.getUserProfile(userId);

        return profileResult.map(
          success: (profileSuccess) {
            // Step 3: Cache profil lokal
            _localDataSource.cacheUserProfile(profileSuccess.data);

            AppLogger.logSuccess(
              'Sign-in complete: ${profileSuccess.data.email}',
              runtimeType: AuthRepository,
            );

            return DataState<UserModel>.success(data: profileSuccess.data);
          },
          error: (profileError) {
            AppLogger.logError(
              'Failed to fetch profile after sign-in: ${profileError.message}',
              runtimeType: AuthRepository,
            );
            return DataState<UserModel>.error(
              message: profileError.message,
              exception: profileError.exception,
              stackTrace: profileError.stackTrace,
            );
          },
        );
      },
      error: (authError) {
        AppLogger.logError(
          'Google Sign-In failed: ${authError.message}',
          runtimeType: AuthRepository,
        );
        return DataState<UserModel>.error(
          message: authError.message,
          exception: authError.exception,
          stackTrace: authError.stackTrace,
        );
      },
    );
  }

  /// Sign out dan bersihkan semua data lokal.
  Future<DataState<void>> signOut() async {
    final result = await _remoteDataSource.signOut();

    return result.map(
      success: (_) {
        // Wipe seluruh Hive box agar tidak ada cache akun lama
        // yang tertinggal ketika user login dengan akun berbeda.
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

  /// Cek apakah ada session aktif saat app dibuka.
  ///
  /// Digunakan di splash screen untuk menentukan redirect.
  /// Jika ada session aktif, coba refresh profil dari remote.
  /// Jika gagal (offline), fallback ke cache lokal.
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
      '[Auth] [AuthRepository] Session found, fetching profile...',
      colorLog: ColorLog.blue,
    );

    // Coba ambil profil terbaru dari remote
    final profileResult = await _remoteDataSource.getUserProfile(userId);

    return profileResult.map(
      success: (profileSuccess) {
        _localDataSource.cacheUserProfile(profileSuccess.data);
        return DataState<UserModel?>.success(data: profileSuccess.data);
      },
      error: (_) {
        // Fallback ke cache lokal jika remote gagal
        final cached = _localDataSource.getCachedUserProfile();
        if (cached != null) {
          AppLogger.call(
            '[Auth] [AuthRepository] Using cached profile as fallback',
            colorLog: ColorLog.yellow,
          );
          return DataState<UserModel?>.success(data: cached);
        }

        // Masih ada session tapi tidak bisa dapat profil
        // Buat UserModel minimal dari auth data
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
      },
    );
  }

  /// Mendapatkan profil user saat ini.
  ///
  /// Prioritas: cache lokal → remote.
  Future<DataState<UserModel>> getCurrentUserProfile() async {
    // Coba cache dulu
    final cached = _localDataSource.getCachedUserProfile();
    if (cached != null) {
      return DataState.success(data: cached);
    }

    // Fallback ke remote
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

  /// Stream auth state change untuk router refresh.
  Stream<AuthState> onAuthStateChange() {
    return _remoteDataSource.onAuthStateChange();
  }

  /// Mendapatkan cached user (sync, tanpa remote call).
  UserModel? getCachedUser() {
    return _localDataSource.getCachedUserProfile();
  }
}
