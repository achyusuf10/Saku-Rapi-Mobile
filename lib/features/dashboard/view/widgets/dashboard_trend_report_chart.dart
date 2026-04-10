import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_chart_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Cumulative line chart untuk Laporan Tren pengeluaran.
///
/// Menampilkan 3 garis:
/// 1. Bulan ini (solid, warna expense)
/// 2. Bulan lalu (dashed, lebih tipis)
/// 3. Rata-rata 3 bulan lalu (dashed gray)
class DashboardTrendReportChart extends ConsumerWidget {
  const DashboardTrendReportChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final chartState = ref.watch(dashboardChartControllerProvider);
    final isMonthly = chartState.chartMode == DashboardChartMode.monthly;
    final isDaily = chartState.chartMode == DashboardChartMode.daily;

    final now = DateTime.now();
    final (currentStart, currentEnd, prevStart, _) =
        DashboardChartController.periodRanges(now, chartState.chartMode);

    // Gap-fill all periods
    final periodLength = currentEnd.difference(currentStart).inDays + 1;
    final currentFilled = _fillGaps(
      chartState.currentPeriodDaily,
      currentStart,
      currentEnd,
    );
    final previousFilled = _fillGaps(
      chartState.previousPeriodDaily,
      prevStart,
      prevStart.add(Duration(days: periodLength - 1)),
    );

    final (m2Start, m2End, m3Start, m3End) =
        DashboardChartController.extraPeriodRanges(now, chartState.chartMode);

    final month2Filled = _fillGaps(chartState.month2Daily, m2Start, m2End);
    final month3Filled = _fillGaps(chartState.month3Daily, m3Start, m3End);

    // Compute cumulative data
    final currentCumulative = _toCumulative(currentFilled);
    final previousCumulative = _toCumulative(previousFilled);
    final avg3Cumulative = _computeAvg3Cumulative(
      previousFilled,
      month2Filled,
      month3Filled,
    );

    // X-axis labels adapted per mode
    final List<String> xLabels;
    if (isDaily) {
      // For daily mode, show hour labels (00:00 - 23:00)
      xLabels = List.generate(24, (i) => '${i.toString().padLeft(2, '0')}:00');
    } else if (isMonthly) {
      final dateFormat = DateFormat('dd/MM');
      xLabels = currentFilled.map((e) {
        final d = DateTime.tryParse(e['date'] as String);
        return d != null ? dateFormat.format(d) : '';
      }).toList();
    } else {
      // Weekly: show day names (Sen, Sel, Rab...)
      final dayFormat = DateFormat('EEE', 'id_ID');
      xLabels = currentFilled.map((e) {
        final d = DateTime.tryParse(e['date'] as String);
        return d != null ? dayFormat.format(d) : '';
      }).toList();
    }

