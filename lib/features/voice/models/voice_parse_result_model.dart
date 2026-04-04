import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';

/// Model hasil parsing voice dari AI (Edge Function) atau local fallback.
///
/// Kontrak JSON voice dari Edge Function:
/// ```json
/// {
///   "isTransaction": true,
///   "amount": <number | null>,
///   "categoryId": "<UUID | null>",
///   "categoryKeyword": "<single keyword>",
///   "note": "<descriptive text | null>",
///   "type": "expense" | "income" | "transfer" | "debt" | "loan",
///   "suggestedWallet": "<wallet name | null>",
///   "destinationWallet": "<wallet name | null>",
///   "withPerson": "<person name | null>",
///   "merchantName": "<merchant | null>",
///   "date": "<yyyy-MM-dd | null>"
/// }
/// ```
class VoiceParseResultModel {
  const VoiceParseResultModel({
    this.isTransaction = true,
    this.amount,
    this.categoryId,
    this.categoryKeyword,
    this.note,
    this.type = TransactionTypeEnum.expense,
    this.debtLoanKind,
    this.provider,
    this.rawTranscript,
    this.suggestedWallet,
    this.destinationWallet,
    this.withPerson,
    this.merchantName,
    this.date,
  });

  /// Apakah input user benar-benar transaksi (bukan ngawur).
  final bool isTransaction;

  /// Nominal transaksi hasil parsing AI.
  final double? amount;

  /// ID kategori dari AI (UUID, matched dari daftar kategori user).
  final String? categoryId;

  /// Keyword kategori dari AI (single keyword, lowercase).
  /// Fallback jika categoryId tidak tersedia.
  final String? categoryKeyword;

  /// Catatan deskriptif dari AI.
  final String? note;

  /// Tipe transaksi: expense, income, transfer, debt, loan.
  final TransactionTypeEnum type;

  /// Jenis operasi hutang/piutang dari AI.
  ///
  /// Nilai: `null` (bukan debt/loan), `"debt"`, `"loan"`,
  /// `"debt_payment"` (pelunasan hutang), `"loan_collection"` (penerimaan piutang).
  final String? debtLoanKind;

  /// Provider AI yang digunakan: 'gemini', 'groq', atau 'local'.
  final String? provider;

  /// Teks transkripsi asli dari STT (untuk display).
  final String? rawTranscript;

  /// Nama wallet yang disarankan AI (match by name).
  final String? suggestedWallet;

  /// Nama wallet tujuan (untuk transfer).
  final String? destinationWallet;

  /// Nama orang terkait (untuk hutang/piutang).
  final String? withPerson;

  /// Nama merchant/toko.
  final String? merchantName;

  /// Tanggal transaksi hasil parsing (yyyy-MM-dd).
  final DateTime? date;

  /// Parse dari response Edge Function voice mode.
  factory VoiceParseResultModel.fromEdgeFunctionMap(
    Map<String, dynamic> json, {
    String? provider,
    String? rawTranscript,
  }) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    final rawType = data['type'] as String? ?? 'expense';
    final type = _parseType(rawType);

    final isTransaction = data['isTransaction'] as bool? ?? true;

    DateTime? date;
    final rawDate = data['date'] as String?;
    if (rawDate != null && rawDate.isNotEmpty) {
      date = DateTime.tryParse(rawDate);
    }

    return VoiceParseResultModel(
      isTransaction: isTransaction,
      amount: (data['amount'] as num?)?.toDouble(),
      categoryId: data['categoryId'] as String?,
      categoryKeyword: data['categoryKeyword'] as String?,
      note: data['note'] as String?,
      type: type,
      debtLoanKind: data['debtLoanKind'] as String?,
      provider: provider ?? json['provider'] as String?,
      rawTranscript: rawTranscript,
      suggestedWallet: data['suggestedWallet'] as String?,
      destinationWallet: data['destinationWallet'] as String?,
      withPerson: data['withPerson'] as String?,
      merchantName: data['merchantName'] as String?,
      date: date,
    );
  }

  /// Buat dari local fallback parser.
  factory VoiceParseResultModel.fromLocal({
    bool isTransaction = true,
    double? amount,
    String? categoryId,
    String? categoryKeyword,
    String? note,
    TransactionTypeEnum type = TransactionTypeEnum.expense,
    String? debtLoanKind,
    String? rawTranscript,
    String? suggestedWallet,
    String? destinationWallet,
    String? withPerson,
    String? merchantName,
    DateTime? date,
  }) {
    return VoiceParseResultModel(
      isTransaction: isTransaction,
      amount: amount,
      categoryId: categoryId,
      categoryKeyword: categoryKeyword,
      note: note,
      type: type,
      debtLoanKind: debtLoanKind,
      provider: 'local',
      rawTranscript: rawTranscript,
      suggestedWallet: suggestedWallet,
      destinationWallet: destinationWallet,
      withPerson: withPerson,
      merchantName: merchantName,
      date: date,
    );
  }

  /// Parse type string ke enum, mendukung semua jenis transaksi.
  static TransactionTypeEnum _parseType(String rawType) {
    return switch (rawType.toLowerCase()) {
      'income' => TransactionTypeEnum.income,
      'expense' => TransactionTypeEnum.expense,
      'transfer' => TransactionTypeEnum.transfer,
      'debt' => TransactionTypeEnum.debt,
      'loan' => TransactionTypeEnum.loan,
      _ => TransactionTypeEnum.expense,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'isTransaction': isTransaction,
      'amount': amount,
      'categoryId': categoryId,
      'categoryKeyword': categoryKeyword,
      'note': note,
      'type': type.toDbValue(),
      'debtLoanKind': debtLoanKind,
      'provider': provider,
      'rawTranscript': rawTranscript,
      'suggestedWallet': suggestedWallet,
      'destinationWallet': destinationWallet,
      'withPerson': withPerson,
      'merchantName': merchantName,
      'date': date?.toIso8601String(),
    };
  }

  VoiceParseResultModel copyWith({
    bool? isTransaction,
    double? amount,
    String? categoryId,
    String? categoryKeyword,
    String? note,
    TransactionTypeEnum? type,
    String? debtLoanKind,
    String? provider,
    String? rawTranscript,
    String? suggestedWallet,
    String? destinationWallet,
    String? withPerson,
    String? merchantName,
    DateTime? date,
  }) {
    return VoiceParseResultModel(
      isTransaction: isTransaction ?? this.isTransaction,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      categoryKeyword: categoryKeyword ?? this.categoryKeyword,
      note: note ?? this.note,
      type: type ?? this.type,
      debtLoanKind: debtLoanKind ?? this.debtLoanKind,
      provider: provider ?? this.provider,
      rawTranscript: rawTranscript ?? this.rawTranscript,
      suggestedWallet: suggestedWallet ?? this.suggestedWallet,
      destinationWallet: destinationWallet ?? this.destinationWallet,
      withPerson: withPerson ?? this.withPerson,
      merchantName: merchantName ?? this.merchantName,
      date: date ?? this.date,
    );
  }

  @override
  String toString() =>
      'VoiceParseResultModel(isTransaction: $isTransaction, amount: $amount, '
      'categoryKeyword: $categoryKeyword, note: $note, type: $type, '
      'provider: $provider, suggestedWallet: $suggestedWallet, '
      'merchantName: $merchantName, date: $date)';
}
