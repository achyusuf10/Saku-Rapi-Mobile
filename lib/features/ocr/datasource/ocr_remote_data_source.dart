import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk panggilan Edge Function OCR.
///
/// Memanggil `ai-parse` dengan mode `ocr` untuk parsing teks struk.
/// Semua panggilan dibungkus [SupabaseHandler.call] untuk error handling.
class OcrRemoteDataSource {
  OcrRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const _tag = '[OcrRemoteDataSource]';

  /// Kirim teks OCR ke Edge Function `ai-parse` mode `ocr`.
  ///
  /// Return [DataState] berisi response map dari AI.
  Future<DataState<Map<String, dynamic>>> callAiParse(String ocrText) {
    return SupabaseHandler.call<Map<String, dynamic>>(
      function: () async {
        AppLogger.call('$_tag Calling ai-parse (mode: ocr)');

        // Pastikan session masih valid sebelum invoke Edge Function
        await _client.auth.refreshSession();

        final response = await _client.functions.invoke(
          'ai-parse',
          body: {'mode': 'ocr', 'text': ocrText},
        );

        final data = response.data as Map<String, dynamic>;

        if (data['success'] != true) {
          final error = data['error'] as String? ?? 'Unknown error';
          AppLogger.logError('$_tag AI parse failed: $error');
          throw Exception(error);
        }

        AppLogger.logSuccess(
          'AI parse OCR success (provider: ${data['provider']})',
          runtimeType: OcrRemoteDataSource,
        );
        return data;
      },
    );
  }
}
