import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';

// ───────────────── Enums ─────────────────

/// Periode filter yang digunakan bersama di fitur history & report.
enum AppPeriod { daily, weekly, monthly, quarterly, yearly, custom }

/// Alias backward-compatible untuk fitur history.
typedef HistoryPeriod = AppPeriod;

/// Mode pengelompokan list transaksi.
enum HistoryGroupMode { byDate, byCategory }

/// Status loading untuk history.
enum HistoryStatus { initial, loading, loaded, error }

// ───────────────── Model ─────────────────

/// Data model untuk satu tab sub-period.
class SubPeriodTab {
  const SubPeriodTab({required this.label, required this.dateRange});

  /// Label yang ditampilkan di tab, misal "Jan 2024", "Hari Ini".
  final String label;

  /// Date range (start, end) UTC untuk sub-period ini.
  final (DateTime, DateTime) dateRange;
}

/// Container untuk hasil RPC [get_history_transactions].
///
/// Menyimpan list transaksi, flag hasMore, dan aggregate totals
/// (dihitung di server dari seluruh data yang cocok — bukan hanya halaman ini).
class HistoryResult {
  const HistoryResult({
    required this.transactions,
    required this.hasMore,
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.totalCount = 0,
  });

  final List<TransactionModel> transactions;
  final bool hasMore;

  /// Total pemasukan (income, bukan settlement) untuk seluruh periode.
  final double totalIncome;

  /// Total pengeluaran (expense, bukan settlement) untuk seluruh periode.
  final double totalExpense;

  /// Jumlah total transaksi yang cocok filter (bukan hanya halaman ini).
  final int totalCount;
}
