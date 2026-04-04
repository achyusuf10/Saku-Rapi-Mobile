import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/history/models/history_models.dart';
import 'package:app_saku_rapi/features/reports/models/report_model.dart';
import 'package:app_saku_rapi/features/reports/models/report_page_argument.dart';
import 'package:app_saku_rapi/features/reports/repositories/report_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';

// ───────────────── Enums ─────────────────

/// Alias backward-compatible untuk fitur report.
typedef ReportPeriod = AppPeriod;

/// Tab breakdown: expense atau income.
enum ReportBreakdownType { expense, income }

// ───────────────── Providers ─────────────────

/// Provider singleton untuk [ReportRepository].
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository();
});

/// Provider utama untuk [ReportController].
final reportControllerProvider =
    StateNotifierProvider<ReportController, ReportState>((ref) {
      final repository = ref.watch(reportRepositoryProvider);
      return ReportController(repository);
    });

/// Provider computed: top 5 kategori + "Lainnya".
final reportTopCategoriesProvider =
    Provider<List<ReportCategoryBreakdownModel>>((ref) {
      final state = ref.watch(reportControllerProvider);
      return ReportRepository.topNCategories(state.categoryBreakdown);
    });

/// Provider computed: total amount dari semua kategori breakdown.
final reportCategoryTotalProvider = Provider<double>((ref) {
  final state = ref.watch(reportControllerProvider);
  return state.categoryBreakdown.fold<double>(0, (s, c) => s + c.amount);
});

/// Provider computed: expense change % vs previous period.
final reportExpenseChangeProvider = Provider<double>((ref) {
  final state = ref.watch(reportControllerProvider);
  return ReportRepository.expenseChangePercent(
    current: state.summary.totalExpense,
    previous: state.previousSummary.totalExpense,
  );
});

/// Provider computed: income change % vs previous period.
final reportIncomeChangeProvider = Provider<double>((ref) {
  final state = ref.watch(reportControllerProvider);
  return ReportRepository.expenseChangePercent(
    current: state.summary.totalIncome,
    previous: state.previousSummary.totalIncome,
  );
});

// ───────────────── State ─────────────────

/// Status loading report.
enum ReportStatus { initial, loading, loaded, error }

/// Immutable state untuk fitur reports.
class ReportState {
  const ReportState({
    this.status = ReportStatus.initial,
    this.period = AppPeriod.monthly,
    this.breakdownType = ReportBreakdownType.expense,
    this.summary = const ReportPeriodSummaryModel(
      totalIncome: 0,
      totalExpense: 0,
    ),
    this.previousSummary = const ReportPeriodSummaryModel(
      totalIncome: 0,
      totalExpense: 0,
    ),
    this.categoryBreakdown = const [],
    this.dailyTrend = const [],
    this.walletId,
    this.customStart,
    this.customEnd,
    this.errorMessage,
    this.subPeriodIndex,
    this.isCategoryLoading = false,
  });

  final ReportStatus status;
  final AppPeriod period;
  final ReportBreakdownType breakdownType;
  final ReportPeriodSummaryModel summary;
  final ReportPeriodSummaryModel previousSummary;
  final List<ReportCategoryBreakdownModel> categoryBreakdown;
  final List<ReportDailyTrendModel> dailyTrend;
  final String? walletId;
  final DateTime? customStart;
  final DateTime? customEnd;
  final String? errorMessage;

  /// Index tab sub-period yang aktif. null = belum di-init (tab terakhir).
  final int? subPeriodIndex;

  /// Loading state khusus untuk category breakdown (saat toggle expense/income).
  final bool isCategoryLoading;

  bool get isLoading => status == ReportStatus.loading;

  /// Generate sub-period tabs berdasarkan [period].
  /// Reuse logic dari HistoryState.
  List<SubPeriodTab> get subPeriodTabs {
    final now = DateTime.now();
    return switch (period) {
      AppPeriod.daily => _generateDailyTabs(now, 30),
      AppPeriod.weekly => _generateWeeklyTabs(now, 30),
      AppPeriod.monthly => _generateMonthlyTabs(now, 14),
      AppPeriod.quarterly => _generateQuarterlyTabs(now, 2),
      AppPeriod.yearly => _generateYearlyTabs(now, 5),
      AppPeriod.custom => const [],
    };
  }

