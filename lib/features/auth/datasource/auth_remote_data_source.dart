import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/auth/models/user_model.dart';
import 'package:app_saku_rapi/features/auth/utils/google_id_token_utils.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk operasi autentikasi via Supabase.
///
/// Bertanggung jawab atas:
/// - Google Sign-In via `signInWithIdToken`
/// - Sign-Out
/// - Membaca data user dari tabel `public.users`
/// - Update profil user (`full_name`, `avatar_url`)
///
/// Semua operasi dibungkus dengan [SupabaseHandler.call] untuk
/// penanganan error terpusat.
class AuthRemoteDataSource {
  AuthRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Web Client ID dari Google Cloud Console untuk Supabase OAuth.
  ///
  /// Harus sesuai dengan yang dikonfigurasi di Supabase Dashboard
  /// Authentication → Providers → Google.
  static const _webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  /// Flag untuk memastikan GoogleSignIn hanya di-initialize sekali.
  Future<void>? _initialization;

  /// Initialize [GoogleSignIn] singleton (lazy, sekali saja).
  Future<void> _ensureInitialized() {
    if (_webClientId.isEmpty) {
      throw Exception(
        'GOOGLE_WEB_CLIENT_ID belum dikonfigurasi. '
        'Google Sign-In native membutuhkan Web Client ID untuk Supabase.',
      );
    }

    return _initialization ??=
        GoogleSignIn.instance.initialize(serverClientId: _webClientId)
          ..catchError((dynamic _) {
            AppLogger.logError(
              'Google Sign-In initialization failed',
              runtimeType: AuthRemoteDataSource,
            );
            _initialization = null;
          });
  }

  /// Melakukan Google Sign-In dan autentikasi ke Supabase.
  ///
  /// Flow (google_sign_in v7):
  /// 1. Panggil `GoogleSignIn.instance.authenticate()` untuk mendapatkan akun.
  /// 2. Ambil `idToken` dari `account.authentication`.
  /// 3. Kirim `idToken` ke Supabase via `signInWithIdToken`.
  /// 4. Trigger di Supabase (`handle_new_user`) otomatis membuat
  ///    record di `public.users`.
  ///
  /// Returns [DataState] berisi [AuthResponse] jika berhasil.
  /// Mengembalikan error jika user membatalkan sign-in atau terjadi kegagalan.
  Future<DataState<AuthResponse>> signInWithGoogle() async {
    return SupabaseHandler.call<AuthResponse>(
      function: () async {
        AppLogger.call(
          '[Auth] [AuthRemoteDataSource] Starting Google Sign-In...',
          colorLog: ColorLog.blue,
        );

        await _ensureInitialized();

        final googleUser = await _resolveGoogleUser();
        final idToken = _readValidIdToken(googleUser);

        AppLogger.call(
          '[Auth] [AuthRemoteDataSource] Google token obtained, signing into Supabase...',
          colorLog: ColorLog.blue,
        );

        final response = await _signInToSupabase(idToken: idToken);

        AppLogger.logSuccess(
          'User signed in: ${response.user?.email}',
          runtimeType: AuthRemoteDataSource,
        );

        return response;
      },
    );
  }

  /// Sign out dari Supabase dan Google.
  ///
  /// Menghapus sesi lokal Supabase dan juga memanggil
  /// `GoogleSignIn().signOut()` agar user bisa memilih akun lain
  /// saat login berikutnya.
  Future<DataState<void>> signOut() async {
    return SupabaseHandler.call<void>(
      function: () async {
        AppLogger.call(
          '[Auth] [AuthRemoteDataSource] Signing out...',
          colorLog: ColorLog.yellow,
        );

        await _ensureInitialized();

        Object? supabaseError;
        StackTrace? supabaseStackTrace;

        try {
          await _client.auth.signOut();
        } catch (error, stackTrace) {
          supabaseError = error;
          supabaseStackTrace = stackTrace;

          AppLogger.logError(
            'Supabase sign-out failed, continuing Google cleanup: $error',
            runtimeType: AuthRemoteDataSource,
          );
        }

        await GoogleSignIn.instance.signOut();

        if (supabaseError != null && supabaseStackTrace != null) {
          Error.throwWithStackTrace(supabaseError, supabaseStackTrace);
        }

        AppLogger.logSuccess(
          'User signed out successfully',
          runtimeType: AuthRemoteDataSource,
        );
      },
    );
  }

  /// Mendapatkan session yang sedang aktif.
  ///
  /// Digunakan saat app pertama kali dibuka (splash screen)
  /// untuk mengecek apakah user masih memiliki sesi valid.
  Session? getCurrentSession() {
    return _client.auth.currentSession;
  }

  /// Mendapatkan user yang sedang login dari Supabase Auth.
  User? getCurrentAuthUser() {
    return _client.auth.currentUser;
  }

