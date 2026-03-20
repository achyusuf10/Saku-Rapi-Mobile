import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/history/controllers/history_controller.dart';
import 'package:app_saku_rapi/features/history/models/category_summary_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Donut chart kategori expense di Report View.
///
/// Menampilkan PieChart dari `fl_chart` dengan center text total expense.
/// Di bawah chart: legend list yang bisa di-tap untuk navigate ke breakdown.
class HistoryDonutChartWidget extends ConsumerWidget {
  const HistoryDonutChartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.colors;
    final l10n = context.l10n;
    final historyState = ref.watch(historyControllerProvider);

    if (historyState.isLoading) {
      return _buildSkeleton(appColors);
    }

    if (historyState.categorySummaries.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        SizedBox(height: 16.h),

        // ── Donut Chart ──
        SizedBox(
          height: 200.r,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 60.r,
                  sections: _buildSections(historyState.categorySummaries),
                  pieTouchData: PieTouchData(
                    touchCallback: (event, pieTouchResponse) {
                      if (event.isInterestedForInteractions &&
                          pieTouchResponse != null &&
                          pieTouchResponse.touchedSection != null) {
                        final index = pieTouchResponse
                            .touchedSection!
                            .touchedSectionIndex;
                        if (index >= 0 &&
                            index < historyState.categorySummaries.length) {
                          _navigateToBreakdown(
                            context,
                            historyState.categorySummaries[index],
                            historyState,
                          );
                        }
                      }
                    },
                  ),
                ),
              ),

              // ── Center text ──
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.historyTotalOut,
                    style: TextStyleConstants.label3.copyWith(
                      color: appColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    historyState.monthlyExpense.toCompactCurrency(),
                    style: TextStyleConstants.h7.copyWith(
                      fontWeight: FontWeight.w800,
                      color: appColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h),

        // ── Legend List ──
        ...historyState.categorySummaries.map((summary) {
          return _CategoryLegendRow(
            summary: summary,
            onTap: () => _navigateToBreakdown(context, summary, historyState),
          );
        }),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(
    List<CategorySummaryModel> summaries,
  ) {
    return summaries.asMap().entries.map((entry) {
      final summary = entry.value;
      final color = _hexColor(summary.categoryColor);

      return PieChartSectionData(
        color: color,
        value: summary.amount,
        title: '',
        radius: 24.r,
      );
    }).toList();
  }

  void _navigateToBreakdown(
    BuildContext context,
    CategorySummaryModel summary,
    HistoryState historyState,
  ) {
    context.push(
      AppRouter.expenseBreakdown,
      extra: {
        'category': summary,
        'periodStart': historyState.activePeriodStart,
        'periodEnd': historyState.activePeriodEnd,
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40.h),
      child: Center(
        child: Column(
          children: [
            FaIcon(
              FontAwesomeIcons.chartPie,
              color: appColors.textSecondary.withValues(alpha: 0.4),
              size: 36.r,
            ),
            SizedBox(height: 12.h),
            Text(
              l10n.historyNoTransactions,
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
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40.h),
      child: Center(
        child: SizedBox(
          width: 160.r,
          height: 160.r,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: appColors.primary,
          ),
        ),
      ),
    );
  }

  Color _hexColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('FF');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

/// Satu baris legend kategori di bawah donut chart.
class _CategoryLegendRow extends StatelessWidget {
  const _CategoryLegendRow({required this.summary, required this.onTap});

  final CategorySummaryModel summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final color = _hexColor(summary.categoryColor);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        child: Row(
          children: [
            // ── Color dot ──
            Container(
              width: 12.r,
              height: 12.r,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),

            SizedBox(width: 10.w),

            // ── Icon + Name ──
            FaIcon(
              _categoryIcon(summary.categoryIcon),
              size: 14.r,
              color: color,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                summary.categoryName,
                style: TextStyleConstants.b2.copyWith(
                  fontWeight: FontWeight.w500,
                  color: appColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ── Percentage ──
            Text(
              summary.percentage.toPercentage(),
              style: TextStyleConstants.label3.copyWith(
                color: appColors.textSecondary,
              ),
            ),

            SizedBox(width: 8.w),

            // ── Amount ──
            Text(
              summary.amount.toCurrency(),
              style: TextStyleConstants.b2.copyWith(
                fontWeight: FontWeight.w700,
                color: appColors.expense,
              ),
            ),

            SizedBox(width: 4.w),

            // ── Arrow ──
            FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 10.r,
              color: appColors.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Color _hexColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('FF');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  IconData _categoryIcon(String iconName) {
    return switch (iconName) {
      'utensils' => FontAwesomeIcons.utensils,
      'cart-shopping' => FontAwesomeIcons.cartShopping,
      'bus' || 'car' => FontAwesomeIcons.bus,
      'house' => FontAwesomeIcons.house,
      'bolt' => FontAwesomeIcons.bolt,
      'gamepad' => FontAwesomeIcons.gamepad,
      'heart-pulse' => FontAwesomeIcons.heartPulse,
      'graduation-cap' => FontAwesomeIcons.graduationCap,
      'shirt' => FontAwesomeIcons.shirt,
      'gift' => FontAwesomeIcons.gift,
      'plane' => FontAwesomeIcons.plane,
      'phone' => FontAwesomeIcons.phone,
      'money-bill-wave' => FontAwesomeIcons.moneyBillWave,
      'building-columns' => FontAwesomeIcons.buildingColumns,
      'briefcase' => FontAwesomeIcons.briefcase,
      'mug-hot' => FontAwesomeIcons.mugHot,
      'gas-pump' => FontAwesomeIcons.gasPump,
      'wifi' => FontAwesomeIcons.wifi,
      'baby' => FontAwesomeIcons.baby,
      'paw' => FontAwesomeIcons.paw,
      'dumbbell' => FontAwesomeIcons.dumbbell,
      _ => FontAwesomeIcons.tag,
    };
  }
}
