import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/category/controllers/category_controller.dart';
import 'package:app_saku_rapi/features/category/utils/category_icon_ext.dart';
import 'package:app_saku_rapi/features/voice/controllers/voice_input_controller.dart';
import 'package:app_saku_rapi/features/voice/models/voice_parse_result_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bottom sheet untuk voice input recording.
///
/// Menampilkan:
/// - Animated mic button (press & hold)
/// - Countdown timer
/// - Transcript display
/// - Status messages (initializing, listening, processing, done, error)
///
/// Returns [VoiceParseResultModel?] saat ditutup (null jika cancel).
class VoiceInputSheet extends ConsumerStatefulWidget {
  const VoiceInputSheet({super.key});

  /// Tampilkan voice input sheet.
  ///
  /// Returns [VoiceParseResultModel?] jika parsing berhasil,
  /// `null` jika user cancel.
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

    // Auto-start voice input saat sheet dibuka
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

    // Control pulse animation based on state
    if (state.status == VoiceInputStatus.listening) {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    } else {
      if (_pulseController.isAnimating) _pulseController.stop();
    }

    return Container(
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

          // ── Status text ──
          _VoiceStatusText(state: state),

          SizedBox(height: 24.h),

          // ── Mic button with pulse ──
          _VoiceMicButton(
            state: state,
            pulseAnimation: _pulseAnimation,
            onStop: () => ref
                .read(voiceInputControllerProvider.notifier)
                .stopAndProcess(),
          ),

          SizedBox(height: 16.h),

          // ── Countdown ──
          if (state.status == VoiceInputStatus.listening)
            Text(
              l10n.voiceCountdown(state.remainingSeconds),
              style: TextStyleConstants.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),

          // ── Transcript display ──
          if (state.transcript.isNotEmpty &&
              state.status != VoiceInputStatus.done) ...[
            SizedBox(height: 16.h),
            _VoiceTranscriptDisplay(
              transcript: state.transcript,
              isProcessing: state.status == VoiceInputStatus.processing,
            ),
          ],

          // ── Preview hasil parsing ──
          if (state.status == VoiceInputStatus.done &&
              state.parseResult != null) ...[
            SizedBox(height: 16.h),
            _VoicePreviewCard(result: state.parseResult!),
          ],

          // ── Error / Permission denied ──
          if (state.status == VoiceInputStatus.error ||
              state.status == VoiceInputStatus.permissionDenied) ...[
            SizedBox(height: 16.h),
            _VoiceErrorDisplay(state: state),
          ],

          SizedBox(height: 24.h),

          // ── Action buttons ──
          _VoiceActionButtons(
            state: state,
            onCancel: () {
              ref.read(voiceInputControllerProvider.notifier).cancel();
              Navigator.of(context).pop();
            },
            onRetry: () {
              ref.read(voiceInputControllerProvider.notifier).startVoiceInput();
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
    );
  }
}

// ═══════════════ Sub-widgets ═══════════════

/// Status text di bagian atas sheet.
class _VoiceStatusText extends StatelessWidget {
  const _VoiceStatusText({required this.state});

  final VoiceInputState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    final (text, color) = switch (state.status) {
      VoiceInputStatus.idle => (l10n.voiceTapToSpeak, colors.textSecondary),
      VoiceInputStatus.initializing => (
        l10n.voiceInitializing,
        colors.textSecondary,
      ),
      VoiceInputStatus.listening => (l10n.voiceListening, colors.info),
      VoiceInputStatus.processing => (l10n.voiceAnalyzingAi, colors.primary),
      VoiceInputStatus.done => (l10n.voicePreviewTitle, colors.success),
      VoiceInputStatus.error => (l10n.voiceError, colors.expense),
      VoiceInputStatus.permissionDenied => (
        l10n.voicePermissionDenied,
        colors.expense,
      ),
    };

    return Text(
      text,
      style: TextStyleConstants.h6.copyWith(color: color),
      textAlign: TextAlign.center,
    );
  }
}

/// Animated mic button.
class _VoiceMicButton extends StatelessWidget {
  const _VoiceMicButton({
    required this.state,
    required this.pulseAnimation,
    required this.onStop,
  });

  final VoiceInputState state;
  final Animation<double> pulseAnimation;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final isListening = state.status == VoiceInputStatus.listening;
    final isProcessing = state.status == VoiceInputStatus.processing;

    final bgColor = isListening
        ? colors.expense
        : isProcessing
        ? colors.primary
        : colors.info;
    final onBgColor = _foregroundForBackground(bgColor);

    final icon = isProcessing
        ? FontAwesomeIcons.spinner
        : isListening
        ? FontAwesomeIcons.stop
        : FontAwesomeIcons.microphone;

    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        final scale = isListening ? pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: isListening ? onStop : null,
            child: Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor,
                boxShadow: [
                  if (isListening)
                    BoxShadow(
                      color: colors.expense.withValues(alpha: 0.25),
                      blurRadius: 12.r,
                      spreadRadius: 2.r,
                    ),
                ],
              ),
              child: Center(
                child: isProcessing
                    ? SizedBox(
                        width: 28.w,
                        height: 28.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.w,
                          valueColor: AlwaysStoppedAnimation(onBgColor),
                        ),
                      )
                    : FaIcon(icon, size: 28.w, color: onBgColor),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _foregroundForBackground(Color backgroundColor) {
    final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
    return brightness == Brightness.dark ? Colors.white : Colors.black87;
  }
}