  /// Date range berdasarkan period + subPeriodIndex.
  (DateTime, DateTime) get dateRange {
    if (period == AppPeriod.custom &&
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

    // Jika sub-period dipilih, gunakan date range dari tab.
    if (subPeriodIndex != null) {
      final tabs = subPeriodTabs;
      if (tabs.isNotEmpty) {
        final idx = subPeriodIndex!.clamp(0, tabs.length - 1);
        return tabs[idx].dateRange;
      }
    }

    // Fallback: range "saat ini" (tab terakhir)
    final now = DateTime.now();
    return switch (period) {
      AppPeriod.daily => (
        DateTime.utc(now.year, now.month, now.day),
        DateTime.utc(now.year, now.month, now.day, 23, 59, 59),
      ),
      AppPeriod.weekly => () {
        final weekday = now.weekday;
        final monday = now.subtract(Duration(days: weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return (
          DateTime.utc(monday.year, monday.month, monday.day),
          DateTime.utc(sunday.year, sunday.month, sunday.day, 23, 59, 59),
        );
      }(),
      AppPeriod.monthly => (
        DateTime.utc(now.year, now.month),
        DateTime.utc(now.year, now.month + 1, 0, 23, 59, 59),
      ),
      AppPeriod.quarterly => () {
        final qStart = ((now.month - 1) ~/ 3) * 3 + 1;
        return (
          DateTime.utc(now.year, qStart),
          DateTime.utc(now.year, qStart + 3, 0, 23, 59, 59),
        );
      }(),
      AppPeriod.yearly => (
        DateTime.utc(now.year),
        DateTime.utc(now.year, 12, 31, 23, 59, 59),
      ),
      AppPeriod.custom => (
        DateTime.utc(now.year, now.month),
        DateTime.utc(now.year, now.month + 1, 0, 23, 59, 59),
      ),
    };
  }

  /// Date range period sebelumnya (untuk comparison badge).
  (DateTime, DateTime) get previousDateRange {
    final (start, end) = dateRange;
    final duration = end.difference(start);

    final prevEnd = start.subtract(const Duration(seconds: 1));
    final prevStart = prevEnd.subtract(duration);
    return (
      DateTime.utc(prevStart.year, prevStart.month, prevStart.day),
      DateTime.utc(prevEnd.year, prevEnd.month, prevEnd.day, 23, 59, 59),
    );
  }

  ReportState copyWith({
    ReportStatus? status,
    AppPeriod? period,
    ReportBreakdownType? breakdownType,
    ReportPeriodSummaryModel? summary,
    ReportPeriodSummaryModel? previousSummary,
    List<ReportCategoryBreakdownModel>? categoryBreakdown,
    List<ReportDailyTrendModel>? dailyTrend,
    String? walletId,
    DateTime? customStart,
    DateTime? customEnd,
    String? errorMessage,
    bool clearWallet = false,
    bool clearError = false,
    int? subPeriodIndex,
    bool clearSubPeriod = false,
    bool? isCategoryLoading,
  }) {
    return ReportState(
      status: status ?? this.status,
      period: period ?? this.period,
      breakdownType: breakdownType ?? this.breakdownType,
      summary: summary ?? this.summary,
      previousSummary: previousSummary ?? this.previousSummary,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      dailyTrend: dailyTrend ?? this.dailyTrend,
      walletId: clearWallet ? null : (walletId ?? this.walletId),
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      subPeriodIndex: clearSubPeriod
          ? null
          : (subPeriodIndex ?? this.subPeriodIndex),
      isCategoryLoading: isCategoryLoading ?? this.isCategoryLoading,
    );
  }

  // ───────────────── Sub-Period Tab Generators ─────────────────

  List<SubPeriodTab> _generateDailyTabs(DateTime now, int maxItems) {
    final tabs = <SubPeriodTab>[];
    final today = DateTime(now.year, now.month, now.day);
    var cursor = today.subtract(Duration(days: maxItems - 1));

    while (!cursor.isAfter(today)) {
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
            DateTime.utc(cursor.year, cursor.month, cursor.day),
            DateTime.utc(cursor.year, cursor.month, cursor.day, 23, 59, 59),
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
            DateTime.utc(monday.year, monday.month, monday.day),
            DateTime.utc(sunday.year, sunday.month, sunday.day, 23, 59, 59),
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
            DateTime.utc(cursor.year, cursor.month, 1),
            DateTime.utc(cursor.year, cursor.month + 1, 0, 23, 59, 59),
          ),
        ),
      );
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
            DateTime.utc(year, qStart, 1),
            DateTime.utc(year, qStart + 3, 0, 23, 59, 59),
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
          dateRange: (
            DateTime.utc(y, 1, 1),
            DateTime.utc(y, 12, 31, 23, 59, 59),
          ),
        ),
      );
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
}

// ───────────────── Controller ─────────────────

/// Controller untuk report state.
///
/// Mengelola:
/// - Periode & wallet filter + sub-period navigation
/// - Income/Expense summary (current + previous)
/// - Category breakdown (granular reload on toggle)
/// - Daily trend
class ReportController extends StateNotifier<ReportState> {
  ReportController(this._repository) : super(const ReportState());

