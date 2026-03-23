import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/category/utils/category_icon_mapper.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Card tile untuk menampilkan satu wallet dalam list.
///
/// Menampilkan icon, nama, saldo, dan badge exclude jika berlaku.
/// Tap untuk membuka detail / menu aksi.
class WalletCardTile extends StatelessWidget {
  const WalletCardTile({
    super.key,
    required this.wallet,
    this.onTap,
    this.onLongPress,
    this.trailing,
  });

  final WalletModel wallet;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final walletColor = _parseColor(wallet.color);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: walletColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: FaIcon(
                  CategoryIconMapper.getIcon(wallet.icon),
                  size: 18.w,
                  color: walletColor,
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // Name + badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    style: TextStyleConstants.b2.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (wallet.excludeFromTotal) ...[
                    SizedBox(height: 2.h),
                    Text(
                      context.l10n.walletExcludeHint,
                      style: TextStyleConstants.label2.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  wallet.balance.toCurrency(),
                  style: TextStyleConstants.b2.copyWith(
                    fontWeight: FontWeight.w700,
                    color: wallet.balance >= 0 ? colors.income : colors.expense,
                  ),
                ),
              ],
            ),

            // Trailing (optional, e.g. popup menu)
            if (trailing != null) ...[SizedBox(width: 4.w), trailing!],
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}
