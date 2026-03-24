import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Card total saldo dengan gradient background futuristik.
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
              ? [
                  const Color(0xFF065F46), // Emerald 800
                  const Color(0xFF047857), // Emerald 700
                  const Color(0xFF059669), // Emerald 600
                ]
              : [
                  colors.primary,
                  colors.primaryDark,
                  colors.primary.withValues(alpha: 0.85),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF065F46).withValues(alpha: 0.5)
                : colors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Title + Visibility Toggle ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.dashboardTotalBalance,
                style: TextStyleConstants.label1.copyWith(
                  color: colors.onPrimary.withValues(alpha: 0.8),
                ),
              ),
              GestureDetector(
                onTap: () {
                  ref
                      .read(dashboardControllerProvider.notifier)
                      .toggleBalanceVisibility();
                },
                child: FaIcon(
                  isHidden ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                  size: 16.w,
                  color: colors.onPrimary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // ─── Balance Amount ───
          Text(
            isHidden ? '••••••••' : totalBalance.toCurrency(),
            style: TextStyleConstants.h4.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),

          // ─── Income/Expense Row ───
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: FontAwesomeIcons.arrowTrendUp,
                  label: l10n.dashboardIncomeLabel,
                  value: isHidden
                      ? '••••'
                      : dashState.currentPeriodIncome.toCurrency(
                          withPrefix: false,
                        ),
                  iconColor: const Color(0xFF6EE7B7), // Emerald 300
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _MiniStat(
                  icon: FontAwesomeIcons.arrowTrendDown,
                  label: l10n.dashboardExpenseLabel,
                  value: isHidden
                      ? '••••'
                      : dashState.currentPeriodExpense.toCurrency(
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
        color: colors.onPrimary.withValues(alpha: 0.12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.2),
            ),
            child: FaIcon(icon, size: 12.w, color: iconColor),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyleConstants.label3.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.7),
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
