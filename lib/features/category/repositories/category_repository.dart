import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/category/datasource/category_local_data_source.dart';
import 'package:app_saku_rapi/features/category/datasource/category_remote_data_source.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';

/// Repository utama untuk modul kategori.
///
/// Mengorkestrasikan [CategoryRemoteDataSource] dan [CategoryLocalDataSource]
/// sesuai 3-file pattern SakuRapi.
///
/// Bertanggung jawab atas:
/// - Fetch & cache kategori
/// - CRUD kategori user
/// - Parent-child grouping (max 2 level)
/// - Validasi constraint sebelum dikirim ke server
class CategoryRepository {
  CategoryRepository({
    CategoryRemoteDataSource? remoteDataSource,
    CategoryLocalDataSource? localDataSource,
  }) : _remoteDataSource = remoteDataSource ?? CategoryRemoteDataSource(),
       _localDataSource = localDataSource ?? CategoryLocalDataSource();

  final CategoryRemoteDataSource _remoteDataSource;
  final CategoryLocalDataSource _localDataSource;

  /// Fetch semua kategori dari remote, cache ke lokal, dan return.
  ///
  /// Jika remote gagal, fallback ke cache lokal.
  Future<DataState<List<CategoryModel>>> getCategories() async {
    final result = await _remoteDataSource.getCategories();

    return result.map(
      success: (success) {
        _localDataSource.cacheCategories(success.data);
        return DataState<List<CategoryModel>>.success(data: success.data);
      },
      error: (error) {
        // Fallback ke cache
        final cached = _localDataSource.getCachedCategories();
        if (cached.isNotEmpty) {
          AppLogger.call(
            '[Category] [CategoryRepository] Using cached categories as fallback',
            colorLog: ColorLog.yellow,
          );
          return DataState<List<CategoryModel>>.success(data: cached);
        }
        return DataState<List<CategoryModel>>.error(
          message: error.message,
          exception: error.exception,
          stackTrace: error.stackTrace,
        );
      },
    );
  }

  /// Fetch kategori berdasarkan [type] (income/expense/system).
  ///
  /// Prioritas: remote → cache lokal (filtered by type).
  Future<DataState<List<CategoryModel>>> getCategoriesByType(
    CategoryType type,
  ) async {
    final result = await _remoteDataSource.getCategoriesByType(type);

    return result.map(
      success: (success) {
        return DataState<List<CategoryModel>>.success(data: success.data);
      },
      error: (error) {
        // Fallback ke cache filtered
        final cached = _localDataSource
            .getCachedCategories()
            .where((c) => c.type == type)
            .toList();
        if (cached.isNotEmpty) {
          AppLogger.call(
            '[Category] [CategoryRepository] Using cached ${type.value} categories',
            colorLog: ColorLog.yellow,
          );
          return DataState<List<CategoryModel>>.success(data: cached);
        }
        return DataState<List<CategoryModel>>.error(
          message: error.message,
          exception: error.exception,
          stackTrace: error.stackTrace,
        );
      },
    );
  }

  /// Buat kategori baru setelah validasi constraint.
  ///
  /// Validasi:
  /// - Jika [parentId] diberikan, cek parent valid & type sama.
  /// - Child tidak boleh punya child (max 2 level).
  /// - Nama tidak boleh duplikat dalam scope yang sama.
  Future<DataState<CategoryModel>> createCategory({
    required String name,
    required String icon,
    required String color,
    required CategoryType type,
    String? parentId,
    List<CategoryModel>? existingCategories,
  }) async {
    // Validasi parent-child constraint
    if (parentId != null && existingCategories != null) {
      final validationError = _validateParentChild(
        parentId: parentId,
        type: type,
        categories: existingCategories,
      );
      if (validationError != null) {
        return DataState<CategoryModel>.error(message: validationError);
      }
    }

    // Validasi duplikat nama di scope yang sama
    if (existingCategories != null) {
      final isDuplicate = _isDuplicateName(
        name: name,
        type: type,
        parentId: parentId,
        categories: existingCategories,
      );
      if (isDuplicate) {
        return const DataState<CategoryModel>.error(
          message: 'Nama kategori sudah ada',
        );
      }
    }

    final result = await _remoteDataSource.createCategory(
      name: name,
      icon: icon,
      color: color,
      type: type,
      parentId: parentId,
    );

    // Refresh cache setelah berhasil create
    if (result.isSuccess()) {
      _refreshCache();
    }

    return result;
  }