  /// Membaca data profil user dari tabel `public.users`.
  ///
  /// Data di `public.users` disinkronkan otomatis saat user
  /// pertama kali sign-up melalui trigger `handle_new_user`.
  Future<DataState<UserModel>> getUserProfile(String userId) async {
    return SupabaseHandler.call<UserModel>(
      function: () async {
        AppLogger.call(
          '[Auth] [AuthRemoteDataSource] Fetching user profile: $userId',
          colorLog: ColorLog.blue,
        );

        final response = await _client
            .from('users')
            .select()
            .eq('id', userId)
            .single();

        final user = UserModel.fromMap(response);

        AppLogger.logSuccess(
          'Profile fetched: ${user.fullName ?? user.email}',
          runtimeType: AuthRemoteDataSource,
        );

        return user;
      },
    );
  }

  /// Update profil user di tabel `public.users`.
  ///
  /// Hanya field `full_name` dan `avatar_url` yang boleh diubah
  /// oleh user. Field `id`, `email` dikelola oleh Supabase Auth.
  Future<DataState<UserModel>> updateUserProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
  }) async {
    return SupabaseHandler.call<UserModel>(
      function: () async {
        AppLogger.call(
          '[Auth] [AuthRemoteDataSource] Updating profile: $userId',
          colorLog: ColorLog.blue,
        );

        final updateData = <String, dynamic>{};
        if (fullName != null) updateData['full_name'] = fullName;
        if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

        final response = await _client
            .from('users')
            .update(updateData)
            .eq('id', userId)
            .select()
            .single();

        final user = UserModel.fromMap(response);

        AppLogger.logSuccess(
          'Profile updated: ${user.fullName}',
          runtimeType: AuthRemoteDataSource,
        );

        return user;
      },
    );
  }

  /// Stream untuk mendengarkan perubahan status autentikasi.
  ///
  /// Digunakan oleh [AuthController] dan router `refreshListenable`
  /// untuk merespons login/logout secara realtime.
  Stream<AuthState> onAuthStateChange() {
    return _client.auth.onAuthStateChange;
  }

  Future<GoogleSignInAccount> _resolveGoogleUser() async {
    final restoredUser = await _attemptLightweightAuthentication();

    if (restoredUser != null) {
      final restoredIdToken = restoredUser.authentication.idToken;

      if (restoredIdToken != null &&
          restoredIdToken.isNotEmpty &&
          !GoogleIdTokenUtils.isExpiredOrNearExpiry(restoredIdToken)) {
        AppLogger.call(
          '[Auth] [AuthRemoteDataSource] Reusing active Google session.',
          colorLog: ColorLog.blue,
        );
        return restoredUser;
      }

      AppLogger.call(
        '[Auth] [AuthRemoteDataSource] Clearing stale Google session before re-authentication...',
        colorLog: ColorLog.yellow,
      );
      await GoogleSignIn.instance.signOut();
    }

    final googleUser = await GoogleSignIn.instance.authenticate();
    final idToken = _readIdToken(googleUser);

    if (!GoogleIdTokenUtils.isExpiredOrNearExpiry(idToken)) {
      return googleUser;
    }

    AppLogger.call(
      '[Auth] [AuthRemoteDataSource] Google returned expired ID token, retrying with a clean session...',
      colorLog: ColorLog.yellow,
    );
    await GoogleSignIn.instance.signOut();

    final refreshedGoogleUser = await GoogleSignIn.instance.authenticate();
    _readValidIdToken(refreshedGoogleUser);

    return refreshedGoogleUser;
  }

  Future<GoogleSignInAccount?> _attemptLightweightAuthentication() async {
    final attempt = GoogleSignIn.instance.attemptLightweightAuthentication();
    if (attempt == null) {
      return null;
    }

    return attempt;
  }

  Future<AuthResponse> _signInToSupabase({required String idToken}) async {
    try {
      return await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } on AuthException catch (error) {
      if (error.message != 'Bad ID token') {
        rethrow;
      }

      AppLogger.call(
        '[Auth] [AuthRemoteDataSource] Supabase rejected Google ID token, forcing fresh Google sign-in...',
        colorLog: ColorLog.yellow,
      );

      await GoogleSignIn.instance.signOut();
      final refreshedGoogleUser = await GoogleSignIn.instance.authenticate();
      final refreshedIdToken = _readValidIdToken(refreshedGoogleUser);

      return _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: refreshedIdToken,
      );
    }
  }

  String _readValidIdToken(GoogleSignInAccount googleUser) {
    final idToken = _readIdToken(googleUser);

    if (GoogleIdTokenUtils.isExpiredOrNearExpiry(idToken)) {
      throw Exception(
        'Google memberikan ID Token yang sudah kedaluwarsa. '
        'Silakan login ulang untuk mengambil token baru.',
      );
    }

    return idToken;
  }

  String _readIdToken(GoogleSignInAccount googleUser) {
    final idToken = googleUser.authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw Exception('Gagal mendapatkan ID Token dari Google');
    }

    return idToken;
  }
}
