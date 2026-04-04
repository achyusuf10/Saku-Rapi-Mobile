import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/utils/color_utils.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_category_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Tombol filter dompet reusable yang menampilkan popup menu.
///
/// Menampilkan daftar dompet dengan icon & nama.
/// "Semua Dompet" menggunakan icon globe.
/// Masing-masing wallet menampilkan icon sesuai [WalletModel.icon].
class SakuWalletFilterButton extends ConsumerWidget {
  const SakuWalletFilterButton({
    super.key,
    required this.selectedWalletId,
    required this.onSelected,
    this.allLabel,
  });

  /// Sentinel value untuk opsi "Semua Dompet".
  /// Dipakai karena PopupMenuButton menganggap `null` sebagai dismiss/cancel.
  static const _allWalletsValue = '__all__';

  /// ID wallet yang sedang dipilih. `null` = semua.
  final String? selectedWalletId;

  /// Callback saat user memilih wallet (null = semua).
  final ValueChanged<String?> onSelected;

  /// Label untuk opsi "Semua Dompet". Default dari l10n.
  final String? allLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final wallets = ref.watch(walletListProvider);
    final label = allLabel ?? l10n.historyAllWallets;

    return Row(
      children: [
        PopupMenuButton<String>(
          onSelected: (value) {
            onSelected(value == _allWalletsValue ? null : value);
          },
          offset: Offset(0, 40.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          color: colors.surface,
          itemBuilder: (context) => [
            // ─── Semua Dompet ───
            PopupMenuItem<String>(
              value: _allWalletsValue,
              child: _WalletMenuItem(
                icon: FontAwesomeIcons.globe,
                iconColor: selectedWalletId == null
                    ? colors.primary
                    : colors.textSecondary,
                label: label,
                isSelected: selectedWalletId == null,
              ),
            ),
            const PopupMenuDivider(),
            // ─── Dompet ───
            ...wallets.map(
              (wallet) => PopupMenuItem<String>(
                value: wallet.id,
                child: _WalletMenuItem(
                  icon: FontAwesomeIcons.wallet,
                  iconColor: selectedWalletId == wallet.id
                      ? colors.primary
                      : parseHexColor(
                          wallet.color,
                          fallback: colors.textSecondary,
                        ),
                  leading: SakuCategoryIcon.raw(
                    iconName: wallet.icon,
                    colorHex: wallet.color,
                    size: 14,
                    showBackground: false,
                    colorOverride: selectedWalletId == wallet.id
                        ? colors.primary
                        : null,
                  ),
                  label: wallet.name,
                  isSelected: selectedWalletId == wallet.id,
                ),
              ),
            ),
          ],
          child: Container(
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(10.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                selectedWalletId == null
                    ? FaIcon(
                        FontAwesomeIcons.globe,
                        color: colors.primary,
                        size: 16.w,
                      )
                    : SakuCategoryIcon.raw(
                        iconName:
                            wallets
                                .where((w) => w.id == selectedWalletId)
                                .firstOrNull
                                ?.icon ??
                            'wallet',
                        colorHex:
                            wallets
                                .where((w) => w.id == selectedWalletId)
                                .firstOrNull
                                ?.color ??
                            '#6B7280',
                        size: 16,
                        showBackground: false,
                      ),
                4.horizontalSpace,
                Text(
                  ' ${wallets.where((w) => w.id == selectedWalletId).firstOrNull?.name ?? label}',
                  style: TextStyleConstants.caption.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                6.horizontalSpace,
                FaIcon(
                  FontAwesomeIcons.caretDown,
                  size: 12.w,
                  color: colors.textPrimary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Item di dalam popup menu wallet filter.
class _WalletMenuItem extends StatelessWidget {
  const _WalletMenuItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.isSelected,
    this.leading,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final bool isSelected;

  /// Widget custom leading (override icon + iconColor).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        leading ?? FaIcon(icon, size: 14.w, color: iconColor),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            label,
            style: TextStyleConstants.b2.copyWith(
              color: isSelected ? colors.primary : colors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        if (isSelected)
          FaIcon(FontAwesomeIcons.check, size: 12.w, color: colors.primary),
      ],
    );
  }
}
