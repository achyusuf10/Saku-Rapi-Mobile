import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/investment/controllers/investment_controller.dart';
import 'package:app_saku_rapi/features/investment/models/asset_price_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

/// Ticker horizontal yang menampilkan harga BTC dan Emas terkini.
///
/// Ditampilkan di bagian atas daftar investasi, di bawah summary card.
/// Ketika [investmentState.isPriceRefreshing] true, tombol refresh
/// menampilkan indikator loading kecil.
class InvestmentPriceTickerWidget extends StatelessWidget {
  const InvestmentPriceTickerWidget({
    super.key,
    required this.investmentState,
    required this.onRefresh,
  });

  final InvestmentState investmentState;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final isRefreshing = investmentState.isPriceRefreshing;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          // ── BTC chip ──
          _PriceChip(
            icon: FontAwesomeIcons.bitcoin,
            iconColor: const Color(0xFFF7931A),
            symbol: 'BTC',
            price: investmentState.btcPrice,
            isRefreshing: isRefreshing,
            colors: colors,
          ),
          SizedBox(width: 8.w),

          // ── Gold chip ──
          _PriceChip(
            icon: FontAwesomeIcons.coins,
            iconColor: const Color(0xFFD4A017),
            symbol: l10n.investmentTypeGold,
            price: investmentState.goldPrice,
            isRefreshing: isRefreshing,
            colors: colors,
          ),

          const Spacer(),

          // ── Updated label + refresh button ──
          if (!isRefreshing) ...[
            _UpdatedLabel(
              btcPrice: investmentState.btcPrice,
              goldPrice: investmentState.goldPrice,
              l10n: l10n,
              colors: colors,
            ),
            SizedBox(width: 4.w),
          ],

          GestureDetector(
            onTap: isRefreshing ? null : onRefresh,
            child: Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: isRefreshing
                  ? SizedBox(
                      width: 14.w,
                      height: 14.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: colors.primary,
                      ),
                    )
                  : FaIcon(
                      FontAwesomeIcons.arrowsRotate,
                      size: 12.r,
                      color: colors.textSecondary,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Private widgets
// ─────────────────────────────────────────────────────────────

class _PriceChip extends StatelessWidget {
  const _PriceChip({
    required this.icon,
    required this.iconColor,
    required this.symbol,
    required this.price,
    required this.isRefreshing,
    required this.colors,
  });

  final IconData icon;
  final Color iconColor;
  final String symbol;
  final AssetPriceModel? price;
  final bool isRefreshing;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    final c = colors as dynamic;
    final hasPrice = price != null;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: c.surfaceVariant as Color,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: c.border as Color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 10.r, color: iconColor),
          SizedBox(width: 4.w),
          Text(
            symbol,
            style: TextStyleConstants.label3.copyWith(
              color: c.textSecondary as Color,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 4.w),
          if (!hasPrice && isRefreshing)
            Container(
              width: 48.w,
              height: 10.h,
              decoration: BoxDecoration(
                color: (c.border as Color).withOpacity(0.5),
                borderRadius: BorderRadius.circular(3.r),
              ),
            )
          else if (!hasPrice)
            Text(
              '--',
              style: TextStyleConstants.label3.copyWith(
                color: c.textSecondary as Color,
              ),
            )
          else
            Text(
              _formatPrice(price!.priceIdr),
              style: TextStyleConstants.label3.copyWith(
                color: c.textPrimary as Color,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000000) {
      return '${(price / 1000000000).toStringAsFixed(2)}M';
    }
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(2)} jt';
    }
    final f = NumberFormat('#,##0', 'id_ID');
    return f.format(price);
  }
}

class _UpdatedLabel extends StatelessWidget {
  const _UpdatedLabel({
    required this.btcPrice,
    required this.goldPrice,
    required this.l10n,
    required this.colors,
  });

  final AssetPriceModel? btcPrice;
  final AssetPriceModel? goldPrice;
  final dynamic l10n;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    final latest = _latestFetch();
    if (latest == null) return const SizedBox.shrink();

    final diff = DateTime.now().difference(latest);
    final l = l10n as dynamic;
    final c = colors as dynamic;

    String timeStr;
    if (diff.inMinutes < 1) {
      timeStr = l.justNow as String;
    } else if (diff.inMinutes < 60) {
      timeStr = '${diff.inMinutes} ${l.minuteSuffix} ${l.agoSuffix}';
    } else {
      timeStr = '${diff.inHours} ${l.hourSuffix} ${l.agoSuffix}';
    }

    return Text(
      timeStr,
      style: TextStyleConstants.label3.copyWith(
        color: c.textSecondary as Color,
      ),
    );
  }

  DateTime? _latestFetch() {
    if (btcPrice == null && goldPrice == null) return null;
    if (btcPrice == null) return goldPrice!.fetchedAt;
    if (goldPrice == null) return btcPrice!.fetchedAt;
    return btcPrice!.fetchedAt.isAfter(goldPrice!.fetchedAt)
        ? btcPrice!.fetchedAt
        : goldPrice!.fetchedAt;
  }
}
