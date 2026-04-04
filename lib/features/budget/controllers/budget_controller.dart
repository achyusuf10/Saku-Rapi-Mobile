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
/// Custom budgets mendapat tab key unik berdasarkan tanggal.
final budgetAvailablePeriodTypesProvider = Provider<List<String>>((ref) {
  final budgets = ref.watch(budgetFilteredListProvider);
  final keys = <String>{};
  for (final b in budgets) {
    if (b.periodType == BudgetPeriodType.custom) {
      keys.add(
        'custom_${b.startDate.toIso8601String().substring(0, 10)}_${b.endDate.toIso8601String().substring(0, 10)}',
      );
    } else {
      keys.add(b.periodType.value);
    }
  }
  // Sort: standard types first (by enum order), then custom by date
  final sorted = keys.toList()
    ..sort((a, b) {
      final aIdx = _periodSortIndex(a);
      final bIdx = _periodSortIndex(b);
      if (aIdx != bIdx) return aIdx.compareTo(bIdx);
      return a.compareTo(b);
    });
  return sorted;
});

int _periodSortIndex(String key) {
  if (key == 'weekly') return 0;
  if (key == 'monthly') return 1;
  if (key == 'quarterly') return 2;
  if (key == 'yearly') return 3;
  return 4; // custom_*
}

/// Provider computed: budget difilter berdasarkan period tab key yang dipilih.
final budgetByPeriodProvider = Provider<List<BudgetModel>>((ref) {
  final budgets = ref.watch(budgetFilteredListProvider);
  final state = ref.watch(budgetControllerProvider);
  final selectedKey = state.selectedPeriodKey;
  if (selectedKey == null) return budgets;

  return budgets.where((b) {
    if (b.periodType == BudgetPeriodType.custom) {
      return 'custom_${b.startDate.toIso8601String().substring(0, 10)}_${b.endDate.toIso8601String().substring(0, 10)}' ==
          selectedKey;
    }
    return b.periodType.value == selectedKey;
  }).toList();
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
    this.upcomingBudgets = const [],
    this.errorMessage,
    this.walletFilter,
    this.selectedPeriodKey,
  });

  final BudgetStatus status;
  final List<BudgetModel> budgets;
  final List<BudgetModel> upcomingBudgets;
  final String? errorMessage;

  /// Wallet ID filter. Null = semua dompet.
  final String? walletFilter;

  /// Period tab key yang sedang dipilih. Null = auto-select pertama.
  final String? selectedPeriodKey;

  bool get isLoading => status == BudgetStatus.loading;

  BudgetState copyWith({
    BudgetStatus? status,
    List<BudgetModel>? budgets,
    List<BudgetModel>? upcomingBudgets,
    String? errorMessage,
    String? walletFilter,
    bool clearWalletFilter = false,
    String? selectedPeriodKey,
    bool clearPeriodKey = false,
  }) {
    return BudgetState(
      status: status ?? this.status,
      budgets: budgets ?? this.budgets,
      upcomingBudgets: upcomingBudgets ?? this.upcomingBudgets,
      errorMessage: errorMessage,
      walletFilter: clearWalletFilter
          ? null
          : (walletFilter ?? this.walletFilter),
      selectedPeriodKey: clearPeriodKey
          ? null
          : (selectedPeriodKey ?? this.selectedPeriodKey),
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

  /// Set period tab key yang sedang dipilih.
  void setSelectedPeriodKey(String? key) {
    if (key == null) {
      state = state.copyWith(clearPeriodKey: true);
    } else {
      state = state.copyWith(selectedPeriodKey: key);
    }
  }

  // ───────────────── LOAD ─────────────────

  /// Fetch budget aktif dari server (atau cache offline).
  Future<void> loadBudgets() async {
    state = state.copyWith(status: BudgetStatus.loading);

    final result = await _repository.getActiveBudgets();

    if (result.isSuccess()) {
      final budgets = result.dataSuccess()!;

      // Also fetch upcoming budgets
      final upcomingResult = await _repository.getUpcomingBudgets();
      final upcoming = upcomingResult.isSuccess()
          ? upcomingResult.dataSuccess()!
          : <BudgetModel>[];

      state = state.copyWith(
        status: BudgetStatus.loaded,
        budgets: budgets,
        upcomingBudgets: upcoming,
      );
    } else {
      final (message, _, _, _) = result.dataError()!;
      state = state.copyWith(status: BudgetStatus.error, errorMessage: message);
    }
  }

  /// Fetch budget yang sudah selesai (expired) dengan pagination.
  Future<DataState<List<BudgetModel>>> loadCompletedBudgets({
    int limit = 20,
    int offset = 0,
  }) {
    return _repository.getCompletedBudgets(limit: limit, offset: offset);
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
    bool carryForward = false,
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
      carryForward: carryForward,
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
    bool carryForward = false,
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
      carryForward: carryForward,
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
    bool carryForward = false,
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
      carryForward: carryForward,
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

/// State untuk halaman completed budgets dengan pagination.
class CompletedBudgetsState {
  const CompletedBudgetsState({
    this.budgets = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
  });

  final List<BudgetModel> budgets;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;

  CompletedBudgetsState copyWith({
    List<BudgetModel>? budgets,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
  }) {
    return CompletedBudgetsState(
      budgets: budgets ?? this.budgets,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }
}

/// Controller untuk daftar budget yang sudah selesai (expired) dengan pagination.
class CompletedBudgetsController extends StateNotifier<CompletedBudgetsState> {
  CompletedBudgetsController(this._repository)
    : super(const CompletedBudgetsState());

  final BudgetRepository _repository;
  static const _pageSize = 20;

  /// Load halaman pertama.
  Future<void> load() async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.getCompletedBudgets(
      limit: _pageSize,
      offset: 0,
    );

    if (result.isSuccess()) {
      final budgets = result.dataSuccess()!;
      state = state.copyWith(
        budgets: budgets,
        isLoading: false,
        hasMore: budgets.length >= _pageSize,
      );
    } else {
      final (message, _, _, _) = result.dataError()!;
      state = state.copyWith(errorMessage: message, isLoading: false);
    }
  }

  /// Load halaman berikutnya (pagination).
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    final result = await _repository.getCompletedBudgets(
      limit: _pageSize,
      offset: state.budgets.length,
    );

    if (result.isSuccess()) {
      final newBudgets = result.dataSuccess()!;
      state = state.copyWith(
        budgets: [...state.budgets, ...newBudgets],
        isLoadingMore: false,
        hasMore: newBudgets.length >= _pageSize,
      );
    } else {
      state = state.copyWith(isLoadingMore: false);
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

    // Build category IDs: budget category + child categories
    final categoryIds = <String>[_budget.categoryId];

    // Fetch child category IDs from DB (more reliable than join)
    final childResult = await _repository.getChildCategoryIds(
      _budget.categoryId,
    );
    if (childResult.isSuccess()) {
      categoryIds.addAll(childResult.dataSuccess()!);
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
