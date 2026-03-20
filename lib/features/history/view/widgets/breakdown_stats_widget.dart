import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/history/controllers/expense_breakdown_controller.dart';
import 'package:app_saku_rapi/global/widgets/saku_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Widget stats: vs bulan lalu + rata-rata harian.
///
/// Menampilkan dua kartu stats:
/// 1. Perubahan nominal & persentase vs bulan lalu (naik = merah, turun = hijau)
/// 2. Rata-rata pengeluaran harian pada kategori ini
class BreakdownStatsWidget extends ConsumerWidget {
  const BreakdownStatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.colors;
    final l10n = context.l10n;
    final breakdownState = ref.watch(expenseBreakdownControllerProvider);

    if (breakdownState.isLoading) {
      return _buildSkeleton(appColors);
    }

    final currentAmount = breakdownState.category.amount;
    final lastMonthAmount = breakdownState.lastMonthAmount;
    final difference = currentAmount - lastMonthAmount;
    final percentChange = lastMonthAmount > 0
        ? (difference / lastMonthAmount)
        : (currentAmount > 0 ? 1.0 : 0.0);

    final isIncrease = difference > 0;
    final changeColor = isIncrease ? appColors.expense : appColors.income;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          // ── vs Bulan Lalu ──
          Expanded(
            child: SakuCard(
              padding: EdgeInsets.all(12.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.breakdownVsLastMonth,
                    style: TextStyleConstants.label3.copyWith(
                      color: appColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      FaIcon(
                        isIncrease
                            ? FontAwesomeIcons.arrowUp
                            : FontAwesomeIcons.arrowDown,
                        size: 12.r,
                        color: changeColor,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          '${isIncrease ? '+' : ''}${difference.toCurrency()}',
                          style: TextStyleConstants.b2.copyWith(
                            fontWeight: FontWeight.w700,
                            color: changeColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${isIncrease ? '+' : ''}${percentChange.toPercentage(decimalDigits: 1)}',
                    style: TextStyleConstants.label3.copyWith(
                      fontWeight: FontWeight.w600,
                      color: changeColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // ── Rata-rata Harian ──
          Expanded(
            child: SakuCard(
              padding: EdgeInsets.all(12.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.breakdownDailyAverage,
                    style: TextStyleConstants.label3.copyWith(
                      color: appColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    breakdownState.dailyAverage.toCurrency(),
                    style: TextStyleConstants.b2.copyWith(
                      fontWeight: FontWeight.w700,
                      color: appColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '/ ${l10n.daySuffix}',
                    style: TextStyleConstants.label3.copyWith(
                      color: appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(appColors) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 80.h,
              decoration: BoxDecoration(
                color: appColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Container(
              height: 80.h,
              decoration: BoxDecoration(
                color: appColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
