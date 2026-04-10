import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/themes/app_colors.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/features/wallet/view/widgets/wallet_adjust_sheet.dart';
import 'package:app_saku_rapi/features/wallet/view/widgets/wallet_card_tile.dart';
import 'package:app_saku_rapi/features/wallet/view/widgets/wallet_form_sheet.dart';
import 'package:app_saku_rapi/features/wallet/view/widgets/wallet_shimmer.dart';
import 'package:app_saku_rapi/features/wallet/view/widgets/wallet_summary_card.dart';
import 'package:app_saku_rapi/global/widgets/saku_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Halaman daftar wallet milik user.
///
/// Menampilkan summary card total saldo, list wallet termasuk & dikecualikan,
/// FAB untuk menambah wallet baru, dan aksi edit/hapus per wallet.
class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  @override
  void initState() {
    super.initState();
    // Load wallets saat halaman pertama kali dibuka.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletControllerProvider.notifier).loadWallets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final walletState = ref.watch(walletControllerProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.walletTitle), centerTitle: false),
      floatingActionButton: FloatingActionButton(
        onPressed: () => WalletFormSheet.show(context),
        backgroundColor: colors.primary,
        child: FaIcon(
          FontAwesomeIcons.plus,
          color: colors.onPrimary,
          size: 18.w,
        ),
      ),
      body: _buildBody(walletState, colors, l10n),
    );
  }

  Widget _buildBody(
    WalletState walletState,
    AppColorScheme colors,
    dynamic l10n,
  ) {
    // Loading
    if (walletState.status == WalletStatus.loading) {
      return const WalletShimmer();
    }

    // Error
    if (walletState.status == WalletStatus.error) {
      return Center(
        child: SakuEmptyState(
          icon: FontAwesomeIcons.triangleExclamation,
          title: walletState.errorMessage ?? '',
          message: walletState.errorMessage ?? '',
          actionLabel: l10n.retryButton,
          onAction: () =>
              ref.read(walletControllerProvider.notifier).loadWallets(),
        ),
      );
    }

    // Empty
    if (walletState.wallets.isEmpty) {
      return Center(
        child: SakuEmptyState(
          icon: FontAwesomeIcons.wallet,
          title: l10n.walletEmpty,
          message: l10n.walletEmptyHint,
          actionLabel: l10n.walletAdd,
          onAction: () => WalletFormSheet.show(context),
        ),
      );
    }

    // Loaded — sections
    final included = ref.watch(includedWalletsProvider);
    final excluded = ref.watch(excludedWalletsProvider);
    final totalBalance = ref.watch(walletTotalBalanceProvider);

    return RefreshIndicator(
      color: colors.primary,
      onRefresh: () =>
          ref.read(walletControllerProvider.notifier).loadWallets(),
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 80.h),
        children: [
          // Summary card
          WalletSummaryCard(
            totalBalance: totalBalance,
            walletCount: included.length,
          ),
          SizedBox(height: 24.h),

          // Included section
          if (included.isNotEmpty) ...[
            _SectionHeader(title: l10n.walletIncludedSection),
            SizedBox(height: 8.h),
            ...included.map(
              (wallet) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: _buildWalletTile(wallet),
              ),
            ),
          ],

          // Excluded section
          if (excluded.isNotEmpty) ...[
            SizedBox(height: 16.h),
            _SectionHeader(title: l10n.walletExcludedSection),
            SizedBox(height: 8.h),
            ...excluded.map(
              (wallet) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: _buildWalletTile(wallet),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWalletTile(WalletModel wallet) {
    return WalletCardTile(
      wallet: wallet,
      onTap: () => _showWalletActions(wallet),
      trailing: PopupMenuButton<String>(
        icon: FaIcon(
          FontAwesomeIcons.ellipsisVertical,
          size: 16.w,
          color: context.colors.textSecondary,
        ),
        onSelected: (value) => _handleMenuAction(value, wallet),
        itemBuilder: (context) {
          final l10n = context.l10n;
          return [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.penToSquare,
                    size: 14.w,
                    color: context.colors.textPrimary,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    l10n.walletOptionEdit,
                    style: TextStyleConstants.b2.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'adjust',
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.scaleBalanced,
                    size: 14.w,
                    color: context.colors.textPrimary,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    l10n.walletOptionAdjust,
                    style: TextStyleConstants.b2.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.trashCan,
                    size: 14.w,
                    color: context.colors.error,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    l10n.walletOptionDelete,
                    style: TextStyle(color: context.colors.error),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );
  }

  void _showWalletActions(WalletModel wallet) {
    WalletFormSheet.show(context, editWallet: wallet);
  }

  void _handleMenuAction(String action, WalletModel wallet) {
    switch (action) {
      case 'edit':
        WalletFormSheet.show(context, editWallet: wallet);
      case 'adjust':
        WalletAdjustSheet.show(context, wallet: wallet);
      case 'delete':
        _confirmDelete(wallet);
    }
  }

  Future<void> _confirmDelete(WalletModel wallet) async {
    final l10n = context.l10n;

    final confirmed = await context.showConfirmDialog(
      title: l10n.walletDelete,
      message: l10n.walletDeleteConfirm(wallet.name),
      confirmLabel: l10n.walletDelete,
    );

    if (confirmed != true) return;
    if (!mounted) return;

    context.showLoadingOverlay();

    try {
      final result = await ref
          .read(walletControllerProvider.notifier)
          .deleteWallet(wallet.id);

      if (!mounted) return;

      if (result.isSuccess()) {
        context.showAppAlert(
          l10n.walletSuccessDelete(wallet.name),
          alertType: AlertTypeEnum.success,
        );
      } else {
        final (message, _, _, _) = result.dataError()!;
        context.showAppAlert(message, alertType: AlertTypeEnum.error);
      }
    } finally {
      if (mounted) {
        context.closeOverlay();
      }
    }
  }
}

/// Header untuk section (Included / Excluded).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Text(
      title,
      style: TextStyleConstants.label1.copyWith(
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
      ),
    );
  }
}
