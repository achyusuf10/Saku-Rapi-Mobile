import 'dart:convert';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/budget/models/budget_model.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';

/// Local data source untuk cache budget menggunakan Hive (encrypted box).
class BudgetLocalDataSource {
  static const _tag = '[Budget] [BudgetLocalDataSource]';
  static const _cacheKey = 'cached_budgets';

  /// Simpan daftar budget ke cache lokal.
  void cacheBudgets(List<BudgetModel> budgets) {
    AppLogger.call('$_tag cacheBudgets: ${budgets.length} budgets');
    final jsonList = budgets.map((e) => e.toFullMap()).toList();
    HiveService.set<String>(key: _cacheKey, data: jsonEncode(jsonList));
  }

  /// Ambil daftar budget dari cache lokal.
  /// Mengembalikan `null` jika cache kosong.
  List<BudgetModel>? getCachedBudgets() {
    final raw = HiveService.get<String>(key: _cacheKey);
    if (raw == null) return null;

    AppLogger.call('$_tag getCachedBudgets: from cache');
    final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
    return jsonList
        .map((e) => BudgetModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Hapus cache budget.
  void clearBudgetCache() {
    AppLogger.call('$_tag clearBudgetCache');
    HiveService.delete(_cacheKey);
  }
}
