import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/investment/controllers/investment_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Widget ringkasan total portofolio investasi.
///
/// Menampilkan nilai saat ini, total modal, dan P&L keseluruhan.
/// Diletakkan di bagian atas [InvestmentListScreen].
class InvestmentPortfolioSummaryWidget extends StatelessWidget {
  const InvestmentPortfolioSummaryWidget({
    super.key,
    required this.investmentState,
  });

  final InvestmentState investmentState;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    final totalValue = investmentState.totalPortfolioValue;
    final totalPL = investmentState.totalProfitLoss;
    final plPercent = investmentState.totalProfitLossPercentage;
    final isProfit = investmentState.isOverallProfit;
    final plColor = isProfit ? colors.income : colors.expense;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Label portofolio ──
          Text(
            l10n.investmentPortfolio,
            style: TextStyleConstants.caption.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6.h),

          // ── Total nilai ──
          Text(
            totalValue.toCurrency(),
            style: TextStyleConstants.h5.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12.h),

          // ── Divider ──
          Divider(color: Colors.white24, height: 1),
          SizedBox(height: 12.h),

          // ── P&L Row ──
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: plColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      isProfit
                          ? FontAwesomeIcons.arrowTrendUp
                          : FontAwesomeIcons.arrowTrendDown,
                      size: 10.r,
                      color: plColor,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${isProfit ? '+' : ''}${plPercent.toStringAsFixed(2)}%',
                      style: TextStyleConstants.label3.copyWith(
                        color: plColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '${isProfit ? '+' : ''}${totalPL.toCurrency()}',
                  style: TextStyleConstants.b2.copyWith(
                    color: plColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                l10n.investmentTotalPL,
                style: TextStyleConstants.caption.copyWith(
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
