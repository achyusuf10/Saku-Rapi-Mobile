import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/dashboard/repositories/dashboard_repository.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Hive key untuk menyimpan chart mode terakhir yang dipilih user.
const _kChartModeKey = 'dashboard_chart_mode';

// ───────────────── Providers ─────────────────

/// Provider utama untuk [DashboardChartController].
///
/// Dipisahkan dari [dashboardControllerProvider] agar perubahan chart mode
/// (harian/mingguan/bulanan) **tidak** menyebabkan rebuild pada widget
/// yang tidak membutuhkan data chart (e.g. balance card, recent transactions).
final dashboardChartControllerProvider =
    StateNotifierProvider<DashboardChartController, DashboardChartState>((ref) {
      final repository = ref.watch(dashboardChartRepositoryProvider);
      return DashboardChartController(repository);
    });

/// Provider singleton repository khusus chart.
///
/// Reuse instance yang sama dengan dashboard repository utama
/// karena underlying data source-nya identik.
final dashboardChartRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

// ───────────────── Enums ─────────────────

/// Mode periode chart perbandingan.
///
/// Menentukan rentang waktu yang digunakan pada:
/// - Laporan Pengeluaran (bar chart comparison)
/// - Laporan Tren (cumulative line chart)
/// - Period Summary
enum DashboardChartMode { monthly, weekly, daily }

/// Status loading khusus chart data.
enum DashboardChartStatus { initial, loading, loaded, error }

// ───────────────── State ─────────────────

/// Immutable state khusus data chart & period summary dashboard.
///
/// State ini dipisahkan dari [DashboardState] agar widget chart
/// (carousel, comparison chart, trend chart, period summary) bisa
/// di-rebuild secara independen tanpa mempengaruhi widget lain.
class DashboardChartState {
  const DashboardChartState({
    this.status = DashboardChartStatus.initial,
    this.chartMode = DashboardChartMode.monthly,
    this.currentPeriodIncome = 0,
    this.currentPeriodExpense = 0,
    this.previousPeriodIncome = 0,
    this.previousPeriodExpense = 0,
    this.currentPeriodDaily = const [],
    this.previousPeriodDaily = const [],
    this.month2Daily = const [],
    this.month3Daily = const [],
    this.errorMessage,
  });

  /// Status loading data chart.
  final DashboardChartStatus status;

  /// Mode chart aktif: bulanan, mingguan, atau harian.
  final DashboardChartMode chartMode;

  /// Income periode ini (bulan/minggu/hari tergantung [chartMode]).
  final double currentPeriodIncome;

  /// Expense periode ini.
  final double currentPeriodExpense;

  /// Income periode sebelumnya untuk perbandingan.
  final double previousPeriodIncome;

  /// Expense periode sebelumnya untuk perbandingan.
  final double previousPeriodExpense;

  /// Daily aggregation periode ini untuk chart detail.
  final List<Map<String, dynamic>> currentPeriodDaily;

  /// Daily aggregation periode sebelumnya.
  final List<Map<String, dynamic>> previousPeriodDaily;

  /// Daily aggregation 2 periode lalu (untuk rata-rata tren).
  final List<Map<String, dynamic>> month2Daily;

  /// Daily aggregation 3 periode lalu (untuk rata-rata tren).
  final List<Map<String, dynamic>> month3Daily;

  /// Error message jika gagal load chart data.
  final String? errorMessage;

  DashboardChartState copyWith({
    DashboardChartStatus? status,
    DashboardChartMode? chartMode,
    double? currentPeriodIncome,
    double? currentPeriodExpense,
    double? previousPeriodIncome,
    double? previousPeriodExpense,
    List<Map<String, dynamic>>? currentPeriodDaily,
    List<Map<String, dynamic>>? previousPeriodDaily,
    List<Map<String, dynamic>>? month2Daily,
    List<Map<String, dynamic>>? month3Daily,
    String? errorMessage,
  }) {
    return DashboardChartState(
      status: status ?? this.status,
      chartMode: chartMode ?? this.chartMode,
      currentPeriodIncome: currentPeriodIncome ?? this.currentPeriodIncome,
      currentPeriodExpense: currentPeriodExpense ?? this.currentPeriodExpense,
      previousPeriodIncome: previousPeriodIncome ?? this.previousPeriodIncome,
      previousPeriodExpense:
          previousPeriodExpense ?? this.previousPeriodExpense,
      currentPeriodDaily: currentPeriodDaily ?? this.currentPeriodDaily,
      previousPeriodDaily: previousPeriodDaily ?? this.previousPeriodDaily,
      month2Daily: month2Daily ?? this.month2Daily,
      month3Daily: month3Daily ?? this.month3Daily,
      errorMessage: errorMessage,
    );
  }
}

