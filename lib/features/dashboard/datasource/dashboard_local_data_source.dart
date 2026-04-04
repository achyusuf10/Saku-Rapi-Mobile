import 'dart:convert';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';

/// Local data source untuk cache data dashboard menggunakan Hive.
class DashboardLocalDataSource {
  static const _tag = '[Dashboard] [DashboardLocalDataSource]';
  static const _recentTxKey = 'cached_dashboard_recent_tx';
  static const _periodSummaryKey = 'cached_dashboard_period_summary';

  // ───────────────── Recent Transactions ─────────────────

  /// Simpan recent transactions ke cache lokal.
  void cacheRecentTransactions(List<TransactionModel> transactions) {
    AppLogger.call(
      '$_tag cacheRecentTransactions: ${transactions.length} items',
    );
    final jsonList = transactions.map((e) => e.toFullMap()).toList();
    HiveService.set<String>(key: _recentTxKey, data: jsonEncode(jsonList));
  }

  /// Ambil recent transactions dari cache lokal.
  List<TransactionModel>? getCachedRecentTransactions() {
    final raw = HiveService.get<String>(key: _recentTxKey);
    if (raw == null) return null;

    AppLogger.call('$_tag getCachedRecentTransactions: from cache');
    final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
    return jsonList
        .map((e) => TransactionModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ───────────────── Period Summary ─────────────────

  /// Simpan period summary ke cache lokal.
  void cachePeriodSummary(Map<String, double> summary) {
    AppLogger.call('$_tag cachePeriodSummary');
    HiveService.set<String>(key: _periodSummaryKey, data: jsonEncode(summary));
  }

  /// Ambil period summary dari cache lokal.
  Map<String, double>? getCachedPeriodSummary() {
    final raw = HiveService.get<String>(key: _periodSummaryKey);
    if (raw == null) return null;

    AppLogger.call('$_tag getCachedPeriodSummary: from cache');
    final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
    return json.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  /// Hapus semua cache dashboard.
  void clearCache() {
    AppLogger.call('$_tag clearCache');
    HiveService.delete(_recentTxKey);
    HiveService.delete(_periodSummaryKey);
  }
}
