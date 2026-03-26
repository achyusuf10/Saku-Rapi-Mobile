import 'dart:convert';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/investment/models/investment_model.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';

/// Local data source untuk cache investasi menggunakan Hive (encrypted box).
class InvestmentLocalDataSource {
  static const _tag = '[Investment] [InvestmentLocalDataSource]';
  static const _cacheKey = 'cached_investments';

  /// Simpan daftar investasi ke cache lokal.
  void cacheInvestments(List<InvestmentModel> investments) {
    AppLogger.call('$_tag cacheInvestments: ${investments.length} investments');
    final jsonList = investments.map((e) => e.toFullMap()).toList();
    HiveService.set<String>(key: _cacheKey, data: jsonEncode(jsonList));
  }

  /// Ambil daftar investasi dari cache lokal.
  /// Mengembalikan `null` jika cache kosong.
  List<InvestmentModel>? getCachedInvestments() {
    final raw = HiveService.get<String>(key: _cacheKey);
    if (raw == null) return null;

    AppLogger.call('$_tag getCachedInvestments: from cache');
    final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
    return jsonList
        .map((e) => InvestmentModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Hapus cache investasi.
  void clearCache() {
    AppLogger.call('$_tag clearCache');
    HiveService.delete(_cacheKey);
  }
}
