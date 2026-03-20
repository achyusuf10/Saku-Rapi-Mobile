import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Widget input nominal besar terpusat, ditampilkan di bagian atas form.
///
/// - Hanya menerima angka bulat (no decimal via keyboard)
/// - Menggunakan [TextEditingController] eksternal agar parent bisa membaca
///   nilai kapan saja
/// - Menampilkan prefix "Rp" berwarna sesuai tipe transaksi
class TransactionAmountField extends StatelessWidget {
  const TransactionAmountField({
    super.key,
    required this.controller,
    required this.typeColor,
    this.onChanged,
  });

  final TextEditingController controller;

  /// Warna prefix "Rp" dan cursor (mengikuti tipe transaksi aktif).
  final Color typeColor;

  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: typeColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: typeColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Prefix "Rp"
          Text(
            'Rp',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: typeColor,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 36.sp,
                fontWeight: FontWeight.w700,
                color: appColors.textPrimary,
                letterSpacing: -0.5,
              ),
              cursorColor: typeColor,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.w700,
                  color: appColors.textSecondary.withValues(alpha: 0.3),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
