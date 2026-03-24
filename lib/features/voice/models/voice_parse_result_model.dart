import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';

/// Model hasil parsing voice dari AI (Edge Function) atau local fallback.
///
/// Kontrak JSON voice dari Edge Function:
/// ```json
/// {
///   "amount": <number | null>,
///   "categoryKeyword": "<single keyword>",
///   "note": "<descriptive text | null>",
///   "type": "expense" | "income"
/// }
/// ```
class VoiceParseResultModel {
  const VoiceParseResultModel({
    this.amount,
    this.categoryKeyword,
    this.note,
    this.type = TransactionTypeEnum.expense,
    this.provider,
    this.rawTranscript,
  });

  /// Nominal transaksi hasil parsing AI.
  final double? amount;

  /// Keyword kategori dari AI (single keyword, lowercase).
  /// Digunakan untuk lookup di `parsing_dictionaries`.
  final String? categoryKeyword;

  /// Catatan deskriptif dari AI.
  final String? note;

  /// Tipe transaksi: expense (default) atau income.
  final TransactionTypeEnum type;

  /// Provider AI yang digunakan: 'gemini', 'groq', atau 'local'.
  final String? provider;

  /// Teks transkripsi asli dari STT (untuk display).
  final String? rawTranscript;

  /// Parse dari response Edge Function voice mode.
  factory VoiceParseResultModel.fromEdgeFunctionMap(
    Map<String, dynamic> json, {
    String? provider,
    String? rawTranscript,
  }) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    final rawType = data['type'] as String? ?? 'expense';
    final type = (rawType == 'income')
        ? TransactionTypeEnum.income
        : TransactionTypeEnum.expense;

    return VoiceParseResultModel(
      amount: (data['amount'] as num?)?.toDouble(),
      categoryKeyword: data['categoryKeyword'] as String?,
      note: data['note'] as String?,
      type: type,
      provider: provider ?? json['provider'] as String?,
      rawTranscript: rawTranscript,
    );
  }

  /// Buat dari local fallback parser.
  factory VoiceParseResultModel.fromLocal({
    double? amount,
    String? categoryKeyword,
    String? note,
    TransactionTypeEnum type = TransactionTypeEnum.expense,
    String? rawTranscript,
  }) {
    return VoiceParseResultModel(
      amount: amount,
      categoryKeyword: categoryKeyword,
      note: note,
      type: type,
      provider: 'local',
      rawTranscript: rawTranscript,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'categoryKeyword': categoryKeyword,
      'note': note,
      'type': type.toDbValue(),
      'provider': provider,
      'rawTranscript': rawTranscript,
    };
  }

  VoiceParseResultModel copyWith({
    double? amount,
    String? categoryKeyword,
    String? note,
    TransactionTypeEnum? type,
    String? provider,
    String? rawTranscript,
  }) {
    return VoiceParseResultModel(
      amount: amount ?? this.amount,
      categoryKeyword: categoryKeyword ?? this.categoryKeyword,
      note: note ?? this.note,
      type: type ?? this.type,
      provider: provider ?? this.provider,
      rawTranscript: rawTranscript ?? this.rawTranscript,
    );
  }

  @override
  String toString() =>
      'VoiceParseResultModel(amount: $amount, categoryKeyword: $categoryKeyword, '
      'note: $note, type: $type, provider: $provider)';
}
