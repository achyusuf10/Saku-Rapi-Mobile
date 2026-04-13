import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/dashboard/view/widgets/chart_fullscreen_dialog.dart';
import 'package:app_saku_rapi/features/reports/controllers/report_controller.dart';
import 'package:app_saku_rapi/features/reports/models/report_category_transactions_argument.dart';
import 'package:app_saku_rapi/features/reports/models/report_model.dart';
import 'package:app_saku_rapi/features/reports/models/report_page_argument.dart';
import 'package:app_saku_rapi/features/reports/view/widgets/report_category_chart.dart';
import 'package:app_saku_rapi/features/reports/view/widgets/report_category_pie_chart.dart';
import 'package:app_saku_rapi/features/reports/view/widgets/report_shimmer.dart';
import 'package:app_saku_rapi/features/reports/view/widgets/report_summary_card.dart';
import 'package:app_saku_rapi/features/reports/view/widgets/report_trend_chart.dart';
import 'package:app_saku_rapi/global/widgets/saku_card.dart';
import 'package:app_saku_rapi/global/widgets/saku_empty_state.dart';
import 'package:app_saku_rapi/global/widgets/saku_error_state.dart';
import 'package:app_saku_rapi/global/widgets/saku_loading_indicator.dart';
import 'package:app_saku_rapi/global/widgets/saku_period_selector.dart';
import 'package:app_saku_rapi/global/widgets/saku_sub_period_tabs.dart';
import 'package:app_saku_rapi/global/widgets/saku_wallet_filter_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Halaman laporan (Reports & Analytics).
///
/// Menampilkan:
/// - Period selector (harian/mingguan/bulanan/3 bulanan/tahunan/kustom)
/// - Sub-period tabs (navigasi bulan ini / bulan lalu, dsb.)
/// - Wallet filter chip
/// - Income vs Expense summary card
/// - Category breakdown pie chart + list per kategori
/// - Daily income/expense trend bar chart + fullscreen
/// - Smart insight
///
/// Setiap section menggunakan ConsumerWidget terpisah
/// agar hanya rebuild widget yang datanya berubah.
class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key, this.argument});

  /// Argument opsional untuk inisialisasi state awal.
  ///
  /// Jika diberikan, period, sub-period, dan wallet filter akan disamakan
  /// dengan nilai yang dikirim (biasanya dari halaman riwayat).
  final ReportPageArgument? argument;

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();

    // PageController diinisialisasi dari state default dulu.
    // Nilai sesungguhnya (dari argument) diterapkan di microtask setelah build.
    _pageController = PageController();

    Future.microtask(() {
      if (!mounted) return;
      final ctrl = ref.read(reportControllerProvider.notifier);

      // Terapkan argument jika ada (misal dari tombol "Lihat Laporan").
      if (widget.argument != null) {
        ctrl.initializeFrom(widget.argument!);
      }

      final s = ref.read(reportControllerProvider);
      final tabs = s.subPeriodTabs;
      final targetIdx =
          s.subPeriodIndex ?? (tabs.isNotEmpty ? tabs.length - 1 : 0);

      // Sync PageController ke index yang benar.
      if (_pageController.hasClients) {
        _pageController.jumpToPage(targetIdx);
      }

      if (s.subPeriodIndex == null) {
        if (tabs.isNotEmpty) {
          ctrl.setSubPeriod(tabs.length - 1);
          return;
        }
      }
      ctrl.loadReport();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await ref.read(reportControllerProvider.notifier).loadReport();
  }

  Future<void> _openCustomDateRange() async {
    final reportState = ref.read(reportControllerProvider);
    final (defaultStart, defaultEnd) = reportState.dateRange;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: defaultStart, end: defaultEnd),
      helpText: context.l10n.historySelectDateRange,
    );

    if (picked != null) {
      await ref
          .read(reportControllerProvider.notifier)
          .setCustomRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reportState = ref.watch(reportControllerProvider);
    final tabs = reportState.subPeriodTabs;

    // Sync PageController ↔ subPeriodIndex (dari tap tab / period change)
    ref.listen<ReportState>(reportControllerProvider, (prev, next) {
      final prevIdx = prev?.subPeriodIndex;
      final newIdx = next.subPeriodIndex;
      if (prevIdx == newIdx || newIdx == null || !_pageController.hasClients) {
        return;
      }
      if (prev?.period != next.period) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(newIdx);
          }
        });
      } else if (_pageController.page?.round() != newIdx) {
        _pageController.animateToPage(
          newIdx,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    });

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(context.l10n.reportTitle),
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
      body: Column(
        children: [
          // ─── Period Selector ───
          Padding(
            padding: EdgeInsets.only(top: 8.h, bottom: 4.h),
            child: SakuPeriodSelector(
              selected: reportState.period,
              onSelected: (period) =>
                  ref.read(reportControllerProvider.notifier).setPeriod(period),
              onCustomTap: _openCustomDateRange,
              customStart: reportState.customStart,
              customEnd: reportState.customEnd,
            ),
          ),

          // ─── Sub-Period Tabs ───
          SakuSubPeriodTabs(
            tabs: tabs,
            selectedIndex:
                reportState.subPeriodIndex ??
                (tabs.isNotEmpty ? tabs.length - 1 : 0),
            onTabSelected: (index) =>
                ref.read(reportControllerProvider.notifier).setSubPeriod(index),
          ),
          SizedBox(height: 4.h),

          // ─── Swipeable Content ───
          Expanded(
            child: tabs.isEmpty
                ? _buildPage(reportState)
                : PageView.builder(
                    controller: _pageController,
                    itemCount: tabs.length,
                    onPageChanged: (index) => ref
                        .read(reportControllerProvider.notifier)
                        .setSubPeriod(index),
                    itemBuilder: (context, index) => _buildPage(reportState),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(ReportState reportState) {
    final l10n = context.l10n;
    final colors = context.colors;

    return switch (reportState.status) {
      ReportStatus.initial || ReportStatus.loading => const ReportShimmer(),
      ReportStatus.error => Center(
        child: SakuErrorState(
          message: reportState.errorMessage ?? l10n.reportErrorGeneric,
          onRetry: _onRefresh,
        ),
      ),
      ReportStatus.loaded when reportState.summary.total == 0 => SakuEmptyState(
        icon: FontAwesomeIcons.chartPie,
        title: l10n.reportEmptyTitle,
        message: l10n.reportEmptyMessage,
      ),
      _ => RefreshIndicator(
        onRefresh: _onRefresh,
        color: colors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: 24.h),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                child: const _ReportSummarySection(),
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: const _ReportCategorySection(),
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: const _ReportTrendSection(),
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: const _ReportInsightSection(),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    };
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

class _ReportCategorySection extends ConsumerStatefulWidget {
  const _ReportCategorySection();

  @override
  ConsumerState<_ReportCategorySection> createState() =>
      _ReportCategorySectionState();
}

class _ReportCategorySectionState
    extends ConsumerState<_ReportCategorySection> {
  bool _isOthersExpanded = false;

  void _navigateToCategory(
    ReportCategoryBreakdownModel cat,
    String type,
    ReportState state,
  ) {
    final (start, end) = state.dateRange;
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
  }

  @override
  Widget build(BuildContext context) {
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

    final type = breakdownType == ReportBreakdownType.expense
        ? 'expense'
        : 'income';
    final othersEntry = categories
        .where((c) => c.categoryId == '__others__')
        .firstOrNull;

    return SakuCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.chartPie,
                size: 15.w,
                color: colors.primary,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  l10n.reportCategoryBreakdown,
                  style: TextStyleConstants.b2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              _BreakdownToggle(
                current: breakdownType,
                onChanged: (type) {
                  setState(() => _isOthersExpanded = false);
                  ref
                      .read(reportControllerProvider.notifier)
                      .setBreakdownType(type);
                },
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
          else ...[
            ReportCategoryPieChart(categories: categories, total: total),
            SizedBox(height: 12.h),
            ReportCategoryChart(
              categories: categories,
              total: total,
              isOthersExpanded: _isOthersExpanded,
              onCategoryTap: (cat) {
                if (cat.categoryId == '__others__') {
                  setState(() => _isOthersExpanded = !_isOthersExpanded);
                  return;
                }
                _navigateToCategory(
                  cat,
                  type,
                  ref.read(reportControllerProvider),
                );
              },
            ),
            if (othersEntry != null)
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _isOthersExpanded
                    ? Padding(
                        padding: EdgeInsets.only(top: 12.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(height: 1, color: colors.border),
                            SizedBox(height: 12.h),
                            ReportCategoryChart(
                              categories: othersEntry.otherItems,
                              total: total,
                              onCategoryTap: (cat) => _navigateToCategory(
                                cat,
                                type,
                                ref.read(reportControllerProvider),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
          ],
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
                    final chartWidget = ReportTrendChart.buildChart(
                      data: dailyTrend,
                      colors: colors,
                      isDark: isDark,
                    );

                    ChartFullscreenDialog.show(
                      context,
                      title: l10n.reportDailyTrend,
                      chartWidget: chartWidget,
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
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: colors.border),
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
                color: colors.textPrimary,
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
        color: colors.surfaceVariant,
        border: Border.all(color: colors.border),
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
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(7.r),
        ),
        child: Text(
          label,
          style: TextStyleConstants.label3.copyWith(
            color: isSelected ? colors.onPrimary : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
