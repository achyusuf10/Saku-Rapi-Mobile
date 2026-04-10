import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_chart_controller.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Card total saldo dashboard dengan gaya minimal dan kontras tinggi.
///
/// Menampilkan total balance (hanya wallet non-excluded),
/// income/expense bulan ini, dan toggle visibility.
class DashboardBalanceCard extends ConsumerWidget {
  const DashboardBalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final dashState = ref.watch(dashboardControllerProvider);
    final chartState = ref.watch(dashboardChartControllerProvider);
    final totalBalance = ref.watch(dashboardTotalBalanceProvider);
    final isHidden = dashState.isBalanceHidden;
    final isDark = context.isDarkMode;
    final cardBackground = isDark ? colors.surface : colors.primary;
    final cardBorder = isDark
        ? colors.border
        : colors.primaryDark.withValues(alpha: 0.25);
    final primaryTextColor = isDark ? colors.textPrimary : colors.onPrimary;
    final secondaryTextColor = isDark
        ? colors.textSecondary
        : colors.onPrimary.withValues(alpha: 0.82);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: cardBorder),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header + Visibility Toggle ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.shieldHalved,
                    size: 14.w,
                    color: secondaryTextColor,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    l10n.dashboardTotalBalance,
                    style: TextStyleConstants.label1.copyWith(
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => ref
                    .read(dashboardControllerProvider.notifier)
                    .toggleBalanceVisibility(),
                child: FaIcon(
                  isHidden ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                  size: 16.w,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // ─── Balance Amount ───
          Text(
            isHidden ? '••••••••' : totalBalance.toCurrency(),
            style: TextStyleConstants.h4.copyWith(
              color: primaryTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16.h),

          // ─── Income / Expense Row ───
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: FontAwesomeIcons.arrowTrendUp,
                  label: l10n.dashboardIncomeLabel,
                  value: isHidden
                      ? '••••'
                      : chartState.currentPeriodIncome.toCurrency(
                          withPrefix: false,
                        ),
                  iconColor: colors.income,
                  isDark: isDark,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _MiniStat(
                  icon: FontAwesomeIcons.arrowTrendDown,
                  label: l10n.dashboardExpenseLabel,
                  value: isHidden
                      ? '••••'
                      : chartState.currentPeriodExpense.toCurrency(
                          withPrefix: false,
                        ),
                  iconColor: colors.expense,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sub-section chip untuk income/expense.
class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: isDark
            ? colors.surfaceVariant.withValues(alpha: 0.7)
            : colors.onPrimary.withValues(alpha: 0.14),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.25),
            ),
            child: FaIcon(icon, size: 11.w, color: iconColor),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyleConstants.label3.copyWith(
                    color: isDark
                        ? colors.textSecondary
                        : colors.onPrimary.withValues(alpha: 0.82),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyleConstants.label2.copyWith(
                    color: isDark ? colors.textPrimary : colors.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
