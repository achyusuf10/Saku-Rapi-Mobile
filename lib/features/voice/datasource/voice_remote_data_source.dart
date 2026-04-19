import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/core/utils/saku_date_utils.dart';
import 'package:app_saku_rapi/features/voice/models/ai_quota_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk voice/text feature.
///
/// Menangani panggilan Edge Function `ai-parse`.
/// - Voice input → mode `voice`
/// - Text input → mode `text`
class VoiceRemoteDataSource {
  VoiceRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const _tag = '[Voice] [VoiceRemoteDataSource]';

  /// Kirim teks ke Edge Function `ai-parse`.
  ///
  /// [mode] menentukan kuota yang digunakan: `'text'` atau `'voice'`.
  /// [categories] berisi daftar kategori user untuk auto-assign oleh AI.
  /// [wallets] berisi daftar wallet user untuk auto-match oleh AI.
  /// Returns raw response map: `{ success, mode, provider, data, quota }`.
  /// Caller bertanggung jawab parse `data` ke [VoiceParseResultModel].
  Future<DataState<Map<String, dynamic>>> callAiParse(
    String text, {
    String mode = 'text',
    List<Map<String, dynamic>> categories = const [],
    List<Map<String, String>> wallets = const [],
  }) {
    return SupabaseHandler.call<Map<String, dynamic>>(
      function: () async {
        AppLogger.call(
          '$_tag callAiParse: text="${text.length > 50 ? '${text.substring(0, 50)}...' : text}"',
          colorLog: ColorLog.blue,
        );

        // Pastikan session masih valid sebelum invoke Edge Function

        final body = <String, dynamic>{
          'mode': mode,
          'text': text,
          'localDate': SakuDateUtils.formatDate(DateTime.now()),
        };
        if (categories.isNotEmpty) {
          body['categories'] = categories;
        }
        if (wallets.isNotEmpty) {
          body['wallets'] = wallets;
        }

        final response = await _client.functions.invoke('ai-parse', body: body);

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

  /// Ambil semua kuota AI user saat ini dari RPC `get_all_ai_quotas`.
  ///
  /// Termasuk auto-downgrade tier jika expired.
  /// Returns [AllAiQuotasModel] berisi kuota text/voice/ocr dan tier aktif.
  Future<DataState<AllAiQuotasModel>> getAllAiQuotas() {
    return SupabaseHandler.call<AllAiQuotasModel>(
      function: () async {
        AppLogger.call('$_tag getAllAiQuotas', colorLog: ColorLog.blue);

        final response = await _client.rpc(
          'get_all_ai_quotas',
          params: {'p_usage_date': SakuDateUtils.formatDate(DateTime.now())},
        );

        if (response == null) {
          throw Exception('get_all_ai_quotas returned null');
        }

        return AllAiQuotasModel.fromRpcResponse(
          response as Map<String, dynamic>,
        );
      },
    );
  }
}
