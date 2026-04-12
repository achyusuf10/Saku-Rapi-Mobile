import 'package:app_saku_rapi/features/voice/controllers/voice_input_controller.dart';
import 'package:app_saku_rapi/features/voice/models/ai_quota_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider untuk fetch semua AI quota user.
///
/// Auto-disposed, di-fetch setiap kali bottom sheet input dibuka.
/// Memanggil [VoiceRepository.getAllAiQuotas] → RPC `get_all_ai_quotas`.
/// Jika gagal, widget [AiQuotaInfoRow] menampilkan `SizedBox.shrink()` secara silent.
final aiQuotaProvider =
    FutureProvider.autoDispose<AllAiQuotasModel>((ref) async {
  final repository = ref.watch(voiceRepositoryProvider);
  return repository.getAllAiQuotas();
});
