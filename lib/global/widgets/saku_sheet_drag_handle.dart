import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Handle drag bawah untuk modal bottom sheet (tanpa border).
///
/// Ukuran default mengikuti sheet input teks/suara; OCR bisa override [width] dan [margin].
class SakuSheetDragHandle extends StatelessWidget {
  /// [color] biasanya `textSecondary` atau `border` dengan alpha sesuai tema sheet.
  const SakuSheetDragHandle({
    super.key,
    required this.color,
    this.width,
    this.height,
    this.margin,
  });

  /// Warna batang handle (sudah termasuk alpha jika perlu).
  final Color color;

  /// Lebar batang; default `40.w` (sheet teks/suara).
  final double? width;

  /// Tinggi batang; default `4.h`.
  final double? height;

  /// Margin luar handle (mis. jarak dari atas sheet OCR).
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: margin,
        width: width ?? 40.w,
        height: height ?? 4.h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2.r),
        ),
      ),
    );
  }
}
