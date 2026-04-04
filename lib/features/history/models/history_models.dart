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
