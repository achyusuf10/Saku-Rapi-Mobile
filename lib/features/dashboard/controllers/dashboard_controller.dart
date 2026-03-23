import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/dashboard/repositories/dashboard_repository.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ───────────────── Providers ─────────────────

/// Provider singleton untuk [DashboardRepository].
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

/// Provider utama untuk [DashboardController].
final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
      final repository = ref.watch(dashboardRepositoryProvider);
      return DashboardController(repository);
    });

/// Provider computed: wallet included in total (reuses wallet state).
final dashboardWalletsProvider = Provider<List<WalletModel>>((ref) {
  final walletState = ref.watch(walletControllerProvider);
  return walletState.wallets;
});

/// Provider computed: total balance excluding `exclude_from_total` wallets.
final dashboardTotalBalanceProvider = Provider<double>((ref) {
  final wallets = ref.watch(dashboardWalletsProvider);
  return wallets
      .where((w) => !w.excludeFromTotal)
      .fold<double>(0, (sum, w) => sum + w.balance);
});

// ───────────────── Enums ─────────────────

/// Status loading dashboard.
enum DashboardStatus { initial, loading, loaded, error }

/// Mode chart perbandingan.
enum DashboardChartMode { monthly, weekly }

// ───────────────── State ─────────────────

/// Immutable state untuk dashboard.
class DashboardState {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.recentTransactions = const [],
    this.currentPeriodIncome = 0,
    this.currentPeriodExpense = 0,
    this.previousPeriodIncome = 0,
    this.previousPeriodExpense = 0,
    this.chartMode = DashboardChartMode.monthly,
    this.currentPeriodDaily = const [],
    this.previousPeriodDaily = const [],
    this.errorMessage,
    this.isBalanceHidden = false,
  });

  final DashboardStatus status;

  /// 5 transaksi terbaru untuk preview.
  final List<TransactionModel> recentTransactions;

  /// Income/expense periode ini (bulan/minggu tergantung chartMode).
  final double currentPeriodIncome;
  final double currentPeriodExpense;

  /// Income/expense periode lalu untuk perbandingan.
  final double previousPeriodIncome;
  final double previousPeriodExpense;

  /// Mode chart: bulanan vs mingguan.
  final DashboardChartMode chartMode;

  /// Daily aggregation untuk chart bar.
  final List<Map<String, dynamic>> currentPeriodDaily;
  final List<Map<String, dynamic>> previousPeriodDaily;

  /// Error message jika gagal load.
  final String? errorMessage;

  /// User toggle: sembunyikan saldo.
  final bool isBalanceHidden;

  DashboardState copyWith({
    DashboardStatus? status,
    List<TransactionModel>? recentTransactions,
    double? currentPeriodIncome,
    double? currentPeriodExpense,
    double? previousPeriodIncome,
    double? previousPeriodExpense,
    DashboardChartMode? chartMode,
    List<Map<String, dynamic>>? currentPeriodDaily,
    List<Map<String, dynamic>>? previousPeriodDaily,
    String? errorMessage,
    bool? isBalanceHidden,
  }) {
    return DashboardState(
      status: status ?? this.status,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      currentPeriodIncome: currentPeriodIncome ?? this.currentPeriodIncome,
      currentPeriodExpense: currentPeriodExpense ?? this.currentPeriodExpense,
      previousPeriodIncome: previousPeriodIncome ?? this.previousPeriodIncome,
      previousPeriodExpense:
          previousPeriodExpense ?? this.previousPeriodExpense,
      chartMode: chartMode ?? this.chartMode,
      currentPeriodDaily: currentPeriodDaily ?? this.currentPeriodDaily,
      previousPeriodDaily: previousPeriodDaily ?? this.previousPeriodDaily,
      errorMessage: errorMessage,
      isBalanceHidden: isBalanceHidden ?? this.isBalanceHidden,
    );
  }
}

// ───────────────── Controller ─────────────────

/// Controller untuk dashboard state.
///
/// Mengelola:
/// - Recent transactions preview
/// - Period income/expense summary
/// - Chart comparison data (month vs last month, week vs last week)
/// - Balance visibility toggle
class DashboardController extends StateNotifier<DashboardState> {
  DashboardController(this._repository) : super(const DashboardState());

  final DashboardRepository _repository;

