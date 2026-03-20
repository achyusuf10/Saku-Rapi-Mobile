/// Model untuk kamus parsing keyword → kategori.
///
/// Digunakan oleh [TransactionParserService] untuk mencocokkan
/// keyword dari teks voice/OCR ke kategori yang sesuai.
///
/// Data disimpan di tabel Supabase `parsing_dictionaries`
/// dan di-cache ke Hive dengan TTL 24 jam.
class ParsingKeywordModel {
  const ParsingKeywordModel({
    required this.id,
    required this.keyword,
    required this.categoryId,
  });

  /// UUID dari record Supabase.
  final String id;

  /// Keyword lowercase, misal: "indomaret", "grab", "bensin".
  final String keyword;

  /// UUID kategori yang di-link ke keyword ini.
  final String categoryId;

  /// Deserialisasi dari Map (Supabase response / Hive cache).
  factory ParsingKeywordModel.fromMap(Map<String, dynamic> map) {
    return ParsingKeywordModel(
      id: map['id'] as String,
      keyword: map['keyword'] as String,
      categoryId: map['category_id'] as String,
    );
  }

  /// Serialisasi ke Map (untuk Hive cache).
  Map<String, dynamic> toMap() {
    return {'id': id, 'keyword': keyword, 'category_id': categoryId};
  }
}
