import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Tombol global SakuRapi yang konsisten di seluruh aplikasi.
///
/// Mendukung dua varian:
/// - **Filled** (default): background `primary`, teks putih.
/// - **Outlined** (`isOutlined: true`): border `primary`, teks `primary`.
///
/// Jika [isLoading] `true`, isi tombol diganti [CircularProgressIndicator].
class SakuButton extends StatelessWidget {
  const SakuButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
  });

  /// Label teks tombol.
  final String text;

  /// Callback ketika tombol ditekan. `null` = disabled.
  final VoidCallback? onPressed;

  /// Jika `true`, tampilkan spinner loading di dalam tombol.
  final bool isLoading;

  /// Jika `true`, tombol menggunakan varian outlined (transparan).
  final bool isOutlined;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    final Widget child = isLoading
        ? SizedBox(
            width: 22.r,
            height: 22.r,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: isOutlined ? appColors.primary : Colors.white,
            ),
          )
        : Text(
            text,
            style: TextStyleConstants.b1.copyWith(
              fontWeight: FontWeight.w700,
              color: isOutlined ? appColors.primary : Colors.white,
            ),
          );

    final effectiveOnPressed = isLoading ? null : onPressed;

    if (isOutlined) {
      return SizedBox(
        height: 48.h,
        child: OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: appColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      height: 48.h,
      child: FilledButton(
        onPressed: effectiveOnPressed,
        style: FilledButton.styleFrom(
          backgroundColor: appColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: child,
      ),
    );
  }
}
