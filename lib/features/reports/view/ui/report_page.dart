import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/dashboard/view/widgets/chart_fullscreen_dialog.dart';
import 'package:app_saku_rapi/features/reports/controllers/report_controller.dart';
import 'package:app_saku_rapi/features/reports/models/report_category_transactions_argument.dart';
import 'package:app_saku_rapi/features/reports/view/widgets/report_category_chart.dart';
import 'package:app_saku_rapi/features/reports/view/widgets/report_sub_period_tabs.dart';
import 'package:app_saku_rapi/features/reports/view/widgets/report_summary_card.dart';
import 'package:app_saku_rapi/features/reports/view/widgets/report_trend_chart.dart';
import 'package:app_saku_rapi/global/widgets/saku_card.dart';
import 'package:app_saku_rapi/global/widgets/saku_empty_state.dart';
import 'package:app_saku_rapi/global/widgets/saku_error_state.dart';
import 'package:app_saku_rapi/global/widgets/saku_loading_indicator.dart';
import 'package:app_saku_rapi/global/widgets/saku_wallet_filter_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Halaman laporan (Reports & Analytics).
///
/// Menampilkan:
/// - Period selector tabs (Mingguan, Bulanan, Kuartal, Tahunan)
/// - Sub-period tabs (navigasi bulan ini / bulan lalu, dsb.)
/// - Wallet filter chip
/// - Income vs Expense summary card
/// - Category breakdown list dengan icon & progress bar
/// - Daily income/expense trend bar chart + fullscreen
/// - Smart insight
///
/// Setiap section menggunakan ConsumerWidget terpisah
/// agar hanya rebuild widget yang datanya berubah.
class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key});

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(reportControllerProvider.notifier);
      // Init sub-period ke tab terakhir (saat ini)
      final state = ref.read(reportControllerProvider);
      final tabs = state.subPeriodTabs;
      if (tabs.isNotEmpty && state.subPeriodIndex == null) {
        ref
            .read(reportControllerProvider.notifier)
            .setSubPeriod(tabs.length - 1);
      } else {
        controller.loadReport();
      }
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(reportControllerProvider.notifier).loadReport();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    // Hanya watch status & period untuk scaffold-level decisions
    final status = ref.watch(reportControllerProvider.select((s) => s.status));
    final errorMessage = ref.watch(
      reportControllerProvider.select((s) => s.errorMessage),
    );
    final total = ref.watch(
      reportControllerProvider.select((s) => s.summary.total),
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.reportTitle),
        centerTitle: false,
        actions: [
          SakuWalletFilterButton(
            selectedWalletId: ref.watch(
              reportControllerProvider.select((s) => s.walletId),
            ),
            onSelected: (id) =>
                ref.read(reportControllerProvider.notifier).setWalletFilter(id),
          ),
          10.horizontalSpace,
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: colors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ─── Period Tabs ───
            const SliverToBoxAdapter(child: _ReportPeriodTabs()),

            // ─── Sub-Period Tabs ───
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: const ReportSubPeriodTabs(),
              ),
            ),

            // ─── Body ───
            if (status == ReportStatus.loading)
              const SliverFillRemaining(
                child: Center(child: SakuLoadingIndicator()),
              )
            else if (status == ReportStatus.error)
              SliverFillRemaining(
                child: Center(
                  child: SakuErrorState(
                    message: errorMessage ?? l10n.reportErrorGeneric,
                    onRetry: _onRefresh,
                  ),
                ),
              )
            else if (status == ReportStatus.loaded && total == 0)
              SliverFillRemaining(
                child: SakuEmptyState(
                  icon: FontAwesomeIcons.chartPie,
                  title: l10n.reportEmptyTitle,
                  message: l10n.reportEmptyMessage,
                ),
              )
            else ...[
              // ─── Summary Card ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                  child: const _ReportSummarySection(),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 20.h)),

              // ─── Category Breakdown ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: const _ReportCategorySection(),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 20.h)),

              // ─── Daily Trend ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: const _ReportTrendSection(),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 20.h)),

              // ─── Insight ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: const _ReportInsightSection(),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
            ],
          ],
        ),
      ),
    );
  }
}

// ───────────────── Period Tabs (granular) ─────────────────

class _ReportPeriodTabs extends ConsumerWidget {
  const _ReportPeriodTabs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final period = ref.watch(reportControllerProvider.select((s) => s.period));

