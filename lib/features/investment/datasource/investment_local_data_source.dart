import 'dart:convert';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/investment/models/investment_asset_model.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';

/// Local data source untuk cache investasi menggunakan Hive (encrypted box).
class InvestmentLocalDataSource {
  static const _tag = '[Investment] [InvestmentLocalDataSource]';
  static const _dashboardCacheKey = 'cached_investment_dashboard';

  /// Simpan daftar aset dashboard ke cache lokal.
  void cacheDashboard(List<InvestmentAssetModel> assets) {
    AppLogger.call('$_tag cacheDashboard: ${assets.length} assets');
    final jsonList = assets.map((e) => e.toFullMap()).toList();
    HiveService.set<String>(
      key: _dashboardCacheKey,
      data: jsonEncode(jsonList),
    );
  }

  /// Ambil daftar aset dashboard dari cache lokal.
  /// Mengembalikan `null` jika cache kosong.
  List<InvestmentAssetModel>? getCachedDashboard() {
    final raw = HiveService.get<String>(key: _dashboardCacheKey);
    if (raw == null) return null;

    AppLogger.call('$_tag getCachedDashboard: from cache');
    final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
    return jsonList
        .map((e) => InvestmentAssetModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Hapus cache dashboard.
  void clearDashboardCache() {
    AppLogger.call('$_tag clearDashboardCache');
    HiveService.delete(_dashboardCacheKey);
  }
}
