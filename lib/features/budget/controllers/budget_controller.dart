import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/budget/models/budget_model.dart';
import 'package:app_saku_rapi/features/budget/repositories/budget_repository.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ───────────────── Providers ─────────────────

/// Provider singleton untuk [BudgetRepository].
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});

/// Provider utama untuk [BudgetController] — mengelola state budget list.
final budgetControllerProvider =
    StateNotifierProvider<BudgetController, BudgetState>((ref) {
      final repository = ref.watch(budgetRepositoryProvider);
      return BudgetController(repository);
    });

/// Provider computed: budget aktif yang difilter berdasarkan wallet.
final budgetFilteredListProvider = Provider<List<BudgetModel>>((ref) {
  final state = ref.watch(budgetControllerProvider);
  final filter = state.walletFilter;
  if (filter == null) return state.budgets;
  return state.budgets
      .where((b) => b.walletId == filter || b.walletId == null)
      .toList();
});

/// Provider computed: period types yang tersedia dari budget aktif.
final budgetAvailablePeriodTypesProvider = Provider<List<BudgetPeriodType>>((
  ref,
) {
  final budgets = ref.watch(budgetFilteredListProvider);
  final types = budgets.map((b) => b.periodType).toSet().toList();
  // Sort: weekly, monthly, quarterly, yearly, custom
  types.sort((a, b) => a.index.compareTo(b.index));
  return types;
});

/// Provider computed: budget difilter berdasarkan period type yang dipilih.
final budgetByPeriodProvider = Provider<List<BudgetModel>>((ref) {
  final budgets = ref.watch(budgetFilteredListProvider);
  final state = ref.watch(budgetControllerProvider);
  final selected = state.selectedPeriodType;
  if (selected == null) return budgets;
  return budgets.where((b) => b.periodType == selected).toList();
});

/// Provider computed: total anggaran dari budget aktif per periode.
final budgetTotalAmountProvider = Provider<double>((ref) {
  final budgets = ref.watch(budgetByPeriodProvider);
  return BudgetRepository.calculateTotalBudget(budgets);
});

/// Provider computed: total terpakai dari budget aktif per periode.
final budgetTotalUsedProvider = Provider<double>((ref) {
  final budgets = ref.watch(budgetByPeriodProvider);
  return BudgetRepository.calculateTotalUsed(budgets);
});

/// Provider computed: jumlah yang masih bisa dibelanjakan per periode.
final budgetSpendableProvider = Provider<double>((ref) {
  final budgets = ref.watch(budgetByPeriodProvider);
  return BudgetRepository.calculateSpendable(budgets);
});

/// Provider computed: budget yang over (>= 100%).
final budgetOverListProvider = Provider<List<BudgetModel>>((ref) {
  final budgets = ref.watch(budgetFilteredListProvider);
  return budgets.where((b) => b.isOverBudget).toList();
});

/// Provider computed: budget yang mendekati limit (>= 80%, < 100%).
final budgetNearLimitListProvider = Provider<List<BudgetModel>>((ref) {
  final budgets = ref.watch(budgetFilteredListProvider);
  return budgets.where((b) => b.isNearLimit && !b.isOverBudget).toList();
});

// ───────────────── State ─────────────────

enum BudgetStatus { initial, loading, loaded, error }

/// Immutable state untuk budget list.
class BudgetState {
  const BudgetState({
    this.status = BudgetStatus.initial,
    this.budgets = const [],
    this.errorMessage,
    this.walletFilter,
    this.selectedPeriodType,
  });

  final BudgetStatus status;
  final List<BudgetModel> budgets;
  final String? errorMessage;

  /// Wallet ID filter. Null = semua dompet.
  final String? walletFilter;

  /// Period type yang sedang dipilih di tab. Null = auto-select pertama.
  final BudgetPeriodType? selectedPeriodType;

  bool get isLoading => status == BudgetStatus.loading;

  BudgetState copyWith({
    BudgetStatus? status,
    List<BudgetModel>? budgets,
    String? errorMessage,
    String? walletFilter,
    bool clearWalletFilter = false,
    BudgetPeriodType? selectedPeriodType,
    bool clearPeriodType = false,
  }) {
    return BudgetState(
      status: status ?? this.status,
      budgets: budgets ?? this.budgets,
      errorMessage: errorMessage,
      walletFilter: clearWalletFilter
          ? null
          : (walletFilter ?? this.walletFilter),
      selectedPeriodType: clearPeriodType
          ? null
          : (selectedPeriodType ?? this.selectedPeriodType),
    );
  }
}

// ───────────────── Controller ─────────────────

