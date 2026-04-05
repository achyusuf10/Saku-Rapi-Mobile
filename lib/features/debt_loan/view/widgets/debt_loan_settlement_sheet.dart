import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/debt_loan/controllers/debt_loan_settlement_form_controller.dart';
import 'package:app_saku_rapi/features/debt_loan/models/debt_loan_transaction_model.dart';
import 'package:app_saku_rapi/features/debt_loan/models/settlement_history_model.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/global/widgets/calculator_keyboard/calculator_keyboard.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_currency_field.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:app_saku_rapi/global/widgets/saku_wallet_picker_sheet.dart';
import 'package:app_saku_rapi/global/widgets/saku_wallet_picker_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bottom sheet untuk pelunasan hutang / penerimaan piutang.
///
/// Mendukung dua mode:
/// - **Create** (default constructor): buat settlement baru untuk transaksi unpaid.
/// - **Edit** (`.edit()` constructor): edit/hapus settlement yang sudah ada.
class DebtLoanSettlementSheet extends ConsumerStatefulWidget {
  /// Create mode: buat settlement baru.
  const DebtLoanSettlementSheet({
    super.key,
    required this.transactions,
    required this.type,
    this.withPerson,
    required this.onSuccess,
  }) : settlement = null,
       originalAmount = null;

  /// Edit mode: edit/hapus settlement yang sudah ada.
  const DebtLoanSettlementSheet.edit({
    super.key,
    required SettlementHistoryModel this.settlement,
    required double this.originalAmount,
    required this.onSuccess,
  }) : transactions = const [],
       type = '',
       withPerson = null;

  /// Transaksi yang belum lunas (create mode).
  final List<DebtLoanTransactionModel> transactions;
  final String type;
  final String? withPerson;

  /// Settlement yang akan diedit (edit mode).
  final SettlementHistoryModel? settlement;

  /// Total amount dari transaksi hutang/piutang asal (edit mode).
  final double? originalAmount;

  /// Callback setelah berhasil create/edit/delete.
  final VoidCallback onSuccess;

  bool get isEditMode => settlement != null;

  /// Tampilkan bottom sheet edit settlement.
  static Future<void> showEdit({
    required BuildContext context,
    required SettlementHistoryModel settlement,
    required double originalAmount,
    required VoidCallback onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => DebtLoanSettlementSheet.edit(
        settlement: settlement,
        originalAmount: originalAmount,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  ConsumerState<DebtLoanSettlementSheet> createState() =>
      _DebtLoanSettlementSheetState();
}

class _DebtLoanSettlementSheetState
    extends ConsumerState<DebtLoanSettlementSheet> {
  final _amountController = SakuCurrencyController();
  final _noteController = TextEditingController();
  DebtLoanTransactionModel? _selectedTransaction;
  WalletModel? _selectedWallet;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      _amountController.setDoubleValue(widget.settlement!.totalAmount);
      _noteController.text = widget.settlement!.note ?? '';
    } else {
      _selectedTransaction = widget.transactions.first;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _maxAmount => widget.isEditMode
      ? widget.originalAmount!
      : _selectedTransaction!.remaining;

  Color _typeColor(BuildContext context) {
    final colors = context.colors;
    if (widget.isEditMode) {
      return widget.settlement!.type == 'expense' ? colors.debt : colors.loan;
    }
    return widget.type == 'debt' ? colors.debt : colors.loan;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final wallets = ref.watch(walletListProvider);
    final formState = ref.watch(debtLoanSettlementFormProvider);
    final typeColor = _typeColor(context);

    // Default wallet.
    if (widget.isEditMode) {
      _selectedWallet ??= wallets.firstWhere(
        (w) => w.id == widget.settlement!.walletId,
        orElse: () => wallets.first,
      );
    } else {
      _selectedWallet ??= wallets.isNotEmpty ? wallets.first : null;
    }

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
            if (widget.isEditMode)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.debtLoanSettlementEditTitle,
                      style: TextStyleConstants.h7.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: formState.isDeleting || formState.isSubmitting
                        ? null
                        : _confirmDelete,
                    icon: FaIcon(
                      FontAwesomeIcons.trashCan,
                      size: 16.w,
                      color: formState.isDeleting
                          ? colors.textSecondary
                          : colors.expense,
                    ),
                  ),
                ],
              )
            else ...[
              Text(
                l10n.debtLoanSettlementTitle,
                style: TextStyleConstants.h7.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                widget.withPerson ?? context.l10n.debtLoanSomeone,
                style: TextStyleConstants.b2.copyWith(color: typeColor),
              ),
            ],
            SizedBox(height: 16.h),

            // ─── Transaction selector (create mode, if multiple) ───
            if (!widget.isEditMode && widget.transactions.length > 1) ...[
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
                  isSelected: tx.id == _selectedTransaction!.id,
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
            SakuCurrencyField(
              controller: _amountController,
              initialValue: widget.isEditMode
                  ? widget.settlement!.totalAmount
                  : null,
              label: l10n.debtLoanSettlementAmount,
              hint: '0',
              suffixIcon: GestureDetector(
                onTap: () {
                  _amountController.setDoubleValue(_maxAmount);
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
            SakuWalletPickerTile(
              label: l10n.debtLoanSettlementWallet,
              selected: _selectedWallet,
              useBorder: true,
              onTap: () async {
                FocusScope.of(context).unfocus();
                final result = await SakuWalletPickerSheet.show(
                  context,
                  selectedWalletId: _selectedWallet?.id,
                );
                if (result != null) {
                  setState(() => _selectedWallet = result);
                }
              },
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
              isLoading: formState.isSubmitting,
              isEnabled: !formState.isDeleting,
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
    final amount = _amountController.numericValue;

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

    final controller = ref.read(debtLoanSettlementFormProvider.notifier);
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    final result = widget.isEditMode
        ? await controller.update(
            settlementId: widget.settlement!.id,
            amount: amount,
            walletId: _selectedWallet!.id,
            note: note,
          )
        : await controller.settle(
            referenceTransactionId: _selectedTransaction!.id,
            settlementKind: widget.type == 'debt'
                ? 'debt_payment'
                : 'loan_collection',
            amount: amount,
            walletId: _selectedWallet!.id,
            note: note,
          );

    if (!mounted) return;

    if (result.isSuccess()) {
      Navigator.pop(context);
      context.showAppAlert(
        widget.isEditMode
            ? l10n.debtLoanSettlementEditSuccess
            : l10n.debtLoanSettlementSuccess,
        alertType: AlertTypeEnum.success,
      );
      widget.onSuccess();
    } else {
      final (message, _, _, _) = result.dataError()!;
      context.showAppAlert(message, alertType: AlertTypeEnum.error);
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = context.l10n;

    final confirmed = await context.showConfirmDialog(
      title: l10n.debtLoanSettlementDeleteConfirm,
      message: l10n.debtLoanSettlementDeleteMessage,
    );

    if (confirmed != true || !mounted) return;

    final result = await ref
        .read(debtLoanSettlementFormProvider.notifier)
        .delete(widget.settlement!.id);

    if (!mounted) return;

    if (result.isSuccess()) {
      Navigator.pop(context);
      context.showAppAlert(
        l10n.debtLoanSettlementDeleteSuccess,
        alertType: AlertTypeEnum.success,
      );
      widget.onSuccess();
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
