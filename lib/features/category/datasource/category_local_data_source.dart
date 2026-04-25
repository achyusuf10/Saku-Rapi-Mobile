import 'dart:convert';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';

// ───────────────── Picker Filter Prefs Model ─────────────────

/// Preferensi filter & sort picker kategori yang di-persist per [typeValue].
class CategoryPickerPrefs {
  const CategoryPickerPrefs({
    this.sortField = 'none',
    this.sortDirection = 'asc',
    this.sourceFilter = 'all',
  });

  final String sortField;
  final String sortDirection;
  final String sourceFilter;

  factory CategoryPickerPrefs.fromMap(Map<String, dynamic> map) {
    return CategoryPickerPrefs(
      sortField: (map['sort_field'] as String?) ?? 'none',
      sortDirection: (map['sort_direction'] as String?) ?? 'asc',
      sourceFilter: (map['source_filter'] as String?) ?? 'all',
    );
  }

  Map<String, dynamic> toMap() => {
    'sort_field': sortField,
    'sort_direction': sortDirection,
    'source_filter': sourceFilter,
  };
}

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

  // ───────────────── Picker Filter Prefs ─────────────────

  static String _filterPrefsKey(String typeValue) =>
      'category_filter_prefs_$typeValue';

  /// Baca preferensi filter picker kategori untuk [typeValue].
  CategoryPickerPrefs getFilterPrefs(String typeValue) {
    final raw = HiveService.get<String>(key: _filterPrefsKey(typeValue));
    if (raw == null) return const CategoryPickerPrefs();
    try {
      return CategoryPickerPrefs.fromMap(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const CategoryPickerPrefs();
    }
  }

  /// Simpan preferensi filter picker kategori untuk [typeValue].
  void saveFilterPrefs(String typeValue, CategoryPickerPrefs prefs) {
    HiveService.set<String>(
      key: _filterPrefsKey(typeValue),
      data: jsonEncode(prefs.toMap()),
    );
  }

  // ───────────────── Collapsed State ─────────────────

  static String _collapsedKey(String typeValue) =>
      'category_picker_collapsed_$typeValue';

  /// Baca set ID kategori yang di-collapse oleh user.
  Set<String> getCollapsedParentIds(String typeValue) {
    final raw = HiveService.get<String>(key: _collapsedKey(typeValue));
    if (raw == null) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  /// Simpan set ID kategori yang di-collapse.
  void saveCollapsedParentIds(String typeValue, Set<String> ids) {
    HiveService.set<String>(
      key: _collapsedKey(typeValue),
      data: jsonEncode(ids.toList()),
    );
  }
}
