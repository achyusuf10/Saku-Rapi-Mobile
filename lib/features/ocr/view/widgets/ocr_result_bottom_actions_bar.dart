import 'package:app_saku_rapi/core/extensions/color_ext.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/ocr/controllers/ocr_scan_controller.dart';
import 'package:app_saku_rapi/features/ocr/controllers/pending_ocr_prefill_provider.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Baris tombol bawah sheet OCR: batal/rescan vs gunakan hasil.
class OcrResultBottomActionsBar extends ConsumerWidget {
  const OcrResultBottomActionsBar({
    super.key,
    required this.state,
    required this.ctrl,
  });

  final OcrScanState state;
  final OcrScanController ctrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final nav = Navigator.of(context);
    final accentColor = colors.accent;
    final accentForeground = accentColor.readableForeground;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SakuButton(
              text:
                  state.status == OcrScanStatus.done ||
                      state.status == OcrScanStatus.error
                  ? l10n.ocrRescan
                  : l10n.confirmCancel,
              onPressed: () async {
                if (state.status == OcrScanStatus.done ||
                    state.status == OcrScanStatus.error) {
                  if (state.status == OcrScanStatus.done) {
                    final confirmed = await context.showConfirmDialog(
                      title: l10n.aiPreviewDiscardTitle,
                      message: l10n.aiPreviewDiscardMessage,
                      confirmLabel: l10n.aiPreviewDiscardConfirm,
                      cancelLabel: l10n.confirmCancel,
                    );
                    if (confirmed == true && context.mounted) ctrl.reset();
                  } else {
                    ctrl.reset();
                  }
                } else {
                  nav.maybePop();
                }
              },
              isOutlined: true,
              icon: FaIcon(
                state.status == OcrScanStatus.done ||
                        state.status == OcrScanStatus.error
                    ? FontAwesomeIcons.rotateRight
                    : FontAwesomeIcons.xmark,
                size: 14.w,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: SakuButton(
              text: l10n.ocrUseResult,
              onPressed:
                  state.status == OcrScanStatus.done &&
                      state.parseResult != null
                  ? () {
                      if (state.imageFile != null) {
                        ref.read(pendingOcrImageFileProvider.notifier).state =
                            state.imageFile;
                      }
                      nav.pop(state.parseResult);
                    }
                  : null,
              backgroundColor: accentColor,
              textColor: accentForeground,
              icon: FaIcon(FontAwesomeIcons.check, size: 14.w),
            ),
          ),
        ],
      ),
    );
  }
}
