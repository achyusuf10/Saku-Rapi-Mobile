import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_item_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Bagian multi-item untuk transaksi expense.
///
/// Jika [formState.isMultiItem] false, menampilkan tombol "Tambah Item".
/// Jika true, menampilkan daftar item dengan total dan tombol tambah.
class TransactionMultiItemSection extends StatelessWidget {
  const TransactionMultiItemSection({
    super.key,
    required this.formState,
    required this.onAddItem,
    required this.onUpdateItem,
    required this.onRemoveItem,
  });

  final TransactionFormState formState;
  final VoidCallback onAddItem;
  final void Function(int index, TransactionItemModel item) onUpdateItem;
  final void Function(int index) onRemoveItem;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (!formState.isMultiItem) {
      return GestureDetector(
        onTap: onAddItem,
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
                '${formState.items.length} item',
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

        // Grand total
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: formState.isTotalMatched
                ? colors.income.withValues(alpha: 0.06)
                : colors.error.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
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
        ),
        SizedBox(height: 10.h),

        // Items list
        ...formState.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return TransactionItemRow(
            key: ValueKey('item_$index'),
            item: item,
            index: index,
            onChanged: (updated) => onUpdateItem(index, updated),
            onRemove: () => onRemoveItem(index),
            canRemove: formState.items.length > 1,
            categoryType: CategoryType.expense,
          );
        }),

        // Add more items
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
