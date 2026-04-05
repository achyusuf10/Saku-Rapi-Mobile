import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Global wallet picker tile — tap untuk buka bottom sheet pemilihan wallet.
///
/// Menampilkan wallet yang dipilih atau placeholder jika belum dipilih.
/// Digunakan di semua form yang membutuhkan pemilihan wallet:
/// - Form transaksi (source & destination wallet)
/// - Form investasi beli/jual
/// - Form settlement hutang/piutang
///
/// Styling:
/// - Tanpa border: `useBorder: false` (default) — background `surface`, tanpa border
/// - Dengan border: `useBorder: true` — background `surfaceVariant`, border berubah
///   warna saat ada seleksi (primary) atau belum (border default)
class SakuWalletPickerTile extends StatelessWidget {
  const SakuWalletPickerTile({
    super.key,
    required this.label,
    required this.onTap,
    this.selected,
    this.iconColor,
    this.placeholder,
    this.useBorder = false,
  });

  /// Label di atas nama wallet (UPPERCASE).
  final String label;

  /// Wallet yang sedang terpilih (null jika belum dipilih).
  final WalletModel? selected;

  /// Callback ketika tile di-tap.
  final VoidCallback onTap;

  /// Warna ikon dan aksen. Default: `colors.primary`.
  final Color? iconColor;

  /// Teks placeholder jika belum ada wallet dipilih.
  /// Default dari l10n.transactionSelectWallet.
  final String? placeholder;

  /// Gunakan border style (surfaceVariant + dynamic border).
  ///
  /// - `false` (default): background surface, tanpa border (gaya form transaksi)
  /// - `true`: background surfaceVariant, border primary saat selected (gaya investasi)
  final bool useBorder;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasSelection = selected != null;
    final color = iconColor ?? colors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: useBorder ? colors.surfaceVariant : colors.surface,
          borderRadius: BorderRadius.circular(useBorder ? 12.r : 14.r),
          border: useBorder
              ? Border.all(
                  color: hasSelection ? color : colors.border,
                  width: hasSelection ? 1.5 : 1,
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.wallet,
                  size: 16.w,
                  color: color,
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
                    selected?.name ??
                        (placeholder ?? context.l10n.transactionSelectWallet),
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
