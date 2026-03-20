import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/budgeting/models/budget_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Parsing hex color string ke [Color], fallback ke abu-abu.
Color _hexColor(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF6B7280);
  final cleaned = hex.replaceAll('#', '');
  if (cleaned.length == 6) {
    return Color(int.parse('FF$cleaned', radix: 16));
  }
  return const Color(0xFF6B7280);
}

/// Memetakan nama ikon string kategori ke [IconData] FontAwesome.
IconData _categoryIcon(String? icon) {
  return switch (icon) {
    'tag' => FontAwesomeIcons.tag,
    'utensils' || 'food' => FontAwesomeIcons.utensils,
    'car' => FontAwesomeIcons.car,
    'house' || 'home' => FontAwesomeIcons.house,
    'shirt' || 'tshirt' => FontAwesomeIcons.shirt,
    'heart-pulse' || 'health' => FontAwesomeIcons.heartPulse,
    'graduation-cap' => FontAwesomeIcons.graduationCap,
    'gamepad' || 'entertainment' => FontAwesomeIcons.gamepad,
    'briefcase' || 'work' => FontAwesomeIcons.briefcase,
    'gift' => FontAwesomeIcons.gift,
    'plane' || 'travel' => FontAwesomeIcons.plane,
    'bolt' || 'electric' => FontAwesomeIcons.bolt,
    'phone' => FontAwesomeIcons.phone,
    'sack-dollar' || 'salary' => FontAwesomeIcons.sackDollar,
    'money-bill' => FontAwesomeIcons.moneyBill,
    'coins' => FontAwesomeIcons.coins,
    'chart-line' => FontAwesomeIcons.chartLine,
    'building-columns' || 'bank' => FontAwesomeIcons.buildingColumns,
    'cart-shopping' || 'shopping' => FontAwesomeIcons.cartShopping,
    'baby' => FontAwesomeIcons.baby,
    'paw' || 'pet' => FontAwesomeIcons.paw,
    'dumbbell' || 'sport' => FontAwesomeIcons.dumbbell,
    'book' => FontAwesomeIcons.book,
    'wifi' => FontAwesomeIcons.wifi,
    'droplet' || 'water' => FontAwesomeIcons.droplet,
    _ => FontAwesomeIcons.tag,
  };
}

/// Item widget untuk satu budget dalam `BudgetListScreen`.
///
/// Struktur:
/// - CircleAvatar (icon + warna kategori)
/// - Kolom: nama + amount | progress bar | sisa + chip "Hari ini"
/// - Tap → navigasi detail/edit
/// - Long press → konfirmasi hapus
class BudgetItemWidget extends StatelessWidget {
  const BudgetItemWidget({
    super.key,
    required this.budget,
    required this.onTap,
    required this.onLongPress,
  });

  final BudgetModel budget;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final catColor = _hexColor(budget.categoryColor);
    final progress = budget.usagePercentage.clamp(0.0, 1.0);

    final progressColor = switch (budget.status) {
      BudgetStatus.safe => colors.primary,
      BudgetStatus.warning => colors.warning,
      BudgetStatus.overBudget => colors.expense,
    };

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Row(
          children: [
            // ── Icon Kategori ──
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: FaIcon(
                  _categoryIcon(budget.categoryIcon),
                  size: 18.r,
                  color: catColor,
                ),
              ),
            ),

            SizedBox(width: 12.w),

            // ── Info Kolom ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris 1: Nama kategori + jumlah
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          budget.categoryName ?? '-',
                          style: TextStyleConstants.b2.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '${budget.usedAmount.toCurrency()} / ${budget.amount.toCurrency()}',
                        style: TextStyleConstants.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 6.h),

                  // Baris 2: Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6.h,
                      backgroundColor: colors.surface,
                      valueColor: AlwaysStoppedAnimation(progressColor),
                    ),
                  ),

                  SizedBox(height: 6.h),

                  // Baris 3: Sisa anggaran + chip "Hari ini"
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          budget.isOverBudget
                              ? l10n.budgetOver(
                                  budget.remainingAmount.abs().toCurrency(),
                                )
                              : l10n.budgetRemaining(
                                  budget.remainingAmount.toCurrency(),
                                ),
                          style: TextStyleConstants.caption.copyWith(
                            color: budget.isOverBudget
                                ? colors.expense
                                : colors.textSecondary,
                          ),
                        ),
                      ),
                      if (budget.isActiveToday)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            l10n.budgetToday,
                            style: TextStyleConstants.label3.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
