import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/utils/color_utils.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_category_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 14.h,
        ).copyWith(right: trailing != null ? 8.w : 16.w),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                SakuCategoryIcon(
                  iconName: wallet.icon,
                  color: parseHexColor(wallet.color),
                  size: 42,
                  iconSize: 18,
                  borderRadius: 12,
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
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                10.horizontalSpace,

                // Balance
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      wallet.balance.toCurrency(),
                      style: TextStyleConstants.b2.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                // Trailing (optional, e.g. popup menu)
                if (trailing != null) ...[SizedBox(width: 4.w), trailing!],
              ],
            ),
            if (wallet.excludeFromTotal) ...[
              SizedBox(height: 2.h),
              Text(
                "* ${context.l10n.walletExcludeHint}",
                style: TextStyleConstants.label2.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
