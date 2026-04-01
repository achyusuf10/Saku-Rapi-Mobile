/// Argument navigasi untuk halaman transaksi per kategori dari Report.
class ReportCategoryTransactionsArgument {
  const ReportCategoryTransactionsArgument({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.startDate,
    required this.endDate,
    required this.type,
    this.walletId,
  });

  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final DateTime startDate;
  final DateTime endDate;

  /// 'expense' atau 'income'.
  final String type;
  final String? walletId;
}
