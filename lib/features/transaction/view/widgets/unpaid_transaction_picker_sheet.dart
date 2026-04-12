import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/debt_loan/controllers/debt_loan_controller.dart';
import 'package:app_saku_rapi/features/debt_loan/models/debt_loan_transaction_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_empty_state.dart';
import 'package:app_saku_rapi/global/widgets/saku_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bottom sheet untuk memilih transaksi hutang/piutang yang belum lunas.
///
/// Memuat daftar dari RPC `get_all_unpaid_debt_loan` dan mengembalikan
/// [DebtLoanTransactionModel] yang dipilih.
class UnpaidTransactionPickerSheet extends ConsumerWidget {
  const UnpaidTransactionPickerSheet({
    super.key,
    required this.type,
    this.selectedId,
  });

  /// 'debt' atau 'loan'.
  final String type;

  /// ID transaksi yang sedang terpilih (untuk highlight).
  final String? selectedId;

  /// Tampilkan picker dan kembalikan transaksi yang dipilih.
  static Future<DebtLoanTransactionModel?> show(
    BuildContext context, {
    required String type,
    String? selectedId,
  }) {
    return showModalBottomSheet<DebtLoanTransactionModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          UnpaidTransactionPickerSheet(type: type, selectedId: selectedId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(unpaidTransactionsControllerProvider(type));
    final colors = context.colors;
    final l10n = context.l10n;
    final isDebt = type == 'debt';

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 10.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Title
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Text(
              l10n.debtLoanFormPickTransaction,
              style: TextStyleConstants.h7.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),

          Divider(height: 1, color: colors.border),

          // Content
          if (state.isLoading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 40.h),
              child: const SakuLoadingIndicator(),
            )
          else if (state.errorMessage != null)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 16.w),
              child: Text(
                state.errorMessage!,
                style: TextStyleConstants.b2.copyWith(color: colors.error),
                textAlign: TextAlign.center,
              ),
            )
          else if (state.transactions.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 40.h),
              child: SakuEmptyState(
                message: isDebt
                    ? l10n.debtLoanFormNoUnpaidDebt
                    : l10n.debtLoanFormNoUnpaidLoan,
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                itemCount: state.transactions.length,
                separatorBuilder: (_, index) => SizedBox(height: 8.h),
                itemBuilder: (context, index) {
                  final txn = state.transactions[index];
                  final isSelected = txn.id == selectedId;
                  final accentColor = isDebt ? colors.debt : colors.loan;

                  return _TransactionItem(
                    txn: txn,
                    isSelected: isSelected,
                    accentColor: accentColor,
                    onTap: () => Navigator.of(context).pop(txn),
                  );
                },
              ),
            ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8.h),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  const _TransactionItem({
    required this.txn,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  final DebtLoanTransactionModel txn;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.08)
              : colors.background,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? accentColor : colors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Person avatar
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (txn.withPerson ?? '?')[0].toUpperCase(),
                  style: TextStyleConstants.b1.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.withPerson ?? l10n.debtLoanSomeone,
                    style: TextStyleConstants.b2.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    txn.date.extToFormattedString(
                      outputDateFormat: 'dd MMMM yyyy HH:mm',
                    ),
                    style: TextStyleConstants.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Amount info
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  txn.totalAmount.toCurrency(),
                  style: TextStyleConstants.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  l10n.debtLoanFormRemainingAmount(txn.remaining.toCurrency()),
                  style: TextStyleConstants.label2.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            if (isSelected) ...[
              SizedBox(width: 8.w),
              FaIcon(
                FontAwesomeIcons.circleCheck,
                size: 16.w,
                color: accentColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
