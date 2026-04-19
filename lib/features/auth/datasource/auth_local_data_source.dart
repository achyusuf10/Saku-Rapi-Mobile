import 'dart:convert';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/auth/models/user_model.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';

/// Local data source untuk cache data user di Hive (encrypted).
///
/// Menyimpan profil user secara lokal agar bisa diakses tanpa
/// harus selalu fetch dari Supabase (misal saat offline atau
/// untuk menampilkan data profil di header).
class AuthLocalDataSource {
  static const _userKey = 'cached_user_profile';

  /// Menyimpan data [UserModel] ke Hive encrypted box.
  void cacheUserProfile(UserModel user) {
    AppLogger.call(
      '[Auth] [AuthLocalDataSource] Caching user: ${user.email}',
      colorLog: ColorLog.blue,
    );
    HiveService.set<String>(key: _userKey, data: jsonEncode(user.toMap()));
  }

  /// Membaca data [UserModel] dari cache Hive.
  ///
  /// Mengembalikan `null` jika belum pernah di-cache.
  UserModel? getCachedUserProfile() {
    final raw = HiveService.get<String>(key: _userKey);
    if (raw == null) return null;
    AppLogger.call(
      '[Auth] [AuthLocalDataSource] Retrieved cached user profile',
      colorLog: ColorLog.blue,
    );

    final map = jsonDecode(raw) as Map<String, dynamic>;
    return UserModel.fromMap(map);
  }

  /// Menghapus cache user (dipanggil saat sign out).
  void clearUserCache() {
    AppLogger.call(
      '[Auth] [AuthLocalDataSource] Clearing user cache',
      colorLog: ColorLog.yellow,
    );
    HiveService.delete(_userKey);
  }
}
