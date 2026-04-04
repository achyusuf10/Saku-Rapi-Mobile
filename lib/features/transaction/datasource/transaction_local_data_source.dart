import 'dart:convert';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';

/// Local data source untuk cache transaksi menggunakan Hive (encrypted box).
///
/// Cache digunakan sebagai fallback offline dan untuk menghindari
/// re-fetch saat mengganti grouping mode pada History page.
class TransactionLocalDataSource {
  static const _tag = '[Transaction] [TransactionLocalDataSource]';
  static const _cacheKey = 'cached_transactions';

  /// Simpan daftar transaksi ke cache lokal.
  void cacheTransactions(List<TransactionModel> transactions) {
    AppLogger.call(
      '$_tag cacheTransactions: ${transactions.length} transactions',
    );
    final jsonList = transactions.map((e) => e.toFullMap()).toList();
    HiveService.set<String>(key: _cacheKey, data: jsonEncode(jsonList));
  }

  /// Ambil daftar transaksi dari cache lokal.
  /// Mengembalikan `null` jika cache kosong.
  List<TransactionModel>? getCachedTransactions() {
    final raw = HiveService.get<String>(key: _cacheKey);
    if (raw == null) return null;

    AppLogger.call('$_tag getCachedTransactions: from cache');
    final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
    return jsonList
        .map((e) => TransactionModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Hapus cache transaksi.
  void clearTransactionCache() {
    AppLogger.call('$_tag clearTransactionCache');
    HiveService.delete(_cacheKey);
  }
}
