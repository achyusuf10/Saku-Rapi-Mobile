import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_wallet_picker.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Tile radio untuk memilih scope wallet pada budget.
///
/// Dua opsi:
/// 1. **Semua Dompet** (`walletId == null`)
/// 2. **Dompet Tertentu** → buka [TransactionWalletPicker]
class BudgetWalletScopeTile extends StatelessWidget {
  const BudgetWalletScopeTile({
    super.key,
    required this.selectedWallet,
    required this.onChanged,
  });

  /// Wallet terpilih. `null` = semua dompet.
  final WalletModel? selectedWallet;

  /// Callback saat scope berubah. `null` = semua dompet.
  final ValueChanged<WalletModel?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final isAllWallets = selectedWallet == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Opsi 1: Semua Dompet
        InkWell(
          borderRadius: BorderRadius.circular(8.r),
          onTap: () => onChanged(null),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Row(
              children: [
                Icon(
                  isAllWallets
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 20.r,
                  color: isAllWallets ? colors.primary : colors.textSecondary,
                ),
                SizedBox(width: 12.w),
                FaIcon(
                  FontAwesomeIcons.wallet,
                  size: 14.r,
                  color: colors.textSecondary,
                ),
                SizedBox(width: 8.w),
                Text(
                  l10n.budgetAllWallets,
                  style: TextStyleConstants.b2.copyWith(
                    fontWeight: isAllWallets
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Opsi 2: Dompet Tertentu
        InkWell(
          borderRadius: BorderRadius.circular(8.r),
          onTap: () => _pickWallet(context),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Row(
              children: [
                Icon(
                  !isAllWallets
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 20.r,
                  color: !isAllWallets ? colors.primary : colors.textSecondary,
                ),
                SizedBox(width: 12.w),
                FaIcon(
                  FontAwesomeIcons.buildingColumns,
                  size: 14.r,
                  color: colors.textSecondary,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    selectedWallet?.name ?? l10n.budgetSpecificWallet,
                    style: TextStyleConstants.b2.copyWith(
                      fontWeight: !isAllWallets
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isAllWallets)
                  FaIcon(
                    FontAwesomeIcons.chevronRight,
                    size: 12.r,
                    color: colors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickWallet(BuildContext context) async {
    final result = await TransactionWalletPicker.show(
      context,
      selectedId: selectedWallet?.id,
    );
    if (result != null) {
      onChanged(result);
    }
  }
}
