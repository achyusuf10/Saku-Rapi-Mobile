import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/themes/app_colors.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/features/transaction/models/manual_transaction_entry_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_item_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bagian multi-item untuk transaksi expense dan income.
///
/// Jika [manualMultiEntryIndex] non-null, data diambil dari entry mode multi.
class TransactionMultiItemSection extends ConsumerWidget {
  const TransactionMultiItemSection({super.key, this.manualMultiEntryIndex});

  /// Index entry mode multi; null = form tunggal seperti sebelumnya.
  final int? manualMultiEntryIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final formState = ref.watch(transactionFormControllerProvider);
    final ctrl = ref.read(transactionFormControllerProvider.notifier);

    if (manualMultiEntryIndex != null) {
      return _buildMultiManual(
        context,
        ctrl,
        colors,
        formState,
        manualMultiEntryIndex!,
      );
    }

    if (!formState.isMultiItem) {
      return GestureDetector(
        onTap: () => ctrl.addItem(),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(
              context.l10n.transactionAddItem,
              style: TextStyleConstants.b2.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return _multiItemColumn(
      context: context,
      colors: colors,
      isTotalMatched: formState.isTotalMatched,
      itemsTotal: formState.itemsTotal,
      itemCount: formState.items.length,
      itemKeys: formState.itemKeys,
      items: formState.items,
      onAddItem: () => ctrl.addItem(),
      onReorder: (o, n) => ctrl.reorderItems(o, n),
      onChanged: (i, u) => ctrl.updateItem(i, u),
      onRemove: (i) => ctrl.removeItem(i),
    );
  }

  Widget _buildMultiManual(
    BuildContext context,
    TransactionFormController ctrl,
    AppColorScheme colors,
    TransactionFormState formState,
    int entryIndex,
  ) {
    if (entryIndex < 0 || entryIndex >= formState.manualMultiEntries.length) {
      return const SizedBox.shrink();
    }
    final ManualTransactionEntryModel e =
        formState.manualMultiEntries[entryIndex];
    final isMulti = e.items.length > 1;

    // Satu item: sama seperti form tunggal — hanya chip aktifkan multi-item.
    if (!isMulti) {
      return GestureDetector(
        onTap: () => ctrl.addManualMultiItem(entryIndex),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(
              context.l10n.transactionAddItem,
              style: TextStyleConstants.b2.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return _multiItemColumn(
      context: context,
      colors: colors,
      isTotalMatched: e.isTotalMatched,
      itemsTotal: e.itemsTotal,
      itemCount: e.items.length,
      itemKeys: e.itemKeys,
      items: e.items,
      onAddItem: () => ctrl.addManualMultiItem(entryIndex),
      onReorder: (o, n) => ctrl.reorderManualMultiEntryItems(entryIndex, o, n),
      onChanged: (i, u) => ctrl.updateManualMultiEntryItem(entryIndex, i, u),
      onRemove: (i) => ctrl.removeManualMultiEntryItem(entryIndex, i),
    );
  }

  Widget _multiItemColumn({
    required BuildContext context,
    required AppColorScheme colors,
    required bool isTotalMatched,
    required double itemsTotal,
    required int itemCount,
    required List<int> itemKeys,
    required List<TransactionItemModel> items,
    required VoidCallback onAddItem,
    required void Function(int oldIndex, int newIndex) onReorder,
    required void Function(int index, TransactionItemModel updated) onChanged,
    required void Function(int index) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.l10n.transactionMultiItemToggle,
              style: TextStyleConstants.label1.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: isTotalMatched
                    ? colors.income.withValues(alpha: 0.1)
                    : colors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                context.l10n.transactionItemCount(itemCount),
                style: TextStyleConstants.label2.copyWith(
                  color: isTotalMatched ? colors.income : colors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isTotalMatched
                ? colors.income.withValues(alpha: 0.06)
                : colors.error.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isTotalMatched ? colors.income : colors.error,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    context.l10n.transactionGrandTotal,
                    style: TextStyleConstants.label1.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    itemsTotal.toCurrency(),
                    style: TextStyleConstants.b1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isTotalMatched ? colors.income : colors.error,
                    ),
                  ),
                ],
              ),
              if (!isTotalMatched) ...[
                SizedBox(height: 6.h),
                Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.triangleExclamation,
                      size: 12.w,
                      color: colors.error,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        context.l10n.transactionTotalMismatch,
                        style: TextStyleConstants.caption.copyWith(
                          color: colors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 10.h),
        if (itemCount > 1) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                FontAwesomeIcons.gripVertical,
                size: 10.w,
                color: colors.textSecondary.withValues(alpha: 0.5),
              ),
              SizedBox(width: 4.w),
              Text(
                context.l10n.transactionReorderHint,
                style: TextStyleConstants.caption.copyWith(
                  color: colors.textSecondary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
        ],
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final elevation = Tween<double>(
                  begin: 0,
                  end: 4,
                ).evaluate(animation);
                return Material(
                  elevation: elevation,
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
                  child: child,
                );
              },
              child: child,
            );
          },
          itemCount: itemCount,
          onReorder: onReorder,
          itemBuilder: (context, index) {
            final item = items[index];
            final itemKey = index < itemKeys.length ? itemKeys[index] : index;
            return TransactionItemRow(
              key: ValueKey('item_$itemKey'),
              item: item,
              index: index,
              onChanged: (updated) => onChanged(index, updated),
              onRemove: () => onRemove(index),
              canRemove: itemCount > 1,
            );
          },
        ),
        SizedBox(height: 4.h),
        GestureDetector(
          onTap: onAddItem,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text(
                context.l10n.transactionAddItem,
                style: TextStyleConstants.b2.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
