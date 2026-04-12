import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/voice/models/ai_quota_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider untuk fetch semua AI quota user.
///
/// Auto-disposed, di-fetch setiap kali bottom sheet input dibuka.
/// Memanggil RPC `get_all_ai_quotas()` yang sudah include auto-downgrade.
final aiQuotaProvider =
    FutureProvider.autoDispose<AllAiQuotasModel>((ref) async {
  final client = Supabase.instance.client;

  final response = await client.rpc('get_all_ai_quotas');

  if (response == null) {
    throw Exception('Failed to fetch AI quotas');
  }

  final data = response as Map<String, dynamic>;
  AppLogger.call('[AI Quota] Fetched: $data');
  return AllAiQuotasModel.fromRpcResponse(data);
});
