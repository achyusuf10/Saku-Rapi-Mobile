import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/investment/models/investment_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Card untuk menampilkan detail satu aset investasi.
///
/// Menampilkan nama, jumlah, harga beli, harga saat ini, dan P&L.
/// Jika [isLoadingPrice] true (harga live sedang diambil), nilai saat ini
/// dan P&L ditampilkan sebagai skeleton.
class InvestmentAssetCard extends StatelessWidget {
  const InvestmentAssetCard({
    super.key,
    required this.investment,
    required this.isLoadingPrice,
    this.onEdit,
    this.onDelete,
  });

  final InvestmentModel investment;

  /// Sedang mengambil harga live? (hanya relevan untuk btc/gold)
  final bool isLoadingPrice;

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  // ── Helpers ──

  IconData get _typeIcon {
    switch (investment.type) {
      case InvestmentType.gold:
        return FontAwesomeIcons.coins;
      case InvestmentType.btc:
        return FontAwesomeIcons.bitcoin;
      case InvestmentType.custom:
        return FontAwesomeIcons.chartLine;
    }
  }

  Color _typeColor(BuildContext context) {
    switch (investment.type) {
      case InvestmentType.gold:
        return const Color(0xFFD4A017);
      case InvestmentType.btc:
        return const Color(0xFFF7931A);
      case InvestmentType.custom:
        return context.colors.primaryLight;
    }
  }

  String _unitLabel() {
    switch (investment.type) {
      case InvestmentType.gold:
        return 'gram';
      case InvestmentType.btc:
        return investment.symbol ?? 'BTC';
      case InvestmentType.custom:
        return investment.symbol ?? 'unit';
    }
  }

  bool get _haslivePrice => investment.livePrice != null;

  bool get _showSkeleton =>
      isLoadingPrice &&
      !_haslivePrice &&
      investment.type != InvestmentType.custom;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final tColor = _typeColor(context);

    final isProfit = investment.isProfit;
    final plColor = isProfit ? colors.income : colors.expense;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Column(
        children: [
          // ── Baris atas: ikon, nama, aksi ──
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 8.w, 10.h),
            child: Row(
              children: [
                // Ikon tipe
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: tColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: FaIcon(_typeIcon, size: 16.r, color: tColor),
                  ),
                ),
                SizedBox(width: 12.w),

                // Nama + symbol
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        investment.name,
                        style: TextStyleConstants.b2.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (investment.symbol != null) ...[
                        SizedBox(height: 2.h),
                        Text(
                          investment.symbol!,
                          style: TextStyleConstants.label3.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Aksi edit / delete
                PopupMenuButton<String>(
                  icon: FaIcon(
                    FontAwesomeIcons.ellipsisVertical,
                    size: 14.r,
                    color: colors.textSecondary,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.penToSquare,
                            size: 13.r,
                            color: colors.textPrimary,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            l10n.investmentEdit,
                            style: TextStyleConstants.b2.copyWith(
                              color: colors.textPrimary,
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
                            FontAwesomeIcons.trash,
                            size: 13.r,
                            color: colors.expense,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            l10n.investmentDelete,
                            style: TextStyleConstants.b2.copyWith(
                              color: colors.expense,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(
            color: colors.border,
            height: 1,
            indent: 16.w,
            endIndent: 16.w,
          ),

          // ── Baris bawah: angka ──
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
            child: Row(
              children: [
                // Jumlah
                _InfoCell(
                  label: l10n.investmentAmount,
                  value: '${_formatAmount(investment.amount)} ${_unitLabel()}',
                  colors: colors,
                ),
                _VertDivider(colors: colors),

                // Harga beli
                _InfoCell(
                  label: l10n.investmentBuyPrice,
                  value: investment.avgBuyPrice.toCurrency(),
                  colors: colors,
                ),
                _VertDivider(colors: colors),

                // Nilai saat ini + P&L
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _showSkeleton
                          ? _PriceSkeleton(colors: colors)
                          : Text(
                              investment.currentValue.toCurrency(),
                              style: TextStyleConstants.b2.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                              textAlign: TextAlign.end,
                            ),
                      SizedBox(height: 2.h),
                      _showSkeleton
                          ? _PriceSkeleton(colors: colors, width: 60.w)
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FaIcon(
                                  isProfit
                                      ? FontAwesomeIcons.caretUp
                                      : FontAwesomeIcons.caretDown,
                                  size: 10.r,
                                  color: plColor,
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  '${isProfit ? '+' : ''}${investment.profitLossPercentage.toStringAsFixed(2)}%',
                                  style: TextStyleConstants.label3.copyWith(
                                    color: plColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount == amount.truncateToDouble()) {
      return amount.toStringAsFixed(0);
    }
    // Hapus trailing zeros setelah decimal
    final s = amount.toStringAsFixed(8);
    return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
}

// ─────────────────────────────────────────────────────────────
// Private helpers
// ─────────────────────────────────────────────────────────────

class _InfoCell extends StatelessWidget {
  const _InfoCell({
    required this.label,
    required this.value,
    required this.colors,
  });

  final String label;
  final String value;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyleConstants.label3.copyWith(
              color: (colors as dynamic).textSecondary as Color,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: TextStyleConstants.label2.copyWith(
              fontWeight: FontWeight.w600,
              color: (colors as dynamic).textPrimary as Color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  const _VertDivider({required this.colors});

  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32.h,
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      color: (colors as dynamic).border as Color,
    );
  }
}

class _PriceSkeleton extends StatelessWidget {
  const _PriceSkeleton({required this.colors, this.width});

  final dynamic colors;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 80.w,
      height: 14.h,
      decoration: BoxDecoration(
        color: (colors as dynamic).surfaceVariant as Color,
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }
}
