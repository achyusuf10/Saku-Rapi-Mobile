import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/voice/datasource/voice_remote_data_source.dart';
import 'package:app_saku_rapi/features/voice/models/ai_quota_model.dart';
import 'package:app_saku_rapi/features/voice/models/voice_parse_result_model.dart';

/// Repository orkestrator untuk voice/text parsing.
///
/// Pipeline:
/// 1. Kirim teks ke Edge Function AI (Gemini only)
/// 2. Jika AI gagal → return DataState.error (tampilkan error + retry ke user)
class VoiceRepository {
  VoiceRepository({VoiceRemoteDataSource? remoteDataSource})
    : _remote = remoteDataSource ?? VoiceRemoteDataSource();

  final VoiceRemoteDataSource _remote;

  static const _tag = '[Voice] [VoiceRepository]';

  /// Parse teks melalui AI pipeline.
  ///
  /// [mode] menentukan kuota: `'text'` (keyboard input) atau `'voice'` (STT).
  /// [categories] berisi daftar kategori user untuk auto-assign oleh AI.
  /// [wallets] berisi daftar wallet user untuk auto-match oleh AI.
  /// Return DataState.error jika AI gagal — caller harus tampilkan error + retry.
  Future<DataState<VoiceParseResultModel>> parseVoiceText(
    String text, {
    String mode = 'text',
    List<Map<String, dynamic>> categories = const [],
    List<Map<String, String>> wallets = const [],
  }) async {
    AppLogger.call('$_tag parseVoiceText (mode: $mode): "$text"');

    final aiResult = await _remote.callAiParse(
      text,
      mode: mode,
      categories: categories,
      wallets: wallets,
    );

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
        return DataState.error(
          message: 'Gagal memproses respons AI. Coba lagi.',
        );
      }
    }

    final (msg, _, _, _) = aiResult.dataError()!;
    AppLogger.call('$_tag AI failed: $msg');
    return DataState.error(message: msg);
  }

  /// Ambil semua kuota AI user saat ini.
  ///
  /// Digunakan oleh [aiQuotaProvider] untuk ditampilkan di bottom sheet.
  /// Delegates ke [VoiceRemoteDataSource.getAllAiQuotas].
  Future<AllAiQuotasModel> getAllAiQuotas() async {
    final result = await _remote.getAllAiQuotas();
    return result.map(
      success: (s) => s.data,
      error: (err) {
        AppLogger.logError(
          '$_tag getAllAiQuotas error: ${err.message}',
          runtimeType: VoiceRepository,
        );
        throw Exception(err.message);
      },
    );
  }
}
