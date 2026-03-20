import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Daftar tab tipe transaksi yang tersedia di form.
///
/// `adjustment` tidak ditampilkan — hanya bisa dibuat via Wallet screen.
const _kTabs = [
  ('expense', FontAwesomeIcons.arrowTrendDown),
  ('income', FontAwesomeIcons.arrowTrendUp),
  ('transfer', FontAwesomeIcons.arrowsLeftRight),
  ('debt', FontAwesomeIcons.handshake),
];

/// TabBar kustom untuk memilih tipe transaksi (Expense / Income / Transfer /
/// Debt).
///
/// Debt dan Loan disatukan dalam satu tab — toggle antara keduanya
/// ditangani di luar widget ini (lihat [TransactionOptionalFields]).
class TransactionTypeTabBar extends StatelessWidget {
  const TransactionTypeTabBar({
    super.key,
    required this.currentType,
    required this.onTypeChanged,
  });

  final String currentType;
  final ValueChanged<String> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;

    return Container(
      height: 44.h,
      decoration: BoxDecoration(
        color: appColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: _kTabs.map((tab) {
          final type = tab.$1;
          final icon = tab.$2;
          final isSelected =
              currentType == type || (type == 'debt' && currentType == 'loan');

          final tabColor = _colorForType(context, type);

          return Expanded(
            child: GestureDetector(
              onTap: () => onTypeChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.all(3.r),
                decoration: BoxDecoration(
                  color: isSelected
                      ? tabColor.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                  border: isSelected
                      ? Border.all(color: tabColor, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        icon,
                        size: 14.r,
                        color: isSelected ? tabColor : appColors.textSecondary,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _labelForType(l10n, type),
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? tabColor
                              : appColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _colorForType(BuildContext context, String type) {
    final c = context.colors;
    return switch (type) {
      'expense' => c.expense,
      'income' => c.income,
      'transfer' => c.transfer,
      'debt' => c.debt,
      _ => c.primary,
    };
  }

  String _labelForType(dynamic l10n, String type) {
    return switch (type) {
      'expense' => l10n.transactionExpense,
      'income' => l10n.transactionIncome,
      'transfer' => l10n.transactionTransfer,
      'debt' => l10n.transactionDebt,
      _ => type,
    };
  }
}
