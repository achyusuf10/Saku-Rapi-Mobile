import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/features/wallet/utils/wallet_icon_data.dart';
import 'package:app_saku_rapi/features/wallet/view/widgets/wallet_adjust_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Tile untuk satu item wallet di daftar.
///
/// Menampilkan ikon, nama, saldo, dan menu opsi (edit, hapus, adjust).
class WalletListTile extends ConsumerWidget {
  const WalletListTile({super.key, required this.wallet});

  /// Wallet yang ditampilkan.
  final WalletModel wallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.colors;
    final walletColor = _hexToColor(wallet.color);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: appColors.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        leading: Container(
          width: 42.r,
          height: 42.r,
          decoration: BoxDecoration(
            color: walletColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Center(
            child: FaIcon(
              getWalletIcon(wallet.icon),
              size: 18.r,
              color: walletColor,
            ),
          ),
        ),
        title: Text(
          wallet.name,
          style: TextStyleConstants.b1.copyWith(
            fontWeight: FontWeight.w600,
            color: appColors.textPrimary,
          ),
        ),
        subtitle: Text(
          wallet.balance.toCurrency(withPrefix: true),
          style: TextStyleConstants.b2.copyWith(
            color: wallet.balance >= 0 ? appColors.income : appColors.expense,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: IconButton(
          icon: FaIcon(
            FontAwesomeIcons.ellipsisVertical,
            size: 16.r,
            color: appColors.textSecondary,
          ),
          onPressed: () => _showOptionsSheet(context, ref),
        ),
      ),
    );
  }

  /// Bottom sheet dengan opsi Edit, Hapus, dan Sesuaikan Saldo.
  void _showOptionsSheet(BuildContext context, WidgetRef ref) {
    final appColors = context.colors;
    final l10n = context.l10n;

    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar.
              Container(
                width: 36.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 8.h),
                decoration: BoxDecoration(
                  color: appColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              ListTile(
                leading: FaIcon(
                  FontAwesomeIcons.penToSquare,
                  size: 18.r,
                  color: appColors.primary,
                ),
                title: Text(
                  l10n.walletOptionEdit,
                  style: TextStyleConstants.b1.copyWith(
                    color: appColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  context.push(AppRouter.walletForm, extra: wallet);
                },
              ),
              ListTile(
                leading: FaIcon(
                  FontAwesomeIcons.scaleBalanced,
                  size: 18.r,
                  color: appColors.accent,
                ),
                title: Text(
                  l10n.walletOptionAdjust,
                  style: TextStyleConstants.b1.copyWith(
                    color: appColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showAdjustSheet(context, ref);
                },
              ),
              ListTile(
                leading: FaIcon(
                  FontAwesomeIcons.trashCan,
                  size: 18.r,
                  color: appColors.expense,
                ),
                title: Text(
                  l10n.walletOptionDelete,
                  style: TextStyleConstants.b1.copyWith(
                    color: appColors.expense,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _confirmDelete(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dialog konfirmasi sebelum menghapus wallet.
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;

    final confirmed = await context.showConfirmDialog(
      title: l10n.walletDelete,
      message: l10n.walletDeleteConfirm(wallet.name),
    );

    if (confirmed != true || !context.mounted) return;

    context.showLoadingOverlay();
    try {
      final result = await ref
          .read(walletControllerProvider.notifier)
          .removeWallet(wallet.id);

      if (!context.mounted) return;

      if (result.isSuccess()) {
        context.showAppAlert(l10n.walletSuccessDelete(wallet.name));
      } else {
        context.showAppAlert(
          result.dataError()?.$1 ?? l10n.walletErrorDelete,
          alertType: AlertTypeEnum.error,
        );
      }
    } finally {
      if (context.mounted) context.closeOverlay();
    }
  }

  /// Bottom sheet untuk menyesuaikan saldo.
  Future<void> _showAdjustSheet(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final actualBalance = await WalletAdjustSheet.show(context, wallet: wallet);

    if (actualBalance == null || !context.mounted) return;

    context.showLoadingOverlay();
    try {
      final result = await ref
          .read(walletControllerProvider.notifier)
          .adjustBalance(walletId: wallet.id, actualBalance: actualBalance);

      if (!context.mounted) return;

      if (result.isSuccess()) {
        context.showAppAlert(l10n.walletSuccessAdjust);
      } else {
        context.showAppAlert(
          result.dataError()?.$1 ?? l10n.walletErrorAdjust,
          alertType: AlertTypeEnum.error,
        );
      }
    } finally {
      if (context.mounted) context.closeOverlay();
    }
  }

  /// Konversi hex string `#RRGGBB` ke [Color].
  static Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('FF');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
