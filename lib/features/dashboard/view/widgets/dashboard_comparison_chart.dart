import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:app_saku_rapi/global/widgets/saku_card.dart';
import 'package:app_saku_rapi/utils/packages/graphify/view/graphify_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Chart perbandingan Bar: bulan ini vs bulan lalu (atau minggu).
///
/// Menggunakan Apache ECharts via [GraphifyView].
/// User bisa switch mode bulanan/mingguan.
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

    // Build chart options
    final chartOptions = _buildChartOptions(
      currentDaily: dashState.currentPeriodDaily,
      previousDaily: dashState.previousPeriodDaily,
      currentLabel: currentLabel,
      previousLabel: previousLabel,
      incomeColor:
          '#${colors.income.toARGB32().toRadixString(16).substring(2)}',
      expenseColor:
          '#${colors.expense.toARGB32().toRadixString(16).substring(2)}',
      textColor: isDark ? '#9CA3AF' : '#6B7280',
      borderColor: isDark ? '#374151' : '#E5E7EB',
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SakuCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header + Mode Toggle ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.dashboardChartTitle,
                  style: TextStyleConstants.b2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                _ModeToggle(
                  isMonthly: isMonthly,
                  monthlyLabel: l10n.dashboardMonthlyMode,
                  weeklyLabel: l10n.dashboardWeeklyMode,
                  onToggle: () {
                    ref
                        .read(dashboardControllerProvider.notifier)
                        .toggleChartMode();
                  },
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // ─── Legend ───
            Row(
              children: [
                _LegendItem(
                  color: colors.income,
                  label: '${l10n.dashboardIncomeLabel} ($currentLabel)',
                ),
                SizedBox(width: 16.w),
                _LegendItem(
                  color: colors.expense,
                  label: '${l10n.dashboardExpenseLabel} ($currentLabel)',
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                _LegendItem(
                  color: colors.income.withValues(alpha: 0.4),
                  label: '${l10n.dashboardIncomeLabel} ($previousLabel)',
                ),
                SizedBox(width: 16.w),
                _LegendItem(
                  color: colors.expense.withValues(alpha: 0.4),
                  label: '${l10n.dashboardExpenseLabel} ($previousLabel)',
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // ─── ECharts ───
            SizedBox(
              height: 220.h,
              child: GraphifyView(
                initialOptions: chartOptions,
                isDarkMode: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds ECharts option map for grouped bar chart.
  Map<String, dynamic> _buildChartOptions({
    required List<Map<String, dynamic>> currentDaily,
    required List<Map<String, dynamic>> previousDaily,
    required String currentLabel,
    required String previousLabel,
    required String incomeColor,
    required String expenseColor,
    required String textColor,
    required String borderColor,
  }) {
    // Extract categories (day labels)
    // Use max length between the two periods
    final maxLen = currentDaily.length > previousDaily.length
        ? currentDaily.length
        : previousDaily.length;

    final categories = <String>[];
    final curIncome = <double>[];
    final curExpense = <double>[];
    final prevIncome = <double>[];
    final prevExpense = <double>[];

    for (int i = 0; i < maxLen; i++) {
      final dayNum = i + 1;
      categories.add('$dayNum');

      if (i < currentDaily.length) {
        curIncome.add((currentDaily[i]['income'] as num).toDouble());
        curExpense.add((currentDaily[i]['expense'] as num).toDouble());
      } else {
        curIncome.add(0);
        curExpense.add(0);
      }

      if (i < previousDaily.length) {
        prevIncome.add((previousDaily[i]['income'] as num).toDouble());
        prevExpense.add((previousDaily[i]['expense'] as num).toDouble());
      } else {
        prevIncome.add(0);
        prevExpense.add(0);
      }
    }

    return {
      'grid': {
        'left': '3%',
        'right': '3%',
        'bottom': '3%',
        'top': '8%',
        'containLabel': true,
      },
      'xAxis': {
        'type': 'category',
        'data': categories,
        'axisLabel': {'color': textColor, 'fontSize': 10},
        'axisLine': {
          'lineStyle': {'color': borderColor},
        },
      },
      'yAxis': {
        'type': 'value',
        'axisLabel': {
          'color': textColor,
          'fontSize': 10,
          'formatter': '{value}',
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
          'name': '$currentLabel Income',
          'type': 'bar',
          'data': curIncome,
          'itemStyle': {
            'color': incomeColor,
            'borderRadius': [4, 4, 0, 0],
          },
          'barGap': '10%',
          'barCategoryGap': '30%',
        },
        {
          'name': '$currentLabel Expense',
          'type': 'bar',
          'data': curExpense,
          'itemStyle': {
            'color': expenseColor,
            'borderRadius': [4, 4, 0, 0],
          },
        },
        {
          'name': '$previousLabel Income',
          'type': 'bar',
          'data': prevIncome,
          'itemStyle': {
            'color': incomeColor,
            'opacity': 0.35,
            'borderRadius': [4, 4, 0, 0],
          },
        },
        {
          'name': '$previousLabel Expense',
          'type': 'bar',
          'data': prevExpense,
          'itemStyle': {
            'color': expenseColor,
            'opacity': 0.35,
            'borderRadius': [4, 4, 0, 0],
          },
        },
      ],
    };
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.isMonthly,
    required this.monthlyLabel,
    required this.weeklyLabel,
    required this.onToggle,
  });

  final bool isMonthly;
  final String monthlyLabel;
  final String weeklyLabel;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: colors.primaryLight,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isMonthly ? monthlyLabel : weeklyLabel,
              style: TextStyleConstants.label2.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.swap_horiz_rounded, size: 14.w, color: colors.primary),
          ],
        ),
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
