import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/dashboard/datasource/dashboard_local_data_source.dart';
import 'package:app_saku_rapi/features/dashboard/datasource/dashboard_remote_data_source.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';

/// Repository untuk fitur Dashboard.
///
/// Mengorkestrasikan [DashboardRemoteDataSource] dan [DashboardLocalDataSource]:
/// - Online: fetch dari Supabase, cache ke Hive.
/// - Offline fallback: sajikan dari Hive cache.
///
/// Semua agregasi dilakukan di data layer, bukan di widget.
class DashboardRepository {
  DashboardRepository({
    DashboardRemoteDataSource? remoteDataSource,
    DashboardLocalDataSource? localDataSource,
  }) : _remote = remoteDataSource ?? DashboardRemoteDataSource(),
       _local = localDataSource ?? DashboardLocalDataSource();

  final DashboardRemoteDataSource _remote;
  final DashboardLocalDataSource _local;

  static const _tag = '[Dashboard] [DashboardRepository]';

  // ───────────────── Recent Transactions ─────────────────

  /// Ambil transaksi terbaru untuk preview dashboard.
  /// Cache hasil ke Hive; fallback ke cache jika offline.
  Future<DataState<List<TransactionModel>>> getRecentTransactions({
    int limit = 5,
  }) async {
    final result = await _remote.getRecentTransactions(limit: limit);

    if (result.isSuccess()) {
      final transactions = result.dataSuccess()!;
      _local.cacheRecentTransactions(transactions);
      return result;
    }

    // Offline fallback
    final cached = _local.getCachedRecentTransactions();
    if (cached != null) {
      AppLogger.call('$_tag getRecentTransactions: serving from cache');
      return DataState.success(data: cached);
    }

    return result;
  }

  // ───────────────── Period Summary ─────────────────

  /// Ambil total income/expense dalam periode [startDate]..[endDate].
  ///
  /// Hanya menghitung transaksi income/expense non-settlement (PRD §4.2).
  Future<DataState<Map<String, double>>> getPeriodSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final result = await _remote.getPeriodSummary(
      startDate: startDate,
      endDate: endDate,
    );

    if (result.isSuccess()) {
      _local.cachePeriodSummary(result.dataSuccess()!);
      return result;
    }

    // Offline fallback
    final cached = _local.getCachedPeriodSummary();
    if (cached != null) {
      AppLogger.call('$_tag getPeriodSummary: serving from cache');
      return DataState.success(data: cached);
    }

    return result;
  }

  // ───────────────── Chart Comparison ─────────────────

  /// Ambil daily aggregation income/expense untuk chart perbandingan.
  /// Tidak di-cache karena chart data bersifat visual saja.
  Future<DataState<List<Map<String, dynamic>>>> getDailyAggregation({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _remote.getDailyAggregation(startDate: startDate, endDate: endDate);
  }
}
