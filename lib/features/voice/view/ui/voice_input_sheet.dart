import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/voice/controllers/ai_quota_provider.dart';
import 'package:app_saku_rapi/features/voice/controllers/voice_input_controller.dart';
import 'package:app_saku_rapi/features/voice/models/voice_parse_result_model.dart';
import 'package:app_saku_rapi/features/voice/view/widgets/ai_quota_info_row.dart';
import 'package:app_saku_rapi/features/voice/view/widgets/voice_input_action_bar.dart';
import 'package:app_saku_rapi/features/voice/view/widgets/voice_input_error_panel.dart';
import 'package:app_saku_rapi/features/voice/view/widgets/voice_input_mic_button.dart';
import 'package:app_saku_rapi/features/voice/view/widgets/voice_input_status_text.dart';
import 'package:app_saku_rapi/features/voice/view/widgets/voice_input_transcript_panel.dart';
import 'package:app_saku_rapi/global/widgets/ai_parse_preview_card.dart';
import 'package:app_saku_rapi/global/widgets/saku_sheet_drag_handle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Bottom sheet rekam suara → transkrip → parse AI.
///
/// Sub-widget dipisah ke file `voice_input_*.dart`; alur state & animasi tidak diubah.
class VoiceInputSheet extends ConsumerStatefulWidget {
  const VoiceInputSheet({super.key});

  static Future<VoiceParseResultModel?> show({required BuildContext context}) {
    return showModalBottomSheet<VoiceParseResultModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const VoiceInputSheet(),
    );
  }

  @override
  ConsumerState<VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends ConsumerState<VoiceInputSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceInputControllerProvider.notifier).startVoiceInput();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceInputControllerProvider);
    final colors = context.colors;
    final l10n = context.l10n;

    ref.listen<VoiceInputState>(voiceInputControllerProvider, (prev, next) {
      if (prev?.status == VoiceInputStatus.processing &&
          (next.status == VoiceInputStatus.done ||
              next.status == VoiceInputStatus.error)) {
        ref.invalidate(aiQuotaProvider);
      }
    });

    if (state.status == VoiceInputStatus.listening) {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    } else {
      if (_pulseController.isAnimating) _pulseController.stop();
    }

    final isProcessing = state.status == VoiceInputStatus.processing;
    final isDone = state.status == VoiceInputStatus.done;

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
            ref.read(voiceInputControllerProvider.notifier).cancel();
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
            const AiQuotaInfoRow(mode: 'voice'),
            VoiceInputStatusText(state: state),
            SizedBox(height: 24.h),
            VoiceInputMicButton(
              state: state,
              pulseAnimation: _pulseAnimation,
              onStop: () => ref
                  .read(voiceInputControllerProvider.notifier)
                  .stopAndProcess(),
            ),
            SizedBox(height: 16.h),
            if (state.status == VoiceInputStatus.listening)
              Text(
                l10n.voiceCountdown(state.remainingSeconds),
                style: TextStyleConstants.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            if (state.transcript.isNotEmpty &&
                state.status != VoiceInputStatus.done) ...[
              SizedBox(height: 16.h),
              VoiceInputTranscriptPanel(transcript: state.transcript),
            ],
            if (state.status == VoiceInputStatus.done &&
                state.parseResult != null) ...[
              SizedBox(height: 16.h),
              Flexible(
                child: SingleChildScrollView(
                  child: AiParsePreviewCard(result: state.parseResult!),
                ),
              ),
            ],
            if (state.status == VoiceInputStatus.error ||
                state.status == VoiceInputStatus.permissionDenied) ...[
              SizedBox(height: 16.h),
              VoiceInputErrorPanel(state: state),
            ],
            SizedBox(height: 24.h),
            VoiceInputActionBar(
              state: state,
              onCancel: () => Navigator.maybePop(context),
              onRetry: () async {
                final confirmed = await context.showConfirmDialog(
                  title: l10n.aiPreviewDiscardTitle,
                  message: l10n.aiPreviewDiscardMessage,
                  confirmLabel: l10n.aiPreviewDiscardConfirm,
                  cancelLabel: l10n.confirmCancel,
                );
                if (confirmed == true && context.mounted) {
                  ref
                      .read(voiceInputControllerProvider.notifier)
                      .startVoiceInput();
                }
              },
              onDone: () {
                Navigator.of(context).pop(state.parseResult);
              },
              onOpenSettings: () {
                ref.read(voiceInputControllerProvider.notifier).openSettings();
              },
            ),
          ],
        ),
      ),
    );
  }
}
