import 'package:app_saku_rapi/core/utils/saku_date_utils.dart';

/// Model hasil parsing OCR struk dari AI (Edge Function) atau local fallback.
///
/// Mendukung semua jenis transaksi: expense (multi-item), income, transfer,
/// debt, dan loan. Untuk expense → items detail, lainnya → grandTotal + type.
///
/// Kontrak JSON OCR dari Edge Function:
/// ```json
/// {
///   "isTransaction": <boolean>,
///   "type": "<expense | income | transfer | debt | loan>",
///   "merchantName": "<string | null>",
///   "date": "<yyyy-MM-dd | null>",
///   "grandTotal": <number | null>,
///   "items": [...],
///   "categoryId": "<UUID | null>",
///   "categoryKeyword": "<string | null>",
///   "suggestedWallet": "<string | null>",
///   "destinationWallet": "<string | null>",
///   "withPerson": "<string | null>",
///   "note": "<string | null>"
/// }
/// ```
class OcrParseResultModel {
  const OcrParseResultModel({
    this.isTransaction = true,
    this.type = 'expense',
    this.merchantName,
    this.date,
    this.grandTotal,
    this.items = const [],
    this.categoryId,
    this.categoryKeyword,
    this.suggestedWallet,
    this.destinationWallet,
    this.withPerson,
    this.note,
    this.provider,
    this.rawOcrText,
  });

  /// Apakah gambar berisi transaksi keuangan yang valid.
  final bool isTransaction;

  /// Jenis transaksi: expense, income, transfer, debt, loan.
  final String type;

  /// Nama toko/merchant dari struk.
  final String? merchantName;

  /// Tanggal transaksi yang terdeteksi.
  final DateTime? date;

  /// Total belanja (grand total) dari struk.
  final double? grandTotal;

  /// Daftar item yang berhasil di-parse (hanya untuk expense).
  final List<OcrItemModel> items;

  /// UUID kategori yang di-assign oleh AI (untuk non-expense single category).
  final String? categoryId;

  /// Keyword kategori sebagai fallback jika categoryId null.
  final String? categoryKeyword;

  /// Nama wallet/payment method yang terdeteksi.
  final String? suggestedWallet;

  /// Wallet tujuan (khusus transfer).
  final String? destinationWallet;

  /// Nama orang terkait (khusus debt/loan).
  final String? withPerson;

  /// Catatan/deskripsi tambahan.
  final String? note;

  /// Provider AI yang digunakan: 'gemini', 'groq', atau 'local'.
  final String? provider;

  /// Teks OCR mentah dari ML Kit (untuk debug/display).
  final String? rawOcrText;

  /// Hitung total dari semua items.
  double get itemsTotal => items.fold(0.0, (sum, item) => sum + item.subtotal);

  /// Apakah total items cocok dengan grandTotal (toleransi < 1).
  bool get isTotalMatched =>
      grandTotal != null && (itemsTotal - grandTotal!).abs() < 1;

  /// Apakah hasil parsing memiliki data berguna.
  bool get hasUsableData =>
      isTransaction &&
      ((grandTotal != null && grandTotal! > 0) || items.isNotEmpty);

  /// Parse dari response Edge Function OCR mode.
  ///
  /// Response structure: `{ success, mode, provider, data: { ... } }`
  factory OcrParseResultModel.fromEdgeFunctionMap(
    Map<String, dynamic> json, {
    String? provider,
    String? rawOcrText,
  }) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    // Parse isTransaction
    final isTransaction = data['isTransaction'] as bool? ?? true;

    // Parse type
    final rawType = data['type'] as String? ?? 'expense';

    // Parse date
    DateTime? parsedDate;
    final rawDate = data['date'] as String?;
    if (rawDate != null && rawDate.isNotEmpty) {
      parsedDate = SakuDateUtils.parseOptionalDate(rawDate);
    }

    // Parse items — hanya untuk expense
    final rawItems = data['items'] as List<dynamic>? ?? [];
    final items = rawItems.map((e) {
      final itemMap = e as Map<String, dynamic>;
      return OcrItemModel.fromMap(itemMap);
    }).toList();

