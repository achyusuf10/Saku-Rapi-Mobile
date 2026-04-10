import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bottom sheet untuk memilih warna kategori.
///
/// Menampilkan grid warna predefinit yang sesuai dengan desain SakuRapi.
class CategoryColorPickerSheet extends StatelessWidget {
  const CategoryColorPickerSheet({super.key, this.selectedColor});

  /// Hex color yang sedang dipilih (untuk highlight).
  final String? selectedColor;

  /// Daftar warna yang tersedia untuk dipilih.
  static const List<String> _availableColors = [
    '#F59E0B', // Amber
    '#EF4444', // Red
    '#3B82F6', // Blue
    '#8B5CF6', // Violet
    '#06B6D4', // Cyan
    '#EC4899', // Pink
    '#10B981', // Emerald
    '#6B7280', // Gray
    '#F97316', // Orange
    '#14B8A6', // Teal
    '#84CC16', // Lime
    '#A855F7', // Purple
    '#E11D48', // Rose
    '#0EA5E9', // Sky
    '#22C55E', // Green
    '#D97706', // Amber dark
    '#BE123C', // Ruby
    '#4F46E5', // Indigo
    '#0D9488', // Teal dark
    '#CA8A04', // Yellow dark
    '#7C3AED', // Violet dark
    '#2563EB', // Blue dark
    '#DC2626', // Red dark
    '#059669', // Emerald dark
  ];

  /// Menampilkan color picker dan return hex color terpilih.
  static Future<String?> show({
    required BuildContext context,
    String? selectedColor,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryColorPickerSheet(selectedColor: selectedColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Text(
              l10n.categoryColorPicker,
              style: TextStyleConstants.h7.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),

          // Color grid
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 12.h,
                crossAxisSpacing: 12.w,
              ),
              itemCount: _availableColors.length,
              itemBuilder: (context, index) {
                final hex = _availableColors[index];
                final isSelected =
                    hex.toLowerCase() == selectedColor?.toLowerCase();
                final color = _parseColor(hex);

                return InkWell(
                  onTap: () => Navigator.pop(context, hex),
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? colors.textPrimary : colors.border,
                        width: 3,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: FaIcon(
                              FontAwesomeIcons.check,
                              size: 16.w,
                              color: _getOnSwatchColor(color),
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),

          SizedBox(height: MediaQuery.paddingOf(context).bottom + 16.h),
        ],
      ),
    );
  }
}

Color _getOnSwatchColor(Color swatch) {
  final brightness = ThemeData.estimateBrightnessForColor(swatch);
  return brightness == Brightness.dark ? Colors.white : Colors.black87;
}

/// Parse hex color string ke [Color].
Color _parseColor(String hexColor) {
  final hex = hexColor.replaceFirst('#', '');
  if (hex.length == 6) {
    return Color(int.parse('FF$hex', radix: 16));
  }
  return const Color(0xFF6B7280);
}
