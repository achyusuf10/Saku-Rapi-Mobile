import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/parsing_dictionary/models/parsing_keyword_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_form_state.dart';

/// Service NLP sederhana untuk parsing teks suara / OCR menjadi
/// [TransactionFormState].
///
/// Algoritma:
/// 1. Detect angka: "dua puluh ribu" → 20000, "25rb" → 25000, "20.000" → 20000
/// 2. Detect tipe: default 'expense'; kata "terima/dapat/masuk/gaji" → income
/// 3. Detect kategori: keyword dari dictionary (Hive kamus, stub sekarang)
/// 4. Extract note: sisa teks setelah angka + keyword dihapus
class TransactionParserService {
  static const String _tag = 'VoiceInput';

  /// Parsing teks voice input menjadi [TransactionFormState].
  TransactionFormState parseVoiceInput(
    String rawText,
    List<ParsingKeywordModel> dictionary,
  ) {
    AppLogger.call('[$_tag] Raw text: $rawText', colorLog: ColorLog.blue);

    final text = rawText.toLowerCase().trim();

    // 1. Extract amount
    final amount = _extractAmount(text);

    // 2. Detect type
    final type = _detectType(text);

    // 3. Detect category
    final category = _detectCategory(text, dictionary);

    // 4. Extract note (sisa teks setelah amount & keyword dihapus)
    final note = _extractNote(text, amount, category);

    final state = TransactionFormState(
      type: type,
      date: DateTime.now(),
      prefillSource: 'voice',
      note: note.isNotEmpty ? note : null,
      items: [
        TransactionItemFormState(
          amount: amount,
          categoryId: category?.categoryId,
          note: note.isNotEmpty ? note : null,
        ),
      ],
    );

    AppLogger.call(
      '[$_tag] Parsed: amount=$amount, type=$type, '
      'categoryId=${category?.categoryId}, note=$note',
      colorLog: ColorLog.green,
    );

    return state;
  }

  /// Parsing teks OCR struk menjadi [OcrParseResult].
  ///
  /// Algoritma:
  /// 1. Detect Grand Total via regex TOTAL/JUMLAH/TOTAL BAYAR
  /// 2. Detect tanggal (dd/mm/yyyy atau variannya)
  /// 3. Detect merchant name (baris pertama non-kosong sebelum tanggal/total)
  /// 4. Detect baris item: nama + angka di akhir baris
  /// 5. Auto-Balance: jika grandTotal > sum(items), tambah selisih
  OcrParseResult parseOcrText(
    String rawText,
    List<ParsingKeywordModel> dictionary,
  ) {
    AppLogger.call(
      '[OcrScan] Raw OCR text:\n$rawText',
      colorLog: ColorLog.blue,
    );

    final lines = rawText.split('\n').map((l) => l.trim()).toList();

    // 1. Grand Total
    final grandTotal = _extractGrandTotal(rawText);

    // 2. Date
    final date = _extractDate(rawText);

    // 3. Merchant name (baris pertama yang bukan kosong dan bukan angka doang)
    final merchantName = _extractMerchant(lines);

    // 4. Items (baris dengan nama + angka di akhir)
    final items = _extractOcrItems(lines, dictionary);

    // 5. Auto-Balance
    if (grandTotal != null && items.isNotEmpty) {
      final sumItems = items.fold(0.0, (sum, i) => sum + i.amount);
      if (grandTotal > sumItems + 0.01) {
        items.add(
          OcrItemResult(
            name: 'Pajak / Biaya Lain / Selisih',
            amount: grandTotal - sumItems,
          ),
        );
      }
    }

    final result = OcrParseResult(
      grandTotal: grandTotal,
      date: date,
      merchantName: merchantName,
      items: items,
    );

    AppLogger.call(
      '[OcrScan] Parsed: total=$grandTotal, merchant=$merchantName, '
      'date=$date, items=${items.length}',
      colorLog: ColorLog.green,
    );

    return result;
  }

