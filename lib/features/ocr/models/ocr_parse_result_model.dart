/// Model hasil parsing OCR struk dari AI (Edge Function) atau local fallback.
///
/// Kontrak JSON OCR dari Edge Function:
/// ```json
/// {
///   "merchantName": "<string | null>",
///   "date": "<yyyy-MM-dd | null>",
///   "grandTotal": <number | null>,
///   "items": [
///     { "name": "<string>", "qty": <number>, "unitPrice": <number|null>, "subtotal": <number> }
///   ]
/// }
/// ```
class OcrParseResultModel {
  const OcrParseResultModel({
    this.merchantName,
    this.date,
    this.grandTotal,
    this.items = const [],
    this.provider,
    this.rawOcrText,
  });

  /// Nama toko/merchant dari struk.
  final String? merchantName;

  /// Tanggal transaksi yang terdeteksi.
  final DateTime? date;

  /// Total belanja (grand total) dari struk.
  final double? grandTotal;

  /// Daftar item yang berhasil di-parse.
  final List<OcrItemModel> items;

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
      (grandTotal != null && grandTotal! > 0) || items.isNotEmpty;

  /// Parse dari response Edge Function OCR mode.
  ///
  /// Response structure: `{ success, mode, provider, data: { ... } }`
  factory OcrParseResultModel.fromEdgeFunctionMap(
    Map<String, dynamic> json, {
    String? provider,
    String? rawOcrText,
  }) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    // Parse date
    DateTime? parsedDate;
    final rawDate = data['date'] as String?;
    if (rawDate != null && rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    // Parse items — handle kedua format (lama: name+amount, baru: name+qty+unitPrice+subtotal)
    final rawItems = data['items'] as List<dynamic>? ?? [];
    final items = rawItems.map((e) {
      final itemMap = e as Map<String, dynamic>;
      return OcrItemModel.fromMap(itemMap);
    }).toList();

    return OcrParseResultModel(
      merchantName: data['merchantName'] as String?,
      date: parsedDate,
      grandTotal: _toDoubleOrNull(data['grandTotal']),
      items: items,
      provider: provider ?? json['provider'] as String?,
      rawOcrText: rawOcrText,
    );
  }

  /// Buat dari local fallback parser.
  factory OcrParseResultModel.fromLocal({
    String? merchantName,
    DateTime? date,
    double? grandTotal,
    List<OcrItemModel> items = const [],
    String? rawOcrText,
  }) {
    return OcrParseResultModel(
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
      'merchantName': merchantName,
      'date': date?.toIso8601String(),
      'grandTotal': grandTotal,
      'items': items.map((i) => i.toMap()).toList(),
      'provider': provider,
      'rawOcrText': rawOcrText,
    };
  }

  OcrParseResultModel copyWith({
    String? merchantName,
    DateTime? date,
    double? grandTotal,
    List<OcrItemModel>? items,
    String? provider,
    String? rawOcrText,
  }) {
    return OcrParseResultModel(
      merchantName: merchantName ?? this.merchantName,
      date: date ?? this.date,
      grandTotal: grandTotal ?? this.grandTotal,
      items: items ?? this.items,
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
      'OcrParseResultModel(merchant: $merchantName, date: $date, '
      'grandTotal: $grandTotal, items: ${items.length}, provider: $provider)';
}

/// Model untuk satu item baris pada struk OCR.
class OcrItemModel {
  const OcrItemModel({
    this.name,
    this.qty = 1,
    this.unitPrice,
    required this.subtotal,
  });

  /// Nama item di struk.
  final String? name;

  /// Jumlah / kuantitas. Default 1.
  final double qty;

  /// Harga per unit (bisa null jika tidak terdeteksi).
  final double? unitPrice;

  /// Subtotal untuk baris ini (authoritative).
  final double subtotal;

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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'qty': qty,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
    };
  }

  OcrItemModel copyWith({
    String? name,
    double? qty,
    double? unitPrice,
    double? subtotal,
  }) {
    return OcrItemModel(
      name: name ?? this.name,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      subtotal: subtotal ?? this.subtotal,
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
      'OcrItemModel(name: $name, qty: $qty, unitPrice: $unitPrice, subtotal: $subtotal)';
}