  /// Update kategori existing.
  Future<DataState<CategoryModel>> updateCategory({
    required String categoryId,
    String? name,
    String? icon,
    String? color,
    bool? isHidden,
    int? sortOrder,
  }) async {
    final result = await _remoteDataSource.updateCategory(
      categoryId: categoryId,
      name: name,
      icon: icon,
      color: color,
      isHidden: isHidden,
      sortOrder: sortOrder,
    );

    if (result.isSuccess()) {
      _refreshCache();
    }

    return result;
  }

  /// Hapus kategori (hard delete).
  ///
  /// Hanya untuk kategori non-default milik user.
  Future<DataState<void>> deleteCategory(String categoryId) async {
    final result = await _remoteDataSource.deleteCategory(categoryId);

    if (result.isSuccess()) {
      _refreshCache();
    }

    return result;
  }

  /// Toggle hide/show kategori.
  Future<DataState<CategoryModel>> toggleHidden({
    required String categoryId,
    required bool isHidden,
  }) async {
    final result = await _remoteDataSource.toggleHidden(
      categoryId: categoryId,
      isHidden: isHidden,
    );

    if (result.isSuccess()) {
      _refreshCache();
    }

    return result;
  }

  /// Bersihkan cache lokal (dipanggil saat sign out).
  void clearCache() {
    _localDataSource.clearCategoryCache();
  }

  // ─────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────

  /// Grouping flat list menjadi hierarki parent → children.
  ///
  /// Mengembalikan hanya parent categories, masing-masing
  /// sudah terisi `children` yang sesuai.
  /// Kategori hidden bisa difilter sesuai kebutuhan.
  static List<CategoryModel> groupParentChild(
    List<CategoryModel> flatList, {
    bool includeHidden = true,
  }) {
    final filtered = includeHidden
        ? flatList
        : flatList.where((c) => !c.isHidden).toList();

    final parents = filtered.where((c) => c.isParent).toList();
    final childMap = <String, List<CategoryModel>>{};

    for (final child in filtered.where((c) => c.isChild)) {
      childMap.putIfAbsent(child.parentId!, () => []).add(child);
    }

    return parents.map((parent) {
      final children = childMap[parent.id] ?? [];
      children.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return parent.copyWith(children: children);
    }).toList();
  }

  /// Refresh cache di background setelah mutasi.
  void _refreshCache() {
    _remoteDataSource.getCategories().then((result) {
      result.map(
        success: (success) {
          _localDataSource.cacheCategories(success.data);
        },
        error: (_) {},
      );
    });
  }

  /// Validasi parent-child constraint.
  ///
  /// - Parent harus ada dan bertipe sama.
  /// - Parent tidak boleh punya parent sendiri (max 2 level).
  String? _validateParentChild({
    required String parentId,
    required CategoryType type,
    required List<CategoryModel> categories,
  }) {
    final parent = categories.where((c) => c.id == parentId).firstOrNull;

    if (parent == null) {
      return 'Kategori induk tidak ditemukan';
    }

    if (parent.type != type) {
      return 'Tipe kategori harus sama dengan kategori induk';
    }

    // Max 2 level: parent tidak boleh punya parent sendiri
    if (parent.parentId != null) {
      return 'Kategori maksimal 2 level (induk → anak)';
    }

    return null;
  }

  /// Cek duplikat nama di scope yang sama (type + parent level).
  bool _isDuplicateName({
    required String name,
    required CategoryType type,
    String? parentId,
    required List<CategoryModel> categories,
    String? excludeId,
  }) {
    final normalizedName = name.trim().toLowerCase();
    return categories.any(
      (c) =>
          c.type == type &&
          c.parentId == parentId &&
          c.name.trim().toLowerCase() == normalizedName &&
          c.id != excludeId,
    );
  }
}
