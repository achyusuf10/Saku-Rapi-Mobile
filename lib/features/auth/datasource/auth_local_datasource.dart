import 'package:app_saku_rapi/utils/services/hive_services.dart';

/// Local data source untuk cache data autentikasi di Hive.
///
/// Menyimpan `userId` agar bisa digunakan untuk pengecekan sesi cepat
/// tanpa harus query ke Supabase.
class AuthLocalDataSource {
  static const String _userIdKey = 'auth_user_id';

  /// Simpan userId ke Hive encrypted box.
  Future<void> saveUserId(String userId) async {
    HiveService.set<String>(key: _userIdKey, data: userId);
  }

  /// Ambil userId yang tersimpan di Hive.
  ///
  /// Return `null` jika belum ada sesi tersimpan.
  String? getUserId() {
    return HiveService.get<String>(key: _userIdKey);
  }

  /// Hapus userId dari Hive (saat logout).
  Future<void> clearUserId() async {
    HiveService.delete(_userIdKey);
  }
}
