import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/category/repositories/category_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

export 'package:app_saku_rapi/features/category/repositories/category_repository.dart'
    show CategoryPickerPrefs;

// ─────────────────────────────────────────────────────────
// Filter & Sort Enums (UI-level)
// ─────────────────────────────────────────────────────────

/// Kolom urutan untuk filter kategori di UI.
enum CategorySortField { none, name, createdAt }

/// Arah urutan untuk filter kategori di UI.
enum CategorySortDirection { asc, desc }

/// Filter sumber kategori di UI (semua / buatan user / dari sistem).
enum CategorySourceFilter { all, user, system }

// ─────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────

/// Provider untuk [CategoryRepository] singleton.
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

/// Provider utama untuk [CategoryController].
///
/// Mengelola state CRUD kategori.
final categoryControllerProvider =
    StateNotifierProvider<CategoryController, CategoryState>((ref) {
      final repository = ref.watch(categoryRepositoryProvider);
      return CategoryController(repository);
    });

/// Provider untuk mendapatkan kategori expense yang sudah di-group parent-child.
///
/// Hanya menampilkan kategori yang visible (non-hidden).
/// Digunakan di picker form transaksi.
final expenseCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  final state = ref.watch(categoryControllerProvider);
  final expenseList = state.categories
      .where((c) => c.type == CategoryType.expense)
      .toList();
  return CategoryRepository.groupParentChild(expenseList, includeHidden: false);
});

/// Provider untuk mendapatkan kategori income yang sudah di-group parent-child.
///
/// Hanya menampilkan kategori yang visible (non-hidden).
/// Digunakan di picker form transaksi.
final incomeCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  final state = ref.watch(categoryControllerProvider);
  final incomeList = state.categories
      .where((c) => c.type == CategoryType.income)
      .toList();
  return CategoryRepository.groupParentChild(incomeList, includeHidden: false);
});

/// Provider untuk semua kategori expense (termasuk hidden).
///
/// Digunakan di category management page.
final allExpenseCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  final state = ref.watch(categoryControllerProvider);
  final expenseList = state.categories
      .where((c) => c.type == CategoryType.expense)
      .toList();
  return CategoryRepository.groupParentChild(expenseList);
});

/// Provider untuk semua kategori income (termasuk hidden).
///
/// Digunakan di category management page.
final allIncomeCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  final state = ref.watch(categoryControllerProvider);
  final incomeList = state.categories
      .where((c) => c.type == CategoryType.income)
      .toList();
  return CategoryRepository.groupParentChild(incomeList);
});

// ─────────────────────────────────────────────────────────
// Category State
// ─────────────────────────────────────────────────────────

/// State untuk modul kategori.
class CategoryState {
  const CategoryState({
    this.status = CategoryStatus.initial,
    this.categories = const [],
    this.errorMessage,
  });

  /// Status operasi saat ini.
  final CategoryStatus status;

  /// Flat list semua kategori (belum di-group).
  final List<CategoryModel> categories;

  /// Pesan error terakhir.
  final String? errorMessage;

  /// Apakah sedang loading.
  bool get isLoading => status == CategoryStatus.loading;

  /// Membuat salinan [CategoryState] dengan field yang diubah.
  CategoryState copyWith({
    CategoryStatus? status,
    List<CategoryModel>? categories,
    String? errorMessage,
  }) {
    return CategoryState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      errorMessage: errorMessage,
    );
  }
}

/// Enum status operasi kategori.
enum CategoryStatus {
  /// State awal.
  initial,

  /// Sedang memproses (loading/saving).
  loading,

  /// Data berhasil dimuat.
  loaded,

  /// Terjadi error.
  error,
}

// ─────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────

/// Controller kategori menggunakan [StateNotifier].
///
/// Mengelola:
/// - `loadCategories()` → fetch & cache semua kategori
/// - `createCategory()` → tambah kategori baru
/// - `updateCategory()` → edit kategori existing
/// - `deleteCategory()` → hapus kategori
/// - `toggleHidden()` → hide/show kategori
class CategoryController extends StateNotifier<CategoryState> {
  CategoryController(this._repository) : super(const CategoryState());

  final CategoryRepository _repository;

