import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/category/datasource/category_remote_datasource.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';

/// Orkestrator utama untuk fitur Kategori.
///
/// Memanggil [CategoryRemoteDataSource] dan menangani hasilnya
/// menggunakan pattern matching `.map(success:, error:)` dari [DataState].
///
/// Juga bertanggung jawab membangun hierarki parent-child dari flat list.
class CategoryRepository {
  CategoryRepository({required CategoryRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final CategoryRemoteDataSource _remoteDataSource;

  static const String _tag = 'Category';

  // ─────────────────────────────────────────────────────────────
  // Read
  // ─────────────────────────────────────────────────────────────

  /// Mengambil semua kategori dan membangun tree parent-child.
  ///
  /// Return flat list parent categories yang sudah diisi [children].
  Future<DataState<List<CategoryModel>>> getCategories({
    required String userId,
    String? type,
    bool includeHidden = true,
  }) async {
    final result = await _remoteDataSource.getCategories(
      userId: userId,
      type: type,
      includeHidden: includeHidden,
    );

    return result.map(
      success: (data) {
        final tree = _buildTree(data.data);
        AppLogger.call(
          '[$_tag] Berhasil memuat ${data.data.length} kategori '
          '(${tree.length} parent)',
          colorLog: ColorLog.green,
        );
        return DataState.success(data: tree);
      },
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal memuat kategori: ${err.message}',
          runtimeType: CategoryRepository,
        );
        return DataState.error(message: err.message, errorData: err.errorData);
      },
    );
  }

  /// Mengambil flat list kategori TANPA tree (untuk picker).
  Future<DataState<List<CategoryModel>>> getCategoriesFlat({
    required String userId,
    String? type,
    bool includeHidden = false,
  }) async {
    final result = await _remoteDataSource.getCategories(
      userId: userId,
      type: type,
      includeHidden: includeHidden,
    );

    return result.map(
      success: (data) {
        AppLogger.call(
          '[$_tag] Flat list: ${data.data.length} kategori',
          colorLog: ColorLog.green,
        );
        return DataState.success(data: data.data);
      },
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal memuat kategori flat: ${err.message}',
          runtimeType: CategoryRepository,
        );
        return DataState.error(message: err.message, errorData: err.errorData);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Create
  // ─────────────────────────────────────────────────────────────

  /// Membuat kategori baru.
  Future<DataState<CategoryModel>> createCategory(
    CategoryModel category,
  ) async {
    final result = await _remoteDataSource.createCategory(category);

    return result.map(
      success: (data) {
        AppLogger.call(
          '[$_tag] Kategori "${data.data.name}" berhasil dibuat',
          colorLog: ColorLog.green,
        );
        return DataState.success(data: data.data);
      },
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal membuat kategori: ${err.message}',
          runtimeType: CategoryRepository,
        );
        return DataState.error(message: err.message, errorData: err.errorData);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Update
  // ─────────────────────────────────────────────────────────────

  /// Memperbarui data kategori.
  Future<DataState<CategoryModel>> updateCategory(
    CategoryModel category,
  ) async {
    final result = await _remoteDataSource.updateCategory(category);

    return result.map(
      success: (data) {
        AppLogger.call(
          '[$_tag] Kategori "${data.data.name}" berhasil diperbarui',
          colorLog: ColorLog.green,
        );
        return DataState.success(data: data.data);
      },
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal memperbarui kategori: ${err.message}',
          runtimeType: CategoryRepository,
        );
        return DataState.error(message: err.message, errorData: err.errorData);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Delete
  // ─────────────────────────────────────────────────────────────

  /// Menghapus kategori berdasarkan [categoryId].
  Future<DataState<void>> deleteCategory(String categoryId) async {
    final result = await _remoteDataSource.deleteCategory(categoryId);

    return result.map(
      success: (_) {
        AppLogger.call(
          '[$_tag] Kategori ($categoryId) berhasil dihapus',
          colorLog: ColorLog.green,
        );
        return const DataState.success(data: null);
      },
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal menghapus kategori ($categoryId): ${err.message}',
          runtimeType: CategoryRepository,
        );
        return DataState.error(message: err.message, errorData: err.errorData);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Toggle Hide
  // ─────────────────────────────────────────────────────────────

  /// Toggle visibility kategori.
  Future<DataState<void>> toggleHideCategory(
    String categoryId,
    bool isHidden,
  ) async {
    final result = await _remoteDataSource.toggleHideCategory(
      categoryId,
      isHidden,
    );

    return result.map(
      success: (_) {
        AppLogger.call(
          '[$_tag] Kategori ($categoryId) '
          '${isHidden ? 'disembunyikan' : 'ditampilkan'}',
          colorLog: ColorLog.green,
        );
        return const DataState.success(data: null);
      },
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal toggle hide ($categoryId): ${err.message}',
          runtimeType: CategoryRepository,
        );
        return DataState.error(message: err.message, errorData: err.errorData);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Check Usage
  // ─────────────────────────────────────────────────────────────

  /// Cek apakah kategori digunakan di transaksi.
  Future<DataState<bool>> isCategoryUsed(String categoryId) async {
    return _remoteDataSource.isCategoryUsed(categoryId);
  }

  // ─────────────────────────────────────────────────────────────
  // Tree Builder
  // ─────────────────────────────────────────────────────────────

  /// Membangun tree parent-child dari flat list.
  ///
  /// Return: list parent categories, masing-masing sudah diisi [children].
  List<CategoryModel> _buildTree(List<CategoryModel> flatList) {
    // Group children by parentId
    final Map<String, List<CategoryModel>> childrenMap = {};
    final List<CategoryModel> parents = [];

    for (final cat in flatList) {
      if (cat.parentId != null) {
        childrenMap.putIfAbsent(cat.parentId!, () => []).add(cat);
      } else {
        parents.add(cat);
      }
    }

    // Attach children to parents
    return parents.map((parent) {
      final kids = childrenMap[parent.id] ?? [];
      kids.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return parent.copyWith(children: kids);
    }).toList();
  }
}
