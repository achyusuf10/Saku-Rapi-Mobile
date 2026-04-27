import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/voice/controllers/ai_quota_provider.dart';
import 'package:app_saku_rapi/features/voice/controllers/text_input_controller.dart';
import 'package:app_saku_rapi/features/voice/models/voice_parse_result_model.dart';
import 'package:app_saku_rapi/features/voice/view/widgets/ai_quota_info_row.dart';
import 'package:app_saku_rapi/features/voice/view/widgets/text_input_action_bar.dart';
import 'package:app_saku_rapi/features/voice/view/widgets/text_input_error_panel.dart';
import 'package:app_saku_rapi/global/widgets/ai_parse_preview_card.dart';
import 'package:app_saku_rapi/global/widgets/saku_sheet_drag_handle.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Bottom sheet: user mengetik deskripsi transaksi lalu AI mem-parse ke model.
///
/// Widget pendukung (error, tombol) dipindah ke file terpisah; perilaku sheet sama.
class TextInputSheet extends ConsumerStatefulWidget {
  const TextInputSheet({super.key});

  /// Membuka sheet modal; hasil non-null berarti user menekan lanjut setelah sukses parse.
  static Future<VoiceParseResultModel?> show({required BuildContext context}) {
    return showModalBottomSheet<VoiceParseResultModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const TextInputSheet(),
    );
  }

  @override
  ConsumerState<TextInputSheet> createState() => _TextInputSheetState();
}

class _TextInputSheetState extends ConsumerState<TextInputSheet> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Fokus keyboard setelah frame pertama agar field langsung aktif.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(textInputControllerProvider);
    final colors = context.colors;
    final l10n = context.l10n;

    ref.listen<TextInputState>(textInputControllerProvider, (prev, next) {
      if (prev?.status == TextInputStatus.processing &&
          (next.status == TextInputStatus.done ||
              next.status == TextInputStatus.error)) {
        ref.invalidate(aiQuotaProvider);
      }
    });

    final isProcessing = state.status == TextInputStatus.processing;
    final isDone = state.status == TextInputStatus.done;

    return PopScope(
      canPop: !isProcessing && !isDone,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (isProcessing) {
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
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.only(
          top: 16.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32.h,
          left: 24.w,
          right: 24.w,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SakuSheetDragHandle(
              color: colors.textSecondary.withValues(alpha: 0.3),
            ),
            SizedBox(height: 24.h),
            Text(
              l10n.textInputTitle,
              style: TextStyleConstants.h6.copyWith(
                color: state.status == TextInputStatus.done
                    ? colors.success
                    : state.status == TextInputStatus.error
                    ? colors.expense
                    : colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            const AiQuotaInfoRow(mode: 'text'),
            SizedBox(height: 8.h),
            if (state.status != TextInputStatus.done) ...[
              SakuTextField(
                controller: _textController,
                focusNode: _focusNode,
                enabled: state.status != TextInputStatus.processing,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                maxLines: 3,
                minLines: 1,
                maxLength: 60,
              ),
            ],
            if (state.status == TextInputStatus.processing) ...[
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w,
                      valueColor: AlwaysStoppedAnimation(colors.primary),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    l10n.textInputAnalyzing,
                    style: TextStyleConstants.b2.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ],
            if (state.status == TextInputStatus.done &&
                state.parseResult != null) ...[
              SizedBox(height: 16.h),
              Flexible(
                child: SingleChildScrollView(
                  child: AiParsePreviewCard(result: state.parseResult!),
                ),
              ),
            ],
            if (state.status == TextInputStatus.error) ...[
              SizedBox(height: 16.h),
              TextInputErrorPanel(errorMessage: state.errorMessage),
            ],
            SizedBox(height: 24.h),
            TextInputActionBar(
              state: state,
              onCancel: () => Navigator.maybePop(context),
              onSubmit: _submit,
              onRetry: () {
                ref.read(textInputControllerProvider.notifier).reset();
                _focusNode.requestFocus();
              },
              onDone: () => Navigator.of(context).pop(state.parseResult),
            ),
          ],
        ),
      ),
    );
  }

  /// Mengirim teks ke controller bila tidak kosong (setelah trim).
  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _focusNode.unfocus();
    ref.read(textInputControllerProvider.notifier).processText(text);
  }
}
