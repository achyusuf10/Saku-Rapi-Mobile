import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/features/wallet/view/widgets/wallet_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Layar utama yang menampilkan daftar semua wallet milik user.
///
/// Wallet dipisahkan menjadi dua section visual:
/// 1. **Dimasukkan dalam Total**
/// 2. **Dikecualikan dari Total**
class WalletListScreen extends ConsumerWidget {
  const WalletListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletControllerProvider);
    final appColors = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.walletTitle), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRouter.walletForm),
        backgroundColor: appColors.primary,
        child: FaIcon(FontAwesomeIcons.plus, color: Colors.white, size: 20.r),
      ),
      body: walletAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBody(
          message: error.toString(),
          onRetry: () => ref.read(walletControllerProvider.notifier).refresh(),
        ),
        data: (wallets) => _SuccessBody(wallets: wallets),
      ),
    );
  }
}

// Body ketika error
class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.triangleExclamation,
              size: 48.r,
              color: appColors.expense,
            ),
            SizedBox(height: 16.h),
            Text(
              message,
              style: TextStyleConstants.b2.copyWith(
                color: appColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            FilledButton.icon(
              onPressed: onRetry,
              icon: FaIcon(FontAwesomeIcons.arrowsRotate, size: 14.r),
              label: Text(
                l10n.retryButton,
                style: TextStyleConstants.b2.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Body ketika sukses
class _SuccessBody extends ConsumerWidget {
  const _SuccessBody({required this.wallets});

  final List<WalletModel> wallets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.colors;
    final l10n = context.l10n;
    final controller = ref.read(walletControllerProvider.notifier);

    final includedWallets = wallets.where((w) => !w.excludeFromTotal).toList();
    final excludedWallets = wallets.where((w) => w.excludeFromTotal).toList();
    final totalBalance = includedWallets.fold<double>(
      0,
      (sum, w) => sum + w.balance,
    );

    if (wallets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.wallet,
              size: 48.r,
              color: appColors.textSecondary.withValues(alpha: 0.4),
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.walletEmpty,
              style: TextStyleConstants.b1.copyWith(
                color: appColors.textSecondary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              l10n.walletEmptyHint,
              style: TextStyleConstants.caption.copyWith(
                color: appColors.textSecondary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.refresh(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _TotalBalanceHeader(totalBalance: totalBalance),
          ),
          if (includedWallets.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(title: l10n.walletIncludedSection),
            ),
            SliverList.builder(
              itemCount: includedWallets.length,
              itemBuilder: (context, index) =>
                  WalletListTile(wallet: includedWallets[index]),
            ),
          ],
          if (excludedWallets.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(title: l10n.walletExcludedSection),
            ),
            SliverList.builder(
              itemCount: excludedWallets.length,
              itemBuilder: (context, index) =>
                  WalletListTile(wallet: excludedWallets[index]),
            ),
          ],
          SliverPadding(padding: EdgeInsets.only(bottom: 80.h)),
        ],
      ),
    );
  }
}

/// Header yang menampilkan total saldo dari wallet yang included.
class _TotalBalanceHeader extends StatelessWidget {
  const _TotalBalanceHeader({required this.totalBalance});

  final double totalBalance;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [appColors.primary, appColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: appColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.walletTotalBalance,
            style: TextStyleConstants.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            totalBalance.toCurrency(withPrefix: true),
            style: TextStyleConstants.h5.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Header section (judul separator antar kelompok wallet).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 4.h),
      child: Text(
        title,
        style: TextStyleConstants.label1.copyWith(
          fontWeight: FontWeight.w700,
          color: appColors.textSecondary,
        ),
      ),
    );
  }
}
