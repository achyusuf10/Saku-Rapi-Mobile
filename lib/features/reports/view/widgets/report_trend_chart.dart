import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/features/reports/models/report_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Bar chart Syncfusion untuk tren harian income vs expense.
///
/// Menampilkan bar ganda (income hijau, expense merah) per hari.
/// Tap pada bar menampilkan tooltip detail.
class ReportTrendChart extends StatelessWidget {
  const ReportTrendChart({super.key, required this.data, this.onFullscreen});

  final List<ReportDailyTrendModel> data;
  final VoidCallback? onFullscreen;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;

    if (data.isEmpty) {
      return SizedBox(height: 200.h);
    }

    return SizedBox(
      height: 220.h,
      child: buildChart(data: data, colors: colors, isDark: isDark),
    );
  }

  /// Build chart widget — static agar bisa dipakai dari luar untuk fullscreen.
  static Widget buildChart({
    required List<ReportDailyTrendModel> data,
    required dynamic colors,
    required bool isDark,
  }) {
    final textColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);
    final gridColor = isDark
        ? const Color(0xFF374151)
        : const Color(0xFFE5E7EB);

    return SfCartesianChart(
      margin: EdgeInsets.zero,
      plotAreaBorderWidth: 0,
      primaryXAxis: CategoryAxis(
        labelStyle: TextStyle(color: textColor, fontSize: 9.sp),
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: AxisLine(color: gridColor),
        majorTickLines: const MajorTickLines(size: 0),
        labelRotation: data.length > 15 ? 45 : 0,
        labelIntersectAction: data.length > 20
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
        enable: true,
        header: '',
        canShowMarker: true,
        builder: (data, point, series, pointIdx, seriesIdx) {
          final d = data as ReportDailyTrendModel;
          final isIncome = seriesIdx == 0;
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
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
                  _formatDate(d.date),
                  style: TextStyle(color: textColor, fontSize: 10.sp),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${isIncome ? "Income" : "Expense"}: ${isIncome ? d.income.toCompactCurrency() : d.expense.toCompactCurrency()}',
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
      zoomPanBehavior: ZoomPanBehavior(
        enablePinching: true,
        enablePanning: true,
        zoomMode: ZoomMode.x,
      ),
      series: <CartesianSeries<ReportDailyTrendModel, String>>[
        ColumnSeries<ReportDailyTrendModel, String>(
          name: 'Income',
          dataSource: data,
          xValueMapper: (d, _) => _formatDate(d.date),
          yValueMapper: (d, _) => d.income,
          color: colors.income,
          borderRadius: BorderRadius.vertical(top: Radius.circular(3.r)),
          spacing: 0.15,
          width: 0.4,
        ),
        ColumnSeries<ReportDailyTrendModel, String>(
          name: 'Expense',
          dataSource: data,
          xValueMapper: (d, _) => _formatDate(d.date),
          yValueMapper: (d, _) => d.expense,
          color: colors.expense,
          borderRadius: BorderRadius.vertical(top: Radius.circular(3.r)),
          spacing: 0.15,
          width: 0.4,
        ),
      ],
    );
  }

  /// Format tanggal "yyyy-MM-dd" → "dd/MM".
  static String _formatDate(String dateStr) {
    final parts = dateStr.split('-');
    return parts.length >= 3 ? '${parts[2]}/${parts[1]}' : dateStr;
  }

  /// Label compact untuk axis Y (contoh: 1.5jt, 75rb).
  static String _compactLabel(num value) {
    final v = value.toDouble();
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)} jt';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(0)} rb';
    return v.toStringAsFixed(0);
  }
}
