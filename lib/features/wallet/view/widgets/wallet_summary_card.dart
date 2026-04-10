import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Card ringkasan total saldo semua wallet (yang termasuk dalam total).
///
/// Menampilkan total balance, jumlah wallet, dan label deskriptif.
/// Menggunakan gaya flat dengan kontras tinggi untuk light/dark mode.
class WalletSummaryCard extends StatelessWidget {
  const WalletSummaryCard({
    super.key,
    required this.totalBalance,
    required this.walletCount,
  });

  /// Total saldo dari wallet yang `exclude_from_total = false`.
  final double totalBalance;

  /// Jumlah wallet yang termasuk dalam total.
  final int walletCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.14 : 0.06,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.wallet,
                size: 14.w,
                color: colors.primary,
              ),
              SizedBox(width: 8.w),
              Text(
                l10n.walletTotalBalance,
                style: TextStyleConstants.label1.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // ─── Balance ───
          Text(
            totalBalance.toCurrency(),
            style: TextStyleConstants.h4.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16.h),

          // ─── Wallet count chip ───
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              color: colors.surfaceVariant,
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  FontAwesomeIcons.creditCard,
                  size: 12.w,
                  color: colors.primary,
                ),
                SizedBox(width: 8.w),
                Text(
                  '$walletCount ${l10n.walletTitle.toLowerCase()}',
                  style: TextStyleConstants.label2.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
