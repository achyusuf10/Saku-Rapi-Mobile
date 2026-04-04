import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Wallet picker tile dengan ikon lingkaran berwarna.
///
/// Menampilkan wallet yang dipilih atau placeholder jika belum dipilih.
/// Digunakan di form transaksi untuk memilih dompet sumber/tujuan.
class TransactionWalletPickerTile extends StatelessWidget {
  const TransactionWalletPickerTile({
    super.key,
    required this.label,
    required this.onTap,
    required this.iconColor,
    this.selected,
    this.excludeWalletId,
  });

  final String label;
  final WalletModel? selected;
  final VoidCallback onTap;
  final Color iconColor;
  final String? excludeWalletId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasSelection = selected != null;

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
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.wallet,
                  size: 16.w,
                  color: iconColor,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyleConstants.overline.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    selected?.name ?? context.l10n.transactionSelectWallet,
                    style: TextStyleConstants.b2.copyWith(
                      color: hasSelection
                          ? colors.textPrimary
                          : colors.textSecondary,
                      fontWeight: hasSelection
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 12.w,
              color: colors.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
