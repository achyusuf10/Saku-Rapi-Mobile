import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/reports/models/report_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Card ringkasan income vs expense.
///
/// Menampilkan total income, total expense, net, dan badge perubahan %.
class ReportSummaryCard extends StatelessWidget {
  const ReportSummaryCard({
    super.key,
    required this.summary,
    required this.expenseChange,
    required this.incomeChange,
  });

  final ReportPeriodSummaryModel summary;
  final double expenseChange;
  final double incomeChange;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final isPositiveNet = summary.net >= 0;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Net
          Row(
            children: [
              Text(
                l10n.reportNet,
                style: TextStyleConstants.label2.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${isPositiveNet ? '+' : ''}${summary.net.toCurrency()}',
                style: TextStyleConstants.h7.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isPositiveNet ? colors.income : colors.expense,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Income row
          _SummaryRow(
            label: l10n.reportIncome,
            value: summary.totalIncome.toCompactCurrency(),
            valueColor: colors.income,
            change: incomeChange,
            colors: colors,
          ),
          SizedBox(height: 10.h),
          // Expense row
          _SummaryRow(
            label: l10n.reportExpense,
            value: summary.totalExpense.toCompactCurrency(),
            valueColor: colors.expense,
            change: expenseChange,
            invertBadge: true,
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.change,
    required this.colors,
    this.invertBadge = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final double change;
  final dynamic colors;
  final bool invertBadge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyleConstants.label2.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyleConstants.b2.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
        if (change != 0) ...[
          SizedBox(width: 6.w),
          _buildChangeBadge(change, invertBadge),
        ],
      ],
    );
  }

  Widget _buildChangeBadge(double change, bool invert) {
    final isDown = change < 0;
    // For expense: down=good(green), up=bad(red). For income: opposite.
    final Color badgeColor;
    if (invert) {
      badgeColor = isDown ? colors.income : colors.expense;
    } else {
      badgeColor = isDown ? colors.expense : colors.income;
    }

    final arrow = isDown ? '\u2193' : '\u2191';
    final text = '${change.abs().toStringAsFixed(0)}%';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        '$arrow $text',
        style: TextStyleConstants.label3.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
