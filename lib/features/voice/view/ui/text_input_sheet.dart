import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/category/controllers/category_controller.dart';
import 'package:app_saku_rapi/features/category/utils/category_icon_mapper.dart';
import 'package:app_saku_rapi/features/voice/controllers/text_input_controller.dart';
import 'package:app_saku_rapi/features/voice/models/voice_parse_result_model.dart';
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
      isDismissible: true,
      enableDrag: true,
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

          SizedBox(height: 16.h),

          // ── Text field + submit ──
          if (state.status != TextInputStatus.done) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SakuTextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    enabled: state.status != TextInputStatus.processing,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                    maxLines: 3,
                    minLines: 1,
                    maxLength: 60,
                  ),
                ),
                SizedBox(width: 8.w),
                _SubmitButton(
                  isProcessing: state.status == TextInputStatus.processing,
                  onTap: _submit,
                ),
              ],
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
                  style: TextStyleConstants.b2.copyWith(color: colors.primary),
                ),
              ],
            ),
          ],

          // ── Preview ──
          if (state.status == TextInputStatus.done &&
              state.parseResult != null) ...[
            SizedBox(height: 16.h),
            _TextPreviewCard(result: state.parseResult!),
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
            onCancel: () => Navigator.of(context).pop(),
            onRetry: () {
              ref.read(textInputControllerProvider.notifier).reset();
              _focusNode.requestFocus();
            },
            onDone: () => Navigator.of(context).pop(state.parseResult),
          ),
        ],
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

/// Tombol submit berbentuk bulat di samping text field.
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.isProcessing, required this.onTap});

  final bool isProcessing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: isProcessing ? null : onTap,
      child: Container(
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isProcessing
              ? colors.primary.withValues(alpha: 0.3)
              : colors.primary,
        ),
        child: Center(
          child: isProcessing
              ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.w,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : FaIcon(
                  FontAwesomeIcons.paperPlane,
                  size: 18.w,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}

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
    required this.onRetry,
    required this.onDone,
  });

  final TextInputState state;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Row(
      children: [
        // Cancel / Retry button
        Expanded(
          child: OutlinedButton(
            onPressed: state.status == TextInputStatus.done
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
              state.status == TextInputStatus.done
                  ? l10n.voiceRetryButton
                  : l10n.confirmCancel,
              style: TextStyleConstants.b2.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ),

        SizedBox(width: 12.w),

        // Action button
        Expanded(child: _buildActionButton(colors, l10n)),
      ],
    );
  }

  Widget _buildActionButton(dynamic colors, dynamic l10n) {
    // Error → "Coba Lagi"
    if (state.status == TextInputStatus.error) {
      return ElevatedButton(
        onPressed: onRetry,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.info,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          l10n.retryButton,
          style: TextStyleConstants.b2.copyWith(color: Colors.white),
        ),
      );
    }

    // Done → "Lanjutkan"
    if (state.status == TextInputStatus.done) {
      return ElevatedButton(
        onPressed: onDone,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.success,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          l10n.voiceContinueButton,
          style: TextStyleConstants.b2.copyWith(color: Colors.white),
        ),
      );
    }

    // Idle / Processing → disabled
    return ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: Text(
        state.status == TextInputStatus.processing
            ? l10n.voicePleaseWait
            : l10n.textInputSubmit,
        style: TextStyleConstants.b2.copyWith(color: colors.textSecondary),
      ),
    );
  }
}

/// Preview card untuk hasil parsing teks.
class _TextPreviewCard extends ConsumerWidget {
  const _TextPreviewCard({required this.result});

  final VoiceParseResultModel result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;

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
          // ── Teks input asli ──
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
              icon: matchedCategory != null
                  ? CategoryIconMapper.getIcon(matchedCategory.icon)
                  : FontAwesomeIcons.tag,
              iconColor: colors.accent,
              label: l10n.transactionCategory,
              value: matchedCategory?.name ?? result.categoryKeyword!,
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
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20.w,
          child: FaIcon(icon, size: 14.w, color: iconColor),
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
