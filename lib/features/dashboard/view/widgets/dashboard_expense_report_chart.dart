import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_chart_controller.dart';
import 'package:app_saku_rapi/utils/packages/graphify/controller/graphify_controller.dart';
import 'package:app_saku_rapi/utils/packages/graphify/view/graphify_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

/// Chart bar perbandingan pengeluaran: periode ini vs sebelumnya.
///
/// Menampilkan:
/// - Total expense & income labels dengan badge persentase perubahan
/// - Bar chart (ECharts) dengan x-axis tanggal (dd/MM) dan gap-fill
/// - Zoom in/out buttons + pinch zoom via ECharts dataZoom
/// - Smart insight text di bawah chart
class DashboardExpenseReportChart extends ConsumerStatefulWidget {
  const DashboardExpenseReportChart({super.key});

  @override
  ConsumerState<DashboardExpenseReportChart> createState() =>
      _DashboardExpenseReportChartState();
}

class _DashboardExpenseReportChartState
    extends ConsumerState<DashboardExpenseReportChart> {
  double _zoomStart = 0;
  double _zoomEnd = 100;

  static const _zoomStep = 20.0;

  void _zoomIn() {
    setState(() {
      final mid = (_zoomStart + _zoomEnd) / 2;
      final halfRange = (_zoomEnd - _zoomStart) / 2;
      final newHalf = (halfRange - _zoomStep).clamp(5.0, 50.0);
      _zoomStart = (mid - newHalf).clamp(0.0, 100.0);
      _zoomEnd = (mid + newHalf).clamp(0.0, 100.0);
    });
  }

  void _zoomOut() {
    setState(() {
      final mid = (_zoomStart + _zoomEnd) / 2;
      final halfRange = (_zoomEnd - _zoomStart) / 2;
      final newHalf = (halfRange + _zoomStep).clamp(5.0, 50.0);
      _zoomStart = (mid - newHalf).clamp(0.0, 100.0);
      _zoomEnd = (mid + newHalf).clamp(0.0, 100.0);
    });
  }

  void _zoomReset() {
    setState(() {
      _zoomStart = 0;
      _zoomEnd = 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final colors = context.colors;
    final l10n = context.l10n;
    final chartState = ref.watch(dashboardChartControllerProvider);
    final isMonthly = chartState.chartMode == DashboardChartMode.monthly;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final now = DateTime.now();
    final (currentStart, currentEnd, prevStart, _) =
        DashboardChartController.periodRanges(now, chartState.chartMode);

    // Gap-fill daily data
    final currentFilled = _fillGaps(
      chartState.currentPeriodDaily,
      currentStart,
      currentEnd,
    );
    final previousFilled = _fillGaps(
      chartState.previousPeriodDaily,
      prevStart,
      // For previous period, use same length as current
      prevStart.add(currentEnd.difference(currentStart)),
    );

    // Build chart
    final chartOptions = _buildChartOptions(
      currentDaily: currentFilled,
      previousDaily: previousFilled,
      incomeColor:
          '#${colors.income.toARGB32().toRadixString(16).substring(2)}',
      expenseColor:
          '#${colors.expense.toARGB32().toRadixString(16).substring(2)}',
      textColor: isDark ? '#9CA3AF' : '#6B7280',
      borderColor: isDark ? '#374151' : '#E5E7EB',
      isDark: isDark,
    );

    // Calculate totals & percentage change
    final currentExpense = chartState.currentPeriodExpense;
    final previousExpense = chartState.previousPeriodExpense;
    final currentIncome = chartState.currentPeriodIncome;

    final expenseChange = previousExpense > 0
        ? ((currentExpense - previousExpense) / previousExpense * 100)
        : 0.0;

    final previousLabel = isMonthly
        ? l10n.dashboardLastMonth
        : l10n.dashboardLastWeek;
    final periodLabel = isMonthly
        ? l10n.dashboardThisMonth
        : l10n.dashboardThisWeek;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Summary Row ───
        Row(
          children: [
            Expanded(
              child: _SummaryItem(
                label: l10n.dashboardTotalExpenseLabel,
                value: currentExpense.toCompactCurrency(),
                valueColor: colors.expense,
                badge: _buildChangeBadge(
                  expenseChange,
                  colors,
                  // For expense: down is good (green), up is bad (red)
                  invertColors: true,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _SummaryItem(
                label: l10n.dashboardTotalIncomeLabel,
                value: currentIncome.toCompactCurrency(),
                valueColor: colors.income,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // ─── Legend ───
        Row(
          children: [
            _LegendItem(color: colors.expense, label: periodLabel),
            SizedBox(width: 16.w),
            _LegendItem(
              color: colors.expense.withValues(alpha: 0.35),
              label: previousLabel,
            ),
          ],
        ),
        SizedBox(height: 8.h),

        // ─── Zoom Controls ───
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _ZoomButton(
              icon: Icons.zoom_in_rounded,
              onPressed: _zoomEnd - _zoomStart > 10 ? _zoomIn : null,
            ),
            SizedBox(width: 4.w),
            _ZoomButton(
              icon: Icons.zoom_out_rounded,
              onPressed: _zoomEnd - _zoomStart < 100 ? _zoomOut : null,
            ),
            SizedBox(width: 4.w),
            _ZoomButton(
              icon: Icons.zoom_out_map_rounded,
              onPressed: _zoomStart != 0 || _zoomEnd != 100 ? _zoomReset : null,
            ),
          ],
        ),
        SizedBox(height: 4.h),

        // ─── ECharts Bar ───
        SizedBox(
          height: 200.h,
          child: GraphifyView(initialOptions: chartOptions, isDarkMode: isDark),
        ),
        SizedBox(height: 12.h),

        // ─── Smart Insight ───
        _buildInsight(
          context,
          expenseChange: expenseChange,
          periodLabel: periodLabel.toLowerCase(),
          previousLabel: previousLabel.toLowerCase(),
          hasData: currentExpense > 0 || previousExpense > 0,
        ),
      ],
    );
  }

  /// Fills gaps in daily data so every date in the range has an entry.
  List<Map<String, dynamic>> _fillGaps(
    List<Map<String, dynamic>> data,
    DateTime start,
    DateTime end,
  ) {
    // Build lookup by date string
    final lookup = <String, Map<String, dynamic>>{};
    for (final entry in data) {
      final dateStr = entry['date'] as String;
      lookup[dateStr] = entry;
    }

    final result = <Map<String, dynamic>>[];
    final dateFormat = DateFormat('yyyy-MM-dd');
    var current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(endDate)) {
      final key = dateFormat.format(current);
      result.add(lookup[key] ?? {'date': key, 'income': 0.0, 'expense': 0.0});
      current = current.add(const Duration(days: 1));
    }

    return result;
  }

  /// Builds ECharts bar chart options comparing current vs previous expenses.
  Map<String, dynamic> _buildChartOptions({
    required List<Map<String, dynamic>> currentDaily,
    required List<Map<String, dynamic>> previousDaily,
    required String incomeColor,
    required String expenseColor,
    required String textColor,
    required String borderColor,
    required bool isDark,
  }) {
    final categories = <String>[];
    final curExpense = <double>[];
    final prevExpense = <double>[];
    final dateFormat = DateFormat('dd/MM');

    final maxLen = currentDaily.length > previousDaily.length
        ? currentDaily.length
        : previousDaily.length;

    for (int i = 0; i < maxLen; i++) {
      // Use current period dates for x-axis labels
      if (i < currentDaily.length) {
        final dateStr = currentDaily[i]['date'] as String;
        final date = DateTime.tryParse(dateStr);
        categories.add(date != null ? dateFormat.format(date) : '${i + 1}');
        curExpense.add((currentDaily[i]['expense'] as num).toDouble());
      } else {
        categories.add('${i + 1}');
        curExpense.add(0);
      }

      if (i < previousDaily.length) {
        prevExpense.add((previousDaily[i]['expense'] as num).toDouble());
      } else {
        prevExpense.add(0);
      }
    }

    return {
      'grid': {
        'left': '3%',
        'right': '3%',
        'bottom': '15%',
        'top': '8%',
        'containLabel': true,
      },
      'dataZoom': [
        {'type': 'inside', 'start': _zoomStart, 'end': _zoomEnd},
        {
          'type': 'slider',
          'start': _zoomStart,
          'end': _zoomEnd,
          'height': 18,
          'bottom': '2%',
          'borderColor': 'transparent',
          'backgroundColor': isDark ? '#1F2937' : '#F3F4F6',
          'fillerColor': isDark ? '#37415180' : '#D1D5DB80',
          'handleSize': '60%',
          'handleStyle': {'color': isDark ? '#6B7280' : '#9CA3AF'},
          'textStyle': {'fontSize': 0},
        },
      ],
      'xAxis': {
        'type': 'category',
        'data': categories,
        'axisLabel': {
          'color': textColor,
          'fontSize': 9,
          'rotate': categories.length > 15 ? 45 : 0,
          'interval': _calculateInterval(categories.length),
        },
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
          'name': 'Current',
          'type': 'bar',
          'data': curExpense,
          'itemStyle': {
            'color': expenseColor,
            'borderRadius': [3, 3, 0, 0],
          },
          'barGap': '10%',
          'barCategoryGap': '20%',
        },
        {
          'name': 'Previous',
          'type': 'bar',
          'data': prevExpense,
          'itemStyle': {
            'color': expenseColor,
            'opacity': 0.35,
            'borderRadius': [3, 3, 0, 0],
          },
        },
      ],
    };
  }

  /// Auto-calculate x-axis label interval based on data count.
  int _calculateInterval(int count) {
    if (count <= 7) return 0;
    if (count <= 14) return 1;
    if (count <= 21) return 2;
    return 4;
  }

  /// Build percentage change badge widget.
  Widget? _buildChangeBadge(
    double change,
    dynamic colors, {
    bool invertColors = false,
  }) {
    if (change == 0) return null;

    final isDown = change < 0;
    final Color badgeColor;
    if (invertColors) {
      badgeColor = isDown ? colors.income : colors.expense;
    } else {
      badgeColor = isDown ? colors.expense : colors.income;
    }

    final arrow = isDown ? '↓' : '↑';
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

  /// Build smart insight text below chart.
  Widget _buildInsight(
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

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 28.w,
      height: 28.w,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 16.w),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: colors.surfaceVariant.withValues(alpha: 0.5),
          disabledBackgroundColor: colors.surfaceVariant.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.r),
          ),
        ),
        color: colors.textPrimary,
        disabledColor: colors.textSecondary.withValues(alpha: 0.3),
      ),
    );
  }
}
