import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/investment/models/investment_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Card individual untuk menampilkan satu aset investasi.
///
/// Menampilkan nama, tipe, jumlah unit, harga beli, harga sekarang, dan P/L.
class InvestmentAssetCard extends StatelessWidget {
  const InvestmentAssetCard({
    super.key,
    required this.investment,
    this.onTap,
    this.onDelete,
  });

  final InvestmentModel investment;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  IconData _typeIcon(String type) {
    return switch (type) {
      'gold' => FontAwesomeIcons.coins,
      'crypto' => FontAwesomeIcons.bitcoin,
      _ => FontAwesomeIcons.chartLine,
    };
  }

  Color _typeColor(String type) {
    return switch (type) {
      'gold' => const Color(0xFFD4A017),
      'crypto' => const Color(0xFFF7931A),
      _ => const Color(0xFF10B981),
    };
  }

  String _typeLabel(BuildContext context, String type) {
    final l10n = context.l10n;
    return switch (type) {
      'gold' => l10n.investmentTypeGold,
      'crypto' => l10n.investmentTypeBtc,
      _ => l10n.investmentTypeCustom,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = _typeColor(investment.type);
    final isProfit = investment.isProfit;
    final plColor = investment.unrealizedPL == 0
        ? colors.textSecondary
        : isProfit
        ? colors.income
        : colors.expense;

    return SakuCard(
      onTap: onTap,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Column(
        children: [
          // ─── Top Row: Icon + Name + Type Badge ───
          Row(
            children: [
              // Type icon
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: FaIcon(
                    _typeIcon(investment.type),
                    size: 18.w,
                    color: typeColor,
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // Name & symbol
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      investment.name,
                      style: TextStyleConstants.b1.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(
                              alpha: isDark ? 0.2 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            _typeLabel(context, investment.type),
                            style: TextStyleConstants.label3.copyWith(
                              color: typeColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (investment.symbol != null) ...[
                          SizedBox(width: 6.w),
                          Text(
                            investment.symbol!,
                            style: TextStyleConstants.label2.copyWith(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (investment.hasLivePrice) ...[
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5.w,
                              vertical: 1.h,
                            ),
                            decoration: BoxDecoration(
                              color: colors.income.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(3.r),
                            ),
                            child: Text(
                              'LIVE',
                              style: TextStyleConstants.overline.copyWith(
                                color: colors.income,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // P/L
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    investment.currentValue.toCompactCurrency(),
                    style: TextStyleConstants.b1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: plColor.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (investment.unrealizedPL != 0)
                          FaIcon(
                            isProfit
                                ? FontAwesomeIcons.caretUp
                                : FontAwesomeIcons.caretDown,
                            size: 10.w,
                            color: plColor,
                          ),
                        if (investment.unrealizedPL != 0) SizedBox(width: 3.w),
                        Text(
                          '${isProfit ? '+' : ''}${investment.unrealizedPLPercent.toPercentage()}',
                          style: TextStyleConstants.label2.copyWith(
                            color: plColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 14.h),
          Divider(
            height: 1,
            color: colors.border.withValues(alpha: isDark ? 0.3 : 0.5),
          ),
          SizedBox(height: 14.h),

          // ─── Bottom Detail Chips ───
          Row(
            children: [
              _DetailChip(
                label: l10n.investmentAmount,
                value:
                    '${investment.amount} ${investment.type == 'gold' ? l10n.investmentGram : l10n.investmentUnit}',
              ),
              SizedBox(width: 8.w),
              _DetailChip(
                label: l10n.investmentBuyPrice,
                value: investment.avgBuyPrice.toCurrency(),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              _DetailChip(
                label: l10n.investmentCurrentPrice,
                value: investment.currentPrice.toCurrency(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isDark
              ? colors.surface.withValues(alpha: 0.8)
              : colors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8.r),
          border: isDark
              ? Border.all(color: colors.border.withValues(alpha: 0.2))
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyleConstants.label3.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 3.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyleConstants.label1.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
