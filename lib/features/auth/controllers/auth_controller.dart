import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/auth/datasource/auth_local_datasource.dart';
import 'package:app_saku_rapi/features/auth/datasource/auth_remote_data_source.dart';
import 'package:app_saku_rapi/features/auth/models/user_model.dart';
import 'package:app_saku_rapi/features/auth/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────

/// Status otentikasi aplikasi.
///
/// Digunakan oleh GoRouter untuk redirect guard.
enum AuthStatus {
  /// Sedang mengecek session awal.
  loading,

  /// User sudah login (session aktif).
  authenticated,

  /// User belum login / session kosong.
  unauthenticated,
}

// ─────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────

/// Provider untuk [AuthLocalDataSource].
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSource();
});

/// Provider untuk [AuthRemoteDataSource].
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource();
});

/// Provider untuk [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
  );
});

/// Provider utama untuk [AuthController].
///
/// State berupa [AsyncValue<UserModel?>]:
/// - `AsyncLoading` saat cek sesi awal
/// - `AsyncData(UserModel)` jika sudah login
/// - `AsyncData(null)` jika belum login
final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserModel?>(() {
      return AuthController();
    });

// ─────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────

/// Riverpod [AsyncNotifier] untuk mengelola state autentikasi.
///
/// Mengecek session Supabase saat inisialisasi, dan menyediakan
/// fungsi `signIn()`, `signOut()`, dan `refreshProfile()`.
///
/// [authListenable] digunakan oleh GoRouter `refreshListenable`
/// agar redirect otomatis bereaksi terhadap perubahan status auth.
class AuthController extends AsyncNotifier<UserModel?> {
  late final AuthRepository _repository;

  /// [ChangeNotifier] terpisah agar GoRouter bisa listen perubahan auth.
  final ChangeNotifier authListenable = ChangeNotifier();

  static const String _tag = 'Auth';

  /// Notify GoRouter bahwa auth state berubah.
  void _notifyRouter() {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    authListenable.notifyListeners();
  }

  @override
  Future<UserModel?> build() async {
    _repository = ref.watch(authRepositoryProvider);

    _listenAuthChanges();

    // Cek apakah ada session Supabase aktif
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      AppLogger.call(
        '[$_tag] Session aktif ditemukan: ${session.user.email}',
        colorLog: ColorLog.green,
      );

      final result = await _repository.getCurrentUser();
      if (result.isSuccess()) {
        state = AsyncData(result.dataSuccess());
        _notifyRouter();
        return result.dataSuccess();
      }
    }

    AppLogger.call(
      '[$_tag] Tidak ada session aktif.',
      colorLog: ColorLog.yellow,
    );
    _notifyRouter();
    return null;
  }

  /// Subscribe ke perubahan auth state dari Supabase secara real-time.
  void _listenAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;

      AppLogger.call(
        '[$_tag] Auth event: ${event.name}',
        colorLog: ColorLog.blue,
      );

      switch (event) {
        case AuthChangeEvent.signedOut:
          state = const AsyncData(null);
          _notifyRouter();
        default:
          break;
      }
    });
  }

  /// Mendapatkan [AuthStatus] saat ini berdasarkan state.
  ///
  /// Digunakan oleh GoRouter redirect.
  AuthStatus get authStatus {
    return state.when(
      data: (user) =>
          user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      loading: () => AuthStatus.loading,
      error: (_, _) => AuthStatus.unauthenticated,
    );
  }

  /// Login menggunakan akun Google.
  ///
  /// Menampilkan loading state, lalu update state dengan [UserModel]
  /// jika berhasil.
  Future<void> signIn() async {
    AppLogger.call('[$_tag] Google Sign-In triggered', colorLog: ColorLog.blue);

    state = const AsyncLoading();

    final result = await _repository.signInWithGoogle();

    result.map(
      success: (data) {
        AppLogger.call(
          '[$_tag] Sign-In sukses: userId=${data.data.id}',
          colorLog: ColorLog.green,
        );
        state = AsyncData(data.data);
        _notifyRouter();
      },
      error: (err) {
        AppLogger.call(
          '[$_tag] Error Sign-In: ${err.message}',
          colorLog: ColorLog.red,
        );
        state = AsyncError(err.message, StackTrace.current);
        // Fallback ke unauthenticated agar redirect ke login
        state = const AsyncData(null);
        _notifyRouter();
      },
    );
  }

  /// Logout user, clear cache.
  Future<void> signOut() async {
    AppLogger.call('[$_tag] Logout...', colorLog: ColorLog.blue);

    final result = await _repository.signOut();

    result.map(
      success: (_) {
        state = const AsyncData(null);
        _notifyRouter();
      },
      error: (err) {
        AppLogger.logError('[$_tag] Logout error: ${err.message}');
      },
    );
  }

  /// Refresh profil user dari Supabase.
  Future<void> refreshProfile() async {
    final result = await _repository.getCurrentUser();

    result.map(
      success: (data) {
        state = AsyncData(data.data);
      },
      error: (err) {
        AppLogger.logError('[$_tag] Refresh profil gagal: ${err.message}');
      },
    );
  }
}
