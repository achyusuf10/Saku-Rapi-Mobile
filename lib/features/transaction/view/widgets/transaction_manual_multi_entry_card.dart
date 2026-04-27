import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_amount_section.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_category_picker_tile.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_date_picker_tile.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_multi_item_section.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_optional_details_section.dart';
import 'package:app_saku_rapi/global/widgets/saku_wallet_picker_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Satu transaksi dalam mode multi: lipat/tarik + field seperti form tunggal.
class TransactionManualMultiEntryCard extends ConsumerStatefulWidget {
  const TransactionManualMultiEntryCard({
    super.key,
    required this.index,
    required this.typeColor,
    required this.type,
    required this.canRemove,
    required this.merchantInitial,
    required this.noteInitial,
    required this.onPickWallet,
    required this.onPickCategory,
    required this.onPickAttachment,
  });

  final int index;
  final Color typeColor;
  final TransactionTypeEnum type;
  final bool canRemove;
  final String merchantInitial;
  final String noteInitial;
  final VoidCallback onPickWallet;
  final VoidCallback onPickCategory;
  final VoidCallback onPickAttachment;

  @override
  ConsumerState<TransactionManualMultiEntryCard> createState() =>
      _TransactionManualMultiEntryCardState();
}

class _TransactionManualMultiEntryCardState
    extends ConsumerState<TransactionManualMultiEntryCard> {
  late TextEditingController _merchant;
  late TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _merchant = TextEditingController(text: widget.merchantInitial);
    _note = TextEditingController(text: widget.noteInitial);
  }

  @override
  void didUpdateWidget(covariant TransactionManualMultiEntryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.merchantInitial != widget.merchantInitial &&
        widget.merchantInitial != _merchant.text) {
      _merchant.text = widget.merchantInitial;
    }
    if (oldWidget.noteInitial != widget.noteInitial &&
        widget.noteInitial != _note.text) {
      _note.text = widget.noteInitial;
    }
  }

  @override
  void dispose() {
    _merchant.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final form = ref.watch(transactionFormControllerProvider);
    final ctrl = ref.read(transactionFormControllerProvider.notifier);
    if (widget.index < 0 || widget.index >= form.manualMultiEntries.length) {
      return const SizedBox.shrink();
    }
    final entry = form.manualMultiEntries[widget.index];

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () =>
                ctrl.setManualMultiEntryExpanded(widget.index, !entry.expanded),
            borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              child: Row(
                children: [
                  FaIcon(
                    entry.expanded
                        ? FontAwesomeIcons.chevronDown
                        : FontAwesomeIcons.chevronRight,
                    size: 12.w,
                    color: colors.textSecondary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    l10n.transactionMultiManualCardTitle(widget.index + 1),
                    style: TextStyleConstants.b2.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                  ),
                  10.horizontalSpace,
                  Expanded(
                    child: Text(
                      entry.totalAmount.toCurrency(),
                      style: TextStyleConstants.label1.copyWith(
                        color: widget.typeColor,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                  if (widget.canRemove) ...[
                    SizedBox(width: 4.w),
                    IconButton(
                      icon: FaIcon(
                        FontAwesomeIcons.trashCan,
                        size: 15.w,
                        color: colors.expense,
                      ),
                      onPressed: () =>
                          ctrl.removeManualMultiEntry(widget.index),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (entry.expanded)
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Urutan selaras form tunggal: nominal → dompet → kategori → tanggal → opsional → multi-item
                  if (!entry.isMultiItem) ...[
                    TransactionAmountSection(
                      typeColor: widget.typeColor,
                      autoFocus: false,
                      initialValue: entry.totalAmount > 0
                          ? entry.totalAmount
                          : null,
                      onChanged: (val) => ctrl.setManualMultiEntryTotalAmount(
                        widget.index,
                        val,
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                  SakuWalletPickerTile(
                    label: l10n.transactionWallet,
                    selected: entry.wallet,
                    onTap: widget.onPickWallet,
                    iconColor: colors.primary,
                    backgroundColor: colors.surface,
                    useBorder: true,
                  ),
                  SizedBox(height: 8.h),
                  TransactionCategoryPickerTile(
                    type: widget.type,
                    category: entry.category,
                    item: entry.items.isNotEmpty ? entry.items.first : null,
                    onTap: widget.onPickCategory,
                    iconColor: widget.typeColor,
                  ),
                  SizedBox(height: 8.h),
                  TransactionDatePickerTile(
                    date: entry.date,
                    onChanged: (d) {
                      FocusScope.of(context).unfocus();
                      ctrl.setManualMultiEntryDate(widget.index, d);
                    },
                  ),
                  SizedBox(height: 10.h),
                  TransactionOptionalDetailsSection(
                    merchantController: _merchant,
                    noteController: _note,
                    onMerchantChanged: (v) =>
                        ctrl.setManualMultiEntryMerchant(widget.index, v),
                    onNoteChanged: (v) =>
                        ctrl.setManualMultiEntryNote(widget.index, v),
                    onPickAttachment: widget.onPickAttachment,
                    onRemoveAttachment: () => ctrl
                        .setManualMultiEntryLocalAttachment(widget.index, null),
                    attachmentUrl: entry.attachmentUrl,
                    localAttachmentPath: entry.localAttachmentPath,
                  ),
                  SizedBox(height: 16.h),
                  TransactionMultiItemSection(
                    manualMultiEntryIndex: widget.index,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
