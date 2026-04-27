import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/ocr/controllers/ocr_scan_controller.dart';
import 'package:app_saku_rapi/features/ocr/models/ocr_parse_result_model.dart';
import 'package:app_saku_rapi/features/ocr/view/widgets/ocr_result_bottom_actions_bar.dart';
import 'package:app_saku_rapi/features/ocr/view/widgets/ocr_result_sheet_content.dart';
import 'package:app_saku_rapi/features/voice/controllers/ai_quota_provider.dart';
import 'package:app_saku_rapi/features/voice/view/widgets/ai_quota_info_row.dart';
import 'package:app_saku_rapi/global/widgets/saku_sheet_drag_handle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bottom sheet alur scan struk OCR hingga hasil AI siap dipakai di form.
///
/// Memuat sub-widget terpisah agar file ini tetap ringkas; logika status
/// dan navigasi tidak diubah dari versi monolit.
class OcrResultSheet extends ConsumerWidget {
  const OcrResultSheet({super.key});

  /// Menampilkan modal dan mengembalikan [OcrParseResultModel] atau `null`.
  static Future<OcrParseResultModel?> show({required BuildContext context}) {
    return showModalBottomSheet<OcrParseResultModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const OcrResultSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final state = ref.watch(ocrScanControllerProvider);
    final ctrl = ref.read(ocrScanControllerProvider.notifier);

    // Setelah AI selesai (sukses/gagal), segarkan kuota harian.
    ref.listen<OcrScanState>(ocrScanControllerProvider, (prev, next) {
      if (prev?.status == OcrScanStatus.analyzingAi &&
          (next.status == OcrScanStatus.done ||
              next.status == OcrScanStatus.error)) {
        ref.invalidate(aiQuotaProvider);
      }
    });

    final isAnalyzing = state.status == OcrScanStatus.analyzingAi;
    final isDone = state.status == OcrScanStatus.done;

    return PopScope(
      canPop: !isAnalyzing && !isDone,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (isAnalyzing) {
          final confirmed = await context.showConfirmDialog(
            title: l10n.aiParseCancelTitle,
            message: l10n.aiParseCancelMessage,
            confirmLabel: l10n.aiParseCancelConfirm,
            cancelLabel: l10n.confirmCancel,
          );
          if (confirmed == true && context.mounted) {
            Navigator.of(context).pop();
          }
        } else if (isDone) {
          final confirmed = await context.showConfirmDialog(
            title: l10n.aiPreviewDiscardTitle,
            message: l10n.aiPreviewDiscardMessage,
            confirmLabel: l10n.aiPreviewDiscardConfirm,
            cancelLabel: l10n.confirmCancel,
          );
          if (confirmed == true && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Container(
        constraints: BoxConstraints(maxHeight: 0.92.sh),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SakuSheetDragHandle(
                color: colors.border.withValues(alpha: 0.4),
                width: 36.w,
                margin: EdgeInsets.only(top: 8.h),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.receipt,
                      size: 18.w,
                      color: colors.accent,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      l10n.ocrResultTitle,
                      style: TextStyleConstants.h6.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.border.withValues(alpha: 0.2)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                child: const AiQuotaInfoRow(mode: 'ocr'),
              ),
              Flexible(
                child: OcrResultSheetContent(state: state, ctrl: ctrl),
              ),
              OcrResultBottomActionsBar(state: state, ctrl: ctrl),
            ],
          ),
        ),
      ),
    );
  }
}
