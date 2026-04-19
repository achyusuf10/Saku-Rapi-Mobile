import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/utils/saku_date_utils.dart';

/// Model hasil parsing voice dari AI (Edge Function) atau local fallback.
///
/// Kontrak JSON voice dari Edge Function:
/// ```json
/// {
///   "isTransaction": true,
///   "amount": <number | null>,
///   "items": [...],
///   "categoryId": "<UUID | null>",
///   "categoryKeyword": "<single keyword>",
///   "note": "<descriptive text | null>",
///   "type": "expense" | "income" | "transfer" | "debt" | "loan",
///   "suggestedWalletId": "<UUID | null>",
///   "destinationWalletId": "<UUID | null>",
///   "withPerson": "<person name | null>",
///   "merchantName": "<merchant | null>",
///   "date": "<yyyy-MM-dd | yyyy-MM-ddTHH:mm:ss | null>"
/// }
/// ```
class VoiceParseResultModel {
  const VoiceParseResultModel({
    this.isTransaction = true,
    this.amount,
    this.items = const [],
    this.categoryId,
    this.categoryKeyword,
    this.note,
    this.type = TransactionTypeEnum.expense,
    this.debtLoanKind,
    this.provider,
    this.rawTranscript,
    this.suggestedWalletId,
    this.destinationWalletId,
    this.withPerson,
    this.merchantName,
    this.date,
  });

  /// Apakah input user benar-benar transaksi (bukan ngawur).
  final bool isTransaction;

  /// Nominal transaksi hasil parsing AI.
  final double? amount;

  /// Daftar item line items dari AI (multi-item voice/text).
  ///
  /// Kosong jika user hanya menyebut satu item atau total saja.
  /// Jika terisi, [amount] = sum(items.subtotal).
  final List<VoiceItemModel> items;

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
  final String? suggestedWalletId;

  /// Nama wallet tujuan (untuk transfer).
  final String? destinationWalletId;

  /// Nama orang terkait (untuk hutang/piutang).
  final String? withPerson;

  /// Nama merchant/toko.
  final String? merchantName;

