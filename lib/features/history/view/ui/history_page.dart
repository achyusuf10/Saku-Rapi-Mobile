import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/core/utils/color_utils.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:app_saku_rapi/features/history/controllers/history_controller.dart';
import 'package:app_saku_rapi/features/history/view/widgets/history_filter_sheet.dart';
import 'package:app_saku_rapi/features/history/view/widgets/history_shimmer.dart';
import 'package:app_saku_rapi/features/history/view/widgets/history_transaction_tile.dart';
import 'package:app_saku_rapi/features/reports/models/report_page_argument.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/global/widgets/saku_category_icon.dart';
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
import 'package:visibility_detector/visibility_detector.dart';

/// Halaman riwayat transaksi (tab kedua bottom nav).
///
/// Features:
/// - Period selector (harian/mingguan/bulanan/3 bulanan/tahunan/kustom)
/// - Summary card (total pemasukan & pengeluaran)
/// - Grouped transaction list (by date / by category)
/// - Infinite scroll pagination
/// - Filter bottom sheet (wallet, type, grouping)
/// - Custom date range picker
/// - Empty/loading/error states
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final s = ref.read(historyControllerProvider);
    final tabs = s.subPeriodTabs;
    final initialIdx =
        s.subPeriodIndex ?? (tabs.isNotEmpty ? tabs.length - 1 : 0);
    _pageController = PageController(initialPage: initialIdx);

    Future.microtask(() {
      final ctrl = ref.read(historyControllerProvider.notifier);
      final s = ref.read(historyControllerProvider);
      if (s.subPeriodIndex == null) {
        final tabs = s.subPeriodTabs;
        if (tabs.isNotEmpty) {
          ctrl.setSubPeriod(tabs.length - 1);
          return;
        }
      }
      ctrl.loadTransactions();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openCustomDateRange() async {
    final historyState = ref.read(historyControllerProvider);
    final (defaultStart, defaultEnd) = historyState.dateRange;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: defaultStart, end: defaultEnd),
      helpText: context.l10n.historySelectDateRange,
    );

    if (picked != null) {
      await ref
          .read(historyControllerProvider.notifier)
          .setCustomRange(picked.start, picked.end);
    }
  }

  Future<void> _navigateToDetail(TransactionModel tx) async {
    final result = await context.push<bool>(
      AppRouter.transactionDetail,
      extra: tx,
    );
    // Refresh if detail page signaled a change (edit/delete)
    if (result == true && mounted) {
      await ref.read(historyControllerProvider.notifier).refresh();
      ref.read(dashboardControllerProvider.notifier).loadDashboard();
      ref.read(walletControllerProvider.notifier).loadWallets();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final historyState = ref.watch(historyControllerProvider);
    final tabs = historyState.subPeriodTabs;

    // Sync PageController ↔ subPeriodIndex (dari tap tab / period change)
    ref.listen<HistoryState>(historyControllerProvider, (prev, next) {
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
        title: Text(l10n.historyTitle),
        centerTitle: false,
        actions: [
          // Wallet filter popup
          SakuWalletFilterButton(
            selectedWalletId: historyState.walletId,
            onSelected: (walletId) {
              ref
                  .read(historyControllerProvider.notifier)
                  .setWalletFilter(walletId);
            },
          ),
          // Filter button
          IconButton(
            icon: Badge(
              isLabelVisible: historyState.typeFilter != null,
              smallSize: 8.w,
              child: FaIcon(FontAwesomeIcons.filter, size: 16.w),
            ),
            onPressed: () => showHistoryFilterSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Period Selector ───
          Padding(
            padding: EdgeInsets.only(top: 8.h, bottom: 4.h),
            child: SakuPeriodSelector(
              selected: historyState.period,
              onSelected: (period) {
                ref.read(historyControllerProvider.notifier).setPeriod(period);
              },
              onCustomTap: _openCustomDateRange,
              customStart: historyState.customStart,
              customEnd: historyState.customEnd,
            ),
          ),

          // ─── Sub-Period Tabs ───
          SakuSubPeriodTabs(
            tabs: tabs,
            selectedIndex:
                historyState.subPeriodIndex ??
                (tabs.isNotEmpty ? tabs.length - 1 : 0),
            onTabSelected: (index) {
              ref.read(historyControllerProvider.notifier).setSubPeriod(index);
            },
          ),

          // ─── Swipeable Content ───
          Expanded(
            child: tabs.isEmpty
                ? _buildPage(historyState)
                : PageView.builder(
                    controller: _pageController,
                    itemCount: tabs.length,
                    onPageChanged: (index) {
                      ref
                          .read(historyControllerProvider.notifier)
                          .setSubPeriod(index);
                    },
                    itemBuilder: (context, index) {
                      return _buildPage(historyState);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(HistoryState historyState) {
    return Column(
      children: [
        // ─── Summary Card ───
        if (historyState.status == HistoryStatus.loaded)
          _SummaryCard(
            income: historyState.totalIncome,
            expense: historyState.totalExpense,
            transactionCount: historyState.filteredTransactions.length,
            onViewReport: () {
              context.push(
                AppRouter.reports,
                extra: ReportPageArgument(
                  period: historyState.period,
                  subPeriodIndex: historyState.subPeriodIndex,
                  walletId: historyState.walletId,
                ),
              );
            },
          ),

        // ─── Body ───
        Expanded(child: _buildBody(historyState)),
      ],
    );
  }

  Widget _buildBody(HistoryState historyState) {
    final l10n = context.l10n;

    return switch (historyState.status) {
      HistoryStatus.initial ||
      HistoryStatus.loading => const HistoryShimmer(),
      HistoryStatus.error => Center(
        child: SakuErrorState(
          message: historyState.errorMessage ?? '',
          onRetry: () =>
              ref.read(historyControllerProvider.notifier).loadTransactions(),
        ),
      ),
      HistoryStatus.loaded =>
        historyState.filteredTransactions.isEmpty
            ? Center(
                child: SakuEmptyState(
                  icon: FontAwesomeIcons.clockRotateLeft,
                  title: l10n.historyNoTransactions,
                  message: l10n.historyFilterEmpty,
                ),
              )
            : _buildGroupedList(historyState),
    };
  }

  Widget _buildGroupedList(HistoryState historyState) {
    final colors = context.colors;

    final grouped = historyState.groupMode == HistoryGroupMode.byDate
        ? historyState.groupedByDate
        : historyState.groupedByCategory;

    // Build section-based list: each group = header + card with tiles
    final sections = grouped.entries.toList();

    return RefreshIndicator(
      color: colors.primary,
      onRefresh: () => ref.read(historyControllerProvider.notifier).refresh(),
      child: ListView.separated(
        separatorBuilder: (context, index) => 12.verticalSpace,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 80.h),
        itemCount: sections.length + 1,
        itemBuilder: (context, index) {
          // Last slot: load-more trigger or loading indicator
          if (index == sections.length) {
            if (historyState.isLoadingMore) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: const Center(child: SakuLoadingIndicator()),
              );
            }
            if (!historyState.hasMore) {
              return const SizedBox.shrink();
            }
            return VisibilityDetector(
              key: const Key('history_load_more_trigger'),
              onVisibilityChanged: (info) {
                if (info.visibleFraction > 0) {
                  ref.read(historyControllerProvider.notifier).loadMore();
                }
              },
              child: const SizedBox(height: 1),
            );
          }

          final entry = sections[index];
          final txList = entry.value;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              16.w,
              index == 0 ? 4.h : 12.h,
              16.w,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Group Header ───
                _GroupHeader(
                  label: _formatGroupLabel(entry.key, historyState.groupMode),
                  total: _groupTotal(txList),
                  transactionCount: txList.length,
                  groupMode: historyState.groupMode,
                  firstTransaction: txList.first,
                ),
                SizedBox(height: 6.h),
                // ─── Transaction Card ───
                Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < txList.length; i++) ...[
                        HistoryTransactionTile(
                          transaction: txList[i],
                          groupMode: historyState.groupMode,
                          onTap: () => _navigateToDetail(txList[i]),
                        ),
                        if (i < txList.length - 1)
                          Divider(
                            height: 1,
                            indent:
                                historyState.groupMode ==
                                    HistoryGroupMode.byCategory
                                ? 16.w
                                : 70.w,
                            color: colors.border.withValues(alpha: 0.3),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatGroupLabel(String key, HistoryGroupMode mode) {
    if (mode == HistoryGroupMode.byCategory) return key;

    // key is 'YYYY-MM-DD'
    try {
      final date = DateTime.parse(key);
      return date.extToDateStringDDMMMMYYYY();
    } catch (_) {
      return key;
    }
  }

  double _groupTotal(List<TransactionModel> txs) {
    return HistoryState.groupNetTotal(txs);
  }
}

// ───────────────── Summary Card ─────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.income,
    required this.expense,
    required this.transactionCount,
    required this.onViewReport,
  });

  final double income;
  final double expense;
  final int transactionCount;

  /// Callback saat tombol "Lihat Laporan" ditekan.
  final VoidCallback onViewReport;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Income
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.income.withValues(alpha: 0.1),
                        ),
                        child: Center(
                          child: FaIcon(
                            FontAwesomeIcons.arrowTrendUp,
                            size: 12.w,
                            color: colors.income,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.historyTotalIn,
                              style: TextStyleConstants.label3.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                            Text(
                              income.toCompactCurrency(),
                              style: TextStyleConstants.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.income,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 36.h,
                  color: colors.border.withValues(alpha: 0.3),
                ),
                SizedBox(width: 12.w),
                // Expense
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.expense.withValues(alpha: 0.1),
                        ),
                        child: Center(
                          child: FaIcon(
                            FontAwesomeIcons.arrowTrendDown,
                            size: 12.w,
                            color: colors.expense,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.historyTotalOut,
                              style: TextStyleConstants.label3.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                            Text(
                              expense.toCompactCurrency(),
                              style: TextStyleConstants.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.expense,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            // Transaction count
            Text(
              l10n.historyTransactionCount(transactionCount),
              style: TextStyleConstants.label3.copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            // ─── View Report Button ───
            GestureDetector(
              onTap: onViewReport,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.chartPie,
                      size: 11.w,
                      color: colors.primary,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      l10n.historyViewReport,
                      style: TextStyleConstants.label3.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────── Group Header ─────────────────

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.label,
    required this.total,
    required this.transactionCount,
    required this.groupMode,
    this.firstTransaction,
  });

  final String label;
  final double total;
  final int transactionCount;
  final HistoryGroupMode groupMode;
  final TransactionModel? firstTransaction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPositive = total >= 0;
    final isByCategory = groupMode == HistoryGroupMode.byCategory;

    return Row(
      children: [
        // ─── Category Icon (only in byCategory mode) ───
        if (isByCategory && firstTransaction != null) ...[
          Builder(
            builder: (_) {
              final iconColor = _resolveIconColor(firstTransaction!, colors);
              return Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: _buildTxIcon(firstTransaction!, iconColor),
                ),
              );
            },
          ),
          SizedBox(width: 10.w),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyleConstants.label1.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                '$transactionCount transaksi',
                style: TextStyleConstants.label3.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${isPositive ? '+' : ''}${total.toCompactCurrency()}',
          style: TextStyleConstants.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: isPositive ? colors.income : colors.expense,
          ),
        ),
      ],
    );
  }

  Widget _buildTxIcon(TransactionModel tx, Color fallbackColor) {
    if (tx.categoryIcon != null) {
      return SakuCategoryIcon.withColor(
        iconName: tx.categoryIcon!,
        color: fallbackColor,
        size: 14,
        showBackground: false,
      );
    }
    final iconData = switch (tx.type) {
      TransactionTypeEnum.income => FontAwesomeIcons.arrowTrendUp,
      TransactionTypeEnum.expense => FontAwesomeIcons.arrowTrendDown,
      TransactionTypeEnum.transfer => FontAwesomeIcons.arrowRightArrowLeft,
      TransactionTypeEnum.debt => FontAwesomeIcons.handHoldingDollar,
      TransactionTypeEnum.loan => FontAwesomeIcons.handHoldingHand,
      TransactionTypeEnum.adjustment => FontAwesomeIcons.scaleBalanced,
      TransactionTypeEnum.transferToAsset => FontAwesomeIcons.chartLine,
    };
    return FaIcon(iconData, size: 14.w, color: fallbackColor);
  }

  Color _resolveIconColor(TransactionModel tx, dynamic colors) {
    if (tx.categoryColor != null && tx.categoryColor!.isNotEmpty) {
      return parseHexColor(tx.categoryColor!);
    }
    return _typeColor(tx.type, colors);
  }

  Color _typeColor(TransactionTypeEnum type, dynamic colors) {
    return switch (type) {
      TransactionTypeEnum.expense => colors.expense as Color,
      TransactionTypeEnum.income => colors.income as Color,
      TransactionTypeEnum.transfer => colors.transfer as Color,
      TransactionTypeEnum.debt => colors.debt as Color,
      TransactionTypeEnum.loan => colors.loan as Color,
      _ => colors.primary as Color,
    };
  }
}
