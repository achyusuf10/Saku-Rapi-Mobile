import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/utils/color_utils.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_category_icon.dart';
import 'package:app_saku_rapi/global/widgets/shimmer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Global bottom sheet picker untuk memilih wallet.
///
/// Centralized widget yang menangani semua kebutuhan wallet picking:
/// - Pilih wallet tunggal (transaksi, investasi)
/// - Pilih wallet dengan opsi "Semua Dompet" (budget scope)
/// - Exclude wallet tertentu (transfer: exclude source saat pilih destination)
/// - Shimmer loading state
/// - Dark/light theme
///
/// Mengembalikan [WalletModel?]:
/// - `WalletModel` jika user memilih wallet tertentu
/// - `null` jika user memilih "Semua Dompet" (hanya saat [showAllOption] true)
/// - `null` jika user dismiss tanpa memilih
class SakuWalletPickerSheet extends ConsumerWidget {
  const SakuWalletPickerSheet({
    super.key,
    this.selectedWalletId,
    this.excludeWalletId,
    this.showAllOption = false,
    this.allLabel,
    this.title,
    this.showBalance = true,
  });

  /// ID wallet yang sedang terpilih (untuk highlight).
  final String? selectedWalletId;

  /// ID wallet yang dikecualikan dari list (misal: wallet asal pada transfer).
  final String? excludeWalletId;

  /// Tampilkan opsi "Semua Dompet" di atas list.
  /// Jika dipilih, mengembalikan `null` dengan flag [_allWalletsSelected].
  final bool showAllOption;

  /// Label untuk opsi "Semua Dompet". Default dari l10n.
  final String? allLabel;

  /// Judul sheet. Default dari l10n.
  final String? title;

  /// Tampilkan saldo di setiap item wallet.
  final bool showBalance;

  /// Sentinel: dipakai internal untuk membedakan "pilih semua" vs "dismiss".
  static const _allWalletsSentinel = '__all_wallets__';

  /// Tampilkan picker dan kembalikan wallet yang dipilih.
  ///
  /// Return value:
  /// - [WalletModel] jika user memilih wallet tertentu
  /// - `null` + `isAllWallets=true` — lihat [showWithAllResult]
  /// - `null` jika dismiss
  static Future<WalletModel?> show(
    BuildContext context, {
    String? selectedWalletId,
    String? excludeWalletId,
    bool showAllOption = false,
    String? allLabel,
    String? title,
    bool showBalance = true,
  }) async {
    final result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SakuWalletPickerSheet(
        selectedWalletId: selectedWalletId,
        excludeWalletId: excludeWalletId,
        showAllOption: showAllOption,
        allLabel: allLabel,
        title: title,
        showBalance: showBalance,
      ),
    );