/// Display transkripsi suara.
class _VoiceTranscriptDisplay extends StatelessWidget {
  const _VoiceTranscriptDisplay({
    required this.transcript,
    required this.isProcessing,
  });

  final String transcript;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.voiceTranscript,
            style: TextStyleConstants.label2.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '"$transcript"',
            style: TextStyleConstants.b1.copyWith(
              color: colors.textPrimary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Error display dengan CTA.
class _VoiceErrorDisplay extends StatelessWidget {
  const _VoiceErrorDisplay({required this.state});

  final VoiceInputState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    final message = state.status == VoiceInputStatus.permissionDenied
        ? l10n.voicePermissionExplainer
        : state.errorMessage == 'no_speech'
        ? l10n.voiceNoSpeech
        : state.errorMessage == 'not_transaction'
        ? l10n.voiceNotTransaction
        : l10n.voiceError;

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

/// Action buttons di bagian bawah sheet.
class _VoiceActionButtons extends StatelessWidget {
  const _VoiceActionButtons({
    required this.state,
    required this.onCancel,
    required this.onRetry,
    required this.onDone,
    required this.onOpenSettings,
  });

  final VoiceInputState state;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final VoidCallback onDone;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Row(
      children: [
        // Cancel / Ulangi button
        Expanded(
          child: OutlinedButton(
            onPressed: state.status == VoiceInputStatus.done
                ? onRetry
                : onCancel,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              side: BorderSide(
                color: colors.textSecondary.withValues(alpha: 0.3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              state.status == VoiceInputStatus.done
                  ? l10n.voiceRetryButton
                  : l10n.confirmCancel,
              style: TextStyleConstants.b2.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ),

        SizedBox(width: 12.w),

        // Contextual action button
        Expanded(child: _buildActionButton(colors, l10n)),
      ],
    );
  }

  Widget _buildActionButton(dynamic colors, dynamic l10n) {
    // Permission denied → "Buka Pengaturan"
    if (state.status == VoiceInputStatus.permissionDenied) {
      final buttonColor = colors.primary as Color;
      return ElevatedButton(
        onPressed: onOpenSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          l10n.voiceOpenSettings,
          style: TextStyleConstants.b2.copyWith(
            color: _foregroundForBackground(buttonColor),
          ),
        ),
      );
    }

    // Error → "Coba Lagi"
    if (state.status == VoiceInputStatus.error) {
      final buttonColor = colors.info as Color;
      return ElevatedButton(
        onPressed: onRetry,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          l10n.retryButton,
          style: TextStyleConstants.b2.copyWith(
            color: _foregroundForBackground(buttonColor),
          ),
        ),
      );
    }

    // Done → "Lanjutkan"
    if (state.status == VoiceInputStatus.done) {
      final buttonColor = colors.success as Color;
      return ElevatedButton(
        onPressed: onDone,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          l10n.voiceContinueButton,
          style: TextStyleConstants.b2.copyWith(
            color: _foregroundForBackground(buttonColor),
          ),
        ),
      );
    }

    // Processing/listening → disabled "Mohon tunggu..."
    return ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: Text(
        l10n.voicePleaseWait,
        style: TextStyleConstants.b2.copyWith(color: colors.textSecondary),
      ),
    );
  }

  Color _foregroundForBackground(Color backgroundColor) {
    final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
    return brightness == Brightness.dark ? Colors.white : Colors.black87;
  }
}

/// Preview card yang menampilkan hasil parsing voice.
///
/// Menampilkan: tipe transaksi, nominal, kategori, catatan, tanggal,
/// wallet, merchant, dan info orang (jika hutang/piutang).
class _VoicePreviewCard extends ConsumerWidget {
  const _VoicePreviewCard({required this.result});

  final VoiceParseResultModel result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;

