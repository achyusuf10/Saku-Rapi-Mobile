import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_currency_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Bottom sheet untuk menyesuaikan saldo wallet.
///
/// User memasukkan saldo aktual, sistem menghitung selisih
/// dan memanggil RPC `create_adjustment_transaction`.
class WalletAdjustSheet extends ConsumerStatefulWidget {
  const WalletAdjustSheet({super.key, required this.wallet});

  final WalletModel wallet;

  /// Helper untuk menampilkan sheet.
  static Future<void> show(
    BuildContext context, {
    required WalletModel wallet,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WalletAdjustSheet(wallet: wallet),
    );
  }

  @override
  ConsumerState<WalletAdjustSheet> createState() => _WalletAdjustSheetState();
}

class _WalletAdjustSheetState extends ConsumerState<WalletAdjustSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _balanceController;
  double _targetBalance = 0;
  bool _isSaving = false;

  double get _diff => _targetBalance - widget.wallet.balance;

  @override
  void initState() {
    super.initState();
    _balanceController = TextEditingController();
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Handle bar ───
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
                  l10n.walletAdjust,
                  style: TextStyleConstants.h6.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),

                // ─── Wallet info ───
                Text(
                  widget.wallet.name,
                  style: TextStyleConstants.b2.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${l10n.walletBalance}: ${widget.wallet.balance.toCurrency()}',
                  style: TextStyleConstants.label1.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                SizedBox(height: 20.h),

                // ─── Input saldo aktual ───
                SakuCurrencyField(
                  controller: _balanceController,
                  label: l10n.walletAdjustActual,
                  hint: l10n.walletAdjustHint,
                  autofocus: true,
                  onChanged: (value) {
                    setState(() => _targetBalance = value);
                  },
                  validator: (_) {
                    if (_targetBalance == widget.wallet.balance) {
                      return l10n.walletAdjustDiff;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12.h),

                // ─── Info selisih ───
                if (_diff != 0)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${l10n.walletAdjustDiff}: ',
                          style: TextStyleConstants.label1.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        Text(
                          '${_diff > 0 ? '+' : ''}${_diff.toCurrency()}',
                          style: TextStyleConstants.b2.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _diff > 0 ? colors.income : colors.expense,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 24.h),

                // ─── Save button ───
                SakuButton(
                  text: l10n.walletSave,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final result = await ref
          .read(walletControllerProvider.notifier)
          .adjustBalance(
            walletId: widget.wallet.id,
            targetBalance: _targetBalance,
          );

      if (!mounted) return;

      if (result.isSuccess()) {
        Navigator.of(context).pop();
        context.showAppAlert(
          context.l10n.walletSuccessAdjust,
          alertType: AlertTypeEnum.success,
        );
      } else {
        final (message, _, _, _) = result.dataError()!;
        context.showAppAlert(message, alertType: AlertTypeEnum.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
