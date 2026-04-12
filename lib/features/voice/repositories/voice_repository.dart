import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/voice/datasource/voice_remote_data_source.dart';
import 'package:app_saku_rapi/features/voice/models/voice_parse_result_model.dart';

/// Repository orkestrator untuk voice parsing.
///
/// Pipeline (PRD §7.5):
/// 1. Kirim teks ke Edge Function AI (Gemini → Groq failover)
/// 2. Jika AI gagal → return DataState.error (tampilkan error + retry ke user)
class VoiceRepository {
  VoiceRepository({VoiceRemoteDataSource? remoteDataSource})
    : _remote = remoteDataSource ?? VoiceRemoteDataSource();

  final VoiceRemoteDataSource _remote;

  static const _tag = '[Voice] [VoiceRepository]';

  /// Parse teks voice melalui AI pipeline.
  ///
  /// [categories] berisi daftar kategori user untuk auto-assign oleh AI.
  /// Return DataState.error jika AI gagal — caller harus tampilkan error + retry.
  Future<DataState<VoiceParseResultModel>> parseVoiceText(
    String text, {
    List<Map<String, String>> categories = const [],
  }) async {
    AppLogger.call('$_tag parseVoiceText: "$text"');

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
        AppLogger.logError('$_tag AI response parse error: $e');
        return DataState.error(message: 'Gagal memproses respons AI. Coba lagi.');
      }
    }

    final (msg, _, _, _) = aiResult.dataError()!;
    AppLogger.call('$_tag AI failed: $msg');
    return DataState.error(message: msg);
  }
}
