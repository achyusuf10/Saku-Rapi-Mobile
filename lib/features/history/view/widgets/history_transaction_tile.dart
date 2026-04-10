import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/debt_loan_kind_enum.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/utils/color_utils.dart';
import 'package:app_saku_rapi/features/history/models/history_models.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_category_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Tile untuk satu transaksi — dipakai di history list dan dashboard.
///
/// Menampilkan icon kategori, nama, tanggal, dan jumlah.
/// [groupMode] menentukan layout:
/// - [HistoryGroupMode.byDate]: Icon | Category + Note | Amount + Time
/// - [HistoryGroupMode.byCategory]: Icon | Note + Date(EEE, dd MMM yyyy HH:mm) | Amount
class HistoryTransactionTile extends StatelessWidget {
  const HistoryTransactionTile({
    super.key,
    required this.transaction,
    required this.onTap,
    this.onLongPress,
    this.showDate = false,
    this.groupMode,
  });

  final TransactionModel transaction;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool showDate;

  /// Jika null, gunakan layout byDate (default untuk dashboard).
  final HistoryGroupMode? groupMode;

  @override
  Widget build(BuildContext context) {
    final effectiveMode = groupMode ?? HistoryGroupMode.byDate;
    if (effectiveMode == HistoryGroupMode.byCategory) {
      return _buildByCategoryLayout(context);
    }
    return _buildByDateLayout(context);
  }

  /// Layout untuk mode byDate:
  /// Icon | Category + Note | Amount + Time
  Widget _buildByDateLayout(BuildContext context) {
    final colors = context.colors;
    final typeColor = _resolveIconColor(transaction, colors);
    final isIncoming =
        transaction.type == TransactionTypeEnum.income ||
        transaction.type == TransactionTypeEnum.debt;

    return Material(
      color: Colors.transparent,
      child: InkWell(
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
                child: Center(child: _buildIcon(transaction, typeColor)),
              ),
              SizedBox(width: 12.w),

              // ─── Category Name + Note ───
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
                    if (transaction.note != null &&
                        transaction.note!.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        transaction.note!,
                        style: TextStyleConstants.label3.copyWith(
                          color: colors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.w),

              // ─── Amount + Time ───
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncoming ? '+' : '-'} ${transaction.totalAmount.toCurrency(withPrefix: false)}',
                    style: TextStyleConstants.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isIncoming ? colors.income : colors.expense,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    transaction.date.extToFormattedString(
                      outputDateFormat: 'HH:mm',
                    ),
                    style: TextStyleConstants.label3.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Layout untuk mode byCategory:
  /// Date(EEE, dd MMM yyyy HH:mm) + Note | Amount
  Widget _buildByCategoryLayout(BuildContext context) {
    final colors = context.colors;
    final isIncoming =
        transaction.type == TransactionTypeEnum.income ||
        transaction.type == TransactionTypeEnum.debt;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              // ─── Date + Note ───
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.date.extToFormattedString(
                        outputDateFormat: 'EEE, dd MMM yyyy HH:mm',
                      ),
                      style: TextStyleConstants.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (transaction.note != null &&
                        transaction.note!.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        transaction.note!,
                        style: TextStyleConstants.label3.copyWith(
                          color: colors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.w),

              // ─── Amount ───
              Text(
                '${isIncoming ? '+' : '-'} ${transaction.totalAmount.toCurrency(withPrefix: false)}',
                style: TextStyleConstants.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isIncoming ? colors.income : colors.expense,
                ),
              ),
            ],
          ),
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
    if (tx.settlementKind == DebtLoanKindEnum.debtPayment) {
      return l10n.debtLoanTitlePayment(person ?? l10n.debtLoanSomeone);
    }
    if (tx.settlementKind == DebtLoanKindEnum.loanCollection) {
      return l10n.debtLoanTitleReceipt(person ?? l10n.debtLoanSomeone);
    }

    // Original debt/loan transactions.
    if (tx.type == TransactionTypeEnum.debt) {
      return l10n.debtLoanTitleDebt(person ?? l10n.debtLoanSomeone);
    }
    if (tx.type == TransactionTypeEnum.loan) {
      return l10n.debtLoanTitleLoan(person ?? l10n.debtLoanSomeone);
    }

    // Fallback for other types.
    if (person != null) return person;
    if (tx.type == TransactionTypeEnum.transfer) {
      return '${tx.walletName ?? ''} → ${tx.destinationWalletName ?? ''}';
    }
    if (tx.type == TransactionTypeEnum.adjustment) return 'Adjustment';
    return tx.note ?? tx.type.toDbValue();
  }

  Widget _buildIcon(TransactionModel tx, Color fallbackColor) {
    if (tx.categoryIcon != null) {
      return SakuCategoryIcon(
        iconName: tx.categoryIcon!,
        color: fallbackColor,
        size: 16,
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
    return FaIcon(iconData, size: 16.w, color: fallbackColor);
  }

  /// Warna icon: prioritaskan categoryColor, fallback ke warna tipe transaksi.
  Color _resolveIconColor(TransactionModel tx, dynamic colors) {
    if (tx.categoryColor != null && tx.categoryColor!.isNotEmpty) {
      return parseHexColor(tx.categoryColor!);
    }
    return _colorForType(tx.type, colors);
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