// ───────────────── Controller ─────────────────

/// Controller khusus data chart & period summary dashboard.
///
/// Mengelola:
/// - Period income/expense summary (current vs previous)
/// - Daily aggregation data untuk bar & line chart
/// - Chart mode toggle (monthly ↔ weekly ↔ daily)
///
/// Dipisahkan dari [DashboardController] untuk optimasi rebuild:
/// saat user mengganti mode chart, **hanya** widget yang menggunakan
/// [dashboardChartControllerProvider] yang akan di-rebuild.
/// Widget seperti balance card, wallet section, dan recent transactions
/// tidak terpengaruh.
class DashboardChartController extends StateNotifier<DashboardChartState> {
  DashboardChartController(this._repository)
    : super(DashboardChartState(chartMode: _readChartModeFromHive()));

  final DashboardRepository _repository;

  /// Baca chart mode terakhir dari Hive.
  ///
  /// Default ke [DashboardChartMode.monthly] jika belum pernah disimpan.
  static DashboardChartMode _readChartModeFromHive() {
    final stored = HiveService.get<String>(key: _kChartModeKey);
    return switch (stored) {
      'weekly' => DashboardChartMode.weekly,
      'daily' => DashboardChartMode.daily,
      _ => DashboardChartMode.monthly,
    };
  }

  /// Load semua data chart berdasarkan [chartMode] saat ini.
  ///
  /// Fetch 6 data sources secara paralel:
  /// 1. Period summary current
  /// 2. Period summary previous
  /// 3. Daily aggregation current
  /// 4. Daily aggregation previous
  /// 5. Daily aggregation 2 periode lalu
  /// 6. Daily aggregation 3 periode lalu
  Future<void> loadChartData() async {
    state = state.copyWith(status: DashboardChartStatus.loading);

    final now = DateTime.now();
    final (currentStart, currentEnd, prevStart, prevEnd) = periodRanges(
      now,
      state.chartMode,
    );
    final (m2Start, m2End, m3Start, m3End) = extraPeriodRanges(
      now,
      state.chartMode,
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
      _repository.getDailyAggregation(startDate: m2Start, endDate: m2End),
      _repository.getDailyAggregation(startDate: m3Start, endDate: m3End),
    ]);

    final currentSummary = results[0] as DataState<Map<String, double>>;
    final previousSummary = results[1] as DataState<Map<String, double>>;
    final currentDaily = results[2] as DataState<List<Map<String, dynamic>>>;
    final previousDaily = results[3] as DataState<List<Map<String, dynamic>>>;
    final m2Daily = results[4] as DataState<List<Map<String, dynamic>>>;
    final m3Daily = results[5] as DataState<List<Map<String, dynamic>>>;

    // Check for critical error
    if (currentSummary.isError() && currentDaily.isError()) {
      final (message, _, _, _) = currentSummary.dataError()!;
      state = state.copyWith(
        status: DashboardChartStatus.error,
        errorMessage: message,
      );
      return;
    }

