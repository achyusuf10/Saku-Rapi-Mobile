/// Model response dari Edge Function `ai-parse`.
///
/// Berisi hasil parsing AI terstruktur untuk mode voice atau OCR.
/// Field [voiceData] terisi jika [mode] == 'voice',
/// field [ocrData] terisi jika [mode] == 'ocr'.
class AiParseResponseModel {
  const AiParseResponseModel({
    required this.success,
    required this.mode,
    this.provider,
    this.error,
    this.voiceData,
    this.ocrData,
  });

  /// `true` jika AI berhasil parsing.
  final bool success;

  /// Mode parsing: `'voice'` atau `'ocr'`.
  final String mode;

  /// Provider AI yang digunakan: `'gemini'` atau `'groq'`.
  final String? provider;

  /// Pesan error jika [success] == false (misal `'AI_BUSY'`).
  final String? error;

  /// Data hasil parsing voice (hanya terisi jika [mode] == 'voice').
  final VoiceParseDataModel? voiceData;

  /// Data hasil parsing OCR (hanya terisi jika [mode] == 'ocr').
  final OcrParseDataModel? ocrData;

  factory AiParseResponseModel.fromMap(Map<String, dynamic> map) {
    final mode = map['mode'] as String? ?? '';
    final rawData = map['data'] as Map<String, dynamic>?;

    return AiParseResponseModel(
      success: map['success'] as bool? ?? false,
      mode: mode,
      provider: map['provider'] as String?,
      error: map['error'] as String?,
      voiceData: mode == 'voice' && rawData != null
          ? VoiceParseDataModel.fromMap(rawData)
          : null,
      ocrData: mode == 'ocr' && rawData != null
          ? OcrParseDataModel.fromMap(rawData)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'mode': mode,
      'provider': provider,
      'error': error,
      'data': mode == 'voice' ? voiceData?.toMap() : ocrData?.toMap(),
    };
  }

  AiParseResponseModel copyWith({
    bool? success,
    String? mode,
    String? provider,
    String? error,
    VoiceParseDataModel? voiceData,
    OcrParseDataModel? ocrData,
  }) {
    return AiParseResponseModel(
      success: success ?? this.success,
      mode: mode ?? this.mode,
      provider: provider ?? this.provider,
      error: error ?? this.error,
      voiceData: voiceData ?? this.voiceData,
      ocrData: ocrData ?? this.ocrData,
    );
  }
}

// ─────────────────────────────────────────────────────
// Voice Parse Data
// ─────────────────────────────────────────────────────

/// Data hasil parsing AI untuk mode voice.
///
/// Berisi nominal, keyword kategori, catatan, dan tipe transaksi
/// yang di-extract oleh AI dari teks voice input.
class VoiceParseDataModel {
  const VoiceParseDataModel({
    this.amount,
    this.categoryKeyword,
    this.note,
    this.type,
  });

  /// Nominal transaksi yang terdeteksi.
  final double? amount;

  /// Keyword kategori lowercase (misal: "makan", "transportasi").
  final String? categoryKeyword;

  /// Catatan / konteks tambahan.
  final String? note;

  /// Tipe transaksi: `'expense'` atau `'income'`.
  final String? type;

  factory VoiceParseDataModel.fromMap(Map<String, dynamic> map) {
    return VoiceParseDataModel(
      amount: (map['amount'] as num?)?.toDouble(),
      categoryKeyword: map['categoryKeyword'] as String?,
      note: map['note'] as String?,
      type: map['type'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'categoryKeyword': categoryKeyword,
      'note': note,
      'type': type,
    };
  }

  VoiceParseDataModel copyWith({
    double? amount,
    String? categoryKeyword,
    String? note,
    String? type,
  }) {
    return VoiceParseDataModel(
      amount: amount ?? this.amount,
      categoryKeyword: categoryKeyword ?? this.categoryKeyword,
      note: note ?? this.note,
      type: type ?? this.type,
    );
  }
}

// ─────────────────────────────────────────────────────
// OCR Parse Data
// ─────────────────────────────────────────────────────

/// Data hasil parsing AI untuk mode OCR (struk/receipt).
///
/// Berisi nama merchant, tanggal, grand total, dan daftar item
/// yang di-extract oleh AI dari teks OCR.
class OcrParseDataModel {
  const OcrParseDataModel({
    this.merchantName,
    this.date,
    this.grandTotal,
    this.items = const [],
  });

  /// Nama merchant / toko.
  final String? merchantName;

  /// Tanggal transaksi dalam format `yyyy-MM-dd`.
  final String? date;

  /// Total keseluruhan dari struk.
  final double? grandTotal;

  /// Daftar item dari struk beserta harganya.
  final List<OcrItemDataModel> items;

  factory OcrParseDataModel.fromMap(Map<String, dynamic> map) {
    return OcrParseDataModel(
      merchantName: map['merchantName'] as String?,
      date: map['date'] as String?,
      grandTotal: (map['grandTotal'] as num?)?.toDouble(),
      items:
          (map['items'] as List<dynamic>?)
              ?.map((e) => OcrItemDataModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'merchantName': merchantName,
      'date': date,
      'grandTotal': grandTotal,
      'items': items.map((e) => e.toMap()).toList(),
    };
  }

  OcrParseDataModel copyWith({
    String? merchantName,
    String? date,
    double? grandTotal,
    List<OcrItemDataModel>? items,
  }) {
    return OcrParseDataModel(
      merchantName: merchantName ?? this.merchantName,
      date: date ?? this.date,
      grandTotal: grandTotal ?? this.grandTotal,
      items: items ?? this.items,
    );
  }
}

/// Satu baris item dari hasil parsing AI untuk OCR.
class OcrItemDataModel {
  const OcrItemDataModel({required this.name, required this.amount});

  /// Nama item dari struk.
  final String name;

  /// Harga / nominal item.
  final double amount;

  factory OcrItemDataModel.fromMap(Map<String, dynamic> map) {
    return OcrItemDataModel(
      name: map['name'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'amount': amount};
  }

  OcrItemDataModel copyWith({String? name, double? amount}) {
    return OcrItemDataModel(
      name: name ?? this.name,
      amount: amount ?? this.amount,
    );
  }
}
