/// Model untuk tabel `parsing_dictionaries` (DB §2.8).
///
/// Menyimpan mapping keyword → category_id untuk
/// local fallback parser voice/OCR.
class ParsingDictionaryModel {
  const ParsingDictionaryModel({
    required this.id,
    required this.keyword,
    required this.categoryId,
  });

  /// Primary key UUID.
  final String id;

  /// Keyword lowercase untuk matching (e.g. "makan", "gaji", "ojol").
  final String keyword;

  /// FK ke `categories.id`.
  final String categoryId;

  factory ParsingDictionaryModel.fromMap(Map<String, dynamic> map) {
    return ParsingDictionaryModel(
      id: map['id'] as String,
      keyword: map['keyword'] as String,
      categoryId: map['category_id'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'keyword': keyword, 'category_id': categoryId};
  }

  @override
  String toString() =>
      'ParsingDictionaryModel(id: $id, keyword: $keyword, categoryId: $categoryId)';
}
