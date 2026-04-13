import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_chart_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Chart perbandingan Bar: total periode ini vs periode sebelumnya.
///
/// Menampilkan 2 grup bar (Current & Previous) dengan series Income & Expense.
/// Dimaksudkan untuk digunakan di dalam [DashboardChartCarousel].
class DashboardComparisonChart extends ConsumerWidget {
  const DashboardComparisonChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final chartState = ref.watch(dashboardChartControllerProvider);
    final isMonthly = chartState.chartMode == DashboardChartMode.monthly;
    final isDaily = chartState.chartMode == DashboardChartMode.daily;

    final String currentLabel;
    final String previousLabel;
    if (isMonthly) {
      currentLabel = l10n.dashboardThisMonth;
      previousLabel = l10n.dashboardLastMonth;
    } else if (isDaily) {
      currentLabel = l10n.dashboardLast7Days;
      previousLabel = l10n.dashboardPrev7Days;
    } else {
      currentLabel = l10n.dashboardThisWeek;
      previousLabel = l10n.dashboardLastWeek;
    }

    // Sum totals per period
    final curIncome = chartState.currentPeriodIncome;
    final curExpense = chartState.currentPeriodExpense;
    final prevIncome = chartState.previousPeriodIncome;
    final prevExpense = chartState.previousPeriodExpense;

    final textColor = colors.textSecondary;
    final gridColor = colors.border.withValues(alpha: 0.75);

    final chartData = <_ComparisonData>[
      _ComparisonData(
        label: currentLabel,
        income: curIncome,
        expense: curExpense,
      ),
      _ComparisonData(
        label: previousLabel,
        income: prevIncome,
        expense: prevExpense,
      ),
    ];

    // Percentage change for insight
    final expenseChange = prevExpense > 0
        ? ((curExpense - prevExpense) / prevExpense * 100)
        : 0.0;

