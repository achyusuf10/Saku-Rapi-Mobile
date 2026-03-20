import 'dart:convert';

import 'package:app_saku_rapi/features/transaction/models/transaction_form_state.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';

/// Local data source untuk menyimpan draft form transaksi ke Hive.
///
/// Berguna untuk:
/// - Menyimpan progress form saat user keluar tanpa menyimpan.
/// - Handoff dari Voice/OCR ke form manual.
class TransactionLocalDataSource {
  static const String _draftKey = 'transaction_form_draft';

  // ─────────────────────────────────────────────────────────────
  // Draft form
  // ─────────────────────────────────────────────────────────────

  /// Simpan draft form sebagai JSON string ke Hive.
  void saveDraft(TransactionFormState formState) {
    final map = _formStateToMap(formState);
    HiveService.set<String>(key: _draftKey, data: jsonEncode(map));
  }

  /// Muat draft form dari Hive.
  ///
  /// Return `null` jika tidak ada draft tersimpan.
  TransactionFormState? loadDraft() {
    final raw = HiveService.get<String>(key: _draftKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return _formStateFromMap(map);
    } catch (_) {
      clearDraft();
      return null;
    }
  }

  /// Hapus draft tersimpan.
  void clearDraft() {
    HiveService.delete(_draftKey);
  }

  // ─────────────────────────────────────────────────────────────
  // Serialization helpers (manual, tanpa freezed/json_serializable)
  // ─────────────────────────────────────────────────────────────

  Map<String, dynamic> _formStateToMap(TransactionFormState s) {
    return {
      'type': s.type,
      'items': s.items
          .map(
            (i) => {
              'categoryId': i.categoryId,
              'categoryName': i.categoryName,
              'categoryColor': i.categoryColor,
              'categoryIcon': i.categoryIcon,
              'amount': i.amount,
              'note': i.note,
            },
          )
          .toList(),
      'walletId': s.walletId,
      'walletName': s.walletName,
      'destinationWalletId': s.destinationWalletId,
      'destinationWalletName': s.destinationWalletName,
      'date': s.date.toIso8601String(),
      'merchantName': s.merchantName,
      'note': s.note,
      'withPerson': s.withPerson,
      'status': s.status,
      'dueDate': s.dueDate?.toIso8601String(),
      'prefillSource': s.prefillSource,
    };
  }

  TransactionFormState _formStateFromMap(Map<String, dynamic> m) {
    final rawItems = m['items'] as List<dynamic>? ?? [];
    return TransactionFormState(
      type: m['type'] as String? ?? 'expense',
      items: rawItems
          .map(
            (i) => TransactionItemFormState(
              categoryId: i['categoryId'] as String?,
              categoryName: i['categoryName'] as String?,
              categoryColor: i['categoryColor'] as String?,
              categoryIcon: i['categoryIcon'] as String?,
              amount: (i['amount'] as num?)?.toDouble(),
              note: i['note'] as String?,
            ),
          )
          .toList(),
      walletId: m['walletId'] as String?,
      walletName: m['walletName'] as String?,
      destinationWalletId: m['destinationWalletId'] as String?,
      destinationWalletName: m['destinationWalletName'] as String?,
      date: m['date'] != null
          ? DateTime.parse(m['date'] as String)
          : DateTime.now(),
      merchantName: m['merchantName'] as String?,
      note: m['note'] as String?,
      withPerson: m['withPerson'] as String?,
      status: m['status'] as String? ?? 'unpaid',
      dueDate: m['dueDate'] != null
          ? DateTime.parse(m['dueDate'] as String)
          : null,
      prefillSource: m['prefillSource'] as String?,
    );
  }
}
