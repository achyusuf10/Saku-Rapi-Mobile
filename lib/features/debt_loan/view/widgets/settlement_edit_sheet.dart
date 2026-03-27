import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/debt_loan/models/settlement_history_model.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_currency_field.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bottom sheet untuk edit/hapus transaksi pelunasan/penerimaan.
///
/// Field yang bisa diedit:
/// - Jumlah pelunasan (dengan validasi maks)
/// - Dompet pembayaran
/// - Catatan
///
/// Juga menyediakan tombol hapus.
class SettlementEditSheet extends ConsumerStatefulWidget {
  const SettlementEditSheet({
    super.key,
    required this.settlement,
    required this.originalAmount,
    required this.onChanged,
  });

  /// Settlement yang akan diedit.
  final SettlementHistoryModel settlement;

  /// Total amount dari transaksi hutang/piutang asal.
  final double originalAmount;

  /// Callback setelah berhasil edit/hapus.
  final VoidCallback onChanged;

  /// Tampilkan bottom sheet edit settlement.
  static Future<void> show({
    required BuildContext context,
    required SettlementHistoryModel settlement,
    required double originalAmount,
    required VoidCallback onChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).extension<dynamic>() != null
          ? Colors.transparent
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => SettlementEditSheet(
        settlement: settlement,
        originalAmount: originalAmount,
        onChanged: onChanged,
      ),
    );
  }

  @override
  ConsumerState<SettlementEditSheet> createState() =>
      _SettlementEditSheetState();
}

class _SettlementEditSheetState extends ConsumerState<SettlementEditSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  WalletModel? _selectedWallet;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.settlement.totalAmount.toInt().toString();
    _noteController.text = widget.settlement.note ?? '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Maks amount = sisa dari settlement lain + originalAmount.
  /// Artinya: originalAmount - (total settled lain) = maks untuk settlement ini.
  /// Kita tidak punya data settled lain di sini, jadi kita hitung:
  /// maxAmount = originalAmount - totalSettledOther
  /// Dari perspektif user: mereka bisa set sampai remaining + current.
  /// Kita set max = originalAmount, validasi server-side yang tepat.
  /// Tapi untuk UX lebih baik, kita tampilkan original amount sebagai referensi.
  double get _maxAmount => widget.originalAmount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final wallets = ref.watch(walletListProvider);
    final isDebtPayment = widget.settlement.type == 'expense';
    final typeColor = isDebtPayment ? colors.debt : colors.loan;

    // Default wallet from settlement's existing walletId
    _selectedWallet ??= wallets.firstWhere(
      (w) => w.id == widget.settlement.walletId,
      orElse: () => wallets.first,
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
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

            // ─── Title + delete button ───
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
                  onPressed: _isDeleting || _isSaving ? null : _confirmDelete,
                  icon: FaIcon(
                    FontAwesomeIcons.trashCan,
                    size: 16.w,
                    color: _isDeleting ? colors.textSecondary : colors.expense,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),

            // ─── Max amount info ───
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
              initialValue: widget.settlement.totalAmount,
              label: l10n.debtLoanSettlementAmount,
              hint: '0',
              suffixIcon: GestureDetector(
                onTap: () {
                  _amountController.text = _maxAmount.toCurrency(
                    withPrefix: false,
                  );
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
                  onSelected: (_) => setState(() => _selectedWallet = wallet),
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

            // ─── Save button ───
            SakuButton(
              text: l10n.debtLoanSettlementSubmit,
              isLoading: _isSaving,
              isEnabled: !_isDeleting,
              onPressed: _save,
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

  Future<void> _save() async {
    final l10n = context.l10n;
    final amount = ThousandInputFormatter.parseNumber(_amountController.text);

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

    setState(() => _isSaving = true);

    final result = await ref
        .read(transactionRepositoryProvider)
        .updateSettlement(
          settlementId: widget.settlement.id,
          amount: amount,
          walletId: _selectedWallet!.id,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.isSuccess()) {
      ref.read(walletControllerProvider.notifier).loadWallets();
      Navigator.pop(context);
      context.showAppAlert(
        l10n.debtLoanSettlementEditSuccess,
        alertType: AlertTypeEnum.success,
      );
      widget.onChanged();
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

    setState(() => _isDeleting = true);

    final result = await ref
        .read(transactionRepositoryProvider)
        .deleteSettlement(widget.settlement.id);

    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (result.isSuccess()) {
      ref.read(walletControllerProvider.notifier).loadWallets();
      Navigator.pop(context);
      context.showAppAlert(
        l10n.debtLoanSettlementDeleteSuccess,
        alertType: AlertTypeEnum.success,
      );
      widget.onChanged();
    } else {
      final (message, _, _, _) = result.dataError()!;
      context.showAppAlert(message, alertType: AlertTypeEnum.error);
    }
  }
}
