import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/utils/color_utils.dart';
import 'package:app_saku_rapi/features/budget/models/budget_model.dart';
import 'package:app_saku_rapi/features/budget/view/widgets/budget_progress_bar.dart';
import 'package:app_saku_rapi/features/category/utils/category_display_name.dart';
import 'package:app_saku_rapi/global/widgets/saku_category_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Card tile untuk menampilkan satu budget dalam list.
///
/// Menampilkan ikon kategori, nama, nominal budget & used, progress bar,
/// dan badge sisa / over budget.
class BudgetCardTile extends StatelessWidget {
  const BudgetCardTile({
    super.key,
    required this.budget,
    this.onTap,
    this.onLongPress,
  });

  final BudgetModel budget;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final ratio = budget.usageRatio;
    final statusColor = BudgetProgressBar.colorForRatio(ratio, context);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header: icon + name + amount ───
            Row(
              children: [
                // Category icon
                SakuCategoryIcon(
                  iconName: budget.category?.icon ?? 'circleQuestion',
                  color: parseHexColor(budget.category?.color ?? '#6B7280'),
                  backgroundFill: parseHexColor(
                    budget.category?.backgroundColor,
                  ),
                  size: 42,
                  iconSize: 18,
                  circular: true,
                ),
                SizedBox(width: 12.w),

                // Name + wallet scope
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.category?.displayTitle(l10n) ?? '-',
                        style: TextStyleConstants.b1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (budget.wallet != null)
                        Text(
                          budget.wallet!.name,
                          style: TextStyleConstants.label2.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),

                // Budget amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      budget.amount.toCurrency(),
                      style: TextStyleConstants.b1.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      budget.isOverBudget
                          ? l10n.budgetOver(
                              (budget.usedAmount - budget.amount).toCurrency(
                                withPrefix: false,
                              ),
                            )
                          : l10n.budgetRemaining(
                              budget.remaining.toCurrency(withPrefix: false),
                            ),
                      style: TextStyleConstants.label2.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // ─── Progress bar ───
            BudgetProgressBar(
              ratio: ratio,
              expectedRatio: budget.expectedRatio,
            ),
            SizedBox(height: 8.h),

            // ─── Footer: days remaining ───
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    budget.daysRemaining == 0
                        ? l10n.budgetToday
                        : l10n.budgetDaysRemaining(budget.daysRemaining),
                    style: TextStyleConstants.label3.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
