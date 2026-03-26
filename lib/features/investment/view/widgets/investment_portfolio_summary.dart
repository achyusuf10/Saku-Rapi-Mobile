import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/investment/controllers/investment_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Widget ringkasan portfolio investasi di bagian atas halaman.
///
/// Menampilkan total nilai portfolio, total modal, P/L absolut & persentase.
/// Menggunakan granular providers agar hanya rebuild saat data portfolio berubah.
class InvestmentPortfolioSummary extends ConsumerWidget {
  const InvestmentPortfolioSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final totalValue = ref.watch(investmentTotalValueProvider);
    final totalInvested = ref.watch(investmentTotalInvestedProvider);
    final totalPL = ref.watch(investmentTotalPLProvider);
    final totalPLPercent = ref.watch(investmentTotalPLPercentProvider);
    final unitSummary = ref.watch(investmentUnitSummaryProvider);
    final isPriceLoading = ref.watch(
      investmentControllerProvider.select((s) => s.isPriceLoading),
    );

    final isProfit = totalPL >= 0;
    final plIcon = isProfit
        ? FontAwesomeIcons.arrowTrendUp
        : FontAwesomeIcons.arrowTrendDown;

    // Warna P/L yang kontras di atas gradient primary
    final plBadgeColor = isProfit
        ? const Color(0xFF34D399) // Emerald 400
        : const Color(0xFFF87171); // Red 400

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF065F46), // Emerald 800
            const Color(0xFF047857), // Emerald 700
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF065F46).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.briefcase,
                size: 14.w,
                color: const Color(0xFFA7F3D0), // Emerald 200
              ),
              SizedBox(width: 8.w),
              Text(
                l10n.investmentPortfolio,
                style: TextStyleConstants.label1.copyWith(
                  color: const Color(0xFFA7F3D0), // Emerald 200
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (isPriceLoading)
                SizedBox(
                  width: 14.w,
                  height: 14.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: const Color(0xFFA7F3D0),
                  ),
                ),
            ],
          ),
          SizedBox(height: 14.h),

          // ─── Total Value ───
          Text(
            totalValue.toCurrency(),
            style: TextStyleConstants.h4.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 6.h),

          // ─── P/L Badge ───
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: plBadgeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(plIcon, size: 11.w, color: plBadgeColor),
                SizedBox(width: 6.w),
                Text(
                  '${isProfit ? '+' : ''}${totalPL.toCurrency()}',
                  style: TextStyleConstants.label1.copyWith(
                    color: plBadgeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  '(${totalPLPercent.toPercentage()})',
                  style: TextStyleConstants.label2.copyWith(
                    color: plBadgeColor.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // ─── Invested Row ───
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.coins,
                  size: 13.w,
                  color: const Color(0xFFA7F3D0),
                ),
                SizedBox(width: 10.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.investmentBuyPrice,
                      style: TextStyleConstants.label2.copyWith(
                        color: const Color(0xFF6EE7B7), // Emerald 300
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      totalInvested.toCurrency(),
                      style: TextStyleConstants.b1.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── Unit Summary (Total Holdings) ───
          if (unitSummary.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.layerGroup,
                        size: 13.w,
                        color: const Color(0xFFA7F3D0),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        l10n.investmentTotalUnits,
                        style: TextStyleConstants.label2.copyWith(
                          color: const Color(0xFF6EE7B7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: unitSummary.map((entry) {
                      final amountStr =
                          entry.amount.truncateToDouble() == entry.amount
                          ? entry.amount.toInt().toString()
                          : entry.amount.toStringAsFixed(2);
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '$amountStr [${entry.unit}] ${entry.label}',
                          style: TextStyleConstants.label2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
