import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Selector tipe transaksi sebagai chip horizontal.
///
/// Menampilkan chip untuk income, expense, transfer, debt, loan.
/// Adjustment tidak ditampilkan di sini (dipanggil dari wallet page).
class TransactionTypeSelector extends StatelessWidget {
  const TransactionTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final TransactionTypeEnum selected;
  final ValueChanged<TransactionTypeEnum> onChanged;
  final bool enabled;

  /// Tipe yang ditampilkan di form manual.
  static const _visibleTypes = [
    TransactionTypeEnum.expense,
    TransactionTypeEnum.income,
    TransactionTypeEnum.transfer,
    TransactionTypeEnum.debt,
    TransactionTypeEnum.loan,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: 38.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _visibleTypes.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final type = _visibleTypes[index];
          final isSelected = type == selected;
          final typeColor = _colorForType(type, colors);

          return GestureDetector(
            onTap: enabled ? () => onChanged(type) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? typeColor.withValues(alpha: 0.15)
                    : colors.surface,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isSelected
                      ? typeColor.withValues(alpha: 0.8)
                      : colors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  _labelForType(type, context),
                  style: TextStyleConstants.label1.copyWith(
                    color: isSelected ? typeColor : colors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _labelForType(TransactionTypeEnum type, BuildContext context) {
    final l10n = context.l10n;
    return switch (type) {
      TransactionTypeEnum.expense => l10n.transactionExpense,
      TransactionTypeEnum.income => l10n.transactionIncome,
      TransactionTypeEnum.transfer => l10n.transactionTransfer,
      TransactionTypeEnum.debt => l10n.transactionDebt,
      TransactionTypeEnum.loan => l10n.transactionLoan,
      TransactionTypeEnum.adjustment => l10n.transactionAdjustment,
      TransactionTypeEnum.transferToAsset => l10n.transactionTransfer,
    };
  }

  Color _colorForType(TransactionTypeEnum type, AppColorScheme colors) {
    return switch (type) {
      TransactionTypeEnum.expense => colors.expense,
      TransactionTypeEnum.income => colors.income,
      TransactionTypeEnum.transfer => colors.transfer,
      TransactionTypeEnum.debt => colors.debt,
      TransactionTypeEnum.loan => colors.loan,
      _ => colors.primary,
    };
  }
}
