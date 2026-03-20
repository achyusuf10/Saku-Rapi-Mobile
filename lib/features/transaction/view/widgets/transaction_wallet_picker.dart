import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/features/wallet/utils/wallet_icon_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Parsing hex color ke [Color], fallback abu-abu.
Color _hexColor(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF6B7280);
  final cleaned = hex.replaceAll('#', '');
  if (cleaned.length == 6) {
    return Color(int.parse('FF$cleaned', radix: 16));
  }
  return const Color(0xFF6B7280);
}

/// Bottom sheet pemilih dompet.
///
/// Menampilkan daftar wallet dari [walletControllerProvider].
/// Dapat dikonfigurasi untuk mengecualikan satu wallet tertentu
/// (berguna saat memilih destination wallet).
class TransactionWalletPicker extends ConsumerWidget {
  const TransactionWalletPicker({
    super.key,
    required this.selectedId,
    this.excludeWalletId,
  });

  final String? selectedId;

  /// ID wallet yang tidak boleh dipilih (misalnya wallet sumber saat transfer).
  final String? excludeWalletId;

  /// Menampilkan bottom sheet dan mengembalikan wallet terpilih.
  static Future<WalletModel?> show(
    BuildContext context, {
    required String? selectedId,
    String? excludeWalletId,
  }) {
    return showModalBottomSheet<WalletModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => TransactionWalletPicker(
        selectedId: selectedId,
        excludeWalletId: excludeWalletId,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletControllerProvider);
    final appColors = context.colors;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36.w,
            height: 4.h,
            margin: EdgeInsets.only(top: 10.h, bottom: 8.h),
            decoration: BoxDecoration(
              color: appColors.border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              l10n.transactionSelectWallet,
              style: TextStyleConstants.h7.copyWith(
                fontWeight: FontWeight.w700,
                color: appColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Divider(color: appColors.border, height: 1),
          walletAsync.when(
            loading: () => Padding(
              padding: EdgeInsets.all(24.r),
              child: const CircularProgressIndicator(),
            ),
            error: (_, __) => Padding(
              padding: EdgeInsets.all(24.r),
              child: Text(
                'Gagal memuat dompet',
                style: TextStyleConstants.b2.copyWith(color: appColors.error),
              ),
            ),
            data: (wallets) {
              final filtered = wallets
                  .where((w) => w.id != excludeWalletId)
                  .toList();
              if (filtered.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Text(
                    'Tidak ada dompet tersedia',
                    style: TextStyleConstants.b2.copyWith(
                      color: appColors.textSecondary,
                    ),
                  ),
                );
              }
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final wallet = filtered[i];
                    final isSelected = wallet.id == selectedId;
                    final walletColor = _hexColor(wallet.color);

                    return InkWell(
                      onTap: () => Navigator.pop(context, wallet),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 10.h,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38.r,
                              height: 38.r,
                              decoration: BoxDecoration(
                                color: walletColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Center(
                                child: FaIcon(
                                  getWalletIcon(wallet.icon),
                                  size: 16.r,
                                  color: walletColor,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    wallet.name,
                                    style: TextStyleConstants.b1.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: appColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    wallet.balance.toCurrency(withPrefix: true),
                                    style: TextStyleConstants.caption.copyWith(
                                      color: wallet.balance >= 0
                                          ? appColors.income
                                          : appColors.expense,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              FaIcon(
                                FontAwesomeIcons.check,
                                size: 14.r,
                                color: appColors.primary,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