    final tabs = [
      (ReportPeriod.weekly, l10n.reportPeriodWeekly),
      (ReportPeriod.monthly, l10n.reportPeriodMonthly),
      (ReportPeriod.quarterly, l10n.reportPeriodQuarterly),
      (ReportPeriod.yearly, l10n.reportPeriodYearly),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = period == tab.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  ref.read(reportControllerProvider.notifier).setPeriod(tab.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary
                      : colors.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  tab.$2,
                  style: TextStyleConstants.label2.copyWith(
                    color: isSelected ? colors.onPrimary : colors.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ───────────────── Summary Section (granular) ─────────────────

class _ReportSummarySection extends ConsumerWidget {
  const _ReportSummarySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(
      reportControllerProvider.select((s) => s.summary),
    );
    final expenseChange = ref.watch(reportExpenseChangeProvider);
    final incomeChange = ref.watch(reportIncomeChangeProvider);

    return ReportSummaryCard(
      summary: summary,
      expenseChange: expenseChange,
      incomeChange: incomeChange,
    );
  }
}

// ───────────────── Category Section (granular) ─────────────────

class _ReportCategorySection extends ConsumerWidget {
  const _ReportCategorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final breakdownType = ref.watch(
      reportControllerProvider.select((s) => s.breakdownType),
    );
    final isCategoryLoading = ref.watch(
      reportControllerProvider.select((s) => s.isCategoryLoading),
    );
    final categories = ref.watch(reportTopCategoriesProvider);
    final total = ref.watch(reportCategoryTotalProvider);

    return SakuCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + toggle expense/income
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.chartPie,
                size: 15.w,
                color: colors.primary,
              ),
              SizedBox(width: 8.w),
              Text(
                l10n.reportCategoryBreakdown,
                style: TextStyleConstants.b2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              _BreakdownToggle(
                current: breakdownType,
                onChanged: (type) => ref
                    .read(reportControllerProvider.notifier)
                    .setBreakdownType(type),
                colors: colors,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (isCategoryLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32.h),
                child: const SakuLoadingIndicator(),
              ),
            )
          else if (categories.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32.h),
                child: Text(
                  l10n.reportNoCategory,
                  style: TextStyleConstants.b2.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ReportCategoryChart(
              categories: categories,
              total: total,
              onCategoryTap: (cat) {
                // Tidak navigasi untuk "Lainnya"
                if (cat.categoryId == '__others__') return;

                final state = ref.read(reportControllerProvider);
                final (start, end) = state.dateRange;
                final type = breakdownType == ReportBreakdownType.expense
                    ? 'expense'
                    : 'income';

                context.push(
                  AppRouter.reportCategoryTransactions,
                  extra: ReportCategoryTransactionsArgument(
                    categoryId: cat.categoryId,
                    categoryName: cat.categoryName,
                    categoryIcon: cat.categoryIcon,
                    categoryColor: cat.categoryColor,
                    startDate: start,
                    endDate: end,
                    type: type,
                    walletId: state.walletId,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ───────────────── Trend Section (granular + fullscreen) ─────────────────

class _ReportTrendSection extends ConsumerWidget {
  const _ReportTrendSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final dailyTrend = ref.watch(
      reportControllerProvider.select((s) => s.dailyTrend),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SakuCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.chartColumn,
                size: 15.w,
                color: colors.primary,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  l10n.reportDailyTrend,
                  style: TextStyleConstants.b2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (dailyTrend.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    final incomeHex =
                        '#${colors.income.toARGB32().toRadixString(16).substring(2)}';
                    final expenseHex =
                        '#${colors.expense.toARGB32().toRadixString(16).substring(2)}';
                    final textColor = isDark ? '#9CA3AF' : '#6B7280';
                    final borderColor = isDark ? '#374151' : '#E5E7EB';

                    final chartOptions = ReportTrendChart.buildChartOptions(
                      data: dailyTrend,
                      incomeColor: incomeHex,
                      expenseColor: expenseHex,
                      textColor: textColor,
                      borderColor: borderColor,
                    );

                    ChartFullscreenDialog.show(
                      context,
                      title: l10n.reportDailyTrend,
                      chartOptions: chartOptions,
                      isDark: isDark,
                    );
                  },
                  child: Icon(
                    Icons.fullscreen_rounded,
                    size: 22.w,
                    color: colors.textSecondary,
                  ),
                ),
            ],
          ),
          SizedBox(height: 4.h),
          // Legend
          Row(
            children: [
              _LegendDot(color: colors.income, label: l10n.reportIncome),
              SizedBox(width: 12.w),
              _LegendDot(color: colors.expense, label: l10n.reportExpense),
            ],
          ),
          SizedBox(height: 8.h),
          if (dailyTrend.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32.h),
                child: Text(
                  l10n.reportNoTrendData,
                  style: TextStyleConstants.b2.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ReportTrendChart(data: dailyTrend),
        ],
      ),
    );
  }
}

// ───────────────── Insight Section (granular) ─────────────────

class _ReportInsightSection extends ConsumerWidget {
  const _ReportInsightSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final expenseChange = ref.watch(reportExpenseChangeProvider);
    final total = ref.watch(
      reportControllerProvider.select((s) => s.summary.total),
    );

    final String text;
    if (expenseChange < -2) {
      text = l10n.reportInsightExpenseDown(
        expenseChange.abs().toStringAsFixed(0),
      );
    } else if (expenseChange > 2) {
      text = l10n.reportInsightExpenseUp(
        expenseChange.abs().toStringAsFixed(0),
      );
    } else if (total > 0) {
      text = l10n.reportInsightStable;
    } else {
      text = l10n.reportInsightNoData;
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

// ───────────────── Private Widgets ─────────────────

class _BreakdownToggle extends StatelessWidget {
  const _BreakdownToggle({
    required this.current,
    required this.onChanged,
    required this.colors,
  });

  final ReportBreakdownType current;
  final ValueChanged<ReportBreakdownType> onChanged;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleItem(
            label: l10n.reportExpense,
            isSelected: current == ReportBreakdownType.expense,
            onTap: () => onChanged(ReportBreakdownType.expense),
            colors: colors,
          ),
          _ToggleItem(
            label: l10n.reportIncome,
            isSelected: current == ReportBreakdownType.income,
            onTap: () => onChanged(ReportBreakdownType.income),
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  const _ToggleItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7.r),
        ),
        child: Text(
          label,
          style: TextStyleConstants.label3.copyWith(
            color: isSelected ? colors.onPrimary : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

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