/// Controller untuk CRUD dan state management budget.
///
/// Mengelola [BudgetState] yang berisi list budget aktif + loading/error status.
class BudgetController extends StateNotifier<BudgetState> {
  BudgetController(this._repository) : super(const BudgetState());

  final BudgetRepository _repository;

  /// Update state dan sinkronkan ke cache lokal.
  void _applyBudgets(List<BudgetModel> budgets) {
    state = state.copyWith(status: BudgetStatus.loaded, budgets: budgets);
    _repository.cacheBudgetList(budgets);
  }

  // ───────────────── FILTER ─────────────────

  /// Set wallet filter. Null = semua dompet.
  void setWalletFilter(String? walletId) {
    if (walletId == null) {
      state = state.copyWith(clearWalletFilter: true);
    } else {
      state = state.copyWith(walletFilter: walletId);
    }
  }

  /// Set period type yang sedang dipilih di tab.
  void setSelectedPeriodType(BudgetPeriodType? type) {
    if (type == null) {
      state = state.copyWith(clearPeriodType: true);
    } else {
      state = state.copyWith(selectedPeriodType: type);
    }
  }

  // ───────────────── LOAD ─────────────────

  /// Fetch budget aktif dari server (atau cache offline).
  Future<void> loadBudgets() async {
    state = state.copyWith(status: BudgetStatus.loading);

    final result = await _repository.getActiveBudgets();

    if (result.isSuccess()) {
      final budgets = result.dataSuccess()!;
      state = state.copyWith(status: BudgetStatus.loaded, budgets: budgets);
    } else {
      final (message, _, _, _) = result.dataError()!;
      state = state.copyWith(status: BudgetStatus.error, errorMessage: message);
    }
  }

  /// Fetch budget yang sudah selesai (expired).
  Future<DataState<List<BudgetModel>>> loadCompletedBudgets() {
    return _repository.getCompletedBudgets();
  }

  /// Fetch transaksi terkait budget.
  Future<DataState<List<TransactionModel>>> getTransactionsForBudget({
    required List<String> categoryIds,
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
  }) {
    return _repository.getTransactionsForBudget(
      categoryIds: categoryIds,
      startDate: startDate,
      endDate: endDate,
      walletId: walletId,
    );
  }

  // ───────────────── DUPLICATE CHECK ─────────────────

