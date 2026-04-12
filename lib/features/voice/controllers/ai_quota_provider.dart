import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/voice/models/ai_quota_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider untuk fetch semua AI quota user.
///
/// Auto-disposed, di-fetch setiap kali bottom sheet input dibuka.
/// Memanggil RPC `get_all_ai_quotas()` yang sudah include auto-downgrade.
/// Jika JWT expired (PGRST303), otomatis refresh session dan retry sekali.
final aiQuotaProvider =
    FutureProvider.autoDispose<AllAiQuotasModel>((ref) async {
  final client = Supabase.instance.client;

  Future<AllAiQuotasModel> fetchQuota() async {
    final response = await client.rpc('get_all_ai_quotas');
    if (response == null) {
      throw Exception('Failed to fetch AI quotas: null response');
    }
    final data = response as Map<String, dynamic>;
    AppLogger.call('[AI Quota] Fetched: $data');
    return AllAiQuotasModel.fromRpcResponse(data);
  }

  try {
    return await fetchQuota();
  } on PostgrestException catch (e) {
    // PGRST303 = JWT expired — refresh session then retry once
    if (e.code == 'PGRST303') {
      AppLogger.call('[AI Quota] JWT expired, refreshing session...');
      try {
        await client.auth.refreshSession();
      } catch (_) {
        // If refresh fails, rethrow original error
        rethrow;
      }
      return await fetchQuota();
    }
    AppLogger.logError('[AI Quota] PostgrestException: ${e.message}');
    rethrow;
  }
});
