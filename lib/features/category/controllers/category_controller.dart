import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/category/datasource/category_remote_datasource.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/category/repositories/category_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────

/// Provider placeholder untuk [CategoryRepository].
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(
    remoteDataSource: CategoryRemoteDataSource(
      client: Supabase.instance.client,
    ),
  );
});

/// State utama yang menyimpan kategori per tipe.
class CategoryState {
  const CategoryState({
    this.expenseCategories = const [],
    this.incomeCategories = const [],
  });

  /// Tree parent-child kategori pengeluaran.
  final List<CategoryModel> expenseCategories;

  /// Tree parent-child kategori pemasukan.
  final List<CategoryModel> incomeCategories;

  CategoryState copyWith({
    List<CategoryModel>? expenseCategories,
    List<CategoryModel>? incomeCategories,
  }) {
    return CategoryState(
      expenseCategories: expenseCategories ?? this.expenseCategories,
      incomeCategories: incomeCategories ?? this.incomeCategories,
    );
  }
}

/// Provider utama untuk [CategoryController].
///
/// State berupa `AsyncValue<CategoryState>`.
final categoryControllerProvider =
    AsyncNotifierProvider<CategoryController, CategoryState>(() {
      return CategoryController();
    });

// ─────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────

/// Riverpod [AsyncNotifier] untuk mengelola CRUD kategori.
///
/// Maintain tree parent-child untuk 'expense' dan 'income'.
/// Dapat di-share ke `TransactionFormScreen` untuk category picker.
class CategoryController extends AsyncNotifier<CategoryState> {
  late final CategoryRepository _repository;

  static const String _tag = 'Category';

  @override
  Future<CategoryState> build() async {
    _repository = ref.watch(categoryRepositoryProvider);
    return _fetchAllCategories();
  }

  /// Fetch semua kategori (expense + income) sekaligus.
  Future<CategoryState> _fetchAllCategories() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    AppLogger.call(
      '[$_tag] Memulai fetch semua kategori...',
      colorLog: ColorLog.blue,
    );

    final expenseResult = await _repository.getCategories(
      userId: userId,
      type: 'expense',
    );
    final incomeResult = await _repository.getCategories(
      userId: userId,
      type: 'income',
    );

    List<CategoryModel> expenses = [];
    List<CategoryModel> incomes = [];

    expenseResult.map(
      success: (data) => expenses = data.data,
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal fetch expense categories: ${err.message}',
          runtimeType: CategoryController,
        );
      },
    );

    incomeResult.map(
      success: (data) => incomes = data.data,
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal fetch income categories: ${err.message}',
          runtimeType: CategoryController,
        );
      },
    );

    AppLogger.call(
      '[$_tag] Fetch berhasil: ${expenses.length} expense parents, '
      '${incomes.length} income parents',
      colorLog: ColorLog.green,
    );

    return CategoryState(
      expenseCategories: expenses,
      incomeCategories: incomes,
    );
  }

  /// Refresh data kategori.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchAllCategories());
  }

  // ───────────────── Getters ─────────────────

  /// Return tree kategori berdasarkan tipe.
  List<CategoryModel> getCategoriesForType(String type) {
    final data = state.value;
    if (data == null) return [];
    return type == 'income' ? data.incomeCategories : data.expenseCategories;
  }

  // ───────────────── Create ─────────────────

  /// Menambah kategori baru.
  Future<DataState<CategoryModel>> addCategory(CategoryModel category) async {
    AppLogger.call(
      '[$_tag] Menambah kategori "${category.name}"...',
      colorLog: ColorLog.blue,
    );

    final result = await _repository.createCategory(category);

    if (result.isSuccess()) {
      await refresh();
    }

    return result;
  }

  // ───────────────── Update ─────────────────

  /// Memperbarui kategori yang sudah ada.
  Future<DataState<CategoryModel>> editCategory(CategoryModel category) async {
    AppLogger.call(
      '[$_tag] Memperbarui kategori "${category.name}"...',
      colorLog: ColorLog.blue,
    );

    final result = await _repository.updateCategory(category);

    if (result.isSuccess()) {
      await refresh();
    }

    return result;
  }

  // ───────────────── Delete ─────────────────

  /// Menghapus kategori.
  ///
  /// Kategori default (`isDefault == true`) TIDAK bisa dihapus.
  Future<DataState<void>> removeCategory(String categoryId) async {
    AppLogger.call(
      '[$_tag] Menghapus kategori ($categoryId)...',
      colorLog: ColorLog.blue,
    );

    final result = await _repository.deleteCategory(categoryId);

    if (result.isSuccess()) {
      await refresh();
    }

    return result;
  }

  // ───────────────── Toggle Hide ─────────────────

  /// Toggle hide/show kategori.
  Future<DataState<void>> toggleHide(String categoryId, bool isHidden) async {
    AppLogger.call(
      '[$_tag] Toggle hide ($categoryId) → $isHidden',
      colorLog: ColorLog.blue,
    );

    final result = await _repository.toggleHideCategory(categoryId, isHidden);

    if (result.isSuccess()) {
      await refresh();
    }

    return result;
  }

  // ───────────────── Check Usage ─────────────────

  /// Cek apakah kategori digunakan di transaksi.
  Future<bool> isCategoryUsed(String categoryId) async {
    final result = await _repository.isCategoryUsed(categoryId);
    return result.dataSuccess() ?? false;
  }
}
