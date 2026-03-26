import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/features/reports/models/report_model.dart';
import 'package:app_saku_rapi/utils/packages/graphify/controller/graphify_controller.dart';
import 'package:app_saku_rapi/utils/packages/graphify/view/graphify_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Bar chart ECharts untuk tren harian income vs expense.
///
/// Menampilkan bar ganda (income hijau, expense merah) per hari.
/// Menyediakan [onFullscreen] callback untuk membuka chart fullscreen.
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

    final incomeHex =
        '#${colors.income.toARGB32().toRadixString(16).substring(2)}';
    final expenseHex =
        '#${colors.expense.toARGB32().toRadixString(16).substring(2)}';
    final textColor = isDark ? '#9CA3AF' : '#6B7280';
    final borderColor = isDark ? '#374151' : '#E5E7EB';

    final chartOptions = buildChartOptions(
      data: data,
      incomeColor: incomeHex,
      expenseColor: expenseHex,
      textColor: textColor,
      borderColor: borderColor,
    );

    return SizedBox(
      height: 220.h,
      child: GraphifyView(initialOptions: chartOptions, isDarkMode: isDark),
    );
  }

  /// Build chart options — static agar bisa dipakai dari luar untuk fullscreen.
  static Map<String, dynamic> buildChartOptions({
    required List<ReportDailyTrendModel> data,
    required String incomeColor,
    required String expenseColor,
    required String textColor,
    required String borderColor,
  }) {
    final dates = data.map((d) {
      // Show dd/MM
      final parts = d.date.split('-');
      return parts.length >= 3 ? '${parts[2]}/${parts[1]}' : d.date;
    }).toList();

    final incomeData = data.map((d) => d.income).toList();
    final expenseData = data.map((d) => d.expense).toList();

    return {
      'backgroundColor': 'transparent',
      'grid': {
        'left': '3%',
        'right': '3%',
        'bottom': '3%',
        'top': '12%',
        'containLabel': true,
      },
      'tooltip': {
        'trigger': 'axis',
        'axisPointer': {'type': 'shadow'},
      },
      'xAxis': {
        'type': 'category',
        'data': dates,
        'axisLabel': {
          'color': textColor,
          'fontSize': 9,
          'rotate': dates.length > 15 ? 45 : 0,
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
      'dataZoom': [
        {'type': 'inside', 'start': 0, 'end': 100},
      ],
      'series': [
        {
          'name': 'Income',
          'type': 'bar',
          'data': incomeData,
          'itemStyle': {
            'color': incomeColor,
            'borderRadius': [4, 4, 0, 0],
          },
          'barGap': '10%',
        },
        {
          'name': 'Expense',
          'type': 'bar',
          'data': expenseData,
          'itemStyle': {
            'color': expenseColor,
            'borderRadius': [4, 4, 0, 0],
          },
        },
      ],
    };
  }
}
