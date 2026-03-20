import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// TextField global SakuRapi dengan styling konsisten Light/Dark mode.
///
/// Menggunakan `context.colors.surface` sebagai fill color dan
/// `context.colors.textPrimary` untuk warna ketikan, memastikan kontras
/// yang aman di kedua mode layar.
class SakuTextField extends StatelessWidget {
  const SakuTextField({
    super.key,
    required this.controller,
    this.hintText = '',
    this.keyboardType,
    this.prefixIcon,
    this.prefixText,
    this.validator,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.maxLines = 1,
  });

  /// Controller untuk mengontrol dan membaca value field.
  final TextEditingController controller;

  /// Teks hint yang ditampilkan saat field kosong.
  final String hintText;

  /// Tipe keyboard (number, email, dll).
  final TextInputType? keyboardType;

  /// Icon di sebelah kiri field (misalnya ikon pencarian).
  final Widget? prefixIcon;

  /// Teks prefix tetap (misalnya 'Rp ').
  final String? prefixText;

  /// Fungsi validasi form.
  final String? Function(String?)? validator;

  /// Formatter input (misalnya hanya digit).
  final List<TextInputFormatter>? inputFormatters;

  /// Kapitalisasi teks.
  final TextCapitalization textCapitalization;

  /// Sembunyikan teks (untuk password).
  final bool obscureText;

  /// Jumlah baris maksimum.
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      maxLines: maxLines,
      style: TextStyleConstants.b1.copyWith(color: appColors.textPrimary),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        prefixText: prefixText,
        hintStyle: TextStyleConstants.b1.copyWith(
          color: appColors.textSecondary.withValues(alpha: 0.5),
        ),
        prefixStyle: TextStyleConstants.b1.copyWith(
          color: appColors.textPrimary,
        ),
        filled: true,
        fillColor: appColors.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: appColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: appColors.expense),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: appColors.expense, width: 1.5),
        ),
      ),
    );
  }
}
