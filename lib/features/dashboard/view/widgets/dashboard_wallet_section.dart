import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/category/utils/category_icon_mapper.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Section daftar wallet horizontal di dashboard.
///
/// Menampilkan wallet cards dalam scroll horizontal,
/// dengan indikator `exclude_from_total`.
class DashboardWalletSection extends ConsumerWidget {
  const DashboardWalletSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final wallets = ref.watch(dashboardWalletsProvider);
    final isHidden = ref.watch(dashboardControllerProvider).isBalanceHidden;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Header ───
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.dashboardMyWallets,
                style: TextStyleConstants.b1.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRouter.wallet),
                child: Text(
                  l10n.dashboardSeeAll,
                  style: TextStyleConstants.label1.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // ─── Wallet Cards Horizontal ───
        if (wallets.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: SakuCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Column(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.wallet,
                        size: 28.w,
                        color: colors.textSecondary.withValues(alpha: 0.4),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        l10n.dashboardEmptyWallets,
                        style: TextStyleConstants.label1.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 100.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: wallets.length,
              separatorBuilder: (_, _) => SizedBox(width: 10.w),
              itemBuilder: (context, index) {
                return _WalletMiniCard(
                  wallet: wallets[index],
                  isHidden: isHidden,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _WalletMiniCard extends StatelessWidget {
  const _WalletMiniCard({required this.wallet, required this.isHidden});

  final WalletModel wallet;
  final bool isHidden;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final walletColor = _parseColor(wallet.color);

    return Container(
      width: 160.w,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: colors.surface,
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: walletColor.withValues(alpha: 0.15),
                ),
                child: FaIcon(
                  CategoryIconMapper.getIcon(wallet.icon),
                  size: 12.w,
                  color: walletColor,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  wallet.name,
                  style: TextStyleConstants.label2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (wallet.excludeFromTotal)
                Padding(
                  padding: EdgeInsets.only(left: 4.w),
                  child: FaIcon(
                    FontAwesomeIcons.eyeSlash,
                    size: 10.w,
                    color: colors.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
          Text(
            isHidden ? '••••' : wallet.balance.toCurrency(),
            style: TextStyleConstants.b2.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    final buffer = StringBuffer();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) buffer.write('FF');
    buffer.write(hex);
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
