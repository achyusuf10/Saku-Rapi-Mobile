import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:app_saku_rapi/global/widgets/saku_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Top 3-5 kategori pengeluaran terbesar bulan ini.
///
/// Per item: icon + nama kategori + nominal + horizontal progress bar.
/// Progress bar dari `context.colors.expense` → fade ke `primaryLight`.
class DashboardTopExpensesWidget extends ConsumerWidget {
  const DashboardTopExpensesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.colors;
    final l10n = context.l10n;
    final dashState = ref.watch(dashboardControllerProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SakuCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dashboardTopExpenses,
              style: TextStyleConstants.h7.copyWith(
                fontWeight: FontWeight.w700,
                color: appColors.textPrimary,
              ),
            ),

            SizedBox(height: 12.h),

            dashState.when(
              loading: () => _buildSkeleton(appColors),
              error: (_, __) => const SizedBox.shrink(),
              data: (data) {
                if (data.topExpenseCategories.isEmpty) {
                  return _buildEmptyState(context);
                }
                return Column(
                  children: data.topExpenseCategories.map((cat) {
                    return _ExpenseCategoryRow(category: cat);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Center(
        child: Text(
          l10n.dashboardEmptyTransactions,
          style: TextStyleConstants.caption.copyWith(
            color: appColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(appColors) {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Container(
            height: 42.h,
            decoration: BoxDecoration(
              color: appColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
      ),
    );
  }
}

/// Satu baris kategori expense dengan progress bar.
class _ExpenseCategoryRow extends StatelessWidget {
  const _ExpenseCategoryRow({required this.category});

  final TopExpenseCategory category;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        children: [
          Row(
            children: [
              // ── Icon ──
              Container(
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(
                  color: _hexColor(
                    category.categoryColor,
                  ).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: FaIcon(
                    _categoryIcon(category.categoryIcon),
                    color: _hexColor(category.categoryColor),
                    size: 14.r,
                  ),
                ),
              ),

              SizedBox(width: 10.w),

              // ── Nama + persentase ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.categoryName,
                      style: TextStyleConstants.b2.copyWith(
                        fontWeight: FontWeight.w600,
                        color: appColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      category.percentage.toPercentage(),
                      style: TextStyleConstants.label3.copyWith(
                        color: appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Nominal ──
              Text(
                category.amount.toCurrency(),
                style: TextStyleConstants.b2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: appColors.expense,
                ),
              ),
            ],
          ),

          SizedBox(height: 6.h),

          // ── Progress bar ──
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: category.percentage.clamp(0.0, 1.0),
              minHeight: 5.h,
              backgroundColor: appColors.border.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                Color.lerp(appColors.expense, appColors.primaryLight, 0.35) ??
                    appColors.expense,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _hexColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('FF');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  IconData _categoryIcon(String iconName) {
    return switch (iconName) {
      'utensils' => FontAwesomeIcons.utensils,
      'cart-shopping' => FontAwesomeIcons.cartShopping,
      'bus' || 'car' => FontAwesomeIcons.bus,
      'house' => FontAwesomeIcons.house,
      'bolt' => FontAwesomeIcons.bolt,
      'gamepad' => FontAwesomeIcons.gamepad,
      'heart-pulse' => FontAwesomeIcons.heartPulse,
      'graduation-cap' => FontAwesomeIcons.graduationCap,
      'shirt' => FontAwesomeIcons.shirt,
      'gift' => FontAwesomeIcons.gift,
      'plane' => FontAwesomeIcons.plane,
      'phone' => FontAwesomeIcons.phone,
      'money-bill-wave' => FontAwesomeIcons.moneyBillWave,
      'building-columns' => FontAwesomeIcons.buildingColumns,
      'briefcase' => FontAwesomeIcons.briefcase,
      'mug-hot' => FontAwesomeIcons.mugHot,
      'gas-pump' => FontAwesomeIcons.gasPump,
      'wifi' => FontAwesomeIcons.wifi,
      'baby' => FontAwesomeIcons.baby,
      'paw' => FontAwesomeIcons.paw,
      'dumbbell' => FontAwesomeIcons.dumbbell,
      _ => FontAwesomeIcons.tag,
    };
  }
}
