import 'package:app_saku_rapi/features/voice/models/voice_parse_result_model.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Provider yang menyimpan data voice parse sementara
/// untuk di-prefill ke transaction form.
///
/// Diatur oleh dashboard quick actions setelah voice input selesai.
/// Dibaca oleh TransactionFormPage saat init.
/// Auto-cleared setelah dibaca.
final pendingVoicePrefillProvider = StateProvider<VoiceParseResultModel?>(
  (ref) => null,
);
