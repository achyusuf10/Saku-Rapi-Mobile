import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/core/utils/saku_date_utils.dart';
import 'package:app_saku_rapi/features/history/datasource/history_local_data_source.dart';
import 'package:app_saku_rapi/features/history/models/history_models.dart';
import 'package:app_saku_rapi/features/history/repositories/history_repository.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';

export 'package:app_saku_rapi/features/history/models/history_models.dart';

// ───────────────── Providers ─────────────────

/// Provider singleton untuk [HistoryRepository].
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository();
});

/// Provider singleton untuk [HistoryLocalDataSource].
final historyLocalDataSourceProvider = Provider<HistoryLocalDataSource>((ref) {
  return HistoryLocalDataSource();
});

/// Provider utama untuk [HistoryController].
final historyControllerProvider =
    StateNotifierProvider<HistoryController, HistoryState>((ref) {
      final repository = ref.watch(historyRepositoryProvider);
      final localDataSource = ref.watch(historyLocalDataSourceProvider);
      return HistoryController(repository, localDataSource);
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
    this.subPeriodIndex,
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

  /// Index tab sub-period yang sedang aktif.
  /// null berarti belum di-init (akan di-set ke tab terakhir / "saat ini").
  final int? subPeriodIndex;

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
    int? subPeriodIndex,
    bool clearSubPeriod = false,
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
      subPeriodIndex: clearSubPeriod
          ? null
          : (subPeriodIndex ?? this.subPeriodIndex),
    );
  }

  /// Hitung date range berdasarkan period + subPeriodIndex saat ini.
  /// Semua batas memakai local calendar date untuk query field `date`.
  (DateTime start, DateTime end) get dateRange {
    // Custom mode — gunakan custom date range.
    if (period == HistoryPeriod.custom &&
        customStart != null &&
        customEnd != null) {
      // Sub-period untuk custom = per hari di dalam custom range
      if (subPeriodIndex != null) {
        final tabs = subPeriodTabs;
        final idx = subPeriodIndex!.clamp(0, tabs.length - 1);
        return tabs[idx].dateRange;
      }
      return (
        DateTime(customStart!.year, customStart!.month, customStart!.day),
        DateTime(customEnd!.year, customEnd!.month, customEnd!.day, 23, 59, 59),
      );
    }

    // Jika sub-period dipilih, gunakan date range sub-period.
    if (subPeriodIndex != null) {
      final tabs = subPeriodTabs;
      final idx = subPeriodIndex!.clamp(0, tabs.length - 1);
      return tabs[idx].dateRange;
    }

    // Fallback: range "saat ini" (tab terakhir)
    final now = DateTime.now();
    return switch (period) {
      HistoryPeriod.daily => (
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day, 23, 59, 59),
      ),
      HistoryPeriod.weekly => () {
        // Monday-based week
        final weekday = now.weekday;
        final monday = now.subtract(Duration(days: weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return (
          DateTime(monday.year, monday.month, monday.day),
          DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59),
        );
      }(),
      HistoryPeriod.monthly => (
        DateTime(now.year, now.month, 1),
        DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      ),
      HistoryPeriod.quarterly => () {
        final qStart = ((now.month - 1) ~/ 3) * 3 + 1;
        return (
          DateTime(now.year, qStart, 1),
          DateTime(now.year, qStart + 3, 0, 23, 59, 59),
        );
      }(),
      HistoryPeriod.yearly => (
        DateTime(now.year, 1, 1),
        DateTime(now.year, 12, 31, 23, 59, 59),
      ),
      HistoryPeriod.custom => (
        DateTime(now.year, now.month, 1),
        DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      ),
    };
  }

  /// Generate list sub-period tabs berdasarkan [period].
  /// Masing-masing tab punya label dan dateRange.
  /// Tab terakhir selalu "saat ini".
  List<SubPeriodTab> get subPeriodTabs {
    final now = DateTime.now();

    return switch (period) {
      HistoryPeriod.daily => _generateDailyTabs(now, 30),
      HistoryPeriod.weekly => _generateWeeklyTabs(now, 30),
      HistoryPeriod.monthly => _generateMonthlyTabs(now, 14),
      HistoryPeriod.quarterly => _generateQuarterlyTabs(now, 2),
      HistoryPeriod.yearly => _generateYearlyTabs(now, 5),
      HistoryPeriod.custom => _generateCustomTabs(),
    };
  }

  List<SubPeriodTab> _generateDailyTabs(DateTime now, int maxItems) {
    final tabs = <SubPeriodTab>[];
    final today = DateTime(now.year, now.month, now.day);
    var cursor = today.subtract(Duration(days: maxItems - 1));

    while (!cursor.isAfter(today)) {
      tabs.add(
        SubPeriodTab(
          label: cursor == today
              ? (appContext?.l10n.today ?? 'Hari Ini')
              : '${cursor.day} ${_shortMonth(cursor.month)}',
          dateRange: (
            DateTime(cursor.year, cursor.month, cursor.day),
            DateTime(cursor.year, cursor.month, cursor.day, 23, 59, 59),
          ),
        ),
      );
      cursor = cursor.add(const Duration(days: 1));
    }
    return tabs;
  }

  List<SubPeriodTab> _generateWeeklyTabs(DateTime now, int maxItems) {
    final tabs = <SubPeriodTab>[];
    final currentMonday = now.subtract(Duration(days: now.weekday - 1));
    final todayMon = DateTime(
      currentMonday.year,
      currentMonday.month,
      currentMonday.day,
    );
    var monday = todayMon.subtract(Duration(days: (maxItems - 1) * 7));

    while (!monday.isAfter(todayMon)) {
      final sunday = monday.add(const Duration(days: 6));
      final isCurrentWeek =
          monday.year == todayMon.year &&
          monday.month == todayMon.month &&
          monday.day == todayMon.day;

      tabs.add(
        SubPeriodTab(
          label: isCurrentWeek
              ? (appContext?.l10n.thisWeek ?? 'Minggu Ini')
              : '${monday.day}-${sunday.day} ${_shortMonth(sunday.month)}',
          dateRange: (
            DateTime(monday.year, monday.month, monday.day),
            DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59),
          ),
        ),
      );
      monday = monday.add(const Duration(days: 7));
    }
    return tabs;
  }

  List<SubPeriodTab> _generateMonthlyTabs(DateTime now, int maxItems) {
    final tabs = <SubPeriodTab>[];
    final currentMonth = DateTime(now.year, now.month);
    var cursor = DateTime(now.year, now.month - (maxItems - 1));

    while (!cursor.isAfter(currentMonth)) {
      final isCurrentMonth =
          cursor.year == currentMonth.year &&
          cursor.month == currentMonth.month;

      tabs.add(
        SubPeriodTab(
          label: isCurrentMonth
              ? (appContext?.l10n.thisMonth ?? 'Bulan Ini')
              : '${_fullMonth(cursor.month)} ${cursor.year}',
          dateRange: (
            DateTime(cursor.year, cursor.month, 1),
            DateTime(cursor.year, cursor.month + 1, 0, 23, 59, 59),
          ),
        ),
      );
      // Next month
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return tabs;
  }

  List<SubPeriodTab> _generateQuarterlyTabs(DateTime now, int maxYears) {
    final tabs = <SubPeriodTab>[];
    final currentQ = ((now.month - 1) ~/ 3) * 3 + 1;
    final currentYear = now.year;
    var year = now.year - maxYears;
    var qStart = 1;

    while (year < currentYear || (year == currentYear && qStart <= currentQ)) {
      final qNum = (qStart - 1) ~/ 3 + 1;
      final isCurrentQ = year == currentYear && qStart == currentQ;

      tabs.add(
        SubPeriodTab(
          label: isCurrentQ
              ? (appContext?.l10n.thisQuarter ?? 'Kuartal Ini')
              : 'Q$qNum $year',
          dateRange: (
            DateTime(year, qStart, 1),
            DateTime(year, qStart + 3, 0, 23, 59, 59),
          ),
        ),
      );
      qStart += 3;
      if (qStart > 12) {
        qStart = 1;
        year++;
      }
    }
    return tabs;
  }

  List<SubPeriodTab> _generateYearlyTabs(DateTime now, int maxYears) {
    final tabs = <SubPeriodTab>[];
    for (var y = now.year - maxYears; y <= now.year; y++) {
      tabs.add(
        SubPeriodTab(
          label: y == now.year
              ? (appContext?.l10n.thisYear ?? 'Tahun Ini')
              : '$y',
          dateRange: (DateTime(y, 1, 1), DateTime(y, 12, 31, 23, 59, 59)),
        ),
      );
    }
    return tabs;
  }

  List<SubPeriodTab> _generateCustomTabs() {
    if (customStart == null || customEnd == null) return [];

    final tabs = <SubPeriodTab>[];
    var cursor = DateTime(
      customStart!.year,
      customStart!.month,
      customStart!.day,
    );
    final endDay = DateTime(customEnd!.year, customEnd!.month, customEnd!.day);
    final today = DateTime.now();

    while (!cursor.isAfter(endDay)) {
      final isToday =
          cursor.year == today.year &&
          cursor.month == today.month &&
          cursor.day == today.day;

      tabs.add(
        SubPeriodTab(
          label: isToday
              ? (appContext?.l10n.today ?? 'Hari Ini')
              : '${cursor.day} ${_shortMonth(cursor.month)}',
          dateRange: (
            DateTime(cursor.year, cursor.month, cursor.day),
            DateTime(cursor.year, cursor.month, cursor.day, 23, 59, 59),
          ),
        ),
      );
      cursor = cursor.add(const Duration(days: 1));
    }
    return tabs;
  }

  static String _shortMonth(int m) {
    final locale = appContext?.locale.languageCode ?? 'id';
    final date = DateTime(2024, m);
    return DateFormat('MMM', locale).format(date);
  }

  static String _fullMonth(int m) {
    final locale = appContext?.locale.languageCode ?? 'id';
    final date = DateTime(2024, m);
    return DateFormat('MMMM', locale).format(date);
  }

  /// Hitung net total untuk sekumpulan transaksi.
  /// Income/debt positif, expense/loan negatif, settlement di-skip.
  static double groupNetTotal(List<TransactionModel> txs) {
    double total = 0;
    for (final tx in txs) {
      if (tx.isSettlement) continue;
      if (tx.type == TransactionTypeEnum.income ||
          tx.type == TransactionTypeEnum.debt) {
        total += tx.totalAmount;
      } else if (tx.type == TransactionTypeEnum.expense ||
          tx.type == TransactionTypeEnum.loan) {
        total -= tx.totalAmount;
      }
    }
    return total;
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
      final key = tx.categoryName ?? tx.type.toLocalizedLabel();
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

// ───────────────── Controller ─────────────────

/// Controller untuk fitur history transaksi.
///
/// Mengelola:
/// - Fetch data dari repository berdasarkan date range + wallet filter
/// - Pagination (infinite scroll)
/// - Periode filter (daily/weekly/monthly/quarterly/yearly/custom)
/// - Grouping mode (by date / by category) — lokal, tanpa refetch
/// - Type filter (income/expense/etc.) — lokal, tanpa refetch
/// - Persistensi preferensi filter ke local storage (Hive)
class HistoryController extends StateNotifier<HistoryState> {
  HistoryController(this._repository, this._local)
    : super(_restoreInitialState(_local));

  final HistoryRepository _repository;
  final HistoryLocalDataSource _local;
  static const _pageSize = 30;

  // ───────────────── RESTORE ─────────────────

  /// Baca preferensi filter terakhir dari Hive dan kembalikan sebagai
  /// [HistoryState] awal. Jika tidak ada data atau parsing gagal,
  /// kembalikan state default.
  static HistoryState _restoreInitialState(HistoryLocalDataSource local) {
    try {
      final prefs = local.loadFilterPrefs();
      if (prefs == null) return const HistoryState();

      // ── period ──
      HistoryPeriod period = HistoryPeriod.monthly;
      final periodName = prefs['period'] as String?;
      if (periodName != null) {
        for (final e in HistoryPeriod.values) {
          if (e.name == periodName) {
            period = e;
            break;
          }
        }
      }

      // ── groupMode ──
      HistoryGroupMode groupMode = HistoryGroupMode.byDate;
      final groupModeName = prefs['groupMode'] as String?;
      if (groupModeName != null) {
        for (final e in HistoryGroupMode.values) {
          if (e.name == groupModeName) {
            groupMode = e;
            break;
          }
        }
      }

      // ── walletId ──
      final walletId = prefs['walletId'] as String?;

      // ── typeFilter ──
      TransactionTypeEnum? typeFilter;
      final typeFilterName = prefs['typeFilter'] as String?;
      if (typeFilterName != null) {
        for (final e in TransactionTypeEnum.values) {
          if (e.name == typeFilterName) {
            typeFilter = e;
            break;
          }
        }
      }

      // ── customStart / customEnd ──
      DateTime? customStart, customEnd;
      final customStartRaw = prefs['customStart'] as String?;
      final customEndRaw = prefs['customEnd'] as String?;
      if (customStartRaw != null) {
        customStart = SakuDateUtils.parseOptionalDate(customStartRaw);
      }
      if (customEndRaw != null) {
        customEnd = SakuDateUtils.parseOptionalDate(customEndRaw);
      }

      // ── subPeriodIndex: validasi agar tidak out of bounds ──
      int? subPeriodIndex = prefs['subPeriodIndex'] as int?;
      if (subPeriodIndex != null) {
        final tempState = HistoryState(
          period: period,
          customStart: customStart,
          customEnd: customEnd,
        );
        final tabs = tempState.subPeriodTabs;
        if (tabs.isEmpty || subPeriodIndex >= tabs.length) {
          subPeriodIndex = tabs.isNotEmpty ? tabs.length - 1 : null;
        }
      }

      return HistoryState(
        period: period,
        groupMode: groupMode,
        walletId: walletId,
        typeFilter: typeFilter,
        customStart: customStart,
        customEnd: customEnd,
        subPeriodIndex: subPeriodIndex,
      );
    } catch (_) {
      return const HistoryState();
    }
  }

  // ───────────────── PERSIST ─────────────────

  /// Simpan preferensi filter dari state saat ini ke local storage.
  void _persist() {
    _local.saveFilterPrefs(
      period: state.period,
      groupMode: state.groupMode,
      walletId: state.walletId,
      typeFilter: state.typeFilter,
      subPeriodIndex: state.subPeriodIndex,
      customStart: state.customStart,
      customEnd: state.customEnd,
    );
  }

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

  /// Ganti periode dan refetch. Reset sub-period ke tab terakhir.
  Future<void> setPeriod(HistoryPeriod period) async {
    if (state.period == period) return;
    state = state.copyWith(period: period, clearSubPeriod: true);
    // Set sub-period ke tab terakhir ("saat ini")
    final tabs = state.subPeriodTabs;
    if (tabs.isNotEmpty) {
      state = state.copyWith(subPeriodIndex: tabs.length - 1);
    }
    _persist();
    await loadTransactions();
  }

  /// Ganti custom range dan refetch.
  Future<void> setCustomRange(DateTime start, DateTime end) async {
    state = state.copyWith(
      period: HistoryPeriod.custom,
      customStart: start,
      customEnd: end,
      clearSubPeriod: true,
    );
    // Set sub-period ke tab terakhir
    final tabs = state.subPeriodTabs;
    if (tabs.isNotEmpty) {
      state = state.copyWith(subPeriodIndex: tabs.length - 1);
    }
    _persist();
    await loadTransactions();
  }

  /// Ganti sub-period tab dan refetch.
  Future<void> setSubPeriod(int index) async {
    if (index == state.subPeriodIndex) return;
    state = state.copyWith(subPeriodIndex: index);
    _persist();
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
    _persist();
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
    _persist();
  }

  /// Ganti grouping mode — lokal saja, tanpa refetch (PRD §7.8).
  void setGroupMode(HistoryGroupMode mode) {
    if (mode == state.groupMode) return;
    state = state.copyWith(groupMode: mode);
    _persist();
  }

  /// Reset semua filter ke default.
  Future<void> resetFilters() async {
    state = const HistoryState(period: HistoryPeriod.monthly);
    final tabs = state.subPeriodTabs;
    if (tabs.isNotEmpty) {
      state = state.copyWith(subPeriodIndex: tabs.length - 1);
    }
    _persist();
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
