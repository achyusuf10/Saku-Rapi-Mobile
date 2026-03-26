import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/budget/models/budget_model.dart';
import 'package:app_saku_rapi/features/budget/view/widgets/budget_progress_bar.dart';
import 'package:app_saku_rapi/features/category/utils/category_icon_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
        border: Border.all(color: colors.border.withValues(alpha: 0.4)),
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
    final catColor = _parseColor(budget.category?.color);
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
                Container(
                  width: isParent ? 42.w : 34.w,
                  height: isParent ? 42.w : 34.w,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(isParent ? 12.r : 10.r),
                  ),
                  child: Center(
                    child: FaIcon(
                      CategoryIconMapper.getIcon(
                        budget.category?.icon ?? 'circle-question',
                      ),
                      size: isParent ? 18.w : 14.w,
                      color: catColor,
                    ),
                  ),
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
                                fontWeight: FontWeight.bold,
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

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF6B7280);
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    return const Color(0xFF6B7280);
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
                color: colors.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(1.r),
              ),
            ),
            SizedBox(width: 8.w),

            // Children list
            Expanded(
              child: Column(
                children: [
                  for (int i = 0; i < children.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        color: colors.border.withValues(alpha: 0.2),
                      ),
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
