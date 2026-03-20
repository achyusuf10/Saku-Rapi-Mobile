import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/parsing_dictionary/models/parsing_keyword_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_form_state.dart';
import 'package:app_saku_rapi/global/models/ai_parse_response_model.dart';
import 'package:app_saku_rapi/global/services/transaction_parser_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service orkestrasi AI parsing untuk voice input dan OCR.
///
/// Flow:
/// 1. Kirim teks ke Edge Function `ai-parse` via Supabase SDK.
/// 2. Jika AI berhasil → map response ke [TransactionFormState].
/// 3. Jika AI gagal (timeout / AI_BUSY / error) → fallback ke
///    [TransactionParserService] (NLP lokal).
///
/// Penggunaan:
/// ```dart
/// final service = AiParsingService(
///   supabaseClient: Supabase.instance.client,
///   localParser: TransactionParserService(),
/// );
/// final formState = await service.parseVoiceText(rawText, dictionary);
/// ```
class AiParsingService {
  static const String _tag = 'AiParsing';

  final SupabaseClient _supabaseClient;
  final TransactionParserService _localParser;

  AiParsingService({
    required SupabaseClient supabaseClient,
    required TransactionParserService localParser,
  }) : _supabaseClient = supabaseClient,
       _localParser = localParser;

  // ─────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────

  /// Parse teks voice input menggunakan AI, fallback ke NLP lokal.
  ///
  /// Mengembalikan [TransactionFormState] dengan `prefillSource` =
  /// `'voice_ai'` (dari AI) atau `'voice'` (dari lokal).
  Future<TransactionFormState> parseVoiceText(
    String rawText,
    List<ParsingKeywordModel> dictionary,
  ) async {
    AppLogger.call(
      '[$_tag] Parsing voice text via AI: $rawText',
      colorLog: ColorLog.blue,
    );

    try {
      final response = await _callEdgeFunction('voice', rawText);

      if (response.success && response.voiceData != null) {
        AppLogger.call(
          '[$_tag] AI voice parse success (${response.provider})',
          colorLog: ColorLog.green,
        );
        return _mapVoiceResponseToFormState(response.voiceData!, dictionary);
      }

      AppLogger.call(
        '[$_tag] AI returned error: ${response.error}',
        colorLog: ColorLog.yellow,
      );
    } catch (e, stackTrace) {
      AppLogger.logError(
        '[$_tag] Voice AI failed, falling back to local parser: $e',
        runtimeType: AiParsingService,
        stackTrace: stackTrace,
      );
    }

    // Fallback ke NLP lokal
    return _localParser.parseVoiceInput(rawText, dictionary);
  }

  /// Parse teks OCR struk menggunakan AI, fallback ke NLP lokal.
  ///
  /// Mengembalikan [TransactionFormState] dengan `prefillSource` =
  /// `'ocr_ai'` (dari AI) atau `'ocr'` (dari lokal).
  Future<TransactionFormState> parseOcrText(
    String rawText,
    List<ParsingKeywordModel> dictionary,
    String? attachmentPath,
  ) async {
    AppLogger.call(
      '[$_tag] Parsing OCR text via AI (${rawText.length} chars)',
      colorLog: ColorLog.blue,
    );

    try {
      final response = await _callEdgeFunction('ocr', rawText);

      if (response.success && response.ocrData != null) {
        AppLogger.call(
          '[$_tag] AI OCR parse success (${response.provider})',
          colorLog: ColorLog.green,
        );
        return _mapOcrResponseToFormState(
          response.ocrData!,
          dictionary,
          attachmentPath,
        );
      }

      AppLogger.call(
        '[$_tag] AI returned error: ${response.error}',
        colorLog: ColorLog.yellow,
      );
    } catch (e, stackTrace) {
      AppLogger.logError(
        '[$_tag] OCR AI failed, falling back to local parser: $e',
        runtimeType: AiParsingService,
        stackTrace: stackTrace,
      );
    }

    // Fallback ke NLP lokal
    final ocrResult = _localParser.parseOcrText(rawText, dictionary);
    return _localParser.ocrResultToFormState(ocrResult, attachmentPath);
  }

