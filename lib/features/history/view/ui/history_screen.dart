import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/history/controllers/history_controller.dart';
import 'package:app_saku_rapi/features/history/view/widgets/history_donut_chart_widget.dart';
import 'package:app_saku_rapi/features/history/view/widgets/history_filter_sheet.dart';
import 'package:app_saku_rapi/features/history/view/widgets/history_period_header.dart';
import 'package:app_saku_rapi/features/history/view/widgets/history_summary_bar.dart';
import 'package:app_saku_rapi/features/history/view/widgets/history_transaction_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Layar history utama dengan navigasi periode, tab list/report.
///
/// Layout:
/// - [HistoryPeriodHeader]: navigasi < bulan >
/// - [HistorySummaryBar]: total in / out
/// - TabBar: Transaksi | Laporan
/// - TabBarView: List View & Report View
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final mode = _tabController.index == 0
            ? HistoryViewMode.listView
            : HistoryViewMode.reportView;
        ref.read(historyControllerProvider.notifier).setViewMode(mode);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: appColors.background,
      appBar: AppBar(
        backgroundColor: appColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.historyTitle,
          style: TextStyleConstants.h7.copyWith(
            fontWeight: FontWeight.w700,
            color: appColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Period Header ──
          const HistoryPeriodHeader(),

          SizedBox(height: 8.h),

          // ── Summary Bar ──
          const HistorySummaryBar(),

          SizedBox(height: 16.h),

          // ── Tab Bar ──
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: appColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: appColors.primary,
                borderRadius: BorderRadius.circular(10.r),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: appColors.onPrimary,
              unselectedLabelColor: appColors.textSecondary,
              labelStyle: TextStyleConstants.b2.copyWith(
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: TextStyleConstants.b2.copyWith(
                fontWeight: FontWeight.w500,
              ),
              padding: EdgeInsets.all(3.r),
              tabs: [
                Tab(text: l10n.historyTabTransactions),
                Tab(text: l10n.historyTabReport),
              ],
            ),
          ),

          SizedBox(height: 8.h),

          // ── Tab Bar View ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_ListViewTab(), _ReportViewTab()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab 1 — List View: filter + grouped transactions + pagination.
class _ListViewTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.colors;
    final l10n = context.l10n;
    final historyState = ref.watch(historyControllerProvider);

    if (historyState.isLoading) {
      return Center(child: CircularProgressIndicator(color: appColors.primary));
    }

    return Column(
      children: [
        // ── Filter Button ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const HistoryFilterSheet(),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: historyState.filterWalletId != null
                        ? appColors.primary.withValues(alpha: 0.1)
                        : appColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: historyState.filterWalletId != null
                          ? appColors.primary.withValues(alpha: 0.3)
                          : appColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.filter,
                        size: 12.r,
                        color: historyState.filterWalletId != null
                            ? appColors.primary
                            : appColors.textSecondary,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        l10n.historyFilter,
                        style: TextStyleConstants.label2.copyWith(
                          fontWeight: FontWeight.w600,
                          color: historyState.filterWalletId != null
                              ? appColors.primary
                              : appColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Transaction Groups ──
        Expanded(
          child: historyState.transactionGroups.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: EdgeInsets.only(bottom: 80.h),
                  itemCount:
                      historyState.transactionGroups.length +
                      (historyState.hasMoreData ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Pagination trigger
                    if (index == historyState.transactionGroups.length) {
                      return VisibilityDetector(
                        key: const Key('history-load-more'),
                        onVisibilityChanged: (info) {
                          if (info.visibleFraction > 0) {
                            ref
                                .read(historyControllerProvider.notifier)
                                .loadMoreData();
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          child: Center(
                            child: historyState.isLoadingMore
                                ? SizedBox(
                                    width: 24.r,
                                    height: 24.r,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: appColors.primary,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      );
                    }

                    return HistoryTransactionGroup(
                      group: historyState.transactionGroups[index],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            FontAwesomeIcons.receipt,
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
    );
  }
}

/// Tab 2 — Report View: Donut chart + category legend.
class _ReportViewTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 80.h),
      child: const HistoryDonutChartWidget(),
    );
  }
}
