import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/debt_loan_kind_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Selector untuk jenis operasi Hutang/Piutang.
///
/// Baris 1: Toggle Hutang | Piutang (tipe utama).
/// Baris 2: Switch pelunasan/penerimaan (mode settlement).
class DebtLoanKindSelector extends StatelessWidget {
  const DebtLoanKindSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final DebtLoanKindEnum selected;
  final ValueChanged<DebtLoanKindEnum> onChanged;

  /// Tipe utama — debt atau loan.
  bool get _isLoan =>
      selected == DebtLoanKindEnum.loan ||
      selected == DebtLoanKindEnum.loanCollection;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final isSettlement = selected.isSettlement;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Row 1: Tipe utama ───
        Row(
          children: [
            Expanded(
              child: _TypeButton(
                label: l10n.transactionDebt,
                icon: FontAwesomeIcons.handHoldingDollar,
                color: colors.debt,
                isSelected: !_isLoan,
                onTap: () => onChanged(
                  isSettlement
                      ? DebtLoanKindEnum.debtPayment
                      : DebtLoanKindEnum.debt,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _TypeButton(
                label: l10n.transactionLoan,
                icon: FontAwesomeIcons.handHoldingHand,
                color: colors.loan,
                isSelected: _isLoan,
                onTap: () => onChanged(
                  isSettlement
                      ? DebtLoanKindEnum.loanCollection
                      : DebtLoanKindEnum.loan,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // ─── Row 2: Toggle settlement ───
        _SettlementToggle(
          isSettlement: isSettlement,
          label: _isLoan
              ? l10n.debtLoanCollection
              : l10n.debtLoanSettlementTitle,
          activeColor: _isLoan ? colors.loan : colors.debt,
          onChanged: (value) {
            if (_isLoan) {
              onChanged(
                value ? DebtLoanKindEnum.loanCollection : DebtLoanKindEnum.loan,
              );
            } else {
              onChanged(
                value ? DebtLoanKindEnum.debtPayment : DebtLoanKindEnum.debt,
              );
            }
          },
        ),
      ],
    );
  }
}

/// Tombol tipe utama (Hutang / Piutang).
class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: isSelected ? color : colors.surface,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? color : colors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                icon,
                size: 16.sp,
                color: isSelected ? colors.onPrimary : colors.textSecondary,
              ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyleConstants.label1.copyWith(
                  color: isSelected ? colors.onPrimary : colors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toggle switch untuk mode pelunasan/penerimaan.
class _SettlementToggle extends StatelessWidget {
  const _SettlementToggle({
    required this.isSettlement,
    required this.label,
    required this.activeColor,
    required this.onChanged,
  });

  final bool isSettlement;
  final String label;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isSettlement
            ? activeColor.withValues(alpha: 0.08)
            : colors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isSettlement ? activeColor : colors.border),
      ),
      child: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.moneyBillTransfer,
            size: 14.sp,
            color: isSettlement ? activeColor : colors.textSecondary,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              label,
              style: TextStyleConstants.label1.copyWith(
                color: isSettlement ? activeColor : colors.textSecondary,
                fontWeight: isSettlement ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          SizedBox(
            height: 40.w,
            child: FittedBox(
              child: Switch.adaptive(
                value: isSettlement,
                onChanged: onChanged,
                activeTrackColor: activeColor,
                activeThumbColor: colors.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
