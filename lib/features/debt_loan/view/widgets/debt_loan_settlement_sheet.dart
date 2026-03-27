import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/debt_loan/models/debt_loan_transaction_model.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bottom sheet untuk melakukan pelunasan hutang / penerimaan piutang.
///
/// Menampilkan:
/// - Pilih transaksi yang mau dilunasi (jika > 1 unpaid)
/// - Input nominal pelunasan
/// - Pilihan dompet pembayaran
/// - Note opsional
class DebtLoanSettlementSheet extends ConsumerStatefulWidget {
  const DebtLoanSettlementSheet({
    super.key,
    required this.transactions,
    required this.type,
    required this.withPerson,
    required this.onSettled,
  });

  /// Transaksi yang belum lunas (bisa > 1 jika dari person page).
  final List<DebtLoanTransactionModel> transactions;
  final String type;
  final String withPerson;
  final VoidCallback onSettled;

  @override
  ConsumerState<DebtLoanSettlementSheet> createState() =>
      _DebtLoanSettlementSheetState();
}

class _DebtLoanSettlementSheetState
    extends ConsumerState<DebtLoanSettlementSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late DebtLoanTransactionModel _selectedTransaction;
  WalletModel? _selectedWallet;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedTransaction = widget.transactions.first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _maxAmount => _selectedTransaction.remaining;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final wallets = ref.watch(walletListProvider);
    final typeColor = widget.type == 'debt' ? colors.debt : colors.loan;

    // Default to first wallet if not selected.
    _selectedWallet ??= wallets.isNotEmpty ? wallets.first : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.w,
        12.h,
        16.w,
        MediaQuery.of(context).viewInsets.bottom + 16.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Handle ───
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // ─── Title ───
            Text(
              l10n.debtLoanSettlementTitle,
              style: TextStyleConstants.h7.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              widget.withPerson,
              style: TextStyleConstants.b2.copyWith(color: typeColor),
            ),
            SizedBox(height: 16.h),

            // ─── Transaction selector (if multiple) ───
            if (widget.transactions.length > 1) ...[
              Text(
                'Pilih transaksi:',
                style: TextStyleConstants.label1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              ...widget.transactions.map(
                (tx) => _TransactionOption(
                  transaction: tx,
                  type: widget.type,
                  isSelected: tx.id == _selectedTransaction.id,
                  onTap: () {
                    setState(() {
                      _selectedTransaction = tx;
                      _amountController.clear();
                    });
                  },
                ),
              ),
              SizedBox(height: 12.h),
            ],

            // ─── Remaining info ───
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: typeColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.debtLoanStatusRemaining,
                    style: TextStyleConstants.label1.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    _maxAmount.toCurrency(),
                    style: TextStyleConstants.b1.copyWith(
                      color: typeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // ─── Amount input ───
            SakuTextField(
              controller: _amountController,
              label: l10n.debtLoanSettlementAmount,
              hint: '0',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              suffixIcon: GestureDetector(
                onTap: () {
                  _amountController.text = _maxAmount.toInt().toString();
                },
                child: Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: Text(
                    'MAX',
                    style: TextStyleConstants.label2.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // ─── Wallet picker ───
            Text(
              l10n.debtLoanSettlementWallet,
              style: TextStyleConstants.label1.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: wallets.map((wallet) {
                final isSelected = _selectedWallet?.id == wallet.id;
                return ChoiceChip(
                  label: Text(wallet.name),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedWallet = wallet);
                  },
                  selectedColor: colors.primary.withValues(alpha: 0.15),
                  backgroundColor: colors.surfaceVariant,
                  labelStyle: TextStyleConstants.label2.copyWith(
                    color: isSelected ? colors.primary : colors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected ? colors.primary : colors.border,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 12.h),

            // ─── Note ───
            SakuTextField(
              controller: _noteController,
              label: l10n.debtLoanSettlementNote,
              hint: l10n.debtLoanSettlementNote,
              maxLines: 2,
            ),
            SizedBox(height: 20.h),

            // ─── Submit ───
            SakuButton(
              text: l10n.debtLoanSettlementSubmit,
              isLoading: _isSubmitting,
              onPressed: _submit,
              icon: FaIcon(
                FontAwesomeIcons.check,
                size: 16.w,
                color: colors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (amount <= 0) {
      context.showAppAlert(
        l10n.debtLoanSettlementAmount,
        alertType: AlertTypeEnum.error,
      );
      return;
    }

    if (amount > _maxAmount) {
      context.showAppAlert(
        l10n.debtLoanSettlementRemainder(_maxAmount.toCurrency()),
        alertType: AlertTypeEnum.error,
      );
      return;
    }

    if (_selectedWallet == null) return;

    setState(() => _isSubmitting = true);

    final settlementKind = widget.type == 'debt'
        ? 'debt_payment'
        : 'loan_collection';

    final result = await ref
        .read(transactionRepositoryProvider)
        .settleDebtOrLoan(
          referenceTransactionId: _selectedTransaction.id,
          settlementKind: settlementKind,
          amount: amount,
          walletId: _selectedWallet!.id,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.isSuccess()) {
      // Reload wallets to reflect balance changes.
      ref.read(walletControllerProvider.notifier).loadWallets();

      Navigator.pop(context);
      context.showAppAlert(
        l10n.debtLoanSettlementSuccess,
        alertType: AlertTypeEnum.success,
      );
      widget.onSettled();
    } else {
      final (message, _, _, _) = result.dataError()!;
      context.showAppAlert(message, alertType: AlertTypeEnum.error);
    }
  }
}

// ───────────────── Transaction Option ─────────────────

class _TransactionOption extends StatelessWidget {
  const _TransactionOption({
    required this.transaction,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final DebtLoanTransactionModel transaction;
  final String type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final typeColor = type == 'debt' ? colors.debt : colors.loan;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? typeColor.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: isSelected ? typeColor : colors.border),
        ),
        child: Row(
          children: [
            FaIcon(
              isSelected
                  ? FontAwesomeIcons.solidCircleCheck
                  : FontAwesomeIcons.circle,
              size: 16.w,
              color: isSelected ? typeColor : colors.textSecondary,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                transaction.note ??
                    (type == 'debt'
                        ? l10n.transactionDebt
                        : l10n.transactionLoan),
                style: TextStyleConstants.b2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${l10n.debtLoanStatusRemaining} ${transaction.remaining.toCurrency()}',
              style: TextStyleConstants.label2.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
