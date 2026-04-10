import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_chart_controller.dart';
import 'package:app_saku_rapi/global/widgets/saku_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Ringkasan periode (bulan/minggu ini) vs periode lalu.
///
/// Menampilkan: income, expense, net flow, dan persentase perubahan.
class DashboardPeriodSummary extends ConsumerWidget {
  const DashboardPeriodSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final chartState = ref.watch(dashboardChartControllerProvider);
    final isMonthly = chartState.chartMode == DashboardChartMode.monthly;
    final isDaily = chartState.chartMode == DashboardChartMode.daily;

    final currentIncome = chartState.currentPeriodIncome;
    final currentExpense = chartState.currentPeriodExpense;
    final previousExpense = chartState.previousPeriodExpense;
    final net = currentIncome - currentExpense;

    // Expense change percentage
    final expenseChange = previousExpense > 0
        ? ((currentExpense - previousExpense) / previousExpense * 100)
        : 0.0;

    final String periodLabel;
    if (isMonthly) {
      periodLabel = l10n.dashboardLastMonth;
    } else if (isDaily) {
      periodLabel = l10n.dashboardYesterday;
    } else {
      periodLabel = l10n.dashboardLastWeek;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SakuCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dashboardSnapshotTitle(switch (chartState.chartMode) {
                DashboardChartMode.monthly => l10n.dashboardMonthlyMode,
                DashboardChartMode.weekly => l10n.dashboardWeeklyMode,
                DashboardChartMode.daily => l10n.dashboardDailyMode,
              }),
              style: TextStyleConstants.b2.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: 14.h),

            // ─── Income / Expense / Net Row ───
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: l10n.dashboardIncomeLabel,
                    value: currentIncome.toCurrency(withPrefix: false),
                    color: colors.income,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: l10n.dashboardExpenseLabel,
                    value: currentExpense.toCurrency(withPrefix: false),
                    color: colors.expense,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: l10n.dashboardNetFlow,
                    value: net.toCurrency(withPrefix: false),
                    color: net >= 0 ? colors.income : colors.expense,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // ─── vs Previous Period ───
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: colors.surfaceVariant,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    expenseChange > 0
                        ? FontAwesomeIcons.arrowUp
                        : expenseChange < 0
                        ? FontAwesomeIcons.arrowDown
                        : FontAwesomeIcons.minus,
                    size: 10.w,
                    color: expenseChange > 0
                        ? colors.expense
                        : expenseChange < 0
                        ? colors.income
                        : colors.textSecondary,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    expenseChange == 0
                        ? l10n.dashboardNoChange
                        : '${expenseChange.abs().toPercentage(decimalDigits: 1)} ${l10n.dashboardVsPrevious(periodLabel)}',
                    style: TextStyleConstants.label2.copyWith(
                      color: expenseChange > 0
                          ? colors.expense
                          : expenseChange < 0
                          ? colors.income
                          : colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // ─── See Full Report ───
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => context.push(AppRouter.reports),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.reportSeeFullReport,
                      style: TextStyleConstants.label2.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    FaIcon(
                      FontAwesomeIcons.arrowRight,
                      size: 11.w,
                      color: colors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6.w,
              height: 6.w,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyleConstants.label2.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Padding(
          padding: EdgeInsets.only(left: 12.w),
          child: Text(
            value,
            style: TextStyleConstants.b2.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