    // Build Syncfusion chart data
    final trendData = <_TrendPoint>[];
    final maxLen = [
      currentCumulative.length,
      previousCumulative.length,
      avg3Cumulative.length,
    ].reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < maxLen; i++) {
      trendData.add(
        _TrendPoint(
          label: i < xLabels.length ? xLabels[i] : '${i + 1}',
          current: i < currentCumulative.length ? currentCumulative[i] : null,
          previous: i < previousCumulative.length
              ? previousCumulative[i]
              : null,
          avg3: i < avg3Cumulative.length ? avg3Cumulative[i] : null,
        ),
      );
    }

    final textColor = colors.textSecondary;
    final gridColor = colors.border.withValues(alpha: 0.75);

    // For insight: compare current cumulative total to 3-month avg total
    final currentTotal = currentCumulative.isNotEmpty
        ? currentCumulative.last
        : 0.0;
    final avg3Total = avg3Cumulative.isNotEmpty ? avg3Cumulative.last : 0.0;

    final hasData = chartState.currentPeriodExpense > 0 || avg3Total > 0;

    // Determine legend labels per mode
    final String currentLegend;
    final String previousLegend;
    final String avgLegend;
    if (isMonthly) {
      currentLegend = l10n.dashboardThisMonthCumulative;
      previousLegend = l10n.dashboardPrevMonthLabel;
      avgLegend = l10n.dashboardAvg3MonthLabel;
    } else if (isDaily) {
      currentLegend = l10n.dashboardToday;
      previousLegend = l10n.dashboardYesterday;
      avgLegend = l10n.dashboardAvg3DayLabel;
    } else {
      currentLegend = l10n.dashboardThisWeek;
      previousLegend = l10n.dashboardLastWeek;
      avgLegend = l10n.dashboardAvg3WeekLabel;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Legend ───
        Wrap(
          spacing: 12.w,
          runSpacing: 4.h,
          children: [
            _LegendItem(
              color: colors.expense,
              label: currentLegend,
              isDashed: false,
            ),
            _LegendItem(
              color: colors.expense.withValues(alpha: 0.5),
              label: previousLegend,
              isDashed: true,
            ),
            _LegendItem(
              color: colors.textSecondary.withValues(alpha: 0.5),
              label: avgLegend,
              isDashed: true,
            ),
          ],
        ),
        SizedBox(height: 8.h),

        // ─── Syncfusion Line Chart ───
        SizedBox(
          height: 220.h,
          child: SfCartesianChart(
            key: ValueKey(
              '${chartState.chartMode}_${currentTotal.toStringAsFixed(0)}_${avg3Total.toStringAsFixed(0)}',
            ),
            margin: EdgeInsets.zero,
            plotAreaBorderWidth: 0,
            primaryXAxis: CategoryAxis(
              labelStyle: TextStyle(color: textColor, fontSize: 9.sp),
              majorGridLines: const MajorGridLines(width: 0),
              axisLine: AxisLine(color: gridColor),
              majorTickLines: const MajorTickLines(size: 0),
              labelRotation: trendData.length > 15 ? 45 : 0,
              labelIntersectAction: trendData.length > 20
                  ? AxisLabelIntersectAction.hide
                  : AxisLabelIntersectAction.none,
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
                final d = data as _TrendPoint;
                final names = [currentLegend, previousLegend, avgLegend];
                final values = [d.current, d.previous, d.avg3];
                final seriesColors = [
                  colors.expense,
                  colors.expense.withValues(alpha: 0.5),
                  colors.textSecondary.withValues(alpha: 0.5),
                ];
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
                        '${names[seriesIdx]}: ${(values[seriesIdx] ?? 0).toCompactCurrency()}',
                        style: TextStyle(
                          color: seriesColors[seriesIdx],
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            zoomPanBehavior: ZoomPanBehavior(
              enablePinching: true,
              enablePanning: true,
              zoomMode: ZoomMode.x,
            ),
            series: <CartesianSeries<_TrendPoint, String>>[
              // Current period — solid line with gradient area
              SplineAreaSeries<_TrendPoint, String>(
                name: currentLegend,
                dataSource: trendData,
                xValueMapper: (d, _) => d.label,
                yValueMapper: (d, _) => d.current,
                color: colors.expense,
                borderColor: colors.expense,
                borderWidth: 2.5,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.expense.withValues(alpha: 0.25),
                    colors.expense.withValues(alpha: 0.02),
                  ],
                ),
                markerSettings: const MarkerSettings(isVisible: false),
              ),
              // Previous period — dashed line
              SplineSeries<_TrendPoint, String>(
                name: previousLegend,
                dataSource: trendData,
                xValueMapper: (d, _) => d.label,
                yValueMapper: (d, _) => d.previous,
                color: colors.expense.withValues(alpha: 0.5),
                width: 1.5,
                dashArray: const <double>[6, 4],
                markerSettings: const MarkerSettings(isVisible: false),
              ),
              // 3-month average — dashed gray line
              SplineSeries<_TrendPoint, String>(
                name: avgLegend,
                dataSource: trendData,
                xValueMapper: (d, _) => d.label,
                yValueMapper: (d, _) => d.avg3,
                color: colors.textSecondary.withValues(alpha: 0.75),
                width: 1.5,
                dashArray: const <double>[6, 4],
                markerSettings: const MarkerSettings(isVisible: false),
              ),
            ],
          ),
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
  static List<Map<String, dynamic>> _fillGaps(
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
  static List<double> _toCumulative(List<Map<String, dynamic>> daily) {
    final result = <double>[];
    double running = 0;
    for (final entry in daily) {
      running += (entry['expense'] as num).toDouble();
      result.add(running);
    }
    return result;
  }

  /// Computes 3-month average cumulative: (prev + month2 + month3) / 3 per day.
  static List<double> _computeAvg3Cumulative(
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

  /// Compact axis label: 1.5 jt, 300 rb, etc.
  static String _compactLabel(num value) {
    final v = value.toDouble();
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)} jt';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(0)} rb';
    return v.toStringAsFixed(0);
  }

  static Widget _buildInsight(
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
    } else if (avg3Total > 0 && currentTotal > avg3Total) {
      // Current spending exceeds average → warning
      text = l10n.dashboardInsightTrendAboveAvg;
    } else {
      // Current spending is below or equal to average → praise
      text = l10n.dashboardInsightTrendBelowAvg;
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

class _TrendPoint {
  _TrendPoint({required this.label, this.current, this.previous, this.avg3});

  final String label;
  final double? current;
  final double? previous;
  final double? avg3;
}
