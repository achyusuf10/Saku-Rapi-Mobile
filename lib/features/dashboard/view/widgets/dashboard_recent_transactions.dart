import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/category/utils/category_icon_mapper.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Section transaksi terbaru di dashboard.
///
/// Menampilkan 5 transaksi terbaru dengan tap untuk detail.
class DashboardRecentTransactions extends ConsumerWidget {
  const DashboardRecentTransactions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final dashState = ref.watch(dashboardControllerProvider);
    final transactions = dashState.recentTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Header ───
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            l10n.dashboardRecentTransactions,
            style: TextStyleConstants.b1.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // ─── Transaction List ───
        if (transactions.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: SakuCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.h),
                  child: Column(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.receipt,
                        size: 28.w,
                        color: colors.textSecondary.withValues(alpha: 0.4),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        l10n.dashboardEmptyTransactions,
                        style: TextStyleConstants.label1.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: SakuCard(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Column(
                children: [
                  for (int i = 0; i < transactions.length; i++) ...[
                    _TransactionTile(transaction: transactions[i]),
                    if (i < transactions.length - 1)
                      Divider(
                        height: 1,
                        indent: 56.w,
                        color: colors.border.withValues(alpha: 0.5),
                      ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typeColor = _colorForType(transaction.type, colors);
    final isIncoming =
        transaction.type == TransactionTypeEnum.income ||
        transaction.type == TransactionTypeEnum.debt;

    return InkWell(
      onTap: () =>
          context.push(AppRouter.transactionDetail, extra: transaction),
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          children: [
            // ─── Icon ───
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: typeColor.withValues(alpha: 0.12),
              ),
              child: Center(
                child: FaIcon(
                  _iconForTransaction(transaction),
                  size: 16.w,
                  color: typeColor,
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // ─── Details ───
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleForTransaction(transaction),
                    style: TextStyleConstants.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    transaction.date.extToFormattedString(
                      outputDateFormat: 'dd MMM yyyy, HH:mm',
                    ),
                    style: TextStyleConstants.label2.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Amount ───
            Text(
              '${isIncoming ? '+' : '-'} ${transaction.totalAmount.toCurrency(withPrefix: false)}',
              style: TextStyleConstants.b2.copyWith(
                fontWeight: FontWeight.bold,
                color: isIncoming ? colors.income : colors.expense,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleForTransaction(TransactionModel tx) {
    if (tx.categoryName != null) return tx.categoryName!;
    if (tx.merchantName != null) return tx.merchantName!;
    if (tx.withPerson != null) return tx.withPerson!;
    if (tx.type == TransactionTypeEnum.transfer) {
      return '${tx.walletName ?? ''} → ${tx.destinationWalletName ?? ''}';
    }
    if (tx.type == TransactionTypeEnum.adjustment) return 'Adjustment';
    return tx.note ?? tx.type.toDbValue();
  }

  IconData _iconForTransaction(TransactionModel tx) {
    if (tx.categoryIcon != null) {
      return CategoryIconMapper.getIcon(tx.categoryIcon!);
    }
    return switch (tx.type) {
      TransactionTypeEnum.income => FontAwesomeIcons.arrowTrendUp,
      TransactionTypeEnum.expense => FontAwesomeIcons.arrowTrendDown,
      TransactionTypeEnum.transfer => FontAwesomeIcons.arrowRightArrowLeft,
      TransactionTypeEnum.debt => FontAwesomeIcons.handHoldingDollar,
      TransactionTypeEnum.loan => FontAwesomeIcons.handHoldingHand,
      TransactionTypeEnum.adjustment => FontAwesomeIcons.scaleBalanced,
      TransactionTypeEnum.transferToAsset => FontAwesomeIcons.chartLine,
    };
  }

  Color _colorForType(TransactionTypeEnum type, dynamic colors) {
    return switch (type) {
      TransactionTypeEnum.expense => colors.expense,
      TransactionTypeEnum.income => colors.income,
      TransactionTypeEnum.transfer => colors.transfer,
      TransactionTypeEnum.debt => colors.debt,
      TransactionTypeEnum.loan => colors.loan,
      _ => colors.primary,
    };
  }
}
