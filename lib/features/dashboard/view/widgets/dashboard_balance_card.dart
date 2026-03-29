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

/// Card total saldo dashboard dengan gradient emerald.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF065F46), const Color(0xFF047857)]
              : [colors.primaryDark, colors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF065F46).withValues(alpha: 0.4)
                : colors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                    color: colors.onPrimary.withValues(alpha: 0.85),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    l10n.dashboardTotalBalance,
                    style: TextStyleConstants.label1.copyWith(
                      color: colors.onPrimary.withValues(alpha: 0.85),
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
                  color: colors.onPrimary.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // ─── Balance Amount ───
          Text(
            isHidden ? '••••••••' : totalBalance.toCurrency(),
            style: TextStyleConstants.h4.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.bold,
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
                  iconColor: Color.fromARGB(255, 88, 255, 188), // Emerald 300
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
                  iconColor: const Color(0xFFFCA5A5), // Red 300
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
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: colors.onPrimary.withValues(alpha: 0.15),
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
                    color: colors.onPrimary.withValues(alpha: 0.85),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyleConstants.label2.copyWith(
                    color: colors.onPrimary,
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