  /// Cek apakah ada budget duplikat. Return ID jika ada, null jika tidak.
  Future<String?> findDuplicateBudgetId({
    required String categoryId,
    String? walletId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final result = await _repository.findDuplicateBudgetId(
      categoryId: categoryId,
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
    );
    if (result.isSuccess()) return result.dataSuccess();
    return null;
  }

  // ───────────────── CREATE ─────────────────

  /// Buat budget baru.
  Future<DataState<BudgetModel>> createBudget({
    required String userId,
    required String categoryId,
    String? walletId,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
    bool isRecurring = false,
    BudgetPeriodType periodType = BudgetPeriodType.monthly,
  }) async {
    final result = await _repository.createBudget(
      userId: userId,
      categoryId: categoryId,
      walletId: walletId,
      amount: amount,
      startDate: startDate,
      endDate: endDate,
      isRecurring: isRecurring,
      periodType: periodType,
    );

    if (result.isSuccess()) {
      final newBudget = result.dataSuccess()!;
      _applyBudgets([newBudget, ...state.budgets]);
    }
    return result;
  }

  /// Ganti budget lama dengan yang baru (hapus + buat baru).
  Future<DataState<BudgetModel>> replaceBudget({
    required String oldBudgetId,
    required String userId,
    required String categoryId,
    String? walletId,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
    bool isRecurring = false,
    BudgetPeriodType periodType = BudgetPeriodType.monthly,
  }) async {
    final result = await _repository.replaceBudget(
      oldBudgetId: oldBudgetId,
      userId: userId,
      categoryId: categoryId,
      walletId: walletId,
      amount: amount,
      startDate: startDate,
      endDate: endDate,
      isRecurring: isRecurring,
      periodType: periodType,
    );

    if (result.isSuccess()) {
      final newBudget = result.dataSuccess()!;
      final updated = state.budgets.where((b) => b.id != oldBudgetId).toList();
      _applyBudgets([newBudget, ...updated]);
    }
    return result;
  }

  // ───────────────── UPDATE ─────────────────

  /// Update budget yang sudah ada.
  Future<DataState<BudgetModel>> updateBudget({
    required BudgetModel existing,
    required String categoryId,
    String? walletId,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
    bool isRecurring = false,
    BudgetPeriodType periodType = BudgetPeriodType.monthly,
  }) async {
    final result = await _repository.updateBudget(
      existing: existing,
      categoryId: categoryId,
      walletId: walletId,
      amount: amount,
      startDate: startDate,
      endDate: endDate,
      isRecurring: isRecurring,
      periodType: periodType,
    );

    if (result.isSuccess()) {
      final updated = result.dataSuccess()!;
      _applyBudgets(
        state.budgets.map((b) => b.id == updated.id ? updated : b).toList(),
      );
    }
    return result;
  }

  // ───────────────── DELETE ─────────────────

  /// Hapus budget.
  Future<DataState<void>> deleteBudget(String budgetId) async {
    final result = await _repository.deleteBudget(budgetId);

    if (result.isSuccess()) {
      _applyBudgets(state.budgets.where((b) => b.id != budgetId).toList());
    }
    return result;
  }

  // ───────────────── REFRESH ─────────────────

  /// Force refresh — re-fetch dari server.
  Future<void> refresh() => loadBudgets();

  /// Clear cache dan reset state.
  void clearCache() {
    _repository.clearCache();
    state = const BudgetState();
  }
}

// ═══════════════════════════════════════════════════════════════════
// CompletedBudgetsController — state untuk halaman budget selesai.
// ═══════════════════════════════════════════════════════════════════

/// Provider autoDispose untuk [CompletedBudgetsController].
///
/// Otomatis load saat pertama kali di-watch/read.
final completedBudgetsControllerProvider =
    StateNotifierProvider.autoDispose<
      CompletedBudgetsController,
      CompletedBudgetsState
    >((ref) {
      final repository = ref.watch(budgetRepositoryProvider);
      final controller = CompletedBudgetsController(repository);
      controller.load();
      return controller;
    });

/// State untuk halaman completed budgets.
class CompletedBudgetsState {
  const CompletedBudgetsState({
    this.budgets = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  final List<BudgetModel> budgets;
  final bool isLoading;
  final String? errorMessage;

  CompletedBudgetsState copyWith({
    List<BudgetModel>? budgets,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CompletedBudgetsState(
      budgets: budgets ?? this.budgets,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Controller untuk daftar budget yang sudah selesai (expired).
class CompletedBudgetsController extends StateNotifier<CompletedBudgetsState> {
  CompletedBudgetsController(this._repository)
    : super(const CompletedBudgetsState());

  final BudgetRepository _repository;

  /// Load daftar budget yang sudah selesai.
  Future<void> load() async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.getCompletedBudgets();

    if (result.isSuccess()) {
      state = state.copyWith(budgets: result.dataSuccess()!, isLoading: false);
    } else {
      final (message, _, _, _) = result.dataError()!;
      state = state.copyWith(errorMessage: message, isLoading: false);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// BudgetDetailController — state untuk halaman detail budget.
// ═══════════════════════════════════════════════════════════════════

/// Provider autoDispose.family untuk [BudgetDetailController].
///
/// Parameter: budget ID. Otomatis load transaksi terkait budget.
final budgetDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<BudgetDetailController, BudgetDetailState, BudgetModel>((
      ref,
      budget,
    ) {
      final repository = ref.watch(budgetRepositoryProvider);
      final controller = BudgetDetailController(repository, budget);
      controller.loadTransactions();
      return controller;
    });

/// State untuk halaman detail budget.
class BudgetDetailState {
  const BudgetDetailState({
    this.transactions = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  final List<TransactionModel> transactions;
  final bool isLoading;
  final String? errorMessage;

  BudgetDetailState copyWith({
    List<TransactionModel>? transactions,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BudgetDetailState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Controller untuk memuat transaksi terkait satu budget.
class BudgetDetailController extends StateNotifier<BudgetDetailState> {
  BudgetDetailController(this._repository, this._budget)
    : super(const BudgetDetailState());

  final BudgetRepository _repository;
  final BudgetModel _budget;

  /// Load daftar transaksi untuk budget ini.
  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true);

    final categoryIds = <String>[_budget.categoryId];
    final category = _budget.category;
    if (category != null && category.children.isNotEmpty) {
      categoryIds.addAll(category.children.map((c) => c.id));
    }

    final result = await _repository.getTransactionsForBudget(
      categoryIds: categoryIds,
      startDate: _budget.startDate,
      endDate: _budget.endDate,
      walletId: _budget.walletId,
    );

    if (result.isSuccess()) {
      state = state.copyWith(
        transactions: result.dataSuccess()!,
        isLoading: false,
      );
    } else {
      final (message, _, _, _) = result.dataError()!;
      state = state.copyWith(errorMessage: message, isLoading: false);
    }
  }
}
