import 'package:app_saku_rapi/core/themes/app_colors.dart';
import 'package:app_saku_rapi/features/export/utils/export_pdf_theme.dart';
import 'package:app_saku_rapi/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ExportPdfPieSlice {
  const ExportPdfPieSlice({required this.name, required this.amount});

  final String name;
  final double amount;
}

/// Grafik pie agregat kategori pengeluaran untuk PDF (capture statis).
class ExportPdfPieChart extends StatelessWidget {
  const ExportPdfPieChart({
    super.key,
    required this.slices,
    required this.totalExpense,
    required this.colors,
    required this.l10n,
  });

  final List<ExportPdfPieSlice> slices;
  final double totalExpense;
  final AppColorScheme colors;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final palette = _palette(colors, slices.length);

    final chart = SfCircularChart(
      margin: EdgeInsets.zero,
      tooltipBehavior: TooltipBehavior(enable: false),
      title: ChartTitle(
        text: l10n.exportChartCategoryTitle,
        textStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        overflowMode: LegendItemOverflowMode.wrap,
        iconWidth: 12,
        iconHeight: 12,
        textStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      series: <CircularSeries<ExportPdfPieSlice, String>>[
        PieSeries<ExportPdfPieSlice, String>(
          dataSource: slices,
          animationDuration: 0,
          xValueMapper: (s, _) => s.name,
          yValueMapper: (s, _) => s.amount,
          pointColorMapper: (ExportPdfPieSlice? s, int i) {
            final idx = i.clamp(0, palette.length - 1);
            return palette[idx];
          },
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            labelPosition: ChartDataLabelPosition.outside,
            connectorLineSettings: ConnectorLineSettings(
              length: '12%',
              type: ConnectorType.line,
              color: colors.border,
            ),
            builder: (data, point, series, pointIndex, seriesIndex) {
              final s = data as ExportPdfPieSlice;
              final pct = totalExpense > 0
                  ? (s.amount / totalExpense * 100).toStringAsFixed(0)
                  : '0';
              final nameLabel = s.name.length > 26
                  ? '${s.name.substring(0, 25)}…'
                  : s.name;
              return Text(
                '$nameLabel · $pct%',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
          explode: false,
          explodeOffset: '0%',
        ),
      ],
    );

    return SizedBox(
      width: ExportPdfLayout.chartCaptureWidth,
      height: ExportPdfLayout.chartCaptureHeightPie,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: chart,
        ),
      ),
    );
  }

  static List<Color> _palette(AppColorScheme c, int n) {
    final base = <Color>[
      c.expense,
      c.primary,
      c.accent,
      c.debt,
      c.loan,
      c.transfer,
      c.info,
      c.success,
    ];
    if (n <= base.length) return base.sublist(0, n);
    final out = List<Color>.from(base);
    var i = 0;
    while (out.length < n) {
      final t = Color.lerp(c.expense, c.primary, (i % 5) / 5.0)!;
      out.add(t);
      i++;
    }
    return out;
  }
}
