import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/voice/datasource/voice_local_data_source.dart';
import 'package:app_saku_rapi/features/voice/datasource/voice_remote_data_source.dart';
import 'package:app_saku_rapi/features/voice/models/parsing_dictionary_model.dart';
import 'package:app_saku_rapi/features/voice/models/voice_parse_result_model.dart';
import 'package:app_saku_rapi/features/voice/services/voice_local_parser.dart';

/// Repository orkestrator untuk voice parsing.
///
/// Pipeline (PRD §7.5):
/// 1. Kirim teks ke Edge Function AI (Gemini → Groq failover)
/// 2. Jika AI gagal → fallback local parser (regex + dictionary)
///
/// Dictionary management:
/// - Fetch dari Supabase, cache ke Hive selama 24 jam (PRD §7.7)
class VoiceRepository {
  VoiceRepository({
    VoiceRemoteDataSource? remoteDataSource,
    VoiceLocalDataSource? localDataSource,
  }) : _remote = remoteDataSource ?? VoiceRemoteDataSource(),
       _local = localDataSource ?? VoiceLocalDataSource();

  final VoiceRemoteDataSource _remote;
  final VoiceLocalDataSource _local;

  static const _tag = '[Voice] [VoiceRepository]';

  /// Parse teks voice melalui AI pipeline dengan local fallback.
  ///
  /// [categories] berisi daftar kategori user untuk auto-assign oleh AI.
  /// 1. Coba Edge Function AI
  /// 2. Jika gagal → local fallback parser
  /// 3. Return success dengan provider info
  Future<DataState<VoiceParseResultModel>> parseVoiceText(
    String text, {
    List<Map<String, String>> categories = const [],
  }) async {
    AppLogger.call('$_tag parseVoiceText: "$text"');

    // ── Try AI (Edge Function) ──
    final aiResult = await _remote.callAiParse(text, categories: categories);

    if (aiResult.isSuccess()) {
      try {
        final model = VoiceParseResultModel.fromEdgeFunctionMap(
          aiResult.dataSuccess()!,
          rawTranscript: text,
        );
        AppLogger.logSuccess(
          '$_tag AI parse OK (provider: ${model.provider})',
          runtimeType: VoiceRepository,
        );
        return DataState.success(data: model);
      } catch (e) {
        // JSON parsing error → fallback lokal
        AppLogger.logError('$_tag AI response parse error: $e');
        return DataState.success(data: _localFallback(text));
      }
    }

    // AI gagal (timeout, AI_BUSY, network) → fallback lokal
    final (msg, _, _, _) = aiResult.dataError()!;
    AppLogger.call('$_tag AI failed: $msg, using local fallback');
    return DataState.success(data: _localFallback(text));
  }

  /// Local fallback parser menggunakan regex + parsing dictionaries.
  VoiceParseResultModel _localFallback(String text) {
    final dictionaries = _getDictionaries();
    return VoiceLocalParser.parse(text, dictionaries: dictionaries);
  }

  /// Ambil parsing dictionaries (cache-first, 24hr TTL).
  List<ParsingDictionaryModel> _getDictionaries() {
    // Coba dari cache dulu
    final cached = _local.getCachedDictionaries();
    if (cached != null) return cached;
    return [];
  }

  /// Refresh parsing dictionaries dari Supabase.
  ///
  /// Dipanggil saat app init atau saat cache expired.
  /// Hasilnya di-cache ke Hive untuk 24 jam.
  Future<DataState<List<ParsingDictionaryModel>>> refreshDictionaries() async {
    AppLogger.call('$_tag refreshDictionaries');

    final result = await _remote.fetchParsingDictionaries();

    if (result.isSuccess()) {
      _local.cacheDictionaries(result.dataSuccess()!);
      return DataState.success(data: result.dataSuccess()!);
    }

    // Jika fetch gagal, return error
    final (msg, _, _, _) = result.dataError()!;
    AppLogger.call('$_tag Dictionaries fetch failed, returning stale cache');
    return DataState.error(message: msg);
  }

  /// Lookup category_id dari keyword melalui parsing dictionaries.
  ///
  /// Returns `null` jika keyword tidak ditemukan → caller harus
  /// fallback ke "Lain-lain" (PRD §7.7).
  String? lookupCategoryId(String? keyword) {
    if (keyword == null || keyword.isEmpty) return null;

    final dictionaries = _getDictionaries();
    final lower = keyword.toLowerCase();

    for (final dict in dictionaries) {
      if (dict.keyword.toLowerCase() == lower) {
        return dict.categoryId;
      }
    }

    // Partial match
    for (final dict in dictionaries) {
      if (lower.contains(dict.keyword.toLowerCase()) ||
          dict.keyword.toLowerCase().contains(lower)) {
        return dict.categoryId;
      }
    }

    return null;
  }
}
