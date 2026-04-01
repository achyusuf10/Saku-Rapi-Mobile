/// Model data untuk modul Reports & Analytics.
///
/// Berisi class immutable untuk:
/// - [ReportPeriodSummaryModel]: total income & expense per periode
/// - [ReportCategoryBreakdownModel]: breakdown per kategori
/// - [ReportDailyTrendModel]: tren harian untuk chart
library;

/// Ringkasan income vs expense untuk satu periode.
class ReportPeriodSummaryModel {
  const ReportPeriodSummaryModel({
    required this.totalIncome,
    required this.totalExpense,
  });

  final double totalIncome;
  final double totalExpense;

  double get net => totalIncome - totalExpense;

  double get total => totalIncome + totalExpense;

  /// Rasio pengeluaran terhadap pemasukan. 0 jika income = 0.
  double get expenseToIncomeRatio =>
      totalIncome > 0 ? totalExpense / totalIncome : 0.0;

  factory ReportPeriodSummaryModel.empty() =>
      const ReportPeriodSummaryModel(totalIncome: 0, totalExpense: 0);

  factory ReportPeriodSummaryModel.fromMap(Map<String, double> map) {
    return ReportPeriodSummaryModel(
      totalIncome: map['income'] ?? 0,
      totalExpense: map['expense'] ?? 0,
    );
  }

  ReportPeriodSummaryModel copyWith({
    double? totalIncome,
    double? totalExpense,
  }) {
    return ReportPeriodSummaryModel(
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
    );
  }
}

/// Breakdown pengeluaran/pemasukan per kategori.
class ReportCategoryBreakdownModel {
  const ReportCategoryBreakdownModel({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.amount,
    this.parentId,
    this.transactionCount = 0,
    this.otherItems = const [],
  });

  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final double amount;
  final String? parentId;
  final int transactionCount;

  /// Isi dari bucket "Lainnya". Hanya terisi jika [categoryId] == '__others__'.
  final List<ReportCategoryBreakdownModel> otherItems;

  /// Rasio terhadap total. Dihitung di luar model.
  double ratioOf(double total) => total > 0 ? amount / total : 0;

  factory ReportCategoryBreakdownModel.fromMap(Map<String, dynamic> map) {
    return ReportCategoryBreakdownModel(
      categoryId: map['category_id'] as String? ?? '',
      categoryName: map['category_name'] as String? ?? '-',
      categoryIcon: map['category_icon'] as String? ?? 'circle-question',
      categoryColor: map['category_color'] as String? ?? '#6B7280',
      amount: _toDouble(map['amount']),
      parentId: map['parent_id'] as String?,
      transactionCount: (map['tx_count'] as int?) ?? 0,
    );
  }

  ReportCategoryBreakdownModel copyWith({
    String? categoryId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    double? amount,
    String? parentId,
    int? transactionCount,
    List<ReportCategoryBreakdownModel>? otherItems,
  }) {
    return ReportCategoryBreakdownModel(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      amount: amount ?? this.amount,
      parentId: parentId ?? this.parentId,
      transactionCount: transactionCount ?? this.transactionCount,
      otherItems: otherItems ?? this.otherItems,
    );
  }
}

/// Tren harian income/expense untuk line/bar chart.
class ReportDailyTrendModel {
  const ReportDailyTrendModel({
    required this.date,
    required this.income,
    required this.expense,
  });

  final String date;
  final double income;
  final double expense;

  double get net => income - expense;

  factory ReportDailyTrendModel.fromMap(Map<String, dynamic> map) {
    return ReportDailyTrendModel(
      date: map['date'] as String? ?? '',
      income: _toDouble(map['income']),
      expense: _toDouble(map['expense']),
    );
  }
}

double _toDouble(dynamic value) {
  if (value is int) return value.toDouble();
  if (value is double) return value;
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