  /// Konversi [OcrParseResult] menjadi [TransactionFormState] siap form.
  TransactionFormState ocrResultToFormState(
    OcrParseResult ocrResult,
    String? attachmentPath,
  ) {
    return TransactionFormState(
      type: 'expense',
      date: ocrResult.date ?? DateTime.now(),
      prefillSource: 'ocr',
      merchantName: ocrResult.merchantName,
      attachmentLocalPath: attachmentPath,
      items: ocrResult.items.isNotEmpty
          ? ocrResult.items
                .map(
                  (item) => TransactionItemFormState(
                    amount: item.amount,
                    categoryId: item.categoryId,
                    note: item.name,
                  ),
                )
                .toList()
          : [TransactionItemFormState(amount: ocrResult.grandTotal)],
    );
  }

  // ─────────────────────────────────────────────────────
  // Internal parsers
  // ─────────────────────────────────────────────────────

  /// Extract nominal dari teks.
  ///
  /// Mendukung:
  /// - Angka langsung: "50000", "50.000"
  /// - Shorthand: "25rb", "25ribu", "1.5jt", "1juta"
  /// - Kata bilangan: "dua puluh lima ribu" → 25000
  double? _extractAmount(String text) {
    // Pola 1: shorthand "25rb", "25ribu", "1.5jt", "1juta"
    final shorthandPattern = RegExp(
      r'(\d+[.,]?\d*)\s*(rb|ribu|rb\.?|jt|juta|jt\.?)',
      caseSensitive: false,
    );
    final shorthandMatch = shorthandPattern.firstMatch(text);
    if (shorthandMatch != null) {
      final numStr = shorthandMatch.group(1)!.replaceAll(',', '.');
      final unit = shorthandMatch.group(2)!.toLowerCase();
      final num = double.tryParse(numStr);
      if (num != null) {
        if (unit.startsWith('jt') || unit.startsWith('juta')) {
          return num * 1000000;
        }
        return num * 1000;
      }
    }

    // Pola 2: angka dengan titik pemisah ribuan "50.000", "1.500.000"
    final dotSeparatedPattern = RegExp(r'(\d{1,3}(?:\.\d{3})+)');
    final dotMatch = dotSeparatedPattern.firstMatch(text);
    if (dotMatch != null) {
      final cleaned = dotMatch.group(1)!.replaceAll('.', '');
      return double.tryParse(cleaned);
    }

    // Pola 3: angka plain "50000", "25000"
    final plainNumberPattern = RegExp(r'(\d{4,})');
    final plainMatch = plainNumberPattern.firstMatch(text);
    if (plainMatch != null) {
      return double.tryParse(plainMatch.group(1)!);
    }

    // Pola 4: kata bilangan Indonesia
    final wordAmount = _parseWordNumber(text);
    if (wordAmount != null && wordAmount > 0) return wordAmount;

    // Pola 5: angka kecil (bisa jadi "50" → 50, tapi biasanya bukan nominal)
    // Skip angka kecil < 1000 untuk menghindari false positive.

    return null;
  }

  /// Parse kata bilangan Indonesia ke angka.
  ///
  /// Contoh: "dua puluh lima ribu" → 25000
  double? _parseWordNumber(String text) {
    const wordToNum = <String, int>{
      'satu': 1,
      'dua': 2,
      'tiga': 3,
      'empat': 4,
      'lima': 5,
      'enam': 6,
      'tujuh': 7,
      'delapan': 8,
      'sembilan': 9,
      'sepuluh': 10,
      'sebelas': 11,
      'seratus': 100,
      'seribu': 1000,
      'sejuta': 1000000,
    };

    // Cari pola "X ribu", "X juta", "X ratus"
    final ribuPattern = RegExp(
      r'((?:(?:se|satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan)\s*(?:belas|puluh)?\s*)+)\s*(ribu|juta|ratus)',
    );
    final ribuMatch = ribuPattern.firstMatch(text);
    if (ribuMatch == null) return null;

    final numberPart = ribuMatch.group(1)!.trim();
    final multiplierWord = ribuMatch.group(2)!;

    int multiplier;
    switch (multiplierWord) {
      case 'juta':
        multiplier = 1000000;
      case 'ribu':
        multiplier = 1000;
      case 'ratus':
        multiplier = 100;
      default:
        multiplier = 1;
    }

    // Parse bagian angka
    int value = 0;
    final words = numberPart.split(RegExp(r'\s+'));

    for (int i = 0; i < words.length; i++) {
      final word = words[i];

      // "belas" modifier: X belas = 10 + X
      if (word == 'belas' && i > 0) {
        // Sudah dihandle di bawah
        continue;
      }

      // "puluh" modifier: X puluh = X * 10
      if (word == 'puluh' && i > 0) {
        continue;
      }

      final n = wordToNum[word];
      if (n != null) {
        // Check next word for belas/puluh
        if (i + 1 < words.length) {
          if (words[i + 1] == 'belas') {
            value += n + 10;
            continue;
          }
          if (words[i + 1] == 'puluh') {
            value += n * 10;
            continue;
          }
        }
        value += n;
      }
    }

    if (value == 0) return null;
    return (value * multiplier).toDouble();
  }

