import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/investment/controllers/investment_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Widget ringkasan portfolio investasi di bagian atas halaman.
///
/// Menampilkan total nilai portfolio, total modal, P/L absolut & persentase,
/// dan unit summary. Menggunakan gradient emerald konsisten dengan
/// card-card lain (Dashboard, Wallet).
class InvestmentPortfolioSummary extends ConsumerWidget {
  const InvestmentPortfolioSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

    // Warna P/L — kontras di atas gradient emerald
    final plColor = isProfit
        ? const Color.fromARGB(255, 88, 255, 188) // Emerald
        : const Color(0xFFFCA5A5); // Red 300

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF065F46), const Color(0xFF047857)]
              : [colors.primaryDark, colors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF065F46).withValues(alpha: 0.4)
                : colors.primary.withValues(alpha: 0.25),
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
                color: colors.onPrimary.withValues(alpha: 0.85),
              ),
              SizedBox(width: 8.w),
              Text(
                l10n.investmentPortfolio,
                style: TextStyleConstants.label1.copyWith(
                  color: colors.onPrimary.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (isPriceLoading)
                SizedBox(
                  width: 14.w,
                  height: 14.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.onPrimary.withValues(alpha: 0.75),
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),

          // ─── Total Value ───
          Text(
            totalValue.toCurrency(),
            style: TextStyleConstants.h4.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),

          // ─── P/L Badge ───
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: plColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(plIcon, size: 11.w, color: plColor),
                SizedBox(width: 6.w),
                Text(
                  '${isProfit ? '+' : ''}${totalPL.toCurrency()}',
                  style: TextStyleConstants.label1.copyWith(
                    color: plColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  '(${totalPLPercent.toPercentage()})',
                  style: TextStyleConstants.label2.copyWith(
                    color: plColor.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // ─── Invested + Holdings Row ───
          Row(
            children: [
              // Modal
              Expanded(
                child: _InfoChip(
                  icon: FontAwesomeIcons.coins,
                  label: l10n.investmentBuyPrice,
                  value: totalInvested.toCurrency(withPrefix: false),
                ),
              ),
              if (unitSummary.isNotEmpty) ...[
                SizedBox(width: 10.w),
                // Holdings ringkas
                Expanded(
                  child: _InfoChip(
                    icon: FontAwesomeIcons.layerGroup,
                    label: l10n.investmentTotalUnits,
                    value: _buildUnitString(unitSummary),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Gabungkan unit summary jadi string ringkas, e.g. "5 gr • 0.01 BTC".
  String _buildUnitString(
    List<({String label, double amount, String unit})> summary,
  ) {
    return summary
        .map((e) {
          final amountStr = e.amount.truncateToDouble() == e.amount
              ? e.amount.toInt().toString()
              : e.amount.toStringAsFixed(2);
          return '$amountStr ${e.unit}';
        })
        .join(' • ');
  }
}

/// Sub-section chip untuk informasi sekunder (modal, holdings).
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: colors.onPrimary.withValues(alpha: 0.15),
      ),
      child: Row(
        children: [
          FaIcon(
            icon,
            size: 12.w,
            color: Color.fromARGB(255, 88, 255, 188), // Emerald 300
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyleConstants.label3.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.85),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyleConstants.label2.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
