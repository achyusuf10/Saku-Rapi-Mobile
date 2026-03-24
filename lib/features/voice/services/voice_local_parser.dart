import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/voice/models/parsing_dictionary_model.dart';
import 'package:app_saku_rapi/features/voice/models/voice_parse_result_model.dart';

/// Local fallback parser untuk voice input.
///
/// Menggunakan regex + parsing dictionaries ketika AI (Gemini/Groq)
/// tidak tersedia (PRD §7.5 fallback lokal).
class VoiceLocalParser {
  static const _tag = '[Voice] [VoiceLocalParser]';

  /// Regex patterns untuk ekstraksi nominal.
  ///
  /// Mendukung format:
  /// - "25rb" / "25 ribu" → 25000
  /// - "1.5jt" / "1,5 juta" → 1500000
  /// - "150000" / "150.000" → 150000
  static final _amountPatterns = [
    // "1.5jt", "1,5jt", "2jt", "1.5 juta", "2 juta"
    RegExp(r'(\d+[.,]?\d*)\s*(?:jt|juta)', caseSensitive: false),
    // "25rb", "25 ribu", "100rb"
    RegExp(r'(\d+[.,]?\d*)\s*(?:rb|ribu)', caseSensitive: false),
    // "150000", "150.000" (plain numbers)
    RegExp(r'(?:rp\.?\s*)?(\d{1,3}(?:[.]\d{3})+|\d{4,})', caseSensitive: false),
  ];

  /// Kata kunci indikator income.
  static const _incomeKeywords = [
    'gaji',
    'terima',
    'dapat',
    'masuk',
    'bonus',
    'thr',
    'pendapatan',
    'income',
    'salary',
    'receive',
    'dividen',
    'freelance',
  ];

  /// Parse teks voice secara lokal menggunakan regex + dictionary.
  ///
  /// [text] adalah teks transkripsi STT.
  /// [dictionaries] adalah daftar keyword→categoryId dari cache/DB.
  static VoiceParseResultModel parse(
    String text, {
    List<ParsingDictionaryModel> dictionaries = const [],
  }) {
    AppLogger.call('$_tag parse: "$text"');

    final lower = text.toLowerCase().trim();

    // 1. Extract amount
    final amount = _extractAmount(lower);

    // 2. Detect type (income vs expense)
    final type = _detectType(lower);

    // 3. Find category keyword via dictionary matching
    final categoryKeyword = _findCategoryKeyword(lower, dictionaries);

    // 4. Remaining text as note (strip amount patterns)
    final note = _extractNote(lower);

    final result = VoiceParseResultModel.fromLocal(
      amount: amount,
      categoryKeyword: categoryKeyword,
      note: note,
      type: type,
      rawTranscript: text,
    );

    AppLogger.call('$_tag result: $result');
    return result;
  }

  /// Extrak nominal dari teks.
  static double? _extractAmount(String text) {
    for (final pattern in _amountPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final rawNum = match.group(1) ?? '';

        // Untuk pattern jt/juta dan rb/ribu: dot dan comma = decimal separator
        if (pattern.pattern.contains('jt|juta') ||
            pattern.pattern.contains('rb|ribu')) {
          final normalized = rawNum.replaceAll(',', '.');
          final value = double.tryParse(normalized);
          if (value == null) continue;

          if (pattern.pattern.contains('jt|juta')) {
            return value * 1000000;
          } else {
            return value * 1000;
          }
        }

        // Untuk plain number: dot = thousands separator
        final normalized = rawNum.replaceAll('.', '');
        final value = double.tryParse(normalized);
        if (value == null) continue;
        return value;
      }
    }
    return null;
  }

  /// Deteksi tipe transaksi dari kata kunci.
  static TransactionTypeEnum _detectType(String text) {
    for (final keyword in _incomeKeywords) {
      if (text.contains(keyword)) {
        return TransactionTypeEnum.income;
      }
    }
    return TransactionTypeEnum.expense;
  }

  /// Cari keyword kategori dari parsing dictionaries.
  ///
  /// Iterasi setiap keyword dictionary, cek apakah ada di teks.
  /// Return keyword pertama yang ditemukan.
  static String? _findCategoryKeyword(
    String text,
    List<ParsingDictionaryModel> dictionaries,
  ) {
    for (final dict in dictionaries) {
      if (text.contains(dict.keyword.toLowerCase())) {
        return dict.keyword;
      }
    }
    return null;
  }

  /// Bersihkan teks dari pola nominal untuk dijadikan note.
  static String? _extractNote(String text) {
    var cleaned = text;

    // Remove amount patterns
    for (final pattern in _amountPatterns) {
      cleaned = cleaned.replaceAll(pattern, '');
    }

    // Remove common filler words
    cleaned = cleaned
        .replaceAll(RegExp(r'\b(beli|bayar|untuk|di|ke)\b'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return cleaned.isEmpty ? null : cleaned;
  }
}
