import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Chip selector untuk tipe investasi: gold, crypto, custom.
///
/// Menampilkan 3 pilihan tipe aset dalam row horizontal.
class InvestmentTypeSelector extends StatelessWidget {
  const InvestmentTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  final String selectedType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TypeChip(
          type: 'gold',
          icon: FontAwesomeIcons.coins,
          label: context.l10n.investmentTypeGold,
          isSelected: selectedType == 'gold',
          color: const Color(0xFFD4A017),
          onTap: () => onChanged('gold'),
        ),
        SizedBox(width: 8.w),
        _TypeChip(
          type: 'crypto',
          icon: FontAwesomeIcons.bitcoin,
          label: context.l10n.investmentTypeBtc,
          isSelected: selectedType == 'crypto',
          color: const Color(0xFFF7931A),
          onTap: () => onChanged('crypto'),
        ),
        SizedBox(width: 8.w),
        _TypeChip(
          type: 'custom',
          icon: FontAwesomeIcons.chartLine,
          label: context.l10n.investmentTypeCustom,
          isSelected: selectedType == 'custom',
          color: context.colors.primary,
          onTap: () => onChanged('custom'),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.type,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String type;
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : colors.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? color : colors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              FaIcon(
                icon,
                size: 20.w,
                color: isSelected ? color : colors.textSecondary,
              ),
              SizedBox(height: 6.h),
              Text(
                label,
                style: TextStyleConstants.label2.copyWith(
                  color: isSelected ? color : colors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
