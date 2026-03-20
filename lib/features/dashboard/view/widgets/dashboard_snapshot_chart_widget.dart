import 'dart:math';

import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:app_saku_rapi/global/widgets/saku_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bar chart income vs expense per minggu dalam bulan berjalan.
///
/// Menggunakan `fl_chart` BarChart. X = Minggu 1-4, Y = IDR.
/// 2 bar per minggu: pemasukan (hijau) vs pengeluaran (merah).
class DashboardSnapshotChartWidget extends ConsumerWidget {
  const DashboardSnapshotChartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.colors;
    final l10n = context.l10n;
    final dashState = ref.watch(dashboardControllerProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SakuCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──
            Text(
              l10n.dashboardSnapshotTitle,
              style: TextStyleConstants.h7.copyWith(
                fontWeight: FontWeight.w700,
                color: appColors.textPrimary,
              ),
            ),

            SizedBox(height: 8.h),

            // ── Legend ──
            Row(
              children: [
                _LegendDot(
                  color: appColors.income,
                  label: l10n.dashboardIncomeLabel,
                ),
                SizedBox(width: 16.w),
                _LegendDot(
                  color: appColors.expense,
                  label: l10n.dashboardExpenseLabel,
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // ── Chart ──
            dashState.when(
              loading: () => _buildSkeleton(appColors),
              error: (_, __) => SizedBox(height: 180.h),
              data: (data) {
                if (data.chartData.every(
                  (w) => w.income == 0 && w.expense == 0,
                )) {
                  return _buildEmptyState(context);
                }
                return SizedBox(
                  height: 180.h,
                  child: _buildBarChart(context, data.chartData),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, List<WeeklyChartData> chartData) {
    final appColors = context.colors;
    final l10n = context.l10n;

    // Hitung maxY untuk axis
    double maxVal = 0;
    for (final w in chartData) {
      maxVal = max(maxVal, max(w.income, w.expense));
    }
    // Round up ke kelipatan yang wajar
    final maxY = maxVal == 0 ? 100.0 : maxVal * 1.2;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.toCurrency(),
                TextStyleConstants.label3.copyWith(
                  color: appColors.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52.w,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: EdgeInsets.only(right: 4.w),
                  child: Text(
                    value.toCompactCurrency(),
                    style: TextStyleConstants.label3.copyWith(
                      color: appColors.textSecondary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= chartData.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Text(
                    l10n.dashboardWeekLabel(
                      chartData[idx].weekNumber.toString(),
                    ),
                    style: TextStyleConstants.label3.copyWith(
                      color: appColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: appColors.border.withValues(alpha: 0.5),
            strokeWidth: 0.8,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: chartData.asMap().entries.map((entry) {
          final i = entry.key;
          final w = entry.value;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: w.income,
                color: appColors.income,
                width: 14.w,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4.r),
                  topRight: Radius.circular(4.r),
                ),
              ),
              BarChartRodData(
                toY: w.expense,
                color: appColors.expense,
                width: 14.w,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4.r),
                  topRight: Radius.circular(4.r),
                ),
              ),
            ],
            barsSpace: 4.w,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;

    return SizedBox(
      height: 120.h,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.chartColumn,
              color: appColors.textSecondary.withValues(alpha: 0.4),
              size: 32.r,
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.dashboardEmptyTransactions,
              style: TextStyleConstants.caption.copyWith(
                color: appColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(appColors) {
    return SizedBox(
      height: 180.h,
      child: Center(
        child: CircularProgressIndicator(
          color: appColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

/// Legend dot: [●] Label
class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10.r,
          height: 10.r,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3.r),
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyleConstants.label2.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
