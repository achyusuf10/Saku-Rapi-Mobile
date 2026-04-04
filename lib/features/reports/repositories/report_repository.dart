import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/reports/datasource/report_remote_data_source.dart';
import 'package:app_saku_rapi/features/reports/models/report_model.dart';

/// Repository untuk modul Reports & Analytics.
///
/// Orkestrator antara [ReportRemoteDataSource] dan logika bisnis report.
/// Menerapkan rule PRD §4.2 secara konsisten.
class ReportRepository {
  ReportRepository({ReportRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? ReportRemoteDataSource();

  final ReportRemoteDataSource _remoteDataSource;

  static const _tag = '[Reports] [ReportRepository]';

  // ───────────────── Period Summary ─────────────────

  /// Ambil ringkasan income vs expense untuk periode tertentu.
  Future<DataState<ReportPeriodSummaryModel>> getPeriodSummary({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
  }) async {
    AppLogger.call('$_tag getPeriodSummary');
    return _remoteDataSource.getPeriodSummary(
      startDate: startDate,
      endDate: endDate,
      walletId: walletId,
    );
  }

  // ───────────────── Category Breakdown ─────────────────

  /// Ambil breakdown per kategori (expense atau income).
  Future<DataState<List<ReportCategoryBreakdownModel>>> getCategoryBreakdown({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
    String type = 'expense',
  }) async {
    AppLogger.call('$_tag getCategoryBreakdown type=$type');
    return _remoteDataSource.getCategoryBreakdown(
      startDate: startDate,
      endDate: endDate,
      walletId: walletId,
      type: type,
    );
  }

  // ───────────────── Daily Trend ─────────────────

  /// Ambil tren harian income/expense.
  Future<DataState<List<ReportDailyTrendModel>>> getDailyTrend({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
  }) async {
    AppLogger.call('$_tag getDailyTrend');
    return _remoteDataSource.getDailyTrend(
      startDate: startDate,
      endDate: endDate,
      walletId: walletId,
    );
  }

  // ───────────────── Computed Helpers ─────────────────

  /// Hitung top N kategori dari list breakdown.
  /// Sisanya di-merge jadi satu entry "Lainnya".
  static List<ReportCategoryBreakdownModel> topNCategories(
    List<ReportCategoryBreakdownModel> categories, {
    int maxCount = 5,
  }) {
    // Urutkan dari value terbesar ke terkecil.
    final sorted = [...categories]
      ..sort((a, b) => b.amount.compareTo(a.amount));

    if (sorted.length <= maxCount) return sorted;

    final top = sorted.sublist(0, maxCount);
    final rest = sorted.sublist(maxCount);
    final restAmount = rest.fold<double>(0, (sum, c) => sum + c.amount);
    final restCount = rest.fold<int>(0, (sum, c) => sum + c.transactionCount);

    top.add(
      ReportCategoryBreakdownModel(
        categoryId: '__others__',
        categoryName: appContext?.l10n.reportOthersCategory ?? 'Lainnya',
        categoryIcon: 'ellipsis',
        categoryColor: '#9CA3AF',
        amount: restAmount,
        transactionCount: restCount,
        otherItems: rest,
      ),
    );

    return top;
  }

  /// Hitung insight: perubahan expense dibanding periode sebelumnya.
  static double expenseChangePercent({
    required double current,
    required double previous,
  }) {
    if (previous <= 0) return 0;
    return ((current - previous) / previous) * 100;
  }
}
