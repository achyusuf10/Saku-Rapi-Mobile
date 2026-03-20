import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/history/models/transaction_group_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Group header (tanggal + ringkasan harian) beserta list transaksi.
///
/// Setiap group menampilkan:
/// - Header: tanggal (format "dd MMMM yyyy") + total income/expense hari itu
/// - List: daftar transaksi intra-hari
class HistoryTransactionGroup extends StatelessWidget {
  const HistoryTransactionGroup({super.key, required this.group});

  final TransactionGroupModel group;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Group Header ──
        _GroupHeader(group: group),

        // ── Transaksi ──
        ...group.transactions.map((tx) {
          return _HistoryTxTile(transaction: tx);
        }),

        // ── Divider ──
        Divider(
          height: 1.h,
          thickness: 0.5,
          color: appColors.border.withValues(alpha: 0.4),
          indent: 16.w,
          endIndent: 16.w,
        ),

        SizedBox(height: 8.h),
      ],
    );
  }
}

/// Header grup tanggal dengan ringkasan harian.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final TransactionGroupModel group;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;

    // Format tanggal: Today, Yesterday, atau dd MMMM yyyy
    String dateLabel;
    if (group.date.extIsToday) {
      dateLabel = l10n.today;
    } else if (group.date.extIsYesterday) {
      dateLabel = l10n.yesterday;
    } else {
      dateLabel = group.date.extToDateStringDDMMMMYYYY();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateLabel,
            style: TextStyleConstants.b2.copyWith(
              fontWeight: FontWeight.w700,
              color: appColors.textPrimary,
            ),
          ),
          Row(
            children: [
              if (group.totalIncome > 0) ...[
                Text(
                  '+${group.totalIncome.toCompactCurrency(withPrefix: false)}',
                  style: TextStyleConstants.label3.copyWith(
                    fontWeight: FontWeight.w600,
                    color: appColors.income,
                  ),
                ),
                SizedBox(width: 8.w),
              ],
              if (group.totalExpense > 0)
                Text(
                  '-${group.totalExpense.toCompactCurrency(withPrefix: false)}',
                  style: TextStyleConstants.label3.copyWith(
                    fontWeight: FontWeight.w600,
                    color: appColors.expense,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tile simple per transaksi di history list.
class _HistoryTxTile extends StatelessWidget {
  const _HistoryTxTile({required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final amountColor = _colorForType(appColors);
    final isIncome = transaction.type == 'income';
    final isTransfer = transaction.type == 'transfer';
    final prefix = isIncome ? '+' : (isTransfer ? '' : '-');

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
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

          // ── Title + Subtitle ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(context),
                  style: TextStyleConstants.b2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: appColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  transaction.date.extToTimeString(),
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

  String _title(BuildContext context) {
    if (transaction.note != null && transaction.note!.isNotEmpty) {
      return transaction.note!;
    }
    if (transaction.merchantName != null &&
        transaction.merchantName!.isNotEmpty) {
      return transaction.merchantName!;
    }
    return _typeLabel(context);
  }

  String _typeLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (transaction.type) {
      'income' => l10n.transactionIncome,
      'expense' => l10n.transactionExpense,
      'transfer' => l10n.transactionTransfer,
      'debt' => l10n.transactionDebt,
      'loan' => l10n.transactionLoan,
      'adjustment' => l10n.transactionAdjustment,
      _ => transaction.type,
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

  IconData _iconForType() {
    return switch (transaction.type) {
      'income' => FontAwesomeIcons.arrowDown,
      'expense' => FontAwesomeIcons.arrowUp,
      'transfer' => FontAwesomeIcons.arrowRightArrowLeft,
      'debt' => FontAwesomeIcons.handHoldingDollar,
      'loan' => FontAwesomeIcons.handHoldingDollar,
      'adjustment' => FontAwesomeIcons.sliders,
      _ => FontAwesomeIcons.receipt,
    };
  }
}
