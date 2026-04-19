import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/voice/controllers/ai_quota_provider.dart';
import 'package:app_saku_rapi/features/voice/controllers/text_input_controller.dart';
import 'package:app_saku_rapi/features/voice/models/voice_parse_result_model.dart';
import 'package:app_saku_rapi/features/voice/view/widgets/ai_quota_info_row.dart';
import 'package:app_saku_rapi/global/widgets/ai_parse_preview_card.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bottom sheet untuk text input → AI parse.
///
/// Returns [VoiceParseResultModel?] saat ditutup (null jika cancel).
class TextInputSheet extends ConsumerStatefulWidget {
  const TextInputSheet({super.key});

  /// Tampilkan text input sheet.
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

    // Refresh quota setelah AI parse selesai (success atau error quota)
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
            // ── Drag handle ──
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            SizedBox(height: 24.h),

            // ── Title ──
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

            // ── Quota info ──
            const AiQuotaInfoRow(mode: 'text'),

            SizedBox(height: 8.h),

            // ── Text field ──
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

            // ── Processing indicator ──
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

            // ── Preview ──
            if (state.status == TextInputStatus.done &&
                state.parseResult != null) ...[
              SizedBox(height: 16.h),
              Flexible(
                child: SingleChildScrollView(
                  child: AiParsePreviewCard(result: state.parseResult!),
                ),
              ),
            ],

            // ── Error ──
            if (state.status == TextInputStatus.error) ...[
              SizedBox(height: 16.h),
              _TextErrorDisplay(errorMessage: state.errorMessage),
            ],

            SizedBox(height: 24.h),

            // ── Action buttons ──
            _TextActionButtons(
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

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _focusNode.unfocus();
    ref.read(textInputControllerProvider.notifier).processText(text);
  }
}

// ═══════════════ Sub-widgets ═══════════════

/// Error display.
class _TextErrorDisplay extends StatelessWidget {
  const _TextErrorDisplay({required this.errorMessage});

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    final message = errorMessage == 'not_transaction'
        ? l10n.voiceNotTransaction
        : errorMessage == 'DAILY_QUOTA_EXCEEDED'
        ? l10n.aiQuotaExhausted
        : l10n.textInputError;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: colors.expense.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.circleExclamation,
            size: 16.w,
            color: colors.expense,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: TextStyleConstants.b2.copyWith(color: colors.expense),
            ),
          ),
        ],
      ),
    );
  }
}

/// Action buttons.
class _TextActionButtons extends StatelessWidget {
  const _TextActionButtons({
    required this.state,
    required this.onCancel,
    required this.onSubmit,
    required this.onRetry,
    required this.onDone,
  });

  final TextInputState state;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final VoidCallback onRetry;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Row(
      children: [
        // Left: "Batalkan" (negative, outlined)
        Expanded(
          child: SakuButton(
            text: l10n.confirmCancel,
            onPressed: onCancel,
            isOutlined: true,
          ),
        ),

        SizedBox(width: 12.w),

        // Right: main action (Analisis / loading / Coba Lagi / Lanjutkan)
        Expanded(child: _buildActionButton(colors, l10n)),
      ],
    );
  }

  Widget _buildActionButton(dynamic colors, dynamic l10n) {
    // Processing → loading spinner
    if (state.status == TextInputStatus.processing) {
      return SakuButton(text: '', onPressed: null, isLoading: true);
    }

    // Error → "Coba Lagi"
    if (state.status == TextInputStatus.error) {
      final buttonColor = colors.info as Color;
      return SakuButton(
        text: l10n.retryButton,
        onPressed: onRetry,
        backgroundColor: buttonColor,
        textColor: _foregroundForBackground(buttonColor),
      );
    }

    // Done → "Lanjutkan"
    if (state.status == TextInputStatus.done) {
      final buttonColor = colors.success as Color;
      return SakuButton(
        text: l10n.voiceContinueButton,
        onPressed: onDone,
        backgroundColor: buttonColor,
        textColor: _foregroundForBackground(buttonColor),
      );
    }

    // Idle → "Analisis"
    return SakuButton(text: l10n.textInputSubmit, onPressed: onSubmit);
  }

  Color _foregroundForBackground(Color backgroundColor) {
    final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
    return brightness == Brightness.dark ? Colors.white : Colors.black87;
  }
}
