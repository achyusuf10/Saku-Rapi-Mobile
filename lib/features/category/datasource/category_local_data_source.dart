import 'dart:convert';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';

/// Local data source untuk cache kategori di Hive (encrypted).
///
/// Menyimpan semua kategori user secara lokal agar bisa diakses
/// tanpa selalu fetch dari Supabase (misal saat offline atau
/// untuk menampilkan picker kategori secara cepat).
class CategoryLocalDataSource {
  static const _categoriesKey = 'cached_categories';

  /// Menyimpan daftar [CategoryModel] ke Hive encrypted box.
  void cacheCategories(List<CategoryModel> categories) {
    AppLogger.call(
      '[Category] [CategoryLocalDataSource] Caching ${categories.length} categories',
      colorLog: ColorLog.blue,
    );
    final jsonList = categories.map((c) => c.toFullMap()).toList();
    HiveService.set<String>(key: _categoriesKey, data: jsonEncode(jsonList));
  }

  /// Membaca daftar [CategoryModel] dari cache Hive.
  ///
  /// Mengembalikan list kosong jika belum pernah di-cache.
  List<CategoryModel> getCachedCategories() {
    final raw = HiveService.get<String>(key: _categoriesKey);
    if (raw == null) return [];

    final jsonList = jsonDecode(raw) as List<dynamic>;
    return jsonList
        .map((e) => CategoryModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Menghapus cache kategori (dipanggil saat sign out).
  void clearCategoryCache() {
    AppLogger.call(
      '[Category] [CategoryLocalDataSource] Clearing category cache',
      colorLog: ColorLog.yellow,
    );
    HiveService.delete(_categoriesKey);
  }
}
