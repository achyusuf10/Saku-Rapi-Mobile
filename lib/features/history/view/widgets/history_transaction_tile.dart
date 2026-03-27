import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/settlement_kind_enum.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/category/utils/category_icon_mapper.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Tile untuk satu transaksi di history list.
///
/// Menampilkan icon kategori, nama, tanggal, dan jumlah.
/// Tap untuk navigasi ke detail.
class HistoryTransactionTile extends StatelessWidget {
  const HistoryTransactionTile({
    super.key,
    required this.transaction,
    required this.onTap,
    this.onLongPress,
  });

  final TransactionModel transaction;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typeColor = _colorForType(transaction.type, colors);
    final isIncoming =
        transaction.type == TransactionTypeEnum.income ||
        transaction.type == TransactionTypeEnum.debt;
    AppLogger.call(
      'Building HistoryTransactionTile for transaction ${transaction.id} of type ${transaction.type} with isIncoming=$isIncoming',
    );

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Row(
          children: [
            // ─── Category Icon ───
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: typeColor.withValues(alpha: 0.1),
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

            // ─── Title + Subtitle ───
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleForTransaction(transaction, context),
                    style: TextStyleConstants.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      if (transaction.walletName != null) ...[
                        FaIcon(
                          FontAwesomeIcons.wallet,
                          size: 9.w,
                          color: colors.textSecondary.withValues(alpha: 0.6),
                        ),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            transaction.walletName!,
                            style: TextStyleConstants.label3.copyWith(
                              color: colors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                      ],
                      Text(
                        transaction.date.extToFormattedString(
                          outputDateFormat: 'HH:mm',
                        ),
                        style: TextStyleConstants.label3.copyWith(
                          color: colors.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),

            // ─── Amount ───
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncoming ? '+' : '-'} ${transaction.totalAmount.toCurrency(withPrefix: false)}',
                  style: TextStyleConstants.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isIncoming ? colors.income : colors.expense,
                  ),
                ),
                if (transaction.isMultiItem)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        '${transaction.items.length} items',
                        style: TextStyleConstants.label3.copyWith(
                          color: colors.primary,
                          fontSize: 9.sp,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _titleForTransaction(TransactionModel tx, BuildContext context) {
    final l10n = context.l10n;
    if (tx.categoryName != null) return tx.categoryName!;
    if (tx.merchantName != null) return tx.merchantName!;

    final person = tx.withPerson;

    // Settlement transactions — show contextual title with person name.
    if (tx.settlementKind == SettlementKindEnum.debtPayment) {
      return person != null
          ? l10n.debtLoanTitlePayment(person)
          : l10n.debtLoanRepayment;
    }
    if (tx.settlementKind == SettlementKindEnum.loanCollection) {
      return person != null
          ? l10n.debtLoanTitleReceipt(person)
          : l10n.debtLoanCollection;
    }

    // Original debt/loan transactions.
    if (tx.type == TransactionTypeEnum.debt && person != null) {
      return l10n.debtLoanTitleDebt(person);
    }
    if (tx.type == TransactionTypeEnum.loan && person != null) {
      return l10n.debtLoanTitleLoan(person);
    }

    // Fallback for other types.
    if (person != null) return person;
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
      TransactionTypeEnum.expense => colors.expense as Color,
      TransactionTypeEnum.income => colors.income as Color,
      TransactionTypeEnum.transfer => colors.transfer as Color,
      TransactionTypeEnum.debt => colors.debt as Color,
      TransactionTypeEnum.loan => colors.loan as Color,
      _ => colors.primary as Color,
    };
  }
}
