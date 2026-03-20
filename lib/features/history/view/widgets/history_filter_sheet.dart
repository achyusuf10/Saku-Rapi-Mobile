import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/history/controllers/history_controller.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bottom sheet filter dompet untuk History.
///
/// Menampilkan daftar dompet user, memungkinkan pilih salah satu
/// atau "Semua Dompet" untuk menunjukkan semua transaksi.
class HistoryFilterSheet extends ConsumerStatefulWidget {
  const HistoryFilterSheet({super.key});

  @override
  ConsumerState<HistoryFilterSheet> createState() => _HistoryFilterSheetState();
}

class _HistoryFilterSheetState extends ConsumerState<HistoryFilterSheet> {
  String? _selectedWalletId;

  @override
  void initState() {
    super.initState();
    _selectedWalletId = ref.read(historyControllerProvider).filterWalletId;
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;
    final walletState = ref.watch(walletControllerProvider);
    final wallets = walletState.value ?? [];

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      decoration: BoxDecoration(
        color: appColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: appColors.border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          SizedBox(height: 16.h),

          // ── Title ──
          Text(
            l10n.historySelectWallet,
            style: TextStyleConstants.h7.copyWith(
              fontWeight: FontWeight.w700,
              color: appColors.textPrimary,
            ),
          ),

          SizedBox(height: 16.h),

          // ── Semua Dompet ──
          _WalletOption(
            label: l10n.historyAllWallets,
            icon: FontAwesomeIcons.wallet,
            isSelected: _selectedWalletId == null,
            onTap: () => setState(() => _selectedWalletId = null),
          ),

          // ── Daftar Dompet ──
          ...wallets.map((wallet) {
            return _WalletOption(
              label: wallet.name,
              icon: FontAwesomeIcons.wallet,
              color: _hexColor(wallet.color),
              isSelected: _selectedWalletId == wallet.id,
              onTap: () => setState(() => _selectedWalletId = wallet.id),
            );
          }),

          SizedBox(height: 16.h),

          // ── Buttons ──
          Row(
            children: [
              Expanded(
                child: SakuButton(
                  text: l10n.historyResetFilter,
                  onPressed: () {
                    ref
                        .read(historyControllerProvider.notifier)
                        .setFilterWallet(null);
                    Navigator.pop(context);
                  },
                  isOutlined: true,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: SakuButton(
                  text: l10n.historyApplyFilter,
                  onPressed: () {
                    ref
                        .read(historyControllerProvider.notifier)
                        .setFilterWallet(_selectedWalletId);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _hexColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('FF');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

/// Opsi dompet tunggal dalam filter.
class _WalletOption extends StatelessWidget {
  const _WalletOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final effectiveColor = color ?? appColors.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        margin: EdgeInsets.only(bottom: 4.h),
        decoration: BoxDecoration(
          color: isSelected
              ? appColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
          border: isSelected
              ? Border.all(color: appColors.primary.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            FaIcon(icon, size: 16.r, color: effectiveColor),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: TextStyleConstants.b2.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: appColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              FaIcon(
                FontAwesomeIcons.circleCheck,
                size: 16.r,
                color: appColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
