import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';

/// Grup transaksi per tanggal untuk tampilan list view di history.
///
/// Setiap group berisi tanggal header beserta daftar transaksi
/// dan ringkasan total pemasukan/pengeluaran hari tersebut.
class TransactionGroupModel {
  const TransactionGroupModel({
    required this.date,
    required this.transactions,
    required this.totalIncome,
    required this.totalExpense,
  });

  /// Tanggal grup (hanya date, tanpa jam).
  final DateTime date;

  /// Daftar transaksi pada tanggal ini.
  final List<TransactionModel> transactions;

  /// Total pemasukan hari ini.
  final double totalIncome;

  /// Total pengeluaran hari ini.
  final double totalExpense;

  /// Membuat grup dari daftar transaksi yang sudah difilter per tanggal.
  factory TransactionGroupModel.fromTransactions({
    required DateTime date,
    required List<TransactionModel> transactions,
  }) {
    double income = 0;
    double expense = 0;
    for (final tx in transactions) {
      if (tx.type == 'income') {
        income += tx.totalAmount;
      } else if (tx.type == 'expense') {
        expense += tx.totalAmount;
      }
    }
    return TransactionGroupModel(
      date: date,
      transactions: transactions,
      totalIncome: income,
      totalExpense: expense,
    );
  }

  TransactionGroupModel copyWith({
    DateTime? date,
    List<TransactionModel>? transactions,
    double? totalIncome,
    double? totalExpense,
  }) {
    return TransactionGroupModel(
      date: date ?? this.date,
      transactions: transactions ?? this.transactions,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
    );
  }
}
