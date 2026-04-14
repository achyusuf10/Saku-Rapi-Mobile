import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_color_wheel_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bottom sheet global untuk memilih warna.
///
/// Mendukung dua mode:
/// - **Preset**: Grid warna predefinit
/// - **Kustom**: Color wheel (HSV) untuk warna bebas
///
/// ```dart
/// final hex = await SakuColorPickerSheet.show(
///   context: context,
///   selectedColor: '#F59E0B',
/// );
/// ```
class SakuColorPickerSheet extends StatefulWidget {
  const SakuColorPickerSheet({super.key, this.selectedColor});

  /// Hex color yang sedang dipilih (untuk highlight).
  final String? selectedColor;

  /// Daftar warna preset yang tersedia.
  static const List<String> availableColors = [
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
    '#6D28D9', // Purple dark
    '#1D4ED8', // Blue-700
    '#B91C1C', // Red-700
    '#047857', // Emerald-700
    '#9333EA', // Purple-700,
    '#00FFC1', // Cyan-900
  ];

  /// Menampilkan color picker dan return hex color terpilih.
  static Future<String?> show({
    required BuildContext context,
    String? selectedColor,
    String? title,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SakuColorPickerSheet(selectedColor: selectedColor),
    );
  }

  @override
  State<SakuColorPickerSheet> createState() => _SakuColorPickerSheetState();
}

class _SakuColorPickerSheetState extends State<SakuColorPickerSheet> {
  bool _isCustomMode = false;
  late Color _wheelColor;

  @override
  void initState() {
    super.initState();
    _wheelColor = widget.selectedColor != null
        ? _parseColor(widget.selectedColor!)
        : const Color(0xFF3B82F6);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
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

            // Mode toggle
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    _ModeTab(
                      label: l10n.colorPickerPresetTab,
                      isActive: !_isCustomMode,
                      onTap: () => setState(() => _isCustomMode = false),
                    ),
                    _ModeTab(
                      label: l10n.colorPickerWheelTab,
                      isActive: _isCustomMode,
                      onTap: () => setState(() => _isCustomMode = true),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 12.h),

            // Content
            if (_isCustomMode)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SakuColorWheelPicker(
                      size: 1.sh / 4.2,
                      ringWidth: 18.w,
                      color: _wheelColor,
                      onColorChanged: (c) => setState(() => _wheelColor = c),
                    ),
                    SizedBox(height: 12.h),
                    SakuButton(
                      text: l10n.colorPickerSelectButton,
                      onPressed: () =>
                          Navigator.pop(context, _colorToHex(_wheelColor)),
                    ),
                  ],
                ),
              )
            else
              _PresetGrid(
                selectedColor: widget.selectedColor,
                onSelected: (hex) => Navigator.pop(context, hex),
              ),

            SizedBox(height: MediaQuery.paddingOf(context).bottom + 8.h),
          ],
        ),
      ),
    );
  }
}

// ───────────────── Mode Toggle Tab ─────────────────

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: isActive ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyleConstants.label1.copyWith(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? colors.onPrimary : colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────── Preset Grid Tab ─────────────────

class _PresetGrid extends StatelessWidget {
  const _PresetGrid({required this.selectedColor, required this.onSelected});

  final String? selectedColor;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Wrap(
        spacing: 12.w,
        runSpacing: 12.h,
        children: SakuColorPickerSheet.availableColors.map((hex) {
          final isSelected = hex.toLowerCase() == selectedColor?.toLowerCase();
          final color = _parseColor(hex);
          final itemSize =
              (MediaQuery.of(context).size.width - 32.w - 60.w) / 6;

          return InkWell(
            onTap: () => onSelected(hex),
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              width: itemSize,
              height: itemSize,
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
        }).toList(),
      ),
    );
  }
}

// ───────────────── Helpers ─────────────────

Color _getOnSwatchColor(Color swatch) {
  final brightness = ThemeData.estimateBrightnessForColor(swatch);
  return brightness == Brightness.dark ? Colors.white : Colors.black87;
}

Color _parseColor(String hexColor) {
  final hex = hexColor.replaceFirst('#', '');
  if (hex.length == 6) {
    return Color(int.parse('FF$hex', radix: 16));
  }
  return const Color(0xFF6B7280);
}

String _colorToHex(Color color) {
  final r = (color.r * 255.0).round().clamp(0, 255);
  final g = (color.g * 255.0).round().clamp(0, 255);
  final b = (color.b * 255.0).round().clamp(0, 255);
  return '#${r.toRadixString(16).padLeft(2, '0')}'
          '${g.toRadixString(16).padLeft(2, '0')}'
          '${b.toRadixString(16).padLeft(2, '0')}'
      .toUpperCase();
}