  /// Detect tipe transaksi dari teks.
  ///
  /// Default: 'expense'.
  /// Jika ada kata income indicator → 'income'.
  String _detectType(String text) {
    const incomeKeywords = [
      'terima',
      'dapat',
      'masuk',
      'gaji',
      'bonus',
      'transfer masuk',
      'pendapatan',
      'penghasilan',
      'dibayar',
      'diterima',
    ];

    for (final keyword in incomeKeywords) {
      if (text.contains(keyword)) return 'income';
    }
    return 'expense';
  }

  /// Detect kategori dari dictionary keyword matching.
  ParsingKeywordModel? _detectCategory(
    String text,
    List<ParsingKeywordModel> dictionary,
  ) {
    for (final entry in dictionary) {
      if (text.contains(entry.keyword.toLowerCase())) {
        return entry;
      }
    }
    return null;
  }

  /// Extract note: sisa teks setelah angka & keyword dihapus, lalu dibersihkan.
  String _extractNote(
    String text,
    double? amount,
    ParsingKeywordModel? category,
  ) {
    var cleaned = text;

    // Hapus angka shorthand
    cleaned = cleaned.replaceAll(
      RegExp(r'\d+[.,]?\d*\s*(rb|ribu|jt|juta)', caseSensitive: false),
      '',
    );

    // Hapus angka dengan titik pemisah
    cleaned = cleaned.replaceAll(RegExp(r'\d{1,3}(?:\.\d{3})+'), '');

    // Hapus angka plain 4+ digit
    cleaned = cleaned.replaceAll(RegExp(r'\d{4,}'), '');

    // Hapus kata bilangan
    cleaned = cleaned.replaceAll(
      RegExp(
        r'(se|satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan)\s*(belas|puluh)?\s*(ribu|juta|ratus)?',
      ),
      '',
    );

    // Hapus keyword category jika ditemukan
    if (category != null) {
      cleaned = cleaned.replaceAll(
        RegExp(RegExp.escape(category.keyword), caseSensitive: false),
        '',
      );
    }

    // Hapus kata umum yang bukan note
    cleaned = cleaned.replaceAll(
      RegExp(r'\b(beli|bayar|buat|untuk|di|ke|dari)\b'),
      '',
    );

    // Bersihkan whitespace berlebih
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  // ─────────────────────────────────────────────────────
  // OCR-specific parsers
  // ─────────────────────────────────────────────────────

  /// Detect Grand Total dari raw OCR text.
  ///
  /// Cari pola: TOTAL / GRAND TOTAL / JUMLAH / TOTAL BAYAR diikuti angka.
  double? _extractGrandTotal(String text) {
    final pattern = RegExp(
      r'(TOTAL|GRAND\s*TOTAL|JUMLAH|TOTAL\s*BAYAR|SUBTOTAL)\s*:?\s*([\d.,]+)',
      caseSensitive: false,
    );

    double? largest;
    for (final match in pattern.allMatches(text)) {
      final numStr = match.group(2)!.replaceAll('.', '').replaceAll(',', '.');
      final value = double.tryParse(numStr);
      if (value != null && (largest == null || value > largest)) {
        largest = value;
      }
    }
    return largest;
  }

  /// Detect tanggal dari raw OCR text.
  ///
  /// Format: dd/mm/yyyy, dd-mm-yyyy, dd.mm.yyyy (2 atau 4 digit tahun).
  DateTime? _extractDate(String text) {
    final pattern = RegExp(r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})');
    final match = pattern.firstMatch(text);
    if (match == null) return null;

    final day = int.tryParse(match.group(1)!) ?? 0;
    final month = int.tryParse(match.group(2)!) ?? 0;
    var year = int.tryParse(match.group(3)!) ?? 0;

    // 2-digit year → assume 2000+
    if (year < 100) year += 2000;

    if (month < 1 || month > 12 || day < 1 || day > 31) return null;

    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  /// Detect nama merchant dari baris-baris OCR.
  ///
  /// Ambil baris pertama non-kosong yang bukan angka murni
  /// dan bukan baris tanggal/total.
  String? _extractMerchant(List<String> lines) {
    final totalPattern = RegExp(
      r'(TOTAL|GRAND\s*TOTAL|JUMLAH|SUBTOTAL)',
      caseSensitive: false,
    );
    final datePattern = RegExp(r'\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}');
    final pureNumberPattern = RegExp(r'^\d[\d.,\s]*$');

    for (final line in lines) {
      if (line.isEmpty) continue;
      if (totalPattern.hasMatch(line)) continue;
      if (datePattern.hasMatch(line)) continue;
      if (pureNumberPattern.hasMatch(line)) continue;
      if (line.length < 3) continue;
      return line;
    }
    return null;
  }

  /// Detect item-item dari baris OCR.
  ///
  /// Baris item = teks + angka di akhir (dipisah whitespace).
  /// Abaikan baris TOTAL/SUBTOTAL/JUMLAH.
  List<OcrItemResult> _extractOcrItems(
    List<String> lines,
    List<ParsingKeywordModel> dictionary,
  ) {
    final items = <OcrItemResult>[];
    final itemPattern = RegExp(r'^(.+?)\s+([\d.,]+)\s*$');
    final skipPattern = RegExp(
      r'(TOTAL|GRAND\s*TOTAL|JUMLAH|SUBTOTAL|DISKON|DISCOUNT|KEMBALIAN|CHANGE|TUNAI|CASH|DEBIT|CREDIT|PPN|TAX|PAJAK)',
      caseSensitive: false,
    );

    for (final line in lines) {
      if (line.isEmpty) continue;
      if (skipPattern.hasMatch(line)) continue;

      final match = itemPattern.firstMatch(line);
      if (match == null) continue;

      final name = match.group(1)!.trim();
      final numStr = match.group(2)!.replaceAll('.', '').replaceAll(',', '.');
      final amount = double.tryParse(numStr);

      if (amount == null || amount <= 0) continue;
      if (name.length < 2) continue;

      // Match keyword dictionary
      final category = _detectCategory(name.toLowerCase(), dictionary);

      items.add(
        OcrItemResult(
          name: name,
          amount: amount,
          categoryId: category?.categoryId,
        ),
      );
    }

    return items;
  }
}

// ─────────────────────────────────────────────────────
// OCR Parse Result Models
// ─────────────────────────────────────────────────────

/// Hasil parsing OCR struk.
///
/// Berisi data terstruktur dari raw text OCR:
/// grand total, tanggal, merchant, dan daftar item.
class OcrParseResult {
  const OcrParseResult({
    this.grandTotal,
    this.date,
    this.merchantName,
    this.items = const [],
  });

  /// Total yang terdeteksi dari struk.
  final double? grandTotal;

  /// Tanggal transaksi dari struk.
  final DateTime? date;

  /// Nama merchant / toko.
  final String? merchantName;

  /// Item-item yang terdeteksi beserta harganya.
  final List<OcrItemResult> items;

  /// Total dari semua item.
  double get itemsTotal => items.fold(0.0, (sum, i) => sum + i.amount);
}

/// Satu baris item dari struk OCR.
class OcrItemResult {
  const OcrItemResult({
    required this.name,
    required this.amount,
    this.categoryId,
  });

  /// Nama item dari struk.
  final String name;

  /// Harga / nominal item.
  final double amount;

  /// ID kategori (hasil matching keyword dictionary).
  final String? categoryId;
}
