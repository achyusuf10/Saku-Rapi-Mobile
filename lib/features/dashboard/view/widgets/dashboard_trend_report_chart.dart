import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:app_saku_rapi/utils/packages/graphify/controller/graphify_controller.dart';
import 'package:app_saku_rapi/utils/packages/graphify/view/graphify_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

/// Cumulative line chart untuk Laporan Tren pengeluaran.
///
/// Menampilkan 3 garis:
/// 1. Bulan ini (solid, warna expense)
/// 2. Bulan lalu (dashed, lebih tipis)
/// 3. Rata-rata 3 bulan lalu (dashed gray)
///
/// Plus zoom controls dan smart insight di bawah chart.
class DashboardTrendReportChart extends ConsumerStatefulWidget {
  const DashboardTrendReportChart({super.key});

  @override
  ConsumerState<DashboardTrendReportChart> createState() =>
      _DashboardTrendReportChartState();
}

class _DashboardTrendReportChartState
    extends ConsumerState<DashboardTrendReportChart> {
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
    final dashState = ref.watch(dashboardControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMonthly = dashState.chartMode == DashboardChartMode.monthly;

    final now = DateTime.now();
    final (currentStart, currentEnd, prevStart, _) =
        DashboardController.periodRanges(now, dashState.chartMode);

    // Gap-fill all periods
    final periodLength = currentEnd.difference(currentStart).inDays + 1;
    final currentFilled = _fillGaps(
      dashState.currentPeriodDaily,
      currentStart,
      currentEnd,
    );
    final previousFilled = _fillGaps(
      dashState.previousPeriodDaily,
      prevStart,
      prevStart.add(Duration(days: periodLength - 1)),
    );

    final (m2Start, m2End, m3Start, m3End) =
        DashboardController.extraPeriodRanges(now, dashState.chartMode);

    final month2Filled = _fillGaps(dashState.month2Daily, m2Start, m2End);
    final month3Filled = _fillGaps(dashState.month3Daily, m3Start, m3End);

    // Compute cumulative data
    final currentCumulative = _toCumulative(currentFilled);
    final previousCumulative = _toCumulative(previousFilled);
    final avg3Cumulative = _computeAvg3Cumulative(
      previousFilled,
      month2Filled,
      month3Filled,
    );

    // X-axis labels from current period dates
    final dateFormat = DateFormat('dd/MM');
    final xLabels = currentFilled.map((e) {
      final d = DateTime.tryParse(e['date'] as String);
      return d != null ? dateFormat.format(d) : '';
    }).toList();

    // Build ECharts options
    final expenseHex =
        '#${colors.expense.toARGB32().toRadixString(16).substring(2)}';
    final textColor = isDark ? '#9CA3AF' : '#6B7280';
    final borderColor = isDark ? '#374151' : '#E5E7EB';

    final chartOptions = _buildChartOptions(
      xLabels: xLabels,
      currentData: currentCumulative,
      previousData: previousCumulative,
      avg3Data: avg3Cumulative,
      expenseColor: expenseHex,
      textColor: textColor,
      borderColor: borderColor,
      isDark: isDark,
    );

    // For insight: compare current cumulative total to 3-month avg total
    final currentTotal = currentCumulative.isNotEmpty
        ? currentCumulative.last
        : 0.0;
    final avg3Total = avg3Cumulative.isNotEmpty ? avg3Cumulative.last : 0.0;

    final hasData = dashState.currentPeriodExpense > 0 || avg3Total > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Legend ───
        Row(
          children: [
            _LegendItem(
              color: colors.expense,
              label: l10n.dashboardThisMonthCumulative,
              isDashed: false,
            ),
            SizedBox(width: 12.w),
            _LegendItem(
              color: colors.expense.withValues(alpha: 0.5),
              label: isMonthly
                  ? l10n.dashboardPrevMonthLabel
                  : l10n.dashboardLastWeek,
              isDashed: true,
            ),
            SizedBox(width: 12.w),
            _LegendItem(
              color: colors.textSecondary.withValues(alpha: 0.5),
              label: l10n.dashboardAvg3MonthLabel,
              isDashed: true,
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

        // ─── ECharts Line ───
        SizedBox(
          height: 220.h,
          child: GraphifyView(initialOptions: chartOptions, isDarkMode: isDark),
        ),
        SizedBox(height: 12.h),

        // ─── Smart Insight ───
        _buildInsight(
          context,
          currentTotal: currentTotal,
          avg3Total: avg3Total,
          hasData: hasData,
        ),
      ],
    );
  }

  /// Fills gaps in daily data so every date in range has an entry.
  List<Map<String, dynamic>> _fillGaps(
    List<Map<String, dynamic>> data,
    DateTime start,
    DateTime end,
  ) {
    final lookup = <String, Map<String, dynamic>>{};
    for (final entry in data) {
      lookup[entry['date'] as String] = entry;
    }

    final result = <Map<String, dynamic>>[];
    final fmt = DateFormat('yyyy-MM-dd');
    var current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(endDate)) {
      final key = fmt.format(current);
      result.add(lookup[key] ?? {'date': key, 'income': 0.0, 'expense': 0.0});
      current = current.add(const Duration(days: 1));
    }

    return result;
  }

  /// Converts daily expense data to cumulative running total.
  List<double> _toCumulative(List<Map<String, dynamic>> daily) {
    final result = <double>[];
    double running = 0;
    for (final entry in daily) {
      running += (entry['expense'] as num).toDouble();
      result.add(running);
    }
    return result;
  }

  /// Computes 3-month average cumulative: (prev + month2 + month3) / 3 per day.
  List<double> _computeAvg3Cumulative(
    List<Map<String, dynamic>> prev,
    List<Map<String, dynamic>> month2,
    List<Map<String, dynamic>> month3,
  ) {
    final c1 = _toCumulative(prev);
    final c2 = _toCumulative(month2);
    final c3 = _toCumulative(month3);

    final maxLen = [
      c1.length,
      c2.length,
      c3.length,
    ].reduce((a, b) => a > b ? a : b);

    final result = <double>[];
    for (int i = 0; i < maxLen; i++) {
      final v1 = i < c1.length ? c1[i] : (c1.isNotEmpty ? c1.last : 0.0);
      final v2 = i < c2.length ? c2[i] : (c2.isNotEmpty ? c2.last : 0.0);
      final v3 = i < c3.length ? c3[i] : (c3.isNotEmpty ? c3.last : 0.0);
      result.add((v1 + v2 + v3) / 3);
    }

    return result;
  }

  /// Builds ECharts option for cumulative line chart.
  Map<String, dynamic> _buildChartOptions({
    required List<String> xLabels,
    required List<double> currentData,
    required List<double> previousData,
    required List<double> avg3Data,
    required String expenseColor,
    required String textColor,
    required String borderColor,
    required bool isDark,
  }) {
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
        'data': xLabels,
        'boundaryGap': false,
        'axisLabel': {
          'color': textColor,
          'fontSize': 9,
          'rotate': xLabels.length > 15 ? 45 : 0,
          'interval': _calculateInterval(xLabels.length),
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
      'tooltip': {'trigger': 'axis'},
      'series': [
        {
          'name': 'Current',
          'type': 'line',
          'data': currentData,
          'smooth': true,
          'symbol': 'none',
          'lineStyle': {'color': expenseColor, 'width': 2.5},
          'itemStyle': {'color': expenseColor},
          'areaStyle': {
            'color': {
              'type': 'linear',
              'x': 0,
              'y': 0,
              'x2': 0,
              'y2': 1,
              'colorStops': [
                {'offset': 0, 'color': '${expenseColor}40'},
                {'offset': 1, 'color': '${expenseColor}05'},
              ],
            },
          },
        },
        {
          'name': 'Previous',
          'type': 'line',
          'data': previousData,
          'smooth': true,
          'symbol': 'none',
          'lineStyle': {
            'color': expenseColor,
            'width': 1.5,
            'opacity': 0.5,
            'type': 'dashed',
          },
          'itemStyle': {'color': expenseColor, 'opacity': 0.5},
        },
        {
          'name': 'Avg 3M',
          'type': 'line',
          'data': avg3Data,
          'smooth': true,
          'symbol': 'none',
          'lineStyle': {'color': '#9CA3AF', 'width': 1.5, 'type': 'dashed'},
          'itemStyle': {'color': '#9CA3AF'},
        },
      ],
    };
  }

  int _calculateInterval(int count) {
    if (count <= 7) return 0;
    if (count <= 14) return 1;
    if (count <= 21) return 2;
    return 4;
  }

  Widget _buildInsight(
    BuildContext context, {
    required double currentTotal,
    required double avg3Total,
    required bool hasData,
  }) {
    final l10n = context.l10n;
    final colors = context.colors;

    final String text;
    if (!hasData) {
      text = l10n.dashboardInsightNoData;
    } else if (avg3Total > 0 && currentTotal < avg3Total) {
      text = l10n.dashboardInsightTrendBelowAvg;
    } else {
      text = l10n.dashboardInsightTrendAboveAvg;
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

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDashed,
  });

  final Color color;
  final String label;
  final bool isDashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDashed)
          SizedBox(
            width: 12.w,
            height: 2.h,
            child: CustomPaint(painter: _DashedLinePainter(color: color)),
          )
        else
          Container(
            width: 12.w,
            height: 2.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1.r),
              color: color,
            ),
          ),
        SizedBox(width: 4.w),
        Flexible(
          child: Text(
            label,
            style: TextStyleConstants.label3.copyWith(
              color: context.colors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height
      ..style = PaintingStyle.stroke;

    const dashWidth = 3.0;
    const dashSpace = 2.0;
    var startX = 0.0;
    final y = size.height / 2;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
