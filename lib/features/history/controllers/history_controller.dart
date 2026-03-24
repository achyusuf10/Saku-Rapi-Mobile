import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/features/history/repositories/history_repository.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ───────────────── Enums ─────────────────

/// Periode filter untuk history.
enum HistoryPeriod { daily, weekly, monthly, quarterly, yearly, custom }

/// Mode pengelompokan list transaksi.
enum HistoryGroupMode { byDate, byCategory }

// ───────────────── Providers ─────────────────

/// Provider singleton untuk [HistoryRepository].
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository();
});

/// Provider utama untuk [HistoryController].
final historyControllerProvider =
    StateNotifierProvider<HistoryController, HistoryState>((ref) {
      final repository = ref.watch(historyRepositoryProvider);
      return HistoryController(repository);
    });

// ───────────────── State ─────────────────

/// Immutable state untuk fitur history.
class HistoryState {
  const HistoryState({
    this.status = HistoryStatus.initial,
    this.transactions = const [],
    this.period = HistoryPeriod.monthly,
    this.groupMode = HistoryGroupMode.byDate,
    this.walletId,
    this.typeFilter,
    this.customStart,
    this.customEnd,
    this.errorMessage,
    this.offset = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final HistoryStatus status;
  final List<TransactionModel> transactions;
  final HistoryPeriod period;
  final HistoryGroupMode groupMode;
  final String? walletId;
  final TransactionTypeEnum? typeFilter;
  final DateTime? customStart;
  final DateTime? customEnd;
  final String? errorMessage;
  final int offset;
  final bool hasMore;
  final bool isLoadingMore;

  HistoryState copyWith({
    HistoryStatus? status,
    List<TransactionModel>? transactions,
    HistoryPeriod? period,
    HistoryGroupMode? groupMode,
    String? walletId,
    TransactionTypeEnum? typeFilter,
    DateTime? customStart,
    DateTime? customEnd,
    String? errorMessage,
    int? offset,
    bool? hasMore,
    bool? isLoadingMore,
    bool clearWallet = false,
    bool clearType = false,
    bool clearError = false,
  }) {
    return HistoryState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      period: period ?? this.period,
      groupMode: groupMode ?? this.groupMode,
      walletId: clearWallet ? null : (walletId ?? this.walletId),
      typeFilter: clearType ? null : (typeFilter ?? this.typeFilter),
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      offset: offset ?? this.offset,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  /// Hitung date range berdasarkan period saat ini.
  /// Semua batas menggunakan UTC aman untuk query Supabase.
  (DateTime start, DateTime end) get dateRange {
    if (period == HistoryPeriod.custom &&
        customStart != null &&
        customEnd != null) {
      return (
        DateTime.utc(customStart!.year, customStart!.month, customStart!.day),
        DateTime.utc(
          customEnd!.year,
          customEnd!.month,
          customEnd!.day,
          23,
          59,
          59,
        ),
      );
    }

    final now = DateTime.now();
    return switch (period) {
      HistoryPeriod.daily => (
        DateTime.utc(now.year, now.month, now.day),
        DateTime.utc(now.year, now.month, now.day, 23, 59, 59),
      ),
      HistoryPeriod.weekly => () {
        // Monday-based week
        final weekday = now.weekday;
        final monday = now.subtract(Duration(days: weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return (
          DateTime.utc(monday.year, monday.month, monday.day),
          DateTime.utc(sunday.year, sunday.month, sunday.day, 23, 59, 59),
        );
      }(),
      HistoryPeriod.monthly => (
        DateTime.utc(now.year, now.month, 1),
        DateTime.utc(now.year, now.month + 1, 0, 23, 59, 59),
      ),
      HistoryPeriod.quarterly => () {
        final qStart = ((now.month - 1) ~/ 3) * 3 + 1;
        return (
          DateTime.utc(now.year, qStart, 1),
          DateTime.utc(now.year, qStart + 3, 0, 23, 59, 59),
        );
      }(),
      HistoryPeriod.yearly => (
        DateTime.utc(now.year, 1, 1),
        DateTime.utc(now.year, 12, 31, 23, 59, 59),
      ),
      HistoryPeriod.custom => (
        DateTime.utc(now.year, now.month, 1),
        DateTime.utc(now.year, now.month + 1, 0, 23, 59, 59),
      ),
    };
  }

  /// Filter transaksi berdasarkan type (lokal, tidak refetch).
  List<TransactionModel> get filteredTransactions {
    if (typeFilter == null) return transactions;
    return transactions.where((t) => t.type == typeFilter).toList();
  }

  /// Grup transaksi berdasarkan tanggal (lokal).
  Map<String, List<TransactionModel>> get groupedByDate {
    final list = filteredTransactions;
    final map = <String, List<TransactionModel>>{};
    for (final tx in list) {
      // Key by date only (YYYY-MM-DD)
      final key =
          '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}';
      (map[key] ??= []).add(tx);
    }
    return map;
  }

  /// Grup transaksi berdasarkan kategori (lokal).
  Map<String, List<TransactionModel>> get groupedByCategory {
    final list = filteredTransactions;
    final map = <String, List<TransactionModel>>{};
    for (final tx in list) {
      final key = tx.categoryName ?? tx.type.toDbValue();
      (map[key] ??= []).add(tx);
    }
    return map;
  }

  /// Total pemasukan dari transaksi terffilter.
  double get totalIncome {
    return filteredTransactions
        .where((t) => t.type == TransactionTypeEnum.income && !t.isSettlement)
        .fold(0.0, (sum, t) => sum + t.totalAmount);
  }

  /// Total pengeluaran dari transaksi terfilter.
  double get totalExpense {
    return filteredTransactions
        .where((t) => t.type == TransactionTypeEnum.expense && !t.isSettlement)
        .fold(0.0, (sum, t) => sum + t.totalAmount);
  }
}

enum HistoryStatus { initial, loading, loaded, error }

// ───────────────── Controller ─────────────────

/// Controller untuk fitur history transaksi.
///
/// Mengelola:
/// - Fetch data dari repository berdasarkan date range + wallet filter
/// - Pagination (infinite scroll)
/// - Periode filter (daily/weekly/monthly/quarterly/yearly/custom)
/// - Grouping mode (by date / by category) — lokal, tanpa refetch
/// - Type filter (income/expense/etc.) — lokal, tanpa refetch
class HistoryController extends StateNotifier<HistoryState> {
  HistoryController(this._repository) : super(const HistoryState());

  final HistoryRepository _repository;
  static const _pageSize = 30;

  // ───────────────── LOAD ─────────────────

  /// Fetch transaksi berdasarkan filter saat ini (reset pagination).
  Future<void> loadTransactions() async {
    state = state.copyWith(
      status: HistoryStatus.loading,
      offset: 0,
      hasMore: true,
      clearError: true,
    );

    final (start, end) = state.dateRange;
    final result = await _repository.getTransactions(
      startDate: start,
      endDate: end,
      walletId: state.walletId,
      limit: _pageSize,
      offset: 0,
    );

    if (result.isSuccess()) {
      final data = result.dataSuccess()!;
      state = state.copyWith(
        status: HistoryStatus.loaded,
        transactions: data,
        offset: data.length,
        hasMore: data.length >= _pageSize,
      );
    } else {
      final (message, _, _, _) = result.dataError()!;
      state = state.copyWith(
        status: HistoryStatus.error,
        errorMessage: message,
      );
    }
  }

  /// Muat halaman berikutnya (infinite scroll).
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);

    final (start, end) = state.dateRange;
    final result = await _repository.getTransactions(
      startDate: start,
      endDate: end,
      walletId: state.walletId,
      limit: _pageSize,
      offset: state.offset,
    );

    if (result.isSuccess()) {
      final data = result.dataSuccess()!;
      state = state.copyWith(
        transactions: [...state.transactions, ...data],
        offset: state.offset + data.length,
        hasMore: data.length >= _pageSize,
        isLoadingMore: false,
      );
    } else {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  // ───────────────── FILTER ACTIONS ─────────────────

  /// Ganti periode dan refetch.
  Future<void> setPeriod(HistoryPeriod period) async {
    if (state.period == period) return;
    state = state.copyWith(period: period);
    await loadTransactions();
  }

  /// Ganti custom range dan refetch.
  Future<void> setCustomRange(DateTime start, DateTime end) async {
    state = state.copyWith(
      period: HistoryPeriod.custom,
      customStart: start,
      customEnd: end,
    );
    await loadTransactions();
  }

  /// Ganti wallet filter dan refetch.
  Future<void> setWalletFilter(String? walletId) async {
    if (walletId == state.walletId) return;
    if (walletId == null) {
      state = state.copyWith(clearWallet: true);
    } else {
      state = state.copyWith(walletId: walletId);
    }
    await loadTransactions();
  }

  /// Ganti type filter — lokal saja, tanpa refetch (PRD §7.8).
  void setTypeFilter(TransactionTypeEnum? type) {
    if (type == state.typeFilter) return;
    if (type == null) {
      state = state.copyWith(clearType: true);
    } else {
      state = state.copyWith(typeFilter: type);
    }
  }

  /// Ganti grouping mode — lokal saja, tanpa refetch (PRD §7.8).
  void setGroupMode(HistoryGroupMode mode) {
    if (mode == state.groupMode) return;
    state = state.copyWith(groupMode: mode);
  }

  /// Reset semua filter ke default.
  Future<void> resetFilters() async {
    state = const HistoryState(period: HistoryPeriod.monthly);
    await loadTransactions();
  }

  /// Refresh setelah create/edit/delete tanpa mengubah filter.
  Future<void> refresh() async {
    await loadTransactions();
  }

  /// Hapus satu transaksi dari list lokal (setelah delete berhasil).
  void removeTransaction(String transactionId) {
    state = state.copyWith(
      transactions: state.transactions
          .where((t) => t.id != transactionId)
          .toList(),
    );
  }
}