  final ReportRepository _repository;

  /// Inisialisasi state dari [ReportPageArgument] sebelum load pertama.
  ///
  /// Dipanggil dari [ReportPage.initState] saat halaman dibuka dengan argument
  /// (misalnya dari tombol "Lihat Laporan" di halaman riwayat).
  void initializeFrom(ReportPageArgument argument) {
    state = state.copyWith(
      period: argument.period,
      subPeriodIndex: argument.subPeriodIndex,
      walletId: argument.walletId,
      clearWallet: argument.walletId == null,
    );
  }

  /// Load semua data report secara paralel.
  Future<void> loadReport() async {
    state = state.copyWith(status: ReportStatus.loading, clearError: true);

    final (start, end) = state.dateRange;
    final (prevStart, prevEnd) = state.previousDateRange;
    final wallet = state.walletId;
    final type = state.breakdownType == ReportBreakdownType.expense
        ? 'expense'
        : 'income';

    final results = await Future.wait([
      _repository.getPeriodSummary(
        startDate: start,
        endDate: end,
        walletId: wallet,
      ),
      _repository.getPeriodSummary(
        startDate: prevStart,
        endDate: prevEnd,
        walletId: wallet,
      ),
      _repository.getCategoryBreakdown(
        startDate: start,
        endDate: end,
        walletId: wallet,
        type: type,
      ),
      _repository.getDailyTrend(
        startDate: start,
        endDate: end,
        walletId: wallet,
      ),
    ]);

    final summaryResult = results[0];
    final prevSummaryResult = results[1];
    final breakdownResult = results[2];
    final trendResult = results[3];

    if (summaryResult.isError()) {
      final (message, _, _, _) = summaryResult.dataError()!;
      state = state.copyWith(status: ReportStatus.error, errorMessage: message);
      return;
    }

    state = state.copyWith(
      status: ReportStatus.loaded,
      summary: summaryResult.dataSuccess() as ReportPeriodSummaryModel?,
      previousSummary:
          prevSummaryResult.dataSuccess() as ReportPeriodSummaryModel?,
      categoryBreakdown:
          breakdownResult.dataSuccess() as List<ReportCategoryBreakdownModel>?,
      dailyTrend: trendResult.dataSuccess() as List<ReportDailyTrendModel>?,
    );
  }

  /// Reload hanya category breakdown (untuk toggle expense ↔ income).
  Future<void> _reloadCategoryOnly() async {
    state = state.copyWith(isCategoryLoading: true);

    final (start, end) = state.dateRange;
    final type = state.breakdownType == ReportBreakdownType.expense
        ? 'expense'
        : 'income';

    final result = await _repository.getCategoryBreakdown(
      startDate: start,
      endDate: end,
      walletId: state.walletId,
      type: type,
    );

    if (result.isSuccess()) {
      state = state.copyWith(
        categoryBreakdown: result.dataSuccess(),
        isCategoryLoading: false,
      );
    } else {
      state = state.copyWith(isCategoryLoading: false);
    }
  }

  /// Ganti periode dan reload. Reset sub-period ke tab terakhir.
  Future<void> setPeriod(AppPeriod period) async {
    if (state.period == period) return;
    state = state.copyWith(period: period, clearSubPeriod: true);
    // Set sub-period ke tab terakhir ("saat ini")
    final tabs = state.subPeriodTabs;
    if (tabs.isNotEmpty) {
      state = state.copyWith(subPeriodIndex: tabs.length - 1);
    }
    await loadReport();
  }

  /// Ganti sub-period tab dan reload.
  Future<void> setSubPeriod(int index) async {
    if (index == state.subPeriodIndex) return;
    state = state.copyWith(subPeriodIndex: index);
    await loadReport();
  }

  /// Set custom date range dan reload.
  Future<void> setCustomRange(DateTime start, DateTime end) async {
    state = state.copyWith(
      period: AppPeriod.custom,
      customStart: start,
      customEnd: end,
      clearSubPeriod: true,
    );
    await loadReport();
  }

  /// Set wallet filter dan reload.
  Future<void> setWalletFilter(String? walletId) async {
    if (walletId == null) {
      state = state.copyWith(clearWallet: true);
    } else {
      state = state.copyWith(walletId: walletId);
    }
    await loadReport();
  }

  /// Toggle breakdown type (expense ↔ income) — hanya reload category.
  Future<void> setBreakdownType(ReportBreakdownType type) async {
    if (state.breakdownType == type) return;
    state = state.copyWith(breakdownType: type);
    await _reloadCategoryOnly();
  }
}
