import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/debt_loan/models/debt_loan_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Tile untuk memilih transaksi hutang/piutang yang belum lunas.
///
/// Menampilkan transaksi yang dipilih (nama orang, sisa hutang) atau
/// placeholder. Tap membuka sheet daftar transaksi belum lunas.
class DebtLoanTransactionPickerTile extends StatelessWidget {
  const DebtLoanTransactionPickerTile({
    super.key,
    required this.onTap,
    this.selected,
    this.iconColor,
  });

  final DebtLoanTransactionModel? selected;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final hasSelection = selected != null;
    final tileIconColor = iconColor ?? colors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: tileIconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.fileInvoiceDollar,
                  size: 16.w,
                  color: tileIconColor,
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // Label + value
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.debtLoanFormSelectedTransaction.toUpperCase(),
                    style: TextStyleConstants.overline.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  if (hasSelection) ...[
                    Text(
                      selected!.withPerson ?? l10n.debtLoanSomeone,
                      style: TextStyleConstants.b2.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      l10n.debtLoanFormRemainingAmount(
                        selected!.remaining.toCurrency(),
                      ),
                      style: TextStyleConstants.caption.copyWith(
                        color: tileIconColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else
                    Text(
                      l10n.debtLoanFormPickTransaction,
                      style: TextStyleConstants.b2.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),

            // Chevron
            FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 12.w,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