    if (result is WalletModel) return result;
    return null;
  }

  /// Tampilkan picker yang bisa membedakan "Semua Dompet" vs dismiss.
  ///
  /// Return value berupa record:
  /// - `(wallet: WalletModel, isAll: false)` — user pilih wallet tertentu
  /// - `(wallet: null, isAll: true)` — user pilih "Semua Dompet"
  /// - `null` — user dismiss tanpa memilih
  static Future<({WalletModel? wallet, bool isAll})?> showWithAllResult(
    BuildContext context, {
    String? selectedWalletId,
    String? excludeWalletId,
    String? allLabel,
    String? title,
    bool showBalance = true,
  }) async {
    final result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SakuWalletPickerSheet(
        selectedWalletId: selectedWalletId,
        showAllOption: true,
        excludeWalletId: excludeWalletId,
        allLabel: allLabel,
        title: title,
        showBalance: showBalance,
      ),
    );

    if (result is WalletModel) return (wallet: result, isAll: false);
    if (result == _allWalletsSentinel) return (wallet: null, isAll: true);
    return null; // dismissed
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final walletState = ref.watch(walletControllerProvider);
    final sheetTitle = title ?? l10n.transactionSelectWallet;

    return SafeArea(
      child: Container(
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
            // ─── Handle bar ───
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

            // ─── Title ───
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  sheetTitle,
                  style: TextStyleConstants.h6.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),

            // ─── Content ───
            if (walletState.status == WalletStatus.loading ||
                walletState.status == WalletStatus.initial)
              const _WalletPickerShimmer()
            else
              _buildWalletList(context, walletState.wallets),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletList(BuildContext context, List<WalletModel> allWallets) {
    final colors = context.colors;
    final l10n = context.l10n;

    final wallets = allWallets.where((w) => w.id != excludeWalletId).toList();

    if (wallets.isEmpty && !showAllOption) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h),
        child: Center(
          child: Text(
            l10n.walletEmpty,
            style: TextStyleConstants.b2.copyWith(color: colors.textSecondary),
          ),
        ),
      );
    }

    final isAllSelected = showAllOption && selectedWalletId == null;

    return Flexible(
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        itemCount: wallets.length + (showAllOption ? 1 : 0),
        separatorBuilder: (_, _) => SizedBox(height: 4.h),
        itemBuilder: (context, index) {
          // ─── "Semua Dompet" option ───
          if (showAllOption && index == 0) {
            return _AllWalletsItem(
              label: allLabel ?? l10n.budgetAllWallets,
              isSelected: isAllSelected,
              onTap: () => Navigator.pop(context, _allWalletsSentinel),
            );
          }

          final walletIndex = showAllOption ? index - 1 : index;
          final wallet = wallets[walletIndex];
          final isSelected = wallet.id == selectedWalletId;

          return _WalletPickerItem(
            wallet: wallet,
            isSelected: isSelected,
            showBalance: showBalance,
            onTap: () => Navigator.pop(context, wallet),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Shimmer loading state
// ═══════════════════════════════════════════════════

class _WalletPickerShimmer extends StatelessWidget {
  const _WalletPickerShimmer();

  @override
  Widget build(BuildContext context) {
    return ShimmerWidget.custom(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            4,
            (_) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _ShimmerRow(),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final baseColor = context.isDarkMode ? Colors.grey.shade800 : Colors.white;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        children: [
          // Icon placeholder
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          SizedBox(width: 12.w),
          // Name placeholder
          Expanded(
            child: Container(
              height: 14.h,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          SizedBox(width: 32.w),
          // Balance placeholder
          Container(
            width: 80.w,
            height: 12.h,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// "Semua Dompet" item
// ═══════════════════════════════════════════════════

class _AllWalletsItem extends StatelessWidget {
  const _AllWalletsItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
            // Globe icon
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: (isSelected ? colors.primary : colors.textSecondary)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.globe,
                  size: 16.w,
                  color: isSelected ? colors.primary : colors.textSecondary,
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // Label
            Expanded(
              child: Text(
                label,
                style: TextStyleConstants.b2.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? colors.primary : colors.textPrimary,
                ),
              ),
            ),

            // Check icon
            if (isSelected)
              FaIcon(
                FontAwesomeIcons.circleCheck,
                size: 16.w,
                color: colors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Wallet item
// ═══════════════════════════════════════════════════

class _WalletPickerItem extends StatelessWidget {
  const _WalletPickerItem({
    required this.wallet,
    required this.isSelected,
    required this.showBalance,
    required this.onTap,
  });

  final WalletModel wallet;
  final bool isSelected;
  final bool showBalance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
            SakuCategoryIcon(
              iconName: wallet.icon,
              color: parseHexColor(wallet.color),
              size: 38,
              iconSize: 16,
              borderRadius: 10,
            ),
            SizedBox(width: 12.w),

            // Name
            Expanded(
              child: Text(
                wallet.name,
                style: TextStyleConstants.b2.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? colors.primary : colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Balance
            if (showBalance)
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
}
