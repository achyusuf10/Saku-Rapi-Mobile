// import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
// import 'package:app_saku_rapi/core/extensions/context_ext.dart';
// import 'package:app_saku_rapi/core/extensions/double_ext.dart';
// import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
// import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_chart_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:intl/intl.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';

// /// Chart bar perbandingan pengeluaran: periode ini vs sebelumnya.
// ///
// /// Menampilkan:
// /// - Total expense & income labels dengan badge persentase perubahan
// /// - Bar chart (ECharts) dengan x-axis tanggal (dd/MM) dan gap-fill
// /// - Zoom in/out buttons + pinch zoom via ECharts dataZoom
// /// - Smart insight text di bawah chart
// class DashboardExpenseReportChart extends ConsumerStatefulWidget {
//   const DashboardExpenseReportChart({super.key});

//   @override
//   ConsumerState<DashboardExpenseReportChart> createState() =>
//       _DashboardExpenseReportChartState();
// }

// class _DashboardExpenseReportChartState
//     extends ConsumerState<DashboardExpenseReportChart> {
//   @override
//   Widget build(BuildContext context) {
//     final ref = this.ref;
//     final colors = context.colors;
//     final l10n = context.l10n;
//     final chartState = ref.watch(dashboardChartControllerProvider);
//     final isMonthly = chartState.chartMode == DashboardChartMode.monthly;
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     final now = DateTime.now();
//     final (currentStart, currentEnd, prevStart, _) =
//         DashboardChartController.periodRanges(now, chartState.chartMode);

//     // Gap-fill daily data
//     final currentFilled = _fillGaps(
//       chartState.currentPeriodDaily,
//       currentStart,
//       currentEnd,
//     );
//     final previousFilled = _fillGaps(
//       chartState.previousPeriodDaily,
//       prevStart,
//       // For previous period, use same length as current
//       prevStart.add(currentEnd.difference(currentStart)),
//     );

//     // Calculate totals & percentage change
//     final currentExpense = chartState.currentPeriodExpense;
//     final previousExpense = chartState.previousPeriodExpense;
//     final currentIncome = chartState.currentPeriodIncome;

//     final expenseChange = previousExpense > 0
//         ? ((currentExpense - previousExpense) / previousExpense * 100)
//         : 0.0;

//     final previousLabel = isMonthly
//         ? l10n.dashboardLastMonth
//         : l10n.dashboardLastWeek;
//     final periodLabel = isMonthly
//         ? l10n.dashboardThisMonth
//         : l10n.dashboardThisWeek;

//     // Build chart data
//     final chartData = _buildChartData(currentFilled, previousFilled);
//     final textColor = isDark
//         ? const Color(0xFF9CA3AF)
//         : const Color(0xFF6B7280);
//     final gridColor = isDark
//         ? const Color(0xFF374151)
//         : const Color(0xFFE5E7EB);

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // ─── Summary Row ───
//         Row(
//           children: [
//             Expanded(
//               child: _SummaryItem(
//                 label: l10n.dashboardTotalExpenseLabel,
//                 value: currentExpense.toCompactCurrency(),
//                 valueColor: colors.expense,
//                 badge: _buildChangeBadge(
//                   expenseChange,
//                   colors,
//                   invertColors: true,
//                 ),
//               ),
//             ),
//             SizedBox(width: 12.w),
//             Expanded(
//               child: _SummaryItem(
//                 label: l10n.dashboardTotalIncomeLabel,
//                 value: currentIncome.toCompactCurrency(),
//                 valueColor: colors.income,
//               ),
//             ),
//           ],
//         ),
//         SizedBox(height: 12.h),

//         // ─── Legend ───
//         Row(
//           children: [
//             _LegendItem(color: colors.expense, label: periodLabel),
//             SizedBox(width: 16.w),
//             _LegendItem(
//               color: colors.expense.withValues(alpha: 0.35),
//               label: previousLabel,
//             ),
//           ],
//         ),
//         SizedBox(height: 8.h),

