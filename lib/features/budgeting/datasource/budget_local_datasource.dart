import 'dart:convert';

import 'package:app_saku_rapi/features/budgeting/models/budget_model.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';

/// Data source lokal untuk cache budget menggunakan Hive.
///
/// Menyimpan daftar budget dan summary sebagai JSON string terenkripsi.
/// Digunakan sebagai fallback jika Supabase gagal (offline-first).
class BudgetLocalDataSource {
  static const String _budgetsKey = 'budgets_data';
  static const String _summaryKey = 'budgets_summary';
  static const String _lastFetchKey = 'budgets_last_fetch';

  /// TTL cache: 1 jam.
  static const int _ttlMinutes = 60;

  /// Apakah cache sudah expired.
  bool isCacheExpired() {
    final lastFetch = HiveService.get<int>(key: _lastFetchKey);
    if (lastFetch == null) return true;

    final lastFetchTime = DateTime.fromMillisecondsSinceEpoch(lastFetch);
    return DateTime.now().difference(lastFetchTime).inMinutes >= _ttlMinutes;
  }

  /// Mendapatkan list budget dari cache.
  List<BudgetModel> getCachedBudgets() {
    final raw = HiveService.get<String>(key: _budgetsKey);
    if (raw == null) return [];

    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => BudgetModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Menyimpan list budget ke cache.
  void saveBudgets(List<BudgetModel> budgets) {
    final raw = jsonEncode(budgets.map(_budgetToCache).toList());
    HiveService.set<String>(key: _budgetsKey, data: raw);
    HiveService.set<int>(
      key: _lastFetchKey,
      data: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Mendapatkan summary dari cache.
  BudgetSummaryModel? getCachedSummary() {
    final raw = HiveService.get<String>(key: _summaryKey);
    if (raw == null) return null;

    final map = jsonDecode(raw) as Map<String, dynamic>;
    return BudgetSummaryModel(
      totalAmount: (map['totalAmount'] as num).toDouble(),
      totalUsedAmount: (map['totalUsedAmount'] as num).toDouble(),
      daysRemainingInMonth: map['daysRemainingInMonth'] as int,
    );
  }

  /// Menyimpan summary ke cache.
  void saveSummary(BudgetSummaryModel summary) {
    final raw = jsonEncode({
      'totalAmount': summary.totalAmount,
      'totalUsedAmount': summary.totalUsedAmount,
      'daysRemainingInMonth': summary.daysRemainingInMonth,
    });
    HiveService.set<String>(key: _summaryKey, data: raw);
  }

  /// Menghapus semua cache budget.
  void clearCache() {
    HiveService.delete(_budgetsKey);
    HiveService.delete(_summaryKey);
    HiveService.delete(_lastFetchKey);
  }

  /// Konversi [BudgetModel] ke Map yang bisa di-cache.
  ///
  /// Menyertakan join fields yang flat (bukan nested) agar
  /// `fromMap` bisa membacanya.
  Map<String, dynamic> _budgetToCache(BudgetModel b) {
    return {
      'id': b.id,
      'user_id': b.userId,
      'category_id': b.categoryId,
      'wallet_id': b.walletId,
      'amount': b.amount,
      'used_amount': b.usedAmount,
      'start_date': b.startDate.toIso8601String(),
      'end_date': b.endDate.toIso8601String(),
      'is_recurring': b.isRecurring,
      'notification_sent_80': b.notificationSent80,
      'notification_sent_100': b.notificationSent100,
      'created_at': b.createdAt.toIso8601String(),
      'updated_at': b.updatedAt.toIso8601String(),
      'categories': {
        'name': b.categoryName,
        'icon': b.categoryIcon,
        'color': b.categoryColor,
      },
      if (b.walletId != null) 'wallets': {'name': b.walletName},
    };
  }
}