    return OcrParseResultModel(
      isTransaction: isTransaction,
      type: rawType.toLowerCase(),
      merchantName: data['merchantName'] as String?,
      date: parsedDate,
      grandTotal: _toDoubleOrNull(data['grandTotal']),
      items: items,
      categoryId: data['categoryId'] as String?,
      categoryKeyword: data['categoryKeyword'] as String?,
      suggestedWallet: data['suggestedWallet'] as String?,
      destinationWallet: data['destinationWallet'] as String?,
      withPerson: data['withPerson'] as String?,
      note: data['note'] as String?,
      provider: provider ?? json['provider'] as String?,
      rawOcrText: rawOcrText,
    );
  }

  /// Buat dari local fallback parser.
  factory OcrParseResultModel.fromLocal({
    bool isTransaction = true,
    String type = 'expense',
    String? merchantName,
    DateTime? date,
    double? grandTotal,
    List<OcrItemModel> items = const [],
    String? rawOcrText,
  }) {
    return OcrParseResultModel(
      isTransaction: isTransaction,
      type: type,
      merchantName: merchantName,
      date: date,
      grandTotal: grandTotal,
      items: items,
      provider: 'local',
      rawOcrText: rawOcrText,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isTransaction': isTransaction,
      'type': type,
      'merchantName': merchantName,
      'date': SakuDateUtils.formatOptionalDate(date),
      'grandTotal': grandTotal,
      'items': items.map((i) => i.toMap()).toList(),
      'categoryId': categoryId,
      'categoryKeyword': categoryKeyword,
      'suggestedWallet': suggestedWallet,
      'destinationWallet': destinationWallet,
      'withPerson': withPerson,
      'note': note,
      'provider': provider,
      'rawOcrText': rawOcrText,
    };
  }

  OcrParseResultModel copyWith({
    bool? isTransaction,
    String? type,
    String? merchantName,
    DateTime? date,
    double? grandTotal,
    List<OcrItemModel>? items,
    String? categoryId,
    String? categoryKeyword,
    String? suggestedWallet,
    String? destinationWallet,
    String? withPerson,
    String? note,
    String? provider,
    String? rawOcrText,
  }) {
    return OcrParseResultModel(
      isTransaction: isTransaction ?? this.isTransaction,
      type: type ?? this.type,
      merchantName: merchantName ?? this.merchantName,
      date: date ?? this.date,
      grandTotal: grandTotal ?? this.grandTotal,
      items: items ?? this.items,
      categoryId: categoryId ?? this.categoryId,
      categoryKeyword: categoryKeyword ?? this.categoryKeyword,
      suggestedWallet: suggestedWallet ?? this.suggestedWallet,
      destinationWallet: destinationWallet ?? this.destinationWallet,
      withPerson: withPerson ?? this.withPerson,
      note: note ?? this.note,
      provider: provider ?? this.provider,
      rawOcrText: rawOcrText ?? this.rawOcrText,
    );
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
      'OcrParseResultModel(isTransaction: $isTransaction, type: $type, '
      'merchant: $merchantName, date: $date, '
      'grandTotal: $grandTotal, items: ${items.length}, provider: $provider)';
}

/// Model untuk satu item baris pada struk OCR.
class OcrItemModel {
  const OcrItemModel({
    this.name,
    this.qty = 1,
    this.unitPrice,
    required this.subtotal,
    this.categoryId,
  });

  /// Nama item di struk.
  final String? name;

  /// Jumlah / kuantitas. Default 1.
  final double qty;

  /// Harga per unit (bisa null jika tidak terdeteksi).
  final double? unitPrice;

  /// Subtotal untuk baris ini (authoritative).
  final double subtotal;

  /// UUID kategori yang di-assign oleh AI (bisa null jika tidak cocok).
  final String? categoryId;

  /// Parse dari map Edge Function.
  ///
  /// Mendukung format lama (`amount` only) dan baru (`qty`, `unitPrice`, `subtotal`).
  factory OcrItemModel.fromMap(Map<String, dynamic> map) {
    final qty = _toDouble(map['qty']) > 0 ? _toDouble(map['qty']) : 1.0;
    final unitPrice = _toDoubleOrNull(map['unitPrice']);

    // Subtotal: prioritas 'subtotal', fallback 'amount'
    double subtotal = _toDouble(map['subtotal']);
    if (subtotal <= 0) {
      subtotal = _toDouble(map['amount']);
    }
    // Jika subtotal masih 0 tapi ada qty * unitPrice, hitung
    if (subtotal <= 0 && unitPrice != null && unitPrice > 0) {
      subtotal = qty * unitPrice;
    }

    return OcrItemModel(
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

  OcrItemModel copyWith({
    String? name,
    double? qty,
    double? unitPrice,
    double? subtotal,
    String? categoryId,
  }) {
    return OcrItemModel(
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
      'OcrItemModel(name: $name, qty: $qty, unitPrice: $unitPrice, subtotal: $subtotal, categoryId: $categoryId)';
}
