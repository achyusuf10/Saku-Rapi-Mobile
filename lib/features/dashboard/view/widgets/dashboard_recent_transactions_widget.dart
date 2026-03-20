import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// 3 transaksi terbaru di dashboard.
///
/// Section title "Transaksi Terkini" + tombol "Lihat Semua".
/// Menggunakan inline tile karena TransactionItemTile butuh kategori info
/// yang belum tersedia di TransactionModel header saja.
class DashboardRecentTransactionsWidget extends ConsumerWidget {
  const DashboardRecentTransactionsWidget({super.key});

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
            // ── Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.dashboardRecentTransactions,
                  style: TextStyleConstants.h7.copyWith(
                    fontWeight: FontWeight.w700,
                    color: appColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(AppRouter.history),
                  child: Text(
                    l10n.dashboardSeeAll,
                    style: TextStyleConstants.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: appColors.primary,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // ── List ──
            dashState.when(
              loading: () => _buildSkeleton(appColors),
              error: (_, __) => const SizedBox.shrink(),
              data: (data) {
                if (data.recentTransactions.isEmpty) {
                  return _buildEmptyState(context);
                }
                return Column(
                  children: data.recentTransactions.map((tx) {
                    return _RecentTransactionTile(transaction: tx);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Center(
        child: Column(
          children: [
            FaIcon(
              FontAwesomeIcons.receipt,
              color: appColors.textSecondary.withValues(alpha: 0.4),
              size: 28.r,
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
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Container(
            height: 48.h,
            decoration: BoxDecoration(
              color: appColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tile untuk satu transaksi terbaru.
class _RecentTransactionTile extends StatelessWidget {
  const _RecentTransactionTile({required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final isIncome = transaction.type == 'income';
    final isTransfer = transaction.type == 'transfer';
    final amountColor = _colorForType(appColors);
    final prefix = isIncome ? '+' : (isTransfer ? '' : '-');

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          // ── Icon ──
          Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: FaIcon(_iconForType(), color: amountColor, size: 15.r),
            ),
          ),

          SizedBox(width: 10.w),

          // ── Title + Date ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleForType(context),
                  style: TextStyleConstants.b2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: appColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  transaction.date.extToFormattedString(
                    outputDateFormat: 'dd MMM yyyy',
                  ),
                  style: TextStyleConstants.label3.copyWith(
                    color: appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ── Amount ──
          Text(
            '$prefix${transaction.totalAmount.toCurrency()}',
            style: TextStyleConstants.b2.copyWith(
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType() {
    return switch (transaction.type) {
      'income' => FontAwesomeIcons.arrowDown,
      'expense' => FontAwesomeIcons.arrowUp,
      'transfer' => FontAwesomeIcons.arrowRightArrowLeft,
      'debt' => FontAwesomeIcons.handHoldingDollar,
      'loan' => FontAwesomeIcons.handshake,
      'adjustment' => FontAwesomeIcons.sliders,
      _ => FontAwesomeIcons.receipt,
    };
  }

  Color _colorForType(appColors) {
    return switch (transaction.type) {
      'income' => appColors.income,
      'expense' => appColors.expense,
      'transfer' => appColors.transfer,
      'debt' => appColors.debt,
      'loan' => appColors.loan,
      _ => appColors.textSecondary,
    };
  }

  String _titleForType(BuildContext context) {
    // Tampilkan note/merchant jika ada, fallback ke tipe
    if (transaction.note != null && transaction.note!.isNotEmpty) {
      return transaction.note!;
    }
    if (transaction.merchantName != null &&
        transaction.merchantName!.isNotEmpty) {
      return transaction.merchantName!;
    }
    final l10n = context.l10n;
    return switch (transaction.type) {
      'income' => l10n.dashboardIncomeLabel,
      'expense' => l10n.dashboardExpenseLabel,
      'transfer' => l10n.transactionTransfer,
      'debt' => l10n.transactionDebt,
      'loan' => l10n.transactionLoan,
      _ => l10n.transactionAdjustment,
    };
  }
}