  // ─────────────────────────────────────────────────────
  // Edge Function call
  // ─────────────────────────────────────────────────────

  /// Panggil Edge Function `ai-parse` via Supabase SDK.
  ///
  /// SDK otomatis mengirim JWT Authorization header.
  Future<AiParseResponseModel> _callEdgeFunction(
    String mode,
    String text,
  ) async {
    final response = await _supabaseClient.functions.invoke(
      'ai-parse',
      body: {'mode': mode, 'text': text},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return AiParseResponseModel.fromMap(data);
    }

    throw Exception('Invalid response from ai-parse: ${data.runtimeType}');
  }

  // ─────────────────────────────────────────────────────
  // Response mapping — Voice
  // ─────────────────────────────────────────────────────

  /// Map response AI voice ke [TransactionFormState].
  TransactionFormState _mapVoiceResponseToFormState(
    VoiceParseDataModel data,
    List<ParsingKeywordModel> dictionary,
  ) {
    final category = _matchCategory(data.categoryKeyword, dictionary);

    final state = TransactionFormState(
      type: data.type ?? 'expense',
      date: DateTime.now(),
      prefillSource: 'voice_ai',
      note: data.note,
      items: [
        TransactionItemFormState(
          amount: data.amount,
          categoryId: category?.categoryId,
          note: data.note,
        ),
      ],
    );

    AppLogger.call(
      '[$_tag] Voice mapped: amount=${data.amount}, '
      'type=${data.type}, categoryId=${category?.categoryId}, '
      'keyword=${data.categoryKeyword}',
      colorLog: ColorLog.green,
    );

    return state;
  }

  // ─────────────────────────────────────────────────────
  // Response mapping — OCR
  // ─────────────────────────────────────────────────────

  /// Map response AI OCR ke [TransactionFormState].
  TransactionFormState _mapOcrResponseToFormState(
    OcrParseDataModel data,
    List<ParsingKeywordModel> dictionary,
    String? attachmentPath,
  ) {
    final date = _parseDate(data.date);

    final items = data.items.isNotEmpty
        ? data.items.map((item) {
            final category = _matchCategory(
              item.name.toLowerCase(),
              dictionary,
            );
            return TransactionItemFormState(
              amount: item.amount,
              categoryId: category?.categoryId,
              note: item.name,
            );
          }).toList()
        : [TransactionItemFormState(amount: data.grandTotal)];

    final state = TransactionFormState(
      type: 'expense',
      date: date ?? DateTime.now(),
      prefillSource: 'ocr_ai',
      merchantName: data.merchantName,
      attachmentLocalPath: attachmentPath,
      items: items,
    );

    AppLogger.call(
      '[$_tag] OCR mapped: merchant=${data.merchantName}, '
      'total=${data.grandTotal}, items=${data.items.length}, date=$date',
      colorLog: ColorLog.green,
    );

    return state;
  }

  // ─────────────────────────────────────────────────────
  // Category matching
  // ─────────────────────────────────────────────────────

  /// Cocokkan keyword AI dengan dictionary parsing.
  ///
  /// Strategi matching (berurutan):
  /// 1. Exact match (keyword dictionary == keyword AI)
  /// 2. Dictionary keyword contains AI keyword
  /// 3. AI keyword contains dictionary keyword
  /// 4. Tidak cocok → `null`
  ParsingKeywordModel? _matchCategory(
    String? keyword,
    List<ParsingKeywordModel> dictionary,
  ) {
    if (keyword == null || keyword.isEmpty) return null;
    final lower = keyword.toLowerCase();

    // 1. Exact match
    for (final entry in dictionary) {
      if (entry.keyword.toLowerCase() == lower) return entry;
    }

    // 2. Dictionary keyword contains AI keyword
    for (final entry in dictionary) {
      if (entry.keyword.toLowerCase().contains(lower)) return entry;
    }

    // 3. AI keyword contains dictionary keyword
    for (final entry in dictionary) {
      if (lower.contains(entry.keyword.toLowerCase())) return entry;
    }

    return null;
  }

  // ─────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────

  /// Parse tanggal dari string `yyyy-MM-dd`.
  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }
}