  /// Fetch semua kategori dari remote + cache.
  Future<void> loadCategories() async {
    state = state.copyWith(status: CategoryStatus.loading);

    final result = await _repository.getCategories();

    result.map(
      success: (success) {
        state = state.copyWith(
          status: CategoryStatus.loaded,
          categories: success.data,
        );
        AppLogger.logSuccess(
          'Loaded ${success.data.length} categories',
          runtimeType: CategoryController,
        );
      },
      error: (error) {
        state = state.copyWith(
          status: CategoryStatus.error,
          errorMessage: error.message,
        );
      },
    );
  }

  /// Buat kategori baru.
  ///
  /// Returns [DataState] untuk UI handling (success alert / error alert).
  /// Setelah berhasil, langsung update state dari response (tanpa reload).
  Future<DataState<CategoryModel>> createCategory({
    required String name,
    required String icon,
    required String color,
    required String backgroundColor,
    required CategoryType type,
    String? parentId,
  }) async {
    final result = await _repository.createCategory(
      name: name,
      icon: icon,
      color: color,
      backgroundColor: backgroundColor,
      type: type,
      parentId: parentId,
      existingCategories: state.categories,
    );

    final created = result.dataSuccess();
    if (created != null) {
      state = state.copyWith(
        status: CategoryStatus.loaded,
        categories: [...state.categories, created],
      );
    }

    return result;
  }

  /// Update kategori existing.
  ///
  /// Setelah berhasil, langsung update state dari response (tanpa reload).
  Future<DataState<CategoryModel>> updateCategory({
    required String categoryId,
    String? name,
    String? icon,
    String? color,
    String? backgroundColor,
    int? sortOrder,
  }) async {
    final result = await _repository.updateCategory(
      categoryId: categoryId,
      name: name,
      icon: icon,
      color: color,
      backgroundColor: backgroundColor,
      sortOrder: sortOrder,
    );

    final updated = result.dataSuccess();
    if (updated != null) {
      state = state.copyWith(
        status: CategoryStatus.loaded,
        categories: state.categories
            .map((c) => c.id == updated.id ? updated : c)
            .toList(),
      );
    }

    return result;
  }

  /// Hapus kategori.
  ///
  /// Setelah berhasil, langsung hapus dari state (tanpa reload).
  Future<DataState<void>> deleteCategory(String categoryId) async {
    final result = await _repository.deleteCategory(categoryId);

    if (result.isSuccess()) {
      state = state.copyWith(
        status: CategoryStatus.loaded,
        categories: state.categories
            .where((c) => c.id != categoryId && c.parentId != categoryId)
            .toList(),
      );
    }

    return result;
  }

  /// Toggle hide/show kategori.
  ///
  /// Setelah berhasil, langsung update state dari response (tanpa reload).
  Future<DataState<CategoryModel>> toggleHidden({
    required String categoryId,
    required bool isHidden,
  }) async {
    final result = await _repository.toggleHidden(
      categoryId: categoryId,
      isHidden: isHidden,
    );

    final updated = result.dataSuccess();
    if (updated != null) {
      state = state.copyWith(
        status: CategoryStatus.loaded,
        categories: state.categories
            .map((c) => c.id == updated.id ? updated : c)
            .toList(),
      );
    }

    return result;
  }

  /// Bersihkan cache kategori (saat sign out).
  void clearCache() {
    _repository.clearCache();
    state = const CategoryState();
  }

  // ───────────────── Picker Filter Prefs ─────────────────

  /// Baca preferensi filter picker kategori untuk [typeValue].
  CategoryPickerPrefs getFilterPrefs(String typeValue) {
    return _repository.getFilterPrefs(typeValue);
  }

  /// Simpan preferensi filter picker kategori untuk [typeValue].
  void saveFilterPrefs(String typeValue, CategoryPickerPrefs prefs) {
    _repository.saveFilterPrefs(typeValue, prefs);
  }

  // ───────────────── Picker Collapsed State ─────────────────

  /// Baca set ID parent yang di-collapse user di picker untuk [typeValue].
  Set<String> getCollapsedParentIds(String typeValue) {
    return _repository.getCollapsedParentIds(typeValue);
  }

  /// Simpan set ID parent yang di-collapse user di picker untuk [typeValue].
  void saveCollapsedParentIds(String typeValue, Set<String> ids) {
    _repository.saveCollapsedParentIds(typeValue, ids);
  }
}
