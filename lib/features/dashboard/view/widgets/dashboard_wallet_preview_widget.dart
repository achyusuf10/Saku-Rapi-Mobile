import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Preview maks 3 dompet teratas di dashboard.
///
/// Section title "Dompet Saya" + tombol "Lihat Semua" → WalletListScreen.
/// Pisahkan visual antara included vs excluded wallets.
class DashboardWalletPreviewWidget extends ConsumerWidget {
  const DashboardWalletPreviewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.colors;
    final l10n = context.l10n;
    final dashState = ref.watch(dashboardControllerProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          // ── Section header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.dashboardMyWallets,
                style: TextStyleConstants.h7.copyWith(
                  fontWeight: FontWeight.w700,
                  color: appColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRouter.walletList),
                child: Text(
                  l10n.dashboardSeeAll,
                  style: TextStyleConstants.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: appColors.primary,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // ── Wallet cards ──
          dashState.when(
            loading: () => _buildSkeleton(appColors),
            error: (_, __) => const SizedBox.shrink(),
            data: (data) {
              if (data.wallets.isEmpty) return const SizedBox.shrink();

              // Sortir: included first, lalu excluded
              final sorted = List<WalletModel>.from(data.wallets)
                ..sort((a, b) {
                  if (a.excludeFromTotal != b.excludeFromTotal) {
                    return a.excludeFromTotal ? 1 : -1;
                  }
                  return a.sortOrder.compareTo(b.sortOrder);
                });

              // Maks 3 wallet
              final preview = sorted.take(3).toList();
              final hasExcluded = preview.any((w) => w.excludeFromTotal);
              final hasIncluded = preview.any((w) => !w.excludeFromTotal);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Included wallets
                  if (hasIncluded)
                    ...preview
                        .where((w) => !w.excludeFromTotal)
                        .map((w) => _WalletTile(wallet: w)),

                  // Divider + label jika ada keduanya
                  if (hasIncluded && hasExcluded) ...[
                    SizedBox(height: 8.h),
                    Padding(
                      padding: EdgeInsets.only(left: 4.w, bottom: 4.h),
                      child: Text(
                        l10n.dashboardExcludedFromTotal,
                        style: TextStyleConstants.label3.copyWith(
                          color: appColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  // Excluded wallets
                  if (hasExcluded)
                    ...preview
                        .where((w) => w.excludeFromTotal)
                        .map((w) => _WalletTile(wallet: w)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(appColors) {
    return Column(
      children: List.generate(
        2,
        (_) => Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Container(
            height: 56.h,
            decoration: BoxDecoration(
              color: appColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tile untuk satu wallet di preview dashboard.
class _WalletTile extends StatelessWidget {
  const _WalletTile({required this.wallet});

  final WalletModel wallet;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: SakuCard(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Row(
          children: [
            // ── Icon berwarna ──
            Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: _hexColor(wallet.color).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Center(
                child: FaIcon(
                  _walletIcon(wallet.icon),
                  color: _hexColor(wallet.color),
                  size: 16.r,
                ),
              ),
            ),

            SizedBox(width: 12.w),

            // ── Nama ──
            Expanded(
              child: Text(
                wallet.name,
                style: TextStyleConstants.b2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: appColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ── Saldo ──
            Text(
              wallet.balance.toCurrency(),
              style: TextStyleConstants.b2.copyWith(
                fontWeight: FontWeight.w700,
                color: appColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _hexColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('FF');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  IconData _walletIcon(String iconName) {
    return switch (iconName) {
      'wallet' => FontAwesomeIcons.wallet,
      'bank' || 'building-columns' => FontAwesomeIcons.buildingColumns,
      'credit-card' => FontAwesomeIcons.creditCard,
      'piggy-bank' => FontAwesomeIcons.piggyBank,
      'money-bill' => FontAwesomeIcons.moneyBill,
      'coins' => FontAwesomeIcons.coins,
      'sack-dollar' => FontAwesomeIcons.sackDollar,
      'landmark' => FontAwesomeIcons.landmark,
      'vault' => FontAwesomeIcons.vault,
      _ => FontAwesomeIcons.wallet,
    };
  }
}
