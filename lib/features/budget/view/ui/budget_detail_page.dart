import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/utils/color_utils.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/budget/controllers/budget_controller.dart';
import 'package:app_saku_rapi/features/budget/models/budget_model.dart';
import 'package:app_saku_rapi/features/budget/view/widgets/budget_progress_bar.dart';
import 'package:app_saku_rapi/features/history/view/widgets/history_transaction_tile.dart';
import 'package:app_saku_rapi/global/widgets/saku_category_icon.dart';
import 'package:app_saku_rapi/global/widgets/shimmer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Halaman detail budget.
///
/// Menampilkan informasi lengkap budget: kategori, nominal, progress,
/// statistik harian, dan daftar transaksi terkait.
class BudgetDetailPage extends ConsumerStatefulWidget {
  const BudgetDetailPage({super.key, required this.budget});

  final BudgetModel budget;

  @override
  ConsumerState<BudgetDetailPage> createState() => _BudgetDetailPageState();
}

class _BudgetDetailPageState extends ConsumerState<BudgetDetailPage> {
  late BudgetModel _budget;

  @override
  void initState() {
    super.initState();
    _budget = widget.budget;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.budgetDetailTitle),
        centerTitle: false,
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.penToSquare, size: 18.w),
            onPressed: () => _onEdit(context),
          ),
          IconButton(
            icon: FaIcon(
              FontAwesomeIcons.trashCan,
              size: 18.w,
              color: colors.error,
            ),
            onPressed: () => _onDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        children: [
          SizedBox(height: 8.h),
          _buildHeader(context),
          SizedBox(height: 20.h),
          _buildProgressSection(context),
          SizedBox(height: 20.h),
          _buildInfoSection(context),
          SizedBox(height: 20.h),
          _buildStatsSection(context),
          SizedBox(height: 24.h),
          _buildTransactionSection(context),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  // ───────────────── Header: Icon + Name + Amount ─────────────────

  Widget _buildHeader(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        SakuCategoryIcon(
          iconName: _budget.category?.icon ?? 'circleQuestion',
          color: parseHexColor(_budget.category?.color ?? '#6B7280'),
          size: 52,
          iconSize: 22,
          borderRadius: 14,
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _budget.category?.name ?? '-',
                style: TextStyleConstants.h6.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                _budget.amount.toCurrency(),
                style: TextStyleConstants.b1.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────────── Progress: Spent + Remaining + Bar ─────────────────

  Widget _buildProgressSection(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final ratio = _budget.usageRatio;
    final statusColor = BudgetProgressBar.colorForRatio(ratio, context);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colors.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          // Spent vs Remaining
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.budgetDetailSpent,
                      style: TextStyleConstants.label2.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _budget.usedAmount.toCurrency(),
                      style: TextStyleConstants.h7.copyWith(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.budgetDetailRemaining,
                      style: TextStyleConstants.label2.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _budget.remaining.toCurrency(),
                      style: TextStyleConstants.h7.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.income,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Progress bar with "Hari ini" label
          Stack(
            clipBehavior: Clip.none,
            children: [
              BudgetProgressBar(
                ratio: ratio,
                expectedRatio: _budget.expectedRatio,
              ),
              if (_budget.expectedRatio > 0)
                Positioned(
                  top: -14.h,
                  left: 0,
                  right: 0,
                  height: 14.h,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final markerLeft =
                          constraints.maxWidth *
                          _budget.expectedRatio.clamp(0.0, 1.0);
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: markerLeft - 18.w,
                            child: Text(
                              l10n.budgetToday,
                              style: TextStyleConstants.label3.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
          SizedBox(height: 4.h),

          // Percentage
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_budget.usagePercent.toStringAsFixed(0)}%',
              style: TextStyleConstants.label2.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── Info: Date range, days, wallet ─────────────────

  Widget _buildInfoSection(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colors.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: FontAwesomeIcons.calendarDays,
            label: l10n.budgetDetailPeriod,
            value:
                '${_budget.startDate.extToFormattedString(outputDateFormat: 'dd/MM')} - ${_budget.endDate.extToFormattedString(outputDateFormat: 'dd/MM')}',
          ),
          SizedBox(height: 12.h),
          _InfoRow(
            icon: FontAwesomeIcons.clock,
            label: l10n.budgetDetailDaysLeft,
            value: _budget.daysRemaining == 0
                ? l10n.budgetToday
                : l10n.budgetDaysRemaining(_budget.daysRemaining),
          ),
          SizedBox(height: 12.h),
          _InfoRow(
            icon: FontAwesomeIcons.wallet,
            label: l10n.budgetDetailWallet,
            value: _budget.wallet?.name ?? l10n.budgetAllWallets,
          ),
        ],
      ),
    );
  }

  // ───────────────── Stats: Daily recommended, projected, actual ─────────────────

  Widget _buildStatsSection(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    final totalDays = _budget.totalDays;
    final dailyRecommended = totalDays > 0 ? _budget.amount / totalDays : 0.0;

    // Elapsed days (min 1 to avoid division by zero)
    final elapsed = totalDays - _budget.daysRemaining;
    final elapsedDays = elapsed > 0 ? elapsed : 1;
    final actualDaily = elapsedDays > 0
        ? _budget.usedAmount / elapsedDays
        : 0.0;
    final projectedSpend = actualDaily * totalDays;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colors.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: FontAwesomeIcons.scaleBalanced,
            label: l10n.budgetDetailDailyRecommended,
            value: dailyRecommended.toCurrency(),
          ),
          SizedBox(height: 12.h),
          _InfoRow(
            icon: FontAwesomeIcons.chartLine,
            label: l10n.budgetDetailProjectedSpend,
            value: projectedSpend.toCurrency(),
            valueColor: projectedSpend > _budget.amount ? colors.error : null,
          ),
          SizedBox(height: 12.h),
          _InfoRow(
            icon: FontAwesomeIcons.receipt,
            label: l10n.budgetDetailActualDaily,
            value: actualDaily.toCurrency(),
            valueColor: actualDaily > dailyRecommended ? colors.warning : null,
          ),
        ],
      ),
    );
  }

  // ───────────────── Transaction list ─────────────────

  Widget _buildTransactionSection(BuildContext context) {
    final detailState = ref.watch(budgetDetailControllerProvider(_budget));
    final colors = context.colors;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.budgetDetailTransactions,
          style: TextStyleConstants.h7.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        if (detailState.isLoading)
          ...List.generate(
            3,
            (_) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: ShimmerWidget.box(
                width: double.infinity,
                height: 60.h,
                radius: 12,
              ),
            ),
          )
        else if (detailState.transactions.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Text(
                l10n.budgetDetailTransactionsEmpty,
                style: TextStyleConstants.b2.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: detailState.transactions.length,
            separatorBuilder: (_, _) => SizedBox(height: 4.h),
            itemBuilder: (_, i) {
              final tx = detailState.transactions[i];
              return HistoryTransactionTile(
                transaction: tx,
                onTap: () =>
                    context.push(AppRouter.transactionDetail, extra: tx),
              );
            },
          ),
      ],
    );
  }

  // ───────────────── Actions ─────────────────

  Future<void> _onEdit(BuildContext context) async {
    final result = await context.push<Map<String, dynamic>>(
      AppRouter.budgetForm,
      extra: <String, dynamic>{'budget': _budget},
    );
    if (result == null || !context.mounted) return;

    final l10n = context.l10n;
    final controller = ref.read(budgetControllerProvider.notifier);
    final categoryId = result['categoryId'] as String;
    final walletId = result['walletId'] as String?;
    final amount = result['amount'] as double;
    final startDate = result['startDate'] as DateTime;
    final endDate = result['endDate'] as DateTime;
    final isRecurring = result['isRecurring'] as bool? ?? false;
    final periodType =
        result['periodType'] as BudgetPeriodType? ?? BudgetPeriodType.monthly;
    final carryForward = result['carryForward'] as bool? ?? false;

    // Check for duplicates (exclude self)
    final duplicateId = await controller.findDuplicateBudgetId(
      categoryId: categoryId,
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
      excludeBudgetId: _budget.id,
    );

    if (!context.mounted) return;

    if (duplicateId != null) {
      final categoryName = result['categoryName'] as String? ?? '';
      final walletName =
          result['walletName'] as String? ?? l10n.budgetFilterAll;

      final confirmed = await context.showConfirmDialog(
        title: l10n.budgetDuplicateTitle,
        message: l10n.budgetDuplicateMessage(categoryName, walletName),
        confirmLabel: l10n.budgetDuplicateReplace,
        cancelLabel: l10n.budgetDuplicateKeep,
      );

      if (confirmed != true || !context.mounted) return;

      final deleteResult = await controller.deleteBudget(duplicateId);
      if (!context.mounted) return;
      if (!deleteResult.isSuccess()) {
        final (message, _, _, _) = deleteResult.dataError()!;
        context.showAppAlert(message, alertType: AlertTypeEnum.error);
        return;
      }
    }

    final updateResult = await controller.updateBudget(
      existing: _budget,
      categoryId: categoryId,
      walletId: walletId,
      amount: amount,
      startDate: startDate,
      endDate: endDate,
      isRecurring: isRecurring,
      periodType: periodType,
      carryForward: carryForward,
    );

    if (!context.mounted) return;
    if (updateResult.isSuccess()) {
      // Update local state so detail page reflects changes immediately
      setState(() => _budget = updateResult.dataSuccess()!);
      context.showAppAlert(
        l10n.budgetSuccessEdit,
        alertType: AlertTypeEnum.success,
      );
      // Refresh budget list in background
      await controller.loadBudgets();
    } else {
      final (message, _, _, _) = updateResult.dataError()!;
      context.showAppAlert(message, alertType: AlertTypeEnum.error);
    }
  }

  Future<void> _onDelete(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await context.showConfirmDialog(
      title: l10n.budgetDeleteConfirmTitle,
      message: l10n.budgetDeleteConfirmMessage(_budget.category?.name ?? '-'),
      confirmLabel: l10n.budgetDeleteConfirmTitle,
      cancelLabel: l10n.budgetCancel,
    );
    if (confirmed == true && context.mounted) {
      final controller = ref.read(budgetControllerProvider.notifier);
      final result = await controller.deleteBudget(_budget.id);
      if (result.isSuccess() && context.mounted) {
        context.showAppAlert(l10n.budgetSuccessDelete);
        Navigator.of(context).pop();
      }
    }
  }
}

// ───────────────── Info Row ─────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        FaIcon(icon, size: 14.w, color: colors.textSecondary),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            label,
            style: TextStyleConstants.b2.copyWith(color: colors.textSecondary),
          ),
        ),
        Text(
          value,
          style: TextStyleConstants.b2.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
