import 'dart:async';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/services/sentry_service.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/auth/models/user_model.dart';
import 'package:app_saku_rapi/features/auth/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ─────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────

/// Provider untuk [AuthRepository] singleton.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provider utama untuk [AuthController].
///
/// Mengelola state autentikasi seluruh aplikasi.
final authControllerProvider =
    StateNotifierProvider<AuthController, AppAuthState>((ref) {
      final repository = ref.watch(authRepositoryProvider);
      return AuthController(repository);
    });

/// Provider untuk mendapatkan [UserModel] saat ini (nullable).
///
/// Digunakan di widget yang hanya perlu data user tanpa
/// peduli state loading/error.
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.user;
});

/// [ChangeNotifier] yang di-trigger saat auth state berubah.
///
/// Digunakan sebagai `refreshListenable` di GoRouter agar
/// redirect otomatis terjadi saat login/logout.
final authChangeNotifierProvider = ChangeNotifierProvider<AuthChangeNotifier>((
  ref,
) {
  final notifier = AuthChangeNotifier();
  // Listen ke auth state changes dari Supabase
  final repository = ref.watch(authRepositoryProvider);
  final subscription = repository.onAuthStateChange().listen((event) {
    AppLogger.call(
      '[Auth] [AuthChangeNotifier] Auth event: ${event.event}',
      colorLog: ColorLog.blue,
    );
    notifier.notify();
  });

  ref.onDispose(() => subscription.cancel());

  return notifier;
});

// ─────────────────────────────────────────────────────────
// Auth State
// ─────────────────────────────────────────────────────────

/// State untuk modul auth.
///
/// Encapsulates status autentikasi dan data user dalam satu objek.
class AppAuthState {
  const AppAuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  /// Status autentikasi saat ini.
  final AuthStatus status;

  /// Data user yang sedang login (null jika belum login).
  final UserModel? user;

  /// Pesan error terakhir (null jika tidak ada error).
  final String? errorMessage;

  /// Apakah sedang dalam proses autentikasi.
  bool get isLoading => status == AuthStatus.loading;

  /// Apakah user sudah terautentikasi.
  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Membuat salinan [AppAuthState] dengan field yang diubah.
  AppAuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AppAuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

/// Enum status autentikasi.
enum AuthStatus {
  /// State awal saat app baru dibuka.
  initial,

  /// Sedang memproses (login, logout, restore session).
  loading,

  /// User berhasil terautentikasi.
  authenticated,

  /// User tidak terautentikasi.
  unauthenticated,

  /// Terjadi error saat proses autentikasi.
  error,
}

// ─────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────

/// Controller autentikasi menggunakan [StateNotifier].
///
/// Mengelola lifecycle autentikasi:
/// - `restoreSession()` → dipanggil saat splash
/// - `signInWithGoogle()` → dipanggil dari login page
/// - `signOut()` → dipanggil dari settings/profile
///
/// Tidak menggunakan Riverpod Generator sesuai aturan SakuRapi.
class AuthController extends StateNotifier<AppAuthState> {
  AuthController(this._repository) : super(const AppAuthState()) {
    // Cek session saat controller diinisialisasi
    restoreSession();
  }

  final AuthRepository _repository;

  /// Cek session existing saat splash screen.
  ///
  /// Jika ada session aktif, set status ke [AuthStatus.authenticated].
  /// Jika tidak ada, set ke [AuthStatus.unauthenticated].
  Future<void> restoreSession() async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _repository.restoreSession();

    result.map(
      success: (success) {
        if (success.data != null) {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: success.data,
          );
          SentryService.setUser(success.data!.id, success.data!.email);
          AppLogger.logSuccess(
            'Session restored: ${success.data!.email}',
            runtimeType: AuthController,
          );
        } else {
          state = state.copyWith(status: AuthStatus.unauthenticated);
          AppLogger.call(
            '[Auth] [AuthController] No session to restore',
            colorLog: ColorLog.yellow,
          );
        }
      },
      error: (error) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: error.message,
        );
      },
    );
  }

  /// Login via Google Sign-In.
  ///
  /// Returns `true` jika berhasil, `false` jika gagal.
  /// UI bisa check [state.errorMessage] untuk pesan error.
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _repository.signInWithGoogle();

    return result.map(
      success: (success) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: success.data,
        );
        SentryService.setUser(success.data.id, success.data.email);
        return true;
      },
      error: (error) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: error.message,
        );
        return false;
      },
    );
  }

  /// Sign out user.
  ///
  /// Returns `true` jika lancar, `false` jika ada error.
  Future<bool> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _repository.signOut();

    return result.map(
      success: (_) {
        state = const AppAuthState(status: AuthStatus.unauthenticated);
        SentryService.clearUser();
        return true;
      },
      error: (error) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: error.message,
        );
        return false;
      },
    );
  }

  /// Refresh profil user dari remote.
  Future<void> refreshProfile() async {
    final currentUser = state.user;
    if (currentUser == null) return;

    final result = await _repository.getCurrentUserProfile();

    result.map(
      success: (success) {
        state = state.copyWith(user: success.data);
      },
      error: (_) {
        // Silently fail, keep existing profile
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Auth Change Notifier (untuk GoRouter refreshListenable)
// ─────────────────────────────────────────────────────────

/// [ChangeNotifier] untuk GoRouter `refreshListenable`.
///
/// Saat dipanggil `notify()`, GoRouter akan re-evaluate
/// semua redirect rules.
class AuthChangeNotifier extends ChangeNotifier {
  /// Trigger re-evaluation redirect GoRouter.
  void notify() {
    notifyListeners();
  }
}
