import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

export 'package:dropdown_button2/dropdown_button2.dart' show DropdownItem;

/// Dropdown utama SakuRapi menggunakan `dropdown_button2`.
///
/// Gunakan widget ini untuk semua dropdown di aplikasi agar konsisten
/// dengan style [SakuTextField].
class SakuDropdown<T> extends StatefulWidget {
  const SakuDropdown({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.hint,
    this.label,
    this.validator,
    this.enabled = true,
    this.isExpanded = true,
    this.icon,
    this.suffixIcon,
    this.selectedItemBuilder,
  });

  /// Daftar item dropdown.
  final List<DropdownItem<T>> items;

  /// Nilai yang sedang terpilih.
  final T? value;

  /// Callback saat value berubah.
  final ValueChanged<T?>? onChanged;

  /// Hint text di dalam dropdown.
  final String? hint;

  /// Label di atas dropdown.
  final String? label;

  /// Validator untuk Form widget.
  final String? Function(T?)? validator;

  /// Apakah dropdown aktif.
  final bool enabled;

  /// Apakah konten dropdown melebar penuh.
  final bool isExpanded;

  /// Custom ikon chevron dropdown (default: FontAwesome chevronDown).
  final Widget? icon;

  /// Ikon tambahan di sisi kanan (misal: gear untuk manage).
  final Widget? suffixIcon;

  /// Builder untuk kustomisasi tampilan item terpilih di button.
  final DropdownButtonBuilder? selectedItemBuilder;

  @override
  State<SakuDropdown<T>> createState() => _SakuDropdownState<T>();
}

class _SakuDropdownState<T> extends State<SakuDropdown<T>> {
  late final ValueNotifier<T?> _valueNotifier;

  @override
  void initState() {
    super.initState();
    _valueNotifier = ValueNotifier<T?>(widget.value);
  }

  @override
  void didUpdateWidget(covariant SakuDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _valueNotifier.value = widget.value;
    }
  }

  @override
  void dispose() {
    _valueNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyleConstants.label1.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: 6.h),
        ],
        DropdownButtonFormField2<T>(
          isExpanded: widget.isExpanded,
          valueListenable: _valueNotifier,
          hint: widget.hint != null
              ? Text(
                  widget.hint!,
                  style: TextStyleConstants.b2.copyWith(
                    color: colors.textSecondary,
                  ),
                )
              : null,
          items: widget.items,
          onChanged: widget.enabled
              ? (value) {
                  widget.onChanged?.call(value);
                }
              : null,
          validator: widget.validator,
          selectedItemBuilder: widget.selectedItemBuilder,
          style: TextStyleConstants.b2.copyWith(color: colors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.surfaceVariant,
            suffixIcon: widget.suffixIcon,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 14.h,
            ).copyWith(left: 6.w),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: colors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: colors.error, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: colors.border.withValues(alpha: 0.5),
              ),
            ),
          ),
          iconStyleData: IconStyleData(
            icon:
                widget.icon ??
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 24.w,
                  color: widget.enabled
                      ? colors.textSecondary
                      : colors.textSecondary.withValues(alpha: 0.5),
                ),
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 300.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              color: colors.surface,
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            elevation: 0,
          ),
          menuItemStyleData: MenuItemStyleData(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            borderRadius: BorderRadius.circular(8.r),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused) ||
                  states.contains(WidgetState.pressed)) {
                return colors.primaryLight;
              }
              return null;
            }),
          ),
        ),
      ],
    );
  }
}