//         // ─── Syncfusion Bar Chart ───
//         SizedBox(
//           height: 200.h,
//           child: SfCartesianChart(
//             key: ValueKey(
//               '${chartState.chartMode}_${currentExpense}_$previousExpense',
//             ),
//             margin: EdgeInsets.zero,
//             plotAreaBorderWidth: 0,
//             primaryXAxis: CategoryAxis(
//               labelStyle: TextStyle(color: textColor, fontSize: 9.sp),
//               majorGridLines: const MajorGridLines(width: 0),
//               axisLine: AxisLine(color: gridColor),
//               majorTickLines: const MajorTickLines(size: 0),
//               labelRotation: chartData.length > 15 ? 45 : 0,
//               labelIntersectAction: chartData.length > 20
//                   ? AxisLabelIntersectAction.hide
//                   : AxisLabelIntersectAction.none,
//             ),
//             primaryYAxis: NumericAxis(
//               labelStyle: TextStyle(color: textColor, fontSize: 10.sp),
//               majorGridLines: MajorGridLines(
//                 color: gridColor,
//                 dashArray: const <double>[4, 3],
//               ),
//               axisLine: const AxisLine(width: 0),
//               majorTickLines: const MajorTickLines(size: 0),
//               axisLabelFormatter: (details) => ChartAxisLabel(
//                 _compactLabel(details.value),
//                 TextStyle(color: textColor, fontSize: 10.sp),
//               ),
//             ),
//             tooltipBehavior: TooltipBehavior(
//               enable: true,
//               header: '',
//               builder: (data, point, series, pointIdx, seriesIdx) {
//                 final d = data as _ExpenseChartData;
//                 final isCurrent = seriesIdx == 0;
//                 final value = isCurrent ? d.current : d.previous;
//                 return Container(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: 10.w,
//                     vertical: 6.h,
//                   ),
//                   decoration: BoxDecoration(
//                     color: isDark ? const Color(0xFF1F2937) : Colors.white,
//                     borderRadius: BorderRadius.circular(8.r),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withValues(alpha: 0.15),
//                         blurRadius: 8,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         d.label,
//                         style: TextStyle(color: textColor, fontSize: 10.sp),
//                       ),
//                       SizedBox(height: 2.h),
//                       Text(
//                         '${isCurrent ? periodLabel : previousLabel}: ${value.toCompactCurrency()}',
//                         style: TextStyle(
//                           color: colors.expense,
//                           fontSize: 11.sp,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//             zoomPanBehavior: ZoomPanBehavior(
//               enablePinching: true,
//               enablePanning: true,
//               zoomMode: ZoomMode.x,
//             ),
//             series: <CartesianSeries<_ExpenseChartData, String>>[
//               ColumnSeries<_ExpenseChartData, String>(
//                 name: periodLabel,
//                 dataSource: chartData,
//                 xValueMapper: (d, _) => d.label,
//                 yValueMapper: (d, _) => d.current,
//                 color: colors.expense,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(3.r)),
//                 spacing: 0.15,
//                 width: 0.35,
//               ),
//               ColumnSeries<_ExpenseChartData, String>(
//                 name: previousLabel,
//                 dataSource: chartData,
//                 xValueMapper: (d, _) => d.label,
//                 yValueMapper: (d, _) => d.previous,
//                 color: colors.expense.withValues(alpha: 0.35),
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(3.r)),
//                 spacing: 0.15,
//                 width: 0.35,
//               ),
//             ],
//           ),
//         ),
//         SizedBox(height: 12.h),

//         // ─── Smart Insight ───
//         _buildInsight(
//           context,
//           expenseChange: expenseChange,
//           periodLabel: periodLabel.toLowerCase(),
//           previousLabel: previousLabel.toLowerCase(),
//           hasData: currentExpense > 0 || previousExpense > 0,
//         ),
//       ],
//     );
//   }

//   /// Fills gaps in daily data so every date in the range has an entry.
//   List<Map<String, dynamic>> _fillGaps(
//     List<Map<String, dynamic>> data,
//     DateTime start,
//     DateTime end,
//   ) {
//     final lookup = <String, Map<String, dynamic>>{};
//     for (final entry in data) {
//       final dateStr = entry['date'] as String;
//       lookup[dateStr] = entry;
//     }

//     final result = <Map<String, dynamic>>[];
//     final dateFormat = DateFormat('yyyy-MM-dd');
//     var current = DateTime(start.year, start.month, start.day);
//     final endDate = DateTime(end.year, end.month, end.day);

//     while (!current.isAfter(endDate)) {
//       final key = dateFormat.format(current);
//       result.add(lookup[key] ?? {'date': key, 'income': 0.0, 'expense': 0.0});
//       current = current.add(const Duration(days: 1));
//     }

//     return result;
//   }

//   /// Builds chart data list from current + previous daily data.
//   List<_ExpenseChartData> _buildChartData(
//     List<Map<String, dynamic>> currentDaily,
//     List<Map<String, dynamic>> previousDaily,
//   ) {
//     final dateFormat = DateFormat('dd/MM');
//     final maxLen = currentDaily.length > previousDaily.length
//         ? currentDaily.length
//         : previousDaily.length;

//     final result = <_ExpenseChartData>[];
//     for (int i = 0; i < maxLen; i++) {
//       String label = '${i + 1}';
//       double curVal = 0;
//       double prevVal = 0;