  /// Load semua data dashboard secara paralel.
  Future<void> loadDashboard() async {
    state = state.copyWith(status: DashboardStatus.loading);

    final now = DateTime.now();

    // Determine current & previous period ranges based on chart mode
    final (currentStart, currentEnd, prevStart, prevEnd) = periodRanges(
      now,
      state.chartMode,
    );

    // Fetch all in parallel
    final results = await Future.wait([
      _repository.getRecentTransactions(limit: 5),
      _repository.getPeriodSummary(
        startDate: currentStart,
        endDate: currentEnd,
      ),
      _repository.getPeriodSummary(startDate: prevStart, endDate: prevEnd),
      _repository.getDailyAggregation(
        startDate: currentStart,
        endDate: currentEnd,
      ),
      _repository.getDailyAggregation(startDate: prevStart, endDate: prevEnd),
    ]);

    final recentResult = results[0] as DataState<List<TransactionModel>>;
    final currentSummary = results[1] as DataState<Map<String, double>>;
    final previousSummary = results[2] as DataState<Map<String, double>>;
    final currentDaily = results[3] as DataState<List<Map<String, dynamic>>>;
    final previousDaily = results[4] as DataState<List<Map<String, dynamic>>>;

    // Check for critical errors
    if (recentResult.isError() && currentSummary.isError()) {
      final (message, _, _, _) = recentResult.dataError()!;
      state = state.copyWith(
        status: DashboardStatus.error,
        errorMessage: message,
      );
      return;
    }

    state = state.copyWith(
      status: DashboardStatus.loaded,
      recentTransactions: recentResult.dataSuccess() ?? [],
      currentPeriodIncome: currentSummary.dataSuccess()?['income'] ?? 0,
      currentPeriodExpense: currentSummary.dataSuccess()?['expense'] ?? 0,
      previousPeriodIncome: previousSummary.dataSuccess()?['income'] ?? 0,
      previousPeriodExpense: previousSummary.dataSuccess()?['expense'] ?? 0,
      currentPeriodDaily: currentDaily.dataSuccess() ?? [],
      previousPeriodDaily: previousDaily.dataSuccess() ?? [],
    );
  }

  /// Ganti mode chart dan reload data perbandingan.
  Future<void> toggleChartMode() async {
    final newMode = state.chartMode == DashboardChartMode.monthly
        ? DashboardChartMode.weekly
        : DashboardChartMode.monthly;

    state = state.copyWith(chartMode: newMode);

    final now = DateTime.now();
    final (currentStart, currentEnd, prevStart, prevEnd) = periodRanges(
      now,
      newMode,
    );

    final results = await Future.wait([
      _repository.getPeriodSummary(
        startDate: currentStart,
        endDate: currentEnd,
      ),
      _repository.getPeriodSummary(startDate: prevStart, endDate: prevEnd),
      _repository.getDailyAggregation(
        startDate: currentStart,
        endDate: currentEnd,
      ),
      _repository.getDailyAggregation(startDate: prevStart, endDate: prevEnd),
    ]);

    final currentSummary = results[0] as DataState<Map<String, double>>;
    final previousSummary = results[1] as DataState<Map<String, double>>;
    final currentDaily = results[2] as DataState<List<Map<String, dynamic>>>;
    final previousDaily = results[3] as DataState<List<Map<String, dynamic>>>;

    state = state.copyWith(
      currentPeriodIncome: currentSummary.dataSuccess()?['income'] ?? 0,
      currentPeriodExpense: currentSummary.dataSuccess()?['expense'] ?? 0,
      previousPeriodIncome: previousSummary.dataSuccess()?['income'] ?? 0,
      previousPeriodExpense: previousSummary.dataSuccess()?['expense'] ?? 0,
      currentPeriodDaily: currentDaily.dataSuccess() ?? [],
      previousPeriodDaily: previousDaily.dataSuccess() ?? [],
    );
  }

  /// Toggle visibility saldo.
  void toggleBalanceVisibility() {
    state = state.copyWith(isBalanceHidden: !state.isBalanceHidden);
  }

  /// Hitung ranges untuk current & previous period.
  ///
  /// Returns `(currentStart, currentEnd, prevStart, prevEnd)`.
  /// Exposed as static for testability.
  static (DateTime, DateTime, DateTime, DateTime) periodRanges(
    DateTime now,
    DashboardChartMode mode,
  ) {
    if (mode == DashboardChartMode.monthly) {
      final currentStart = DateTime(now.year, now.month);
      final currentEnd = DateTime(
        now.year,
        now.month + 1,
      ).subtract(const Duration(milliseconds: 1));
      final prevStart = DateTime(now.year, now.month - 1);
      final prevEnd = currentStart.subtract(const Duration(milliseconds: 1));
      return (currentStart, currentEnd, prevStart, prevEnd);
    } else {
      // Weekly: Monday-Sunday
      final weekday = now.weekday; // 1 = Monday
      final currentStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: weekday - 1));
      final currentEnd = currentStart
          .add(const Duration(days: 7))
          .subtract(const Duration(milliseconds: 1));
      final prevStart = currentStart.subtract(const Duration(days: 7));
      final prevEnd = currentStart.subtract(const Duration(milliseconds: 1));
      return (currentStart, currentEnd, prevStart, prevEnd);
    }
  }
}
