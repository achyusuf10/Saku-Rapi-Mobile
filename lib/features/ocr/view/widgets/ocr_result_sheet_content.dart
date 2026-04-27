import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/ocr/controllers/ocr_scan_controller.dart';
import 'package:app_saku_rapi/features/ocr/view/widgets/ocr_result_error_body.dart';
import 'package:app_saku_rapi/features/ocr/view/widgets/ocr_result_loading_body.dart';
import 'package:app_saku_rapi/features/ocr/view/widgets/ocr_result_parsed_body.dart';
import 'package:app_saku_rapi/features/ocr/view/widgets/ocr_result_permission_body.dart';
import 'package:app_saku_rapi/features/ocr/view/widgets/ocr_result_source_picker_body.dart';
import 'package:flutter/material.dart';

/// Area scroll utama sheet: memilih isi sesuai [OcrScanState.status].
///
/// Mempertahankan urutan cabang yang sama dengan implementasi monolit sebelumnya.
class OcrResultSheetContent extends StatelessWidget {
  const OcrResultSheetContent({
    super.key,
    required this.state,
    required this.ctrl,
  });

  final OcrScanState state;
  final OcrScanController ctrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    // Memuat / crop gambar.
    if (state.status == OcrScanStatus.pickingImage ||
        state.status == OcrScanStatus.cropping) {
      return OcrResultLoadingBody(message: l10n.ocrProcessing, colors: colors);
    }

    // AI menganalisis struk.
    if (state.status == OcrScanStatus.analyzingAi) {
      return OcrResultLoadingBody(message: l10n.ocrAnalyzingAi, colors: colors);
    }

    // Izin ditolak.
    if (state.status == OcrScanStatus.permissionDenied) {
      return OcrResultPermissionBody(
        ctrl: ctrl,
        isPermanent: state.isPermanentlyDenied,
        colors: colors,
        l10n: l10n,
      );
    }

    // Error pipeline OCR / AI.
    if (state.status == OcrScanStatus.error) {
      return OcrResultErrorBody(state: state, colors: colors, l10n: l10n);
    }

    // Berhasil parse.
    if (state.status == OcrScanStatus.done && state.parseResult != null) {
      return OcrResultParsedBody(state: state);
    }

    // Idle: pilih kamera atau galeri.
    return OcrResultSourcePickerBody(ctrl: ctrl, colors: colors, l10n: l10n);
  }
}