  /// Tanggal/waktu transaksi hasil parsing.
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
      date = SakuDateUtils.parseOptionalFlexibleLocalDateTime(rawDate);
    }

    // Parse multi-item list dari AI (bisa kosong)
    final rawItems = data['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((e) => VoiceItemModel.fromMap(e as Map<String, dynamic>))
        .toList();

    return VoiceParseResultModel(
      isTransaction: isTransaction,
      amount: (data['amount'] as num?)?.toDouble(),
      items: items,
      categoryId: data['categoryId'] as String?,
      categoryKeyword: data['categoryKeyword'] as String?,
      note: data['note'] as String?,
      type: type,
      debtLoanKind: data['debtLoanKind'] as String?,
      provider: provider ?? json['provider'] as String?,
      rawTranscript: rawTranscript,
      suggestedWalletId: data['suggestedWalletId'] as String?,
      destinationWalletId: data['destinationWalletId'] as String?,
      withPerson: data['withPerson'] as String?,
      merchantName: data['merchantName'] as String?,
      date: date,
    );
  }

  /// Buat dari local fallback parser.
  factory VoiceParseResultModel.fromLocal({
    bool isTransaction = true,
    double? amount,
    List<VoiceItemModel> items = const [],
    String? categoryId,
    String? categoryKeyword,
    String? note,
    TransactionTypeEnum type = TransactionTypeEnum.expense,
    String? debtLoanKind,
    String? rawTranscript,
    String? suggestedWalletId,
    String? destinationWalletId,
    String? withPerson,
    String? merchantName,
    DateTime? date,
  }) {
    return VoiceParseResultModel(
      isTransaction: isTransaction,
      amount: amount,
      items: items,
      categoryId: categoryId,
      categoryKeyword: categoryKeyword,
      note: note,
      type: type,
      debtLoanKind: debtLoanKind,
      provider: 'local',
      rawTranscript: rawTranscript,
      suggestedWalletId: suggestedWalletId,
      destinationWalletId: destinationWalletId,
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
      'items': items.map((i) => i.toMap()).toList(),
      'categoryId': categoryId,
      'categoryKeyword': categoryKeyword,
      'note': note,
      'type': type.toDbValue(),
      'debtLoanKind': debtLoanKind,
      'provider': provider,
      'rawTranscript': rawTranscript,
      'suggestedWalletId': suggestedWalletId,
      'destinationWalletId': destinationWalletId,
      'withPerson': withPerson,
      'merchantName': merchantName,
      'date': SakuDateUtils.formatOptionalTimestamp(date),
    };
  }

  VoiceParseResultModel copyWith({
    bool? isTransaction,
    double? amount,
    List<VoiceItemModel>? items,
    String? categoryId,
    String? categoryKeyword,
    String? note,
    TransactionTypeEnum? type,
    String? debtLoanKind,
    String? provider,
    String? rawTranscript,
    String? suggestedWalletId,
    String? destinationWalletId,
    String? withPerson,
    String? merchantName,
    DateTime? date,
  }) {
    return VoiceParseResultModel(
      isTransaction: isTransaction ?? this.isTransaction,
      amount: amount ?? this.amount,
      items: items ?? this.items,
      categoryId: categoryId ?? this.categoryId,
      categoryKeyword: categoryKeyword ?? this.categoryKeyword,
      note: note ?? this.note,
      type: type ?? this.type,
      debtLoanKind: debtLoanKind ?? this.debtLoanKind,
      provider: provider ?? this.provider,
      rawTranscript: rawTranscript ?? this.rawTranscript,
      suggestedWalletId: suggestedWalletId ?? this.suggestedWalletId,
      destinationWalletId: destinationWalletId ?? this.destinationWalletId,
      withPerson: withPerson ?? this.withPerson,
      merchantName: merchantName ?? this.merchantName,
      date: date ?? this.date,
    );
  }

  /// Hitung total dari semua items.
  double get itemsTotal => items.fold(0.0, (sum, item) => sum + item.subtotal);

  @override
  String toString() =>
      'VoiceParseResultModel(isTransaction: $isTransaction, amount: $amount, '
      'items: ${items.length}, categoryKeyword: $categoryKeyword, note: $note, '
      'type: $type, provider: $provider, suggestedWalletId: $suggestedWalletId, '
      'merchantName: $merchantName, date: $date)';
}

/// Model untuk satu item baris pada voice/text multi-item parsing.
///
/// Digunakan ketika user menyebut beberapa item dengan harga masing-masing.
/// Contoh: "Beli ikan 20K, ayam 10K, sayur 5rb"
class VoiceItemModel {
  const VoiceItemModel({
    this.name,
    this.qty = 1,
    this.unitPrice,
    required this.subtotal,
    this.categoryId,
  });

  /// Nama item.
  final String? name;

  /// Jumlah / kuantitas. Default 1.
  final double qty;

  /// Harga per unit (bisa null jika tidak terdeteksi).
  final double? unitPrice;

  /// Subtotal untuk item ini (authoritative).
  final double subtotal;

  /// UUID kategori yang di-assign oleh AI (bisa null).
  final String? categoryId;

  /// Parse dari map Edge Function.
  factory VoiceItemModel.fromMap(Map<String, dynamic> map) {
    final qty = _toDouble(map['qty']) > 0 ? _toDouble(map['qty']) : 1.0;
    final unitPrice = _toDoubleOrNull(map['unitPrice']);

    // Subtotal: prioritas 'subtotal', fallback hitung dari qty * unitPrice
    double subtotal = _toDouble(map['subtotal']);
    if (subtotal <= 0 && unitPrice != null && unitPrice > 0) {
      subtotal = qty * unitPrice;
    }

    return VoiceItemModel(
      name: map['name'] as String?,
      qty: qty,
      unitPrice: unitPrice,
      subtotal: subtotal,
      categoryId: map['categoryId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'qty': qty,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
      'categoryId': categoryId,
    };
  }

  VoiceItemModel copyWith({
    String? name,
    double? qty,
    double? unitPrice,
    double? subtotal,
    String? categoryId,
  }) {
    return VoiceItemModel(
      name: name ?? this.name,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      subtotal: subtotal ?? this.subtotal,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  String toString() =>
      'VoiceItemModel(name: $name, qty: $qty, unitPrice: $unitPrice, '
      'subtotal: $subtotal, categoryId: $categoryId)';
}
