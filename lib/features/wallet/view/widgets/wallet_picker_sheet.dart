import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/category/utils/category_icon_mapper.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bottom sheet picker untuk memilih wallet (dipakai di form transaksi).
///
/// Menampilkan daftar semua wallet milik user dan mengembalikan
/// [WalletModel] yang dipilih.
class WalletPickerSheet extends ConsumerWidget {
  const WalletPickerSheet({
    super.key,
    this.selectedWalletId,
    this.excludeWalletId,
  });

  /// ID wallet yang sedang terpilih (untuk highlight).
  final String? selectedWalletId;

  /// ID wallet yang dikecualikan dari list (misal: wallet asal pada transfer).
  final String? excludeWalletId;

  /// Tampilkan picker dan kembalikan wallet yang dipilih.
  static Future<WalletModel?> show(
    BuildContext context, {
    String? selectedWalletId,
    String? excludeWalletId,
  }) {
    return showModalBottomSheet<WalletModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WalletPickerSheet(
        selectedWalletId: selectedWalletId,
        excludeWalletId: excludeWalletId,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final walletState = ref.watch(walletControllerProvider);

    final wallets = walletState.wallets
        .where((w) => w.id != excludeWalletId)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: EdgeInsets.only(top: 12.h, bottom: 8.h),
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),

          // Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.transactionSelectWallet,
                style: TextStyleConstants.h6.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // List
          if (wallets.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 32.h),
              child: Text(
                l10n.walletEmpty,
                style: TextStyleConstants.b2.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                itemCount: wallets.length,
                separatorBuilder: (_, __) => SizedBox(height: 4.h),
                itemBuilder: (context, index) {
                  final wallet = wallets[index];
                  final isSelected = wallet.id == selectedWalletId;

                  return _WalletPickerItem(
                    wallet: wallet,
                    isSelected: isSelected,
                    onTap: () => Navigator.pop(context, wallet),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Item dalam wallet picker list.
class _WalletPickerItem extends StatelessWidget {
  const _WalletPickerItem({
    required this.wallet,
    required this.isSelected,
    required this.onTap,
  });

  final WalletModel wallet;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final walletColor = _parseColor(wallet.color);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: isSelected
              ? Border.all(color: colors.primary, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: walletColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Center(
                child: FaIcon(
                  CategoryIconMapper.getIcon(wallet.icon),
                  size: 16.w,
                  color: walletColor,
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // Name
            Expanded(
              child: Text(
                wallet.name,
                style: TextStyleConstants.b2.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Balance
            Text(
              wallet.balance.toCurrency(),
              style: TextStyleConstants.label1.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Check icon
            if (isSelected) ...[
              SizedBox(width: 8.w),
              FaIcon(
                FontAwesomeIcons.circleCheck,
                size: 16.w,
                color: colors.primary,
              ),
            ],
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
