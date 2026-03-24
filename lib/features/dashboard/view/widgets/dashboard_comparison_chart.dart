import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:app_saku_rapi/features/dashboard/view/widgets/chart_fullscreen_dialog.dart';
import 'package:app_saku_rapi/utils/packages/graphify/controller/graphify_controller.dart';
import 'package:app_saku_rapi/utils/packages/graphify/view/graphify_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    final dashState = ref.watch(dashboardControllerProvider);
    final isMonthly = dashState.chartMode == DashboardChartMode.monthly;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentLabel = isMonthly
        ? l10n.dashboardThisMonth
        : l10n.dashboardThisWeek;
    final previousLabel = isMonthly
        ? l10n.dashboardLastMonth
        : l10n.dashboardLastWeek;

    // Sum totals per period
    final curIncome = dashState.currentPeriodIncome;
    final curExpense = dashState.currentPeriodExpense;
    final prevIncome = dashState.previousPeriodIncome;
    final prevExpense = dashState.previousPeriodExpense;

    final incomeHex =
        '#${colors.income.toARGB32().toRadixString(16).substring(2)}';
    final expenseHex =
        '#${colors.expense.toARGB32().toRadixString(16).substring(2)}';
    final textColor = isDark ? '#9CA3AF' : '#6B7280';
    final borderColor = isDark ? '#2D3F38' : '#E5E7EB';

    final chartOptions = _buildChartOptions(
      currentLabel: currentLabel,
      previousLabel: previousLabel,
      curIncome: curIncome,
      curExpense: curExpense,
      prevIncome: prevIncome,
      prevExpense: prevExpense,
      incomeColor: incomeHex,
      expenseColor: expenseHex,
      textColor: textColor,
      borderColor: borderColor,
    );

    // Percentage change for insight
    final expenseChange = prevExpense > 0
        ? ((curExpense - prevExpense) / prevExpense * 100)
        : 0.0;

    final periodLabel =
        (isMonthly ? l10n.dashboardThisMonth : l10n.dashboardThisWeek)
            .toLowerCase();
    final prevPeriodLabel =
        (isMonthly ? l10n.dashboardLastMonth : l10n.dashboardLastWeek)
            .toLowerCase();

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

        // --- Legend + Fullscreen ---
        Row(
          children: [
            _LegendItem(color: colors.income, label: l10n.dashboardIncomeLabel),
            SizedBox(width: 16.w),
            _LegendItem(
              color: colors.expense,
              label: l10n.dashboardExpenseLabel,
            ),
            const Spacer(),
            _FullscreenButton(
              onPressed: () => ChartFullscreenDialog.show(
                context,
                title: l10n.dashboardChartTitle,
                chartOptions: chartOptions,
                isDark: isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),

        // --- ECharts ---
        SizedBox(
          height: 200.h,
          child: GraphifyView(
            key: ValueKey(dashState.chartMode),
            initialOptions: chartOptions,
            isDarkMode: isDark,
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

  /// Builds ECharts option for 2-group bar chart (Current vs Previous).
  static Map<String, dynamic> _buildChartOptions({
    required String currentLabel,
    required String previousLabel,
    required double curIncome,
    required double curExpense,
    required double prevIncome,
    required double prevExpense,
    required String incomeColor,
    required String expenseColor,
    required String textColor,
    required String borderColor,
  }) {
    return {
      'backgroundColor': 'transparent',
      'grid': {
        'left': '3%',
        'right': '3%',
        'bottom': '3%',
        'top': '8%',
        'containLabel': true,
      },
      'xAxis': {
        'type': 'category',
        'data': [currentLabel, previousLabel],
        'axisLabel': {'color': textColor, 'fontSize': 11},
        'axisLine': {
          'lineStyle': {'color': borderColor},
        },
      },
      'yAxis': {
        'type': 'value',
        'axisLabel': {
          'color': textColor,
          'fontSize': 10,
          'formatter': JsFunctionModel(
            'function(value) {'
            '  if (value >= 1000000) return (value/1000000).toFixed(1) + " jt";'
            '  if (value >= 1000) return (value/1000).toFixed(0) + " rb";'
            '  return value;'
            '}',
          ),
        },
        'splitLine': {
          'lineStyle': {'color': borderColor, 'type': 'dashed'},
        },
      },
      'tooltip': {
        'trigger': 'axis',
        'axisPointer': {'type': 'shadow'},
      },
      'series': [
        {
          'name': 'Income',
          'type': 'bar',
          'data': [curIncome, prevIncome],
          'itemStyle': {
            'color': incomeColor,
            'borderRadius': [6, 6, 0, 0],
          },
          'barGap': '20%',
          'barCategoryGap': '40%',
        },
        {
          'name': 'Expense',
          'type': 'bar',
          'data': [curExpense, prevExpense],
          'itemStyle': {
            'color': expenseColor,
            'borderRadius': [6, 6, 0, 0],
          },
        },
      ],
    };
  }
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
                  fontWeight: FontWeight.bold,
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

class _FullscreenButton extends StatelessWidget {
  const _FullscreenButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 28.w,
      height: 28.w,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.fullscreen_rounded, size: 18.w),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: colors.surfaceVariant.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.r),
          ),
        ),
        color: colors.textPrimary,
      ),
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