    // Lookup matched category from database by categoryId
    final allCategories = ref.watch(categoryControllerProvider).categories;
    final matchedCategory = result.categoryId != null
        ? allCategories.where((c) => c.id == result.categoryId).firstOrNull
        : null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colors.success.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Transcript asli ──
          if (result.rawTranscript != null &&
              result.rawTranscript!.isNotEmpty) ...[
            Text(
              l10n.voiceTranscript,
              style: TextStyleConstants.label2.copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              '"${result.rawTranscript}"',
              style: TextStyleConstants.b2.copyWith(
                color: colors.textPrimary,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 12.h),
            Divider(height: 1, color: colors.border.withValues(alpha: 0.15)),
            SizedBox(height: 12.h),
          ],

          // ── Tipe transaksi ──
          _PreviewRow(
            icon: _typeIcon(result.type),
            iconColor: _typeColor(result.type, colors),
            label: l10n.voicePreviewType,
            value: _typeLabel(result.type, l10n),
          ),

          // ── Nominal ──
          if (result.amount != null && result.amount! > 0) ...[
            SizedBox(height: 8.h),
            _PreviewRow(
              icon: FontAwesomeIcons.moneyBill,
              iconColor: colors.primary,
              label: l10n.transactionAmount,
              value: result.amount!.toCurrency(),
            ),
          ],

          // ── Kategori ──
          if (matchedCategory != null ||
              (result.categoryKeyword != null &&
                  result.categoryKeyword!.isNotEmpty)) ...[
            SizedBox(height: 8.h),
            _PreviewRow(
              icon: FontAwesomeIcons.tag,
              iconColor: colors.accent,
              label: l10n.transactionCategory,
              value: matchedCategory?.name ?? result.categoryKeyword!,
              leading: matchedCategory?.toIcon(
                size: 14,
                showBackground: false,
                colorOverride: colors.accent,
              ),
            ),
          ],

          // ── Merchant ──
          if (result.merchantName != null &&
              result.merchantName!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            _PreviewRow(
              icon: FontAwesomeIcons.store,
              iconColor: colors.info,
              label: l10n.transactionMerchant,
              value: result.merchantName!,
            ),
          ],

          // ── Wallet ──
          if (result.suggestedWallet != null &&
              result.suggestedWallet!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            _PreviewRow(
              icon: FontAwesomeIcons.wallet,
              iconColor: colors.transfer,
              label: l10n.transactionWallet,
              value: result.suggestedWallet!,
            ),
          ],

          // ── Destination wallet (transfer) ──
          if (result.type == TransactionTypeEnum.transfer &&
              result.destinationWallet != null &&
              result.destinationWallet!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            _PreviewRow(
              icon: FontAwesomeIcons.arrowRight,
              iconColor: colors.transfer,
              label: l10n.voicePreviewDestWallet,
              value: result.destinationWallet!,
            ),
          ],

          // ── Nama orang (hutang/piutang) ──
          if (result.withPerson != null && result.withPerson!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            _PreviewRow(
              icon: FontAwesomeIcons.userTag,
              iconColor: colors.expense,
              label: l10n.transactionWithPerson,
              value: result.withPerson!,
            ),
          ],

          // ── Tanggal ──
          if (result.date != null) ...[
            SizedBox(height: 8.h),
            _PreviewRow(
              icon: FontAwesomeIcons.calendar,
              iconColor: colors.textSecondary,
              label: l10n.transactionDate,
              value: result.date!.extToFormattedString(),
            ),
          ],

          // ── Catatan ──
          if (result.note != null && result.note!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            _PreviewRow(
              icon: FontAwesomeIcons.noteSticky,
              iconColor: colors.textSecondary,
              label: l10n.transactionNote,
              value: result.note!,
            ),
          ],

          // ── Provider badge ──
          SizedBox(height: 12.h),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                result.provider ?? 'AI',
                style: TextStyleConstants.label3.copyWith(
                  color: colors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(TransactionTypeEnum type) {
    return switch (type) {
      TransactionTypeEnum.income => FontAwesomeIcons.arrowDown,
      TransactionTypeEnum.expense => FontAwesomeIcons.arrowUp,
      TransactionTypeEnum.transfer => FontAwesomeIcons.arrowRightArrowLeft,
      TransactionTypeEnum.debt => FontAwesomeIcons.handHoldingDollar,
      TransactionTypeEnum.loan => FontAwesomeIcons.handHoldingHand,
      _ => FontAwesomeIcons.circleQuestion,
    };
  }

  Color _typeColor(TransactionTypeEnum type, dynamic colors) {
    return switch (type) {
      TransactionTypeEnum.income => colors.income as Color,
      TransactionTypeEnum.expense => colors.expense as Color,
      TransactionTypeEnum.transfer => colors.transfer as Color,
      TransactionTypeEnum.debt => colors.expense as Color,
      TransactionTypeEnum.loan => colors.income as Color,
      _ => colors.textSecondary as Color,
    };
  }

  String _typeLabel(TransactionTypeEnum type, dynamic l10n) {
    return switch (type) {
      TransactionTypeEnum.income => l10n.transactionIncome as String,
      TransactionTypeEnum.expense => l10n.transactionExpense as String,
      TransactionTypeEnum.transfer => l10n.transactionTransfer as String,
      TransactionTypeEnum.debt => l10n.transactionDebt as String,
      TransactionTypeEnum.loan => l10n.transactionLoan as String,
      _ => type.toDbValue(),
    };
  }
}

/// Baris tunggal dalam preview card.
class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.leading,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  /// Widget custom leading (override icon + iconColor).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20.w,
          child: leading ?? FaIcon(icon, size: 14.w, color: iconColor),
        ),
        SizedBox(width: 8.w),
        SizedBox(
          width: 80.w,
          child: Text(
            label,
            style: TextStyleConstants.label2.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyleConstants.b2.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