    final String periodLabel;
    final String prevPeriodLabel;
    if (isMonthly) {
      periodLabel = l10n.dashboardThisMonth.toLowerCase();
      prevPeriodLabel = l10n.dashboardLastMonth.toLowerCase();
    } else if (isDaily) {
      periodLabel = l10n.dashboardLast7Days.toLowerCase();
      prevPeriodLabel = l10n.dashboardPrev7Days.toLowerCase();
    } else {
      periodLabel = l10n.dashboardThisWeek.toLowerCase();
      prevPeriodLabel = l10n.dashboardLastWeek.toLowerCase();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Summary Row ---
        Row(
          children: [
            Expanded(
              child: _SummaryItem(
                label: l10n.dashboardTotalExpenseLabel,
                value: curExpense.toCompactCurrency(),
                valueColor: colors.expense,
                badge: _buildChangeBadge(expenseChange, colors),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _SummaryItem(
                label: l10n.dashboardTotalIncomeLabel,
                value: curIncome.toCompactCurrency(),
                valueColor: colors.income,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // --- Legend ---
        Row(
          children: [
            _LegendItem(color: colors.income, label: l10n.dashboardIncomeLabel),
            SizedBox(width: 16.w),
            _LegendItem(
              color: colors.expense,
              label: l10n.dashboardExpenseLabel,
            ),
          ],
        ),
        SizedBox(height: 8.h),

        // --- Syncfusion Grouped Bar Chart ---
        SizedBox(
          height: 200.h,
          child: SfCartesianChart(
            key: ValueKey(
              '${chartState.chartMode}_${curIncome}_${curExpense}_${prevIncome}_$prevExpense',
            ),
            margin: EdgeInsets.zero,
            plotAreaBorderWidth: 0,
            primaryXAxis: CategoryAxis(
              labelStyle: TextStyle(color: textColor, fontSize: 11.sp),
              majorGridLines: const MajorGridLines(width: 0),
              axisLine: AxisLine(color: gridColor),
              majorTickLines: const MajorTickLines(size: 0),
            ),
            primaryYAxis: NumericAxis(
              labelStyle: TextStyle(color: textColor, fontSize: 10.sp),
              majorGridLines: MajorGridLines(
                color: gridColor,
                dashArray: const <double>[4, 3],
              ),
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              axisLabelFormatter: (details) => ChartAxisLabel(
                _compactLabel(details.value),
                TextStyle(color: textColor, fontSize: 10.sp),
              ),
            ),
            tooltipBehavior: TooltipBehavior(
              color: colors.surface,
              enable: true,
              header: '',
              builder: (data, point, series, pointIdx, seriesIdx) {
                final d = data as _ComparisonData;
                final isIncome = seriesIdx == 0;
                final value = isIncome ? d.income : d.expense;
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: colors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.label,
                        style: TextStyle(color: textColor, fontSize: 10.sp),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${isIncome ? l10n.dashboardIncomeLabel : l10n.dashboardExpenseLabel}: ${value.toCompactCurrency()}',
                        style: TextStyle(
                          color: isIncome ? colors.income : colors.expense,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            series: <CartesianSeries<_ComparisonData, String>>[
              ColumnSeries<_ComparisonData, String>(
                name: l10n.dashboardIncomeLabel,
                dataSource: chartData,
                xValueMapper: (d, _) => d.label,
                yValueMapper: (d, _) => d.income,
                color: colors.income,
                borderRadius: BorderRadius.vertical(top: Radius.circular(5.r)),
                spacing: 0.25,
                width: 0.35,
              ),
              ColumnSeries<_ComparisonData, String>(
                name: l10n.dashboardExpenseLabel,
                dataSource: chartData,
                xValueMapper: (d, _) => d.label,
                yValueMapper: (d, _) => d.expense,
                color: colors.expense,
                borderRadius: BorderRadius.vertical(top: Radius.circular(5.r)),
                spacing: 0.25,
                width: 0.35,
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // --- Smart Insight ---
        _buildInsight(
          context,
          expenseChange: expenseChange,
          periodLabel: periodLabel,
          previousLabel: prevPeriodLabel,
          hasData: curExpense > 0 || prevExpense > 0,
        ),
      ],
    );
  }

  static Widget? _buildChangeBadge(double change, dynamic colors) {
    if (change == 0) return null;

    final isDown = change < 0;
    // For expense: down is good (green), up is bad (red)
    final Color badgeColor = isDown ? colors.income : colors.expense;
    final arrow = isDown ? '\u2193' : '\u2191';
    final text = '${change.abs().toStringAsFixed(0)}%';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        '$arrow $text',
        style: TextStyleConstants.label3.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static Widget _buildInsight(
    BuildContext context, {
    required double expenseChange,
    required String periodLabel,
    required String previousLabel,
    required bool hasData,
  }) {
    final l10n = context.l10n;
    final colors = context.colors;

    final String text;
    if (!hasData) {
      text = l10n.dashboardInsightNoData;
    } else if (expenseChange < -2) {
      text = l10n.dashboardInsightExpenseDown(
        periodLabel,
        expenseChange.abs().toStringAsFixed(0),
        previousLabel,
      );
    } else if (expenseChange > 2) {
      text = l10n.dashboardInsightExpenseUp(
        periodLabel,
        expenseChange.abs().toStringAsFixed(0),
        previousLabel,
      );
    } else {
      text = l10n.dashboardInsightExpenseSame(previousLabel);
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 16.w,
            color: colors.warning,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyleConstants.label2.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Label compact untuk axis Y (contoh: 1.5jt, 75rb).
  static String _compactLabel(num value) {
    final v = value.toDouble();
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)} jt';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(0)} rb';
    return v.toStringAsFixed(0);
  }
}

/// Data model untuk chart perbandingan.
class _ComparisonData {
  const _ComparisonData({
    required this.label,
    required this.income,
    required this.expense,
  });

  final String label;
  final double income;
  final double expense;
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.valueColor,
    this.badge,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyleConstants.label2.copyWith(
            color: colors.textSecondary,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Flexible(
              child: Text(
                value,
                style: TextStyleConstants.b2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badge != null) ...[SizedBox(width: 6.w), badge!],
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2.r),
            color: color,
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyleConstants.label3.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
