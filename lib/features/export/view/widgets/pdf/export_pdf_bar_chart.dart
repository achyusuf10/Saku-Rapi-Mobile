import 'package:app_saku_rapi/core/themes/app_colors.dart';
import 'package:app_saku_rapi/features/export/utils/export_pdf_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Grafik tren pemasukan & pengeluaran harian (garis) untuk capture → PDF.
///
/// [SizedBox] eksplisit + [animationDuration: 0] diperlukan agar screenshot
/// menangkap plot (Syncfusion KB / forum export chart).
class ExportPdfBarChart extends StatelessWidget {
  const ExportPdfBarChart({
    super.key,
    required this.sortedDays,
    required this.dailyIncome,
    required this.dailyExpense,
    required this.colors,
    required this.chartTitle,
    required this.localeName,
    required this.incomeLabel,
    required this.expenseLabel,
  });

  final List<DateTime> sortedDays;
  final List<double> dailyIncome;
  final List<double> dailyExpense;
  final AppColorScheme colors;
  final String chartTitle;
  final String localeName;
  final String incomeLabel;
  final String expenseLabel;

  @override
  Widget build(BuildContext context) {
    final axisLabelFmt = DateFormat('dd/MM', localeName);
    final data = <_TrendPoint>[];
    for (var i = 0; i < sortedDays.length; i++) {
      data.add(
        _TrendPoint(
          axisLabelFmt.format(sortedDays[i]),
          dailyIncome[i],
          dailyExpense[i],
        ),
      );
    }

    final grid = colors.border.withValues(alpha: 0.65);
    final maxVal = [
      ...dailyIncome,
      ...dailyExpense,
    ].fold<double>(0, (a, b) => a > b ? a : b);
    final yMax = maxVal <= 0 ? 1.0 : maxVal * 1.12;

    final chart = SfCartesianChart(
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,
      enableSideBySideSeriesPlacement: false,
      primaryXAxis: CategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: AxisLine(width: 1, color: grid),
        majorTickLines: const MajorTickLines(size: 0),
        labelStyle: TextStyle(
          color: colors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        labelRotation: sortedDays.length > 10 ? -40 : 0,
      ),
      primaryYAxis: NumericAxis(
        minimum: 0,
        maximum: yMax,
        numberFormat: NumberFormat.compact(locale: localeName),
        axisLine: AxisLine(width: 1, color: grid),
        majorTickLines: const MajorTickLines(size: 0),
        majorGridLines: MajorGridLines(width: 1, color: grid),
        labelStyle: TextStyle(color: colors.textSecondary, fontSize: 10),
      ),
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        iconWidth: 14,
        iconHeight: 14,
        textStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      tooltipBehavior: TooltipBehavior(enable: false),
      title: ChartTitle(
        text: chartTitle,
        alignment: ChartAlignment.near,
        textStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      series: <CartesianSeries<_TrendPoint, String>>[
        SplineSeries<_TrendPoint, String>(
          name: incomeLabel,
          dataSource: data,
          xValueMapper: (p, _) => p.label,
          yValueMapper: (p, _) => p.income,
          color: colors.income,
          width: 3,
          splineType: SplineType.natural,
          markerSettings: MarkerSettings(
            isVisible: true,
            height: 7,
            width: 7,
            borderWidth: 2,
            borderColor: colors.surface,
            color: colors.income,
          ),
          animationDuration: 0,
        ),
        SplineSeries<_TrendPoint, String>(
          name: expenseLabel,
          dataSource: data,
          xValueMapper: (p, _) => p.label,
          yValueMapper: (p, _) => p.expense,
          color: colors.expense,
          width: 3,
          splineType: SplineType.natural,
          markerSettings: MarkerSettings(
            isVisible: true,
            height: 7,
            width: 7,
            borderWidth: 2,
            borderColor: colors.surface,
            color: colors.expense,
          ),
          animationDuration: 0,
        ),
      ],
    );

    return SizedBox(
      width: ExportPdfLayout.chartCaptureWidth,
      height: ExportPdfLayout.chartCaptureHeightBar,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: chart,
        ),
      ),
    );
  }
}

class _TrendPoint {
  _TrendPoint(this.label, this.income, this.expense);

  final String label;
  final double income;
  final double expense;
}
