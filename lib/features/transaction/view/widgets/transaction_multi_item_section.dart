import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_item_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bagian multi-item untuk transaksi expense dan income.
///
/// ConsumerWidget yang watch provider langsung agar rebuild hanya terjadi
/// di section ini saat items berubah, tanpa mempengaruhi seluruh halaman.
class TransactionMultiItemSection extends ConsumerWidget {
  const TransactionMultiItemSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final formState = ref.watch(transactionFormControllerProvider);
    final ctrl = ref.read(transactionFormControllerProvider.notifier);

    final categoryType = formState.type == TransactionTypeEnum.income
        ? CategoryType.income
        : CategoryType.expense;

    if (!formState.isMultiItem) {
      return GestureDetector(
        onTap: () => ctrl.addItem(),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
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

    // Multi-item mode
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
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
                color: formState.isTotalMatched
                    ? colors.income.withValues(alpha: 0.1)
                    : colors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                context.l10n.transactionItemCount(formState.items.length),
                style: TextStyleConstants.label2.copyWith(
                  color: formState.isTotalMatched
                      ? colors.income
                      : colors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),

        // Grand total + mismatch warning
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: formState.isTotalMatched
                ? colors.income.withValues(alpha: 0.06)
                : colors.error.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10.r),
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
                    formState.itemsTotal.toCurrency(),
                    style: TextStyleConstants.b1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: formState.isTotalMatched
                          ? colors.income
                          : colors.error,
                    ),
                  ),
                ],
              ),
              // Mismatch warning
              if (!formState.isTotalMatched) ...[
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

        // Reorder hint
        if (formState.items.length > 1) ...[
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

        // Items list with ReorderableListView
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
          itemCount: formState.items.length,
          onReorder: (oldIndex, newIndex) =>
              ctrl.reorderItems(oldIndex, newIndex),
          itemBuilder: (context, index) {
            final item = formState.items[index];
            final itemKey = index < formState.itemKeys.length
                ? formState.itemKeys[index]
                : index;
            return TransactionItemRow(
              key: ValueKey('item_$itemKey'),
              item: item,
              index: index,
              onChanged: (updated) => ctrl.updateItem(index, updated),
              onRemove: () => ctrl.removeItem(index),
              canRemove: formState.items.length > 1,
              categoryType: categoryType,
            );
          },
        ),

        // Add more items
        SizedBox(height: 4.h),
        GestureDetector(
          onTap: () => ctrl.addItem(),
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
