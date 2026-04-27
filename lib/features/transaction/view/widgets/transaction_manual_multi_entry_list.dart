import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/features/transaction/utils/manual_multi_batch_limits.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_manual_multi_entry_card.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Daftar transaksi mode multi + tombol tambah.
class TransactionManualMultiEntryList extends ConsumerWidget {
  const TransactionManualMultiEntryList({
    super.key,
    required this.typeColor,
    required this.type,
    required this.onPickWalletFor,
    required this.onPickCategoryFor,
    required this.onPickAttachmentFor,
  });

  final Color typeColor;
  final TransactionTypeEnum type;
  final void Function(int index) onPickWalletFor;
  final void Function(int index) onPickCategoryFor;
  final void Function(int index) onPickAttachmentFor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final form = ref.watch(transactionFormControllerProvider);
    final ctrl = ref.read(transactionFormControllerProvider.notifier);
    final entries = form.manualMultiEntries;
    final atLimit = entries.length >= kManualMultiBatchMaxTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(entries.length, (i) {
          final e = entries[i];
          return TransactionManualMultiEntryCard(
            key: ValueKey(e.entryKey),
            index: i,
            typeColor: typeColor,
            type: type,
            canRemove: entries.length > 1,
            merchantInitial: e.merchantName ?? '',
            noteInitial: e.note ?? '',
            onPickWallet: () => onPickWalletFor(i),
            onPickCategory: () => onPickCategoryFor(i),
            onPickAttachment: () => onPickAttachmentFor(i),
          );
        }),
        if (atLimit) ...[
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FaIcon(
                FontAwesomeIcons.triangleExclamation,
                size: 14.w,
                color: colors.warning,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  l10n.transactionMultiManualAtLimitBanner(
                    kManualMultiBatchMaxTransactions,
                  ),
                  style: TextStyleConstants.caption.copyWith(
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: 8.h),
        SakuButton(
          text: l10n.transactionMultiManualAddAnother,
          icon: FaIcon(
            FontAwesomeIcons.plus,
            size: 14.w,
            color: colors.onPrimary,
          ),
          backgroundColor: colors.primary,
          isEnabled: !atLimit,
          onPressed: () {
            final ok = ctrl.addManualMultiEntry();
            if (!ok && context.mounted) {
              context.showAppAlert(
                l10n.transactionMultiManualMaxReached(
                  kManualMultiBatchMaxTransactions,
                ),
                alertType: AlertTypeEnum.warning,
              );
            }
          },
        ),
      ],
    );
  }
}
