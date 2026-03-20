import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/auth/datasource/auth_local_datasource.dart';
import 'package:app_saku_rapi/features/auth/datasource/auth_remote_data_source.dart';
import 'package:app_saku_rapi/features/auth/models/user_model.dart';

/// Repository autentikasi SakuRapi.
///
/// Orkestrator yang memanggil [AuthRemoteDataSource] dan [AuthLocalDataSource],
/// menangani hasilnya menggunakan pattern matching `.map()` dari [DataState].
class AuthRepository {
  AuthRepository({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  }) : _remote = remoteDataSource,
       _local = localDataSource;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  static const String _tag = 'Auth';

  /// Login dengan Google, simpan userId ke Hive, dan kembalikan profil.
  ///
  /// Return [DataState<UserModel>] setelah login + fetch profil sukses.
  Future<DataState<UserModel>> signInWithGoogle() async {
    final authResult = await _remote.signInWithGoogle();

    return authResult.map(
      success: (data) async {
        final userId = data.data?.user?.id;
        if (userId == null) {
          AppLogger.logError('[$_tag] Login sukses tapi userId null');
          return const DataState<UserModel>.error(
            message: 'Login gagal: userId tidak ditemukan',
          );
        }

        AppLogger.call(
          '[$_tag] Sign-In sukses: userId=$userId',
          colorLog: ColorLog.green,
        );

        // Simpan userId ke Hive untuk cek sesi cepat
        await _local.saveUserId(userId);

        // Upsert profil ke public.users (create jika user baru,
        // update jika sudah ada) menggunakan metadata Supabase Auth.
        final upsertResult = await _remote.upsertProfile();
        if (upsertResult.isError()) {
          AppLogger.logError(
            '[$_tag] Upsert profil gagal: ${upsertResult.dataError()?.$1}',
          );
          return DataState<UserModel>.error(
            message: upsertResult.dataError()?.$1 ?? 'Gagal membuat profil',
          );
        }

        // Fetch profil dari public.users
        return getCurrentUser();
      },
      error: (err) async {
        AppLogger.logError('[$_tag] Error Sign-In: ${err.message}');
        return DataState<UserModel>.error(message: err.message);
      },
    );
  }

  /// Ambil profil user saat ini dari Supabase.
  Future<DataState<UserModel>> getCurrentUser() async {
    final result = await _remote.getCurrentUser();

    result.map(
      success: (data) {
        AppLogger.logSuccess('[$_tag] Profil loaded: ${data.data.email}');
      },
      error: (err) {
        AppLogger.logError('[$_tag] Gagal load profil: ${err.message}');
      },
    );

    return result;
  }

  /// Update profil user dan kembalikan data terbaru.
  Future<DataState<UserModel>> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    final result = await _remote.updateProfile(
      fullName: fullName,
      avatarUrl: avatarUrl,
    );

    result.map(
      success: (data) {
        AppLogger.logSuccess('[$_tag] Profil updated: ${data.data.fullName}');
      },
      error: (err) {
        AppLogger.logError('[$_tag] Gagal update profil: ${err.message}');
      },
    );

    return result;
  }

  /// Logout user, hapus cache Hive.
  Future<DataState<void>> signOut() async {
    final result = await _remote.signOut();

    result.map(
      success: (_) {
        _local.clearUserId();
        AppLogger.logSuccess('[$_tag] Logout berhasil.');
      },
      error: (err) {
        AppLogger.logError('[$_tag] Logout gagal: ${err.message}');
      },
    );

    return result;
  }

  /// Cek apakah ada userId tersimpan di Hive (sesi cepat).
  String? getCachedUserId() => _local.getUserId();
}
