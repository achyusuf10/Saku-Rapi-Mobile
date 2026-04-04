import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Widget untuk menampilkan state error dengan tombol retry.
///
/// Gunakan widget ini di semua halaman yang membutuhkan error state.
class SakuErrorState extends StatelessWidget {
  const SakuErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.title,
    this.icon,
  });

  /// Judul error (opsional).
  final String? title;

  /// Pesan error yang ditampilkan.
  final String message;

  /// Callback untuk tombol retry.
  final VoidCallback onRetry;

  /// Icon kustom. Default: circle-exclamation.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 48.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon ?? FontAwesomeIcons.circleExclamation,
              size: 48.w,
              color: colors.error.withValues(alpha: 0.6),
            ),
            SizedBox(height: 16.h),
            if (title != null) ...[
              Text(
                title!,
                style: TextStyleConstants.h7.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
            ],
            Text(
              message,
              style: TextStyleConstants.b2.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            TextButton.icon(
              onPressed: onRetry,
              icon: FaIcon(
                FontAwesomeIcons.arrowRotateRight,
                size: 14.w,
                color: colors.primary,
              ),
              label: Text(
                context.l10n.retryButton,
                style: TextStyleConstants.b2.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
