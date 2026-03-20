/// Summary per kategori untuk donut chart di report view.
///
/// Menyimpan data agregat satu kategori termasuk total amount,
/// persentase terhadap total, dan metadata kategori.
class CategorySummaryModel {
  const CategorySummaryModel({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.amount,
    required this.percentage,
    this.parentId,
    this.childSummaries = const [],
  });

  /// ID kategori.
  final String categoryId;

  /// Nama kategori (misal: Makanan, Transportasi).
  final String categoryName;

  /// Nama ikon FontAwesome (tanpa prefix).
  final String categoryIcon;

  /// Hex color string (#RRGGBB).
  final String categoryColor;

  /// Total nominal di kategori ini pada periode aktif.
  final double amount;

  /// Persentase terhadap total expense/income (0.0 – 1.0).
  final double percentage;

  /// ID parent kategori (null jika ini parent).
  final String? parentId;

  /// Sub-kategori summaries (untuk breakdown).
  final List<CategorySummaryModel> childSummaries;

  CategorySummaryModel copyWith({
    String? categoryId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    double? amount,
    double? percentage,
    String? parentId,
    List<CategorySummaryModel>? childSummaries,
  }) {
    return CategorySummaryModel(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
      parentId: parentId ?? this.parentId,
      childSummaries: childSummaries ?? this.childSummaries,
    );
  }
}
