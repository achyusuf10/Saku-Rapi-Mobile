import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Tombol "Masuk dengan Google" yang branded untuk halaman login.
///
/// Menggunakan desain outlined dengan ikon Google (FontAwesome)
/// dan mendukung state loading.
class AuthGoogleButton extends StatelessWidget {
  const AuthGoogleButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  /// Label teks tombol.
  final String text;

  /// Callback ketika tombol ditekan. `null` = disabled.
  final VoidCallback? onPressed;

  /// Jika `true`, tampilkan spinner loading di dalam tombol.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    final effectiveOnPressed = isLoading ? null : onPressed;

    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: OutlinedButton(
        onPressed: effectiveOnPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: appColors.border),
          backgroundColor: appColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22.r,
                height: 22.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: appColors.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.google,
                    size: 18.r,
                    color: appColors.textPrimary,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    text,
                    style: TextStyleConstants.b1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: appColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
