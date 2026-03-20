import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/history/controllers/history_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bar ringkasan: Total In (hijau) | Total Out (merah) bulan ini.
///
/// Ditampilkan di bawah period header dan di atas TabBar.
class HistorySummaryBar extends ConsumerWidget {
  const HistorySummaryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.colors;
    final l10n = context.l10n;
    final historyState = ref.watch(historyControllerProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          // ── Total In ──
          Expanded(
            child: _SummaryChip(
              label: l10n.historyTotalIn,
              amount: historyState.monthlyIncome,
              color: appColors.income,
              icon: FontAwesomeIcons.arrowTrendUp,
            ),
          ),

          SizedBox(width: 12.w),

          // ── Total Out ──
          Expanded(
            child: _SummaryChip(
              label: l10n.historyTotalOut,
              amount: historyState.monthlyExpense,
              color: appColors.expense,
              icon: FontAwesomeIcons.arrowTrendDown,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip ringkasan tunggal (income atau expense).
class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: FaIcon(icon, size: 13.r, color: color),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyleConstants.label3.copyWith(
                    color: appColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  amount.toCompactCurrency(),
                  style: TextStyleConstants.b2.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
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
