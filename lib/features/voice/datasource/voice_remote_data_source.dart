import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/voice/models/parsing_dictionary_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk voice feature.
///
/// Menangani:
/// - Panggilan Edge Function `ai-parse` (mode voice)
/// - Fetch `parsing_dictionaries` dari Supabase
class VoiceRemoteDataSource {
  VoiceRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const _tag = '[Voice] [VoiceRemoteDataSource]';

  /// Kirim teks hasil STT ke Edge Function `ai-parse` mode voice.
  ///
  /// Returns raw response map: `{ success, mode, provider, data }`.
  /// Caller bertanggung jawab parse `data` ke [VoiceParseResultModel].
  Future<DataState<Map<String, dynamic>>> callAiParse(String text) async {
    return SupabaseHandler.call<Map<String, dynamic>>(
      function: () async {
        AppLogger.call(
          '$_tag callAiParse: text="${text.length > 50 ? '${text.substring(0, 50)}...' : text}"',
          colorLog: ColorLog.blue,
        );

        // Pastikan session masih valid sebelum invoke Edge Function
        await _client.auth.refreshSession();

        final response = await _client.functions.invoke(
          'ai-parse',
          body: {'mode': 'voice', 'text': text},
        );

        final data = response.data as Map<String, dynamic>;

        if (data['success'] == true) {
          AppLogger.logSuccess(
            '$_tag AI parse success, provider: ${data['provider']}',
            runtimeType: VoiceRemoteDataSource,
          );
          return data;
        }

        // AI_BUSY atau error lain dari Edge Function
        final errMsg = data['error'] as String? ?? 'Unknown AI error';
        throw Exception(errMsg);
      },
    );
  }

  /// Fetch semua parsing dictionaries dari Supabase.
  ///
  /// RLS memastikan hanya data yang sesuai yang dikembalikan.
  Future<DataState<List<ParsingDictionaryModel>>>
  fetchParsingDictionaries() async {
    return SupabaseHandler.call<List<ParsingDictionaryModel>>(
      function: () async {
        AppLogger.call(
          '$_tag fetchParsingDictionaries',
          colorLog: ColorLog.blue,
        );

        final response = await _client
            .from('parsing_dictionaries')
            .select()
            .order('keyword', ascending: true);

        final dictionaries = (response as List)
            .map(
              (e) => ParsingDictionaryModel.fromMap(e as Map<String, dynamic>),
            )
            .toList();

        AppLogger.logSuccess(
          '$_tag Fetched ${dictionaries.length} dictionaries',
          runtimeType: VoiceRemoteDataSource,
        );

        return dictionaries;
      },
    );
  }
}
