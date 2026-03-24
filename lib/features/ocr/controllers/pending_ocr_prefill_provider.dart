import 'package:app_saku_rapi/features/ocr/models/ocr_parse_result_model.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Provider yang menyimpan data OCR parse sementara
/// untuk di-prefill ke transaction form.
///
/// Diatur oleh dashboard quick actions setelah OCR scan selesai.
/// Dibaca oleh TransactionFormPage saat init.
/// Auto-cleared setelah dibaca.
final pendingOcrPrefillProvider = StateProvider<OcrParseResultModel?>(
  (ref) => null,
);
