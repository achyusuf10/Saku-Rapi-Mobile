import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Text field utama SakuRapi.
///
/// Gunakan widget ini untuk semua input teks di aplikasi agar konsisten.
class SakuTextField extends StatelessWidget {
  const SakuTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.textInputAction,
    this.validator,
  });

  /// Controller untuk text field.
  final TextEditingController? controller;

  /// Label di atas field.
  final String? label;

  /// Hint di dalam field.
  final String? hint;

  /// Teks error validasi di bawah field.
  final String? errorText;

  /// Ikon di sebelah kiri.
  final Widget? prefixIcon;

  /// Ikon di sebelah kanan.
  final Widget? suffixIcon;

  /// Callback saat value berubah.
  final ValueChanged<String>? onChanged;

  /// Callback saat submit.
  final ValueChanged<String>? onSubmitted;

  /// Callback saat field di-tap.
  final VoidCallback? onTap;

  /// Jenis keyboard.
  final TextInputType? keyboardType;

  /// Input formatters (misal: AmountInputFormatter).
  final List<TextInputFormatter>? inputFormatters;

  /// Jumlah baris maksimal.
  final int maxLines;

  /// Jumlah baris minimal.
  final int? minLines;

  /// Panjang karakter maksimal.
  final int? maxLength;

  /// Apakah field bersifat password.
  final bool obscureText;

  /// Apakah field hanya baca.
  final bool readOnly;

  /// Apakah field aktif.
  final bool enabled;

  /// Apakah field otomatis fokus.
  final bool autofocus;

  /// Kapitalisasi teks.
  final TextCapitalization textCapitalization;

  /// Focus node.
  final FocusNode? focusNode;

  /// Action keyboard.
  final TextInputAction? textInputAction;

  /// Validator untuk Form widget.
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyleConstants.label1.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onTap: onTap,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          obscureText: obscureText,
          readOnly: readOnly,
          enabled: enabled,
          autofocus: autofocus,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          validator: validator,
          style: TextStyleConstants.b2.copyWith(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyleConstants.b2.copyWith(
              color: colors.textSecondary,
            ),
            errorText: errorText,
            errorStyle: TextStyleConstants.label3.copyWith(color: colors.error),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: colors.surfaceVariant,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
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
        ),
      ],
    );
  }
}
