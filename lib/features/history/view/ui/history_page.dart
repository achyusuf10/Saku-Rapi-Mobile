import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/history/controllers/history_controller.dart';
import 'package:app_saku_rapi/features/history/view/widgets/history_filter_sheet.dart';
import 'package:app_saku_rapi/features/history/view/widgets/history_period_selector.dart';
import 'package:app_saku_rapi/features/history/view/widgets/history_transaction_tile.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_empty_state.dart';
import 'package:app_saku_rapi/global/widgets/saku_error_state.dart';
import 'package:app_saku_rapi/global/widgets/saku_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

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
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load data on first open
    Future.microtask(() {
      ref.read(historyControllerProvider.notifier).loadTransactions();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(historyControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _openCustomDateRange() async {
    final historyState = ref.read(historyControllerProvider);
    final (defaultStart, defaultEnd) = historyState.dateRange;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final historyState = ref.watch(historyControllerProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.historyTitle,
          style: TextStyleConstants.h6.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          // Filter button
          IconButton(
            icon: Badge(
              isLabelVisible: _hasActiveFilter(historyState),
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
            child: HistoryPeriodSelector(
              selected: historyState.period,
              onSelected: (period) {
                ref.read(historyControllerProvider.notifier).setPeriod(period);
              },
              onCustomTap: _openCustomDateRange,
              customStart: historyState.customStart,
              customEnd: historyState.customEnd,
            ),
          ),

          // ─── Summary Card ───
          if (historyState.status == HistoryStatus.loaded)
            _SummaryCard(
              income: historyState.totalIncome,
              expense: historyState.totalExpense,
              transactionCount: historyState.filteredTransactions.length,
            ),

          // ─── Content ───
          Expanded(child: _buildBody(historyState)),
        ],
      ),
    );
  }

  bool _hasActiveFilter(HistoryState state) {
    return state.walletId != null || state.typeFilter != null;
  }

  Widget _buildBody(HistoryState historyState) {
    final l10n = context.l10n;

    return switch (historyState.status) {
      HistoryStatus.initial ||
      HistoryStatus.loading => const Center(child: SakuLoadingIndicator()),
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

    // Build a flat list of headers + tiles for efficient sliver rendering
    final items = <_ListItem>[];
    for (final entry in grouped.entries) {
      items.add(_ListItem.header(entry.key, entry.value));
      for (final tx in entry.value) {
        items.add(_ListItem.transaction(tx));
      }
    }

    return RefreshIndicator(
      color: colors.primary,
      onRefresh: () => ref.read(historyControllerProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 80.h),
        itemCount: items.length + (historyState.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading more indicator
          if (index == items.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: const Center(child: SakuLoadingIndicator()),
            );
          }

          final item = items[index];
          if (item.isHeader) {
            return _GroupHeader(
              label: _formatGroupLabel(item.headerKey!, historyState.groupMode),
              total: _groupTotal(item.headerTransactions!),
              transactionCount: item.headerTransactions!.length,
              groupMode: historyState.groupMode,
            );
          }

          return HistoryTransactionTile(
            transaction: item.tx!,
            onTap: () => _navigateToDetail(item.tx!),
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
    double total = 0;
    for (final tx in txs) {
      if (tx.isSettlement) continue;
      if (tx.type == TransactionTypeEnum.income ||
          tx.type == TransactionTypeEnum.debt) {
        total += tx.totalAmount;
      } else if (tx.type == TransactionTypeEnum.expense ||
          tx.type == TransactionTypeEnum.loan) {
        total -= tx.totalAmount;
      }
    }
    return total;
  }
}

// ───────────────── List Item Model ─────────────────

class _ListItem {
  _ListItem.header(this.headerKey, this.headerTransactions)
    : tx = null,
      isHeader = true;

  _ListItem.transaction(this.tx)
    : headerKey = null,
      headerTransactions = null,
      isHeader = false;

  final bool isHeader;
  final String? headerKey;
  final List<TransactionModel>? headerTransactions;
  final TransactionModel? tx;
}

// ───────────────── Summary Card ─────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.income,
    required this.expense,
    required this.transactionCount,
  });

  final double income;
  final double expense;
  final int transactionCount;

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
  });

  final String label;
  final double total;
  final int transactionCount;
  final HistoryGroupMode groupMode;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPositive = total >= 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 4.h),
      child: Row(
        children: [
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
                if (groupMode == HistoryGroupMode.byDate)
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
      ),
    );
  }
}