    state = state.copyWith(
      status: DashboardChartStatus.loaded,
      currentPeriodIncome: currentSummary.dataSuccess()?['income'] ?? 0,
      currentPeriodExpense: currentSummary.dataSuccess()?['expense'] ?? 0,
      previousPeriodIncome: previousSummary.dataSuccess()?['income'] ?? 0,
      previousPeriodExpense: previousSummary.dataSuccess()?['expense'] ?? 0,
      currentPeriodDaily: currentDaily.dataSuccess() ?? [],
      previousPeriodDaily: previousDaily.dataSuccess() ?? [],
      month2Daily: m2Daily.dataSuccess() ?? [],
      month3Daily: m3Daily.dataSuccess() ?? [],
    );
  }

  /// Pilih mode chart dan reload data perbandingan.
  ///
  /// Mode yang dipilih disimpan ke Hive agar tetap saat app dibuka ulang.
  Future<void> selectChartMode(DashboardChartMode mode) async {
    if (state.chartMode == mode) return; // Tidak ada perubahan

    HiveService.set<String>(key: _kChartModeKey, data: mode.name);
    state = state.copyWith(
      chartMode: mode,
      status: DashboardChartStatus.loading,
    );

    final now = DateTime.now();
    final (currentStart, currentEnd, prevStart, prevEnd) = periodRanges(
      now,
      mode,
    );
    final (m2Start, m2End, m3Start, m3End) = extraPeriodRanges(now, mode);

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
      _repository.getDailyAggregation(startDate: m2Start, endDate: m2End),
      _repository.getDailyAggregation(startDate: m3Start, endDate: m3End),
    ]);

    final currentSummary = results[0] as DataState<Map<String, double>>;
    final previousSummary = results[1] as DataState<Map<String, double>>;
    final currentDaily = results[2] as DataState<List<Map<String, dynamic>>>;
    final previousDaily = results[3] as DataState<List<Map<String, dynamic>>>;
    final m2Daily = results[4] as DataState<List<Map<String, dynamic>>>;
    final m3Daily = results[5] as DataState<List<Map<String, dynamic>>>;

    // Error handling: mirror loadChartData()
    if (currentSummary.isError() && currentDaily.isError()) {
      final (message, _, _, _) = currentSummary.dataError()!;
      state = state.copyWith(
        status: DashboardChartStatus.error,
        errorMessage: message,
      );
      return;
    }

    state = state.copyWith(
      status: DashboardChartStatus.loaded,
      currentPeriodIncome: currentSummary.dataSuccess()?['income'] ?? 0,
      currentPeriodExpense: currentSummary.dataSuccess()?['expense'] ?? 0,
      previousPeriodIncome: previousSummary.dataSuccess()?['income'] ?? 0,
      previousPeriodExpense: previousSummary.dataSuccess()?['expense'] ?? 0,
      currentPeriodDaily: currentDaily.dataSuccess() ?? [],
      previousPeriodDaily: previousDaily.dataSuccess() ?? [],
      month2Daily: m2Daily.dataSuccess() ?? [],
      month3Daily: m3Daily.dataSuccess() ?? [],
    );
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
    } else if (mode == DashboardChartMode.weekly) {
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
    } else {
      // Daily: rolling last 7 days vs previous 7 days
      final today = DateTime(now.year, now.month, now.day);
      final currentStart = today.subtract(const Duration(days: 6));
      final currentEnd = today
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));
      final prevStart = today.subtract(const Duration(days: 13));
      final prevEnd = currentStart.subtract(const Duration(milliseconds: 1));
      return (currentStart, currentEnd, prevStart, prevEnd);
    }
  }

  /// Hitung ranges untuk periode-2 dan periode-3 (untuk rata-rata tren).
  ///
  /// Returns `(period2Start, period2End, period3Start, period3End)`.
  static (DateTime, DateTime, DateTime, DateTime) extraPeriodRanges(
    DateTime now,
    DashboardChartMode mode,
  ) {
    if (mode == DashboardChartMode.monthly) {
      final m2Start = DateTime(now.year, now.month - 2);
      final m2End = DateTime(
        now.year,
        now.month - 1,
      ).subtract(const Duration(milliseconds: 1));
      final m3Start = DateTime(now.year, now.month - 3);
      final m3End = DateTime(
        now.year,
        now.month - 2,
      ).subtract(const Duration(milliseconds: 1));
      return (m2Start, m2End, m3Start, m3End);
    } else if (mode == DashboardChartMode.weekly) {
      final weekday = now.weekday;
      final thisWeekStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: weekday - 1));
      final w2Start = thisWeekStart.subtract(const Duration(days: 14));
      final w2End = thisWeekStart
          .subtract(const Duration(days: 7))
          .subtract(const Duration(milliseconds: 1));
      final w3Start = thisWeekStart.subtract(const Duration(days: 21));
      final w3End = thisWeekStart
          .subtract(const Duration(days: 14))
          .subtract(const Duration(milliseconds: 1));
      return (w2Start, w2End, w3Start, w3End);
    } else {
      // Daily: 7-day rolling extra windows (m2: 14-20 days ago, m3: 21-27 days ago)
      final today = DateTime(now.year, now.month, now.day);
      final m2Start = today.subtract(const Duration(days: 20));
      final m2End = today
          .subtract(const Duration(days: 13))
          .subtract(const Duration(milliseconds: 1));
      final m3Start = today.subtract(const Duration(days: 27));
      final m3End = today
          .subtract(const Duration(days: 20))
          .subtract(const Duration(milliseconds: 1));
      return (m2Start, m2End, m3Start, m3End);
    }
  }
}
