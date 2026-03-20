import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 18 predefined colors yang cocok untuk kategori keuangan.
const List<({String hex, String label})> _availableColors = [
  (hex: '#6B7280', label: 'Gray'),
  (hex: '#EF4444', label: 'Red'),
  (hex: '#F97316', label: 'Orange'),
  (hex: '#F59E0B', label: 'Amber'),
  (hex: '#EAB308', label: 'Yellow'),
  (hex: '#84CC16', label: 'Lime'),
  (hex: '#22C55E', label: 'Green'),
  (hex: '#10B981', label: 'Emerald'),
  (hex: '#14B8A6', label: 'Teal'),
  (hex: '#06B6D4', label: 'Cyan'),
  (hex: '#0EA5E9', label: 'Sky'),
  (hex: '#3B82F6', label: 'Blue'),
  (hex: '#6366F1', label: 'Indigo'),
  (hex: '#8B5CF6', label: 'Violet'),
  (hex: '#A855F7', label: 'Purple'),
  (hex: '#D946EF', label: 'Fuchsia'),
  (hex: '#EC4899', label: 'Pink'),
  (hex: '#F43F5E', label: 'Rose'),
];

/// Bottom sheet grid view untuk memilih warna kategori.
///
/// Grid 6 kolom dengan 18 warna predefined.
/// Warna yang dipilih ditandai dengan checkmark putih.
class CategoryColorPickerSheet extends StatelessWidget {
  const CategoryColorPickerSheet({super.key, this.selectedColor});

  /// Hex color string yang sedang dipilih (untuk highlight).
  final String? selectedColor;

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.startsWith('#')) buffer.write(hex.substring(1));
    if (buffer.length == 6) buffer.write('FF');
    // swap alpha to front
    final str = buffer.toString();
    if (str.length == 8) {
      return Color(
        int.parse('${str.substring(6)}${str.substring(0, 6)}', radix: 16),
      );
    }
    return const Color(0xFF6B7280);
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;

    return Container(
      padding: EdgeInsets.only(
        top: 16.h,
        left: 16.w,
        right: 16.w,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      decoration: BoxDecoration(
        color: appColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle bar ──
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: appColors.border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 12.h),

          // ── Title ──
          Text(
            l10n.categoryColorPicker,
            style: TextStyleConstants.h7.copyWith(
              fontWeight: FontWeight.w700,
              color: appColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),

          // ── Color Grid ──
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 12.w,
            ),
            itemCount: _availableColors.length,
            itemBuilder: (context, index) {
              final item = _availableColors[index];
              final color = _hexToColor(item.hex);
              final isSelected =
                  selectedColor?.toUpperCase() == item.hex.toUpperCase();

              return GestureDetector(
                onTap: () => Navigator.of(context).pop(item.hex),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: appColors.textPrimary, width: 3)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? Icon(Icons.check, color: Colors.white, size: 20.r)
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
