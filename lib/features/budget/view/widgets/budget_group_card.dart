import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/utils/color_utils.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/budget/models/budget_model.dart';
import 'package:app_saku_rapi/features/budget/view/widgets/budget_progress_bar.dart';
import 'package:app_saku_rapi/global/widgets/saku_category_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Model grup: satu parent budget (opsional) + child budgets.
class BudgetGroup {
  const BudgetGroup({this.parent, this.children = const []});

  /// Budget parent. Null jika hanya punya child tanpa parent budget.
  final BudgetModel? parent;

  /// Budget children yang categoryId-nya punya parentId = parent's categoryId.
  final List<BudgetModel> children;

  /// Semua budget dalam group (parent + children).
  List<BudgetModel> get all => [?parent, ...children];

  /// Apakah grup ini hanya berisi satu budget (tanpa parent-child).
  bool get isSingle => parent != null && children.isEmpty;
}

/// Card grouped untuk menampilkan parent + child budgets dalam satu card.
///
/// Jika [group.isSingle], tampilkan seperti card biasa.
/// Jika ada children, tampilkan parent di atas lalu children di bawah
/// dengan garis vertikal penghubung.
class BudgetGroupCard extends StatelessWidget {
  const BudgetGroupCard({super.key, required this.group, this.onTap});

  final BudgetGroup group;
  final void Function(BudgetModel budget)? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parent budget row
          if (group.parent != null)
            _BudgetRow(
              budget: group.parent!,
              isParent: true,
              hasChildren: group.children.isNotEmpty,
              onTap: () => onTap?.call(group.parent!),
            ),

          // Children with connector line
          if (group.children.isNotEmpty)
            _ChildrenSection(children: group.children, onTap: onTap),
        ],
      ),
    );
  }
}

/// Satu baris budget (parent atau child).
class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.budget,
    this.isParent = false,
    this.hasChildren = false,
    this.onTap,
  });

  final BudgetModel budget;
  final bool isParent;
  final bool hasChildren;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final ratio = budget.usageRatio;
    final statusColor = BudgetProgressBar.colorForRatio(ratio, context);

    return InkWell(
      onTap: onTap,
      borderRadius: isParent && !hasChildren
          ? BorderRadius.circular(16.r)
          : isParent
          ? BorderRadius.vertical(top: Radius.circular(16.r))
          : BorderRadius.zero,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Category icon
                SakuCategoryIcon(
                  iconName: budget.category?.icon ?? 'circleQuestion',
                  color: parseHexColor(budget.category?.color ?? '#6B7280'),
                  backgroundFill: parseHexColor(budget.category?.backgroundColor),
                  size: isParent ? 42 : 34,
                  iconSize: isParent ? 18 : 14,
                  circular: true,
                ),
                SizedBox(width: 12.w),

                // Name + wallet
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.category?.name ?? '-',
                        style:
                            (isParent
                                    ? TextStyleConstants.b1
                                    : TextStyleConstants.b2)
                                .copyWith(
                                  fontWeight: isParent
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: colors.textPrimary,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isParent && budget.wallet != null)
                        Text(
                          budget.wallet!.name,
                          style: TextStyleConstants.label2.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),

                // Amount + remaining/over
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      budget.amount.toCurrency(),
                      style:
                          (isParent
                                  ? TextStyleConstants.b1
                                  : TextStyleConstants.b2)
                              .copyWith(
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
            SizedBox(height: 8.h),

            // Progress bar
            BudgetProgressBar(
              ratio: ratio,
              expectedRatio: budget.expectedRatio,
              height: isParent ? null : 4.h,
            ),
          ],
        ),
      ),
    );
  }
}

/// Section children dengan garis vertikal penghubung.
class _ChildrenSection extends StatelessWidget {
  const _ChildrenSection({required this.children, this.onTap});

  final List<BudgetModel> children;
  final void Function(BudgetModel)? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.only(left: 36.w),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vertical connector line
            Container(
              width: 2.w,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(1.r),
              ),
            ),
            SizedBox(width: 8.w),

            // Children list
            Expanded(
              child: Column(
                children: [
                  for (int i = 0; i < children.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: colors.border),
                    _BudgetRow(
                      budget: children[i],
                      onTap: () => onTap?.call(children[i]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
