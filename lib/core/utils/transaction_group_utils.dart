import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';

/// Utility functions untuk mengelompokkan transaksi berdasarkan tanggal.
abstract class TransactionGroupUtils {
  TransactionGroupUtils._();

  /// Grup list transaksi berdasarkan tanggal lokal device.
  ///
  /// Key: `'YYYY-MM-DD'` dalam local timezone.
  /// Urutan: tanggal terbaru di atas (descending).
  static Map<String, List<TransactionModel>> groupByDate(
    List<TransactionModel> transactions,
  ) {
    final map = <String, List<TransactionModel>>{};
    for (final tx in transactions) {
      final key =
          '${tx.date.year}-'
          '${tx.date.month.toString().padLeft(2, '0')}-'
          '${tx.date.day.toString().padLeft(2, '0')}';
      (map[key] ??= []).add(tx);
    }
    return map;
  }

  /// Hitung net total dari list transaksi (pemasukan - pengeluaran).
  ///
  /// Transfer, adjustment, dan settlement diabaikan dari total.
  static double groupNetTotal(List<TransactionModel> txs) {
    double total = 0;
    for (final tx in txs) {
      if (tx.isSettlement) continue;
      if (tx.type == TransactionTypeEnum.income ||
          tx.type == TransactionTypeEnum.debt) {
        total += tx.totalAmount;
      } else if (tx.type == TransactionTypeEnum.expense ||
          tx.type == TransactionTypeEnum.loan) {
        total -= tx.totalAmount;
      }
    }
    return total;
  }
}
