import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/auth/models/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk operasi autentikasi SakuRapi.
///
/// Menggunakan `google_sign_in` untuk mendapatkan token OAuth Google,
/// lalu meneruskannya ke Supabase Auth via `signInWithIdToken`.
///
/// Semua fungsi dibungkus [SupabaseHandler.call] dan me-return [DataState].
class AuthRemoteDataSource {
  AuthRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Web client ID untuk Google Sign-In (dari Supabase dashboard / GCP).
  ///
  /// Diambil dari compile-time env agar tidak ter-hardcode di source.
  static const String _webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  /// iOS client ID untuk Google Sign-In.
  static const String _iosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
  Future<void>? _initialization;

  Future<void> _ensureInitialized() {
    AppLogger.call('Ensuring Google Sign-In is initialized...');
    AppLogger.call('Web Client ID: $_webClientId');
    return _initialization ??=
        GoogleSignInPlatform.instance.init(
          InitParameters(
            // clientId: _iosClientId.isNotEmpty ? _iosClientId : null,
            serverClientId: _webClientId.isNotEmpty ? _webClientId : null,
          ),
        )..catchError((dynamic _) {
          AppLogger.call('Google Sign In Initialization Error');
          _initialization = null;
        });
  }

  /// Login menggunakan Google Sign-In dan sambungkan ke Supabase.
  ///
  /// Return [DataState<AuthResponse?>].
  Future<DataState<AuthResponse?>> signInWithGoogle() async {
    return SupabaseHandler.call(
      function: () async {
        await _ensureInitialized();
        final result = await GoogleSignInPlatform.instance.authenticate(
          AuthenticateParameters(),
        );
        final idToken = result.authenticationTokens.idToken ?? '';
        final AuthResponse res = await _client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
        );
        return res;
      },
    );
  }

  /// Logout user dari Supabase dan Google.
  ///
  /// Return [DataState<void>].
  Future<DataState<void>> signOut() {
    return SupabaseHandler.call<void>(
      function: () async {
        await _ensureInitialized();
        await _client.auth.signOut();
        await GoogleSignIn.instance.signOut();
      },
    );
  }

  /// Ambil profil user saat ini dari tabel `public.users`.
  ///
  /// Return [DataState<UserModel>].
  Future<DataState<UserModel>> getCurrentUser() {
    return SupabaseHandler.call<UserModel>(
      function: () async {
        final userId = _client.auth.currentUser!.id;
        final data = await _client
            .from('users')
            .select()
            .eq('id', userId)
            .single();
        return UserModel.fromMap(data);
      },
    );
  }

  /// Upsert profil user ke tabel `public.users` menggunakan metadata
  /// dari Supabase Auth (email, nama, avatar dari Google).
  ///
  /// Dipanggil setelah Google Sign-In berhasil untuk memastikan row
  /// ada di tabel (baik user baru maupun user yang sudah ada).
  ///
  /// Return [DataState<void>].
  Future<DataState<void>> upsertProfile() {
    return SupabaseHandler.call<void>(
      function: () async {
        final user = _client.auth.currentUser!;
        await _client.from('users').upsert({
          'id': user.id,
          'email': user.email ?? '',
          'full_name': user.userMetadata?['full_name'],
          'avatar_url': user.userMetadata?['avatar_url'],
        }, onConflict: 'id');
      },
    );
  }

  /// Update profil user di tabel `public.users`.
  ///
  /// Return [DataState<UserModel>] dengan data terbaru.
  Future<DataState<UserModel>> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) {
    return SupabaseHandler.call<UserModel>(
      function: () async {
        final userId = _client.auth.currentUser!.id;
        final updates = <String, dynamic>{};
        if (fullName != null) updates['full_name'] = fullName;
        if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
        final data = await _client
            .from('users')
            .update(updates)
            .eq('id', userId)
            .select()
            .single();
        return UserModel.fromMap(data);
      },
    );
  }
}