//       if (i < currentDaily.length) {
//         final dateStr = currentDaily[i]['date'] as String;
//         final date = DateTime.tryParse(dateStr);
//         label = date != null ? dateFormat.format(date) : '${i + 1}';
//         curVal = (currentDaily[i]['expense'] as num).toDouble();
//       }

//       if (i < previousDaily.length) {
//         prevVal = (previousDaily[i]['expense'] as num).toDouble();
//       }

//       result.add(
//         _ExpenseChartData(label: label, current: curVal, previous: prevVal),
//       );
//     }

//     return result;
//   }

//   /// Label compact untuk axis Y (contoh: 1.5jt, 75rb).
//   static String _compactLabel(num value) {
//     final v = value.toDouble();
//     if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)} jt';
//     if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(0)} rb';
//     return v.toStringAsFixed(0);
//   }

//   /// Build percentage change badge widget.
//   Widget? _buildChangeBadge(
//     double change,
//     dynamic colors, {
//     bool invertColors = false,
//   }) {
//     if (change == 0) return null;

//     final isDown = change < 0;
//     final Color badgeColor;
//     if (invertColors) {
//       badgeColor = isDown ? colors.income : colors.expense;
//     } else {
//       badgeColor = isDown ? colors.expense : colors.income;
//     }

//     final arrow = isDown ? '↓' : '↑';
//     final text = '${change.abs().toStringAsFixed(0)}%';

//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
//       decoration: BoxDecoration(
//         color: badgeColor.withValues(alpha: 0.15),
//         borderRadius: BorderRadius.circular(8.r),
//       ),
//       child: Text(
//         '$arrow $text',
//         style: TextStyleConstants.label3.copyWith(
//           color: badgeColor,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }

//   /// Build smart insight text below chart.
//   Widget _buildInsight(
//     BuildContext context, {
//     required double expenseChange,
//     required String periodLabel,
//     required String previousLabel,
//     required bool hasData,
//   }) {
//     final l10n = context.l10n;
//     final colors = context.colors;

//     final String text;
//     if (!hasData) {
//       text = l10n.dashboardInsightNoData;
//     } else if (expenseChange < -2) {
//       text = l10n.dashboardInsightExpenseDown(
//         periodLabel,
//         expenseChange.abs().toStringAsFixed(0),
//         previousLabel,
//       );
//     } else if (expenseChange > 2) {
//       text = l10n.dashboardInsightExpenseUp(
//         periodLabel,
//         expenseChange.abs().toStringAsFixed(0),
//         previousLabel,
//       );
//     } else {
//       text = l10n.dashboardInsightExpenseSame(previousLabel);
//     }

//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(10.w),
//       decoration: BoxDecoration(
//         color: colors.surfaceVariant.withValues(alpha: 0.5),
//         borderRadius: BorderRadius.circular(8.r),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(
//             Icons.lightbulb_outline_rounded,
//             size: 16.w,
//             color: colors.warning,
//           ),
//           SizedBox(width: 8.w),
//           Expanded(
//             child: Text(
//               text,
//               style: TextStyleConstants.label2.copyWith(
//                 color: colors.textSecondary,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _SummaryItem extends StatelessWidget {
//   const _SummaryItem({
//     required this.label,
//     required this.value,
//     required this.valueColor,
//     this.badge,
//   });

//   final String label;
//   final String value;
//   final Color valueColor;
//   final Widget? badge;

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.colors;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyleConstants.label2.copyWith(
//             color: colors.textSecondary,
//           ),
//         ),
//         SizedBox(height: 2.h),
//         Row(
//           children: [
//             Flexible(
//               child: Text(
//                 value,
//                 style: TextStyleConstants.b2.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: valueColor,
//                 ),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//             if (badge != null) ...[SizedBox(width: 6.w), badge!],
//           ],
//         ),
//       ],
//     );
//   }
// }

// class _LegendItem extends StatelessWidget {
//   const _LegendItem({required this.color, required this.label});

//   final Color color;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           width: 8.w,
//           height: 8.w,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(2.r),
//             color: color,
//           ),
//         ),
//         SizedBox(width: 4.w),
//         Text(
//           label,
//           style: TextStyleConstants.label3.copyWith(
//             color: context.colors.textSecondary,
//           ),
//         ),
//       ],
//     );
//   }
// }

// /// Data model untuk chart perbandingan expense current vs previous.
// class _ExpenseChartData {
//   const _ExpenseChartData({
//     required this.label,
//     required this.current,
//     required this.previous,
//   });

//   final String label;
//   final double current;
//   final double previous;
// }
