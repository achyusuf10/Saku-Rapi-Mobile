import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Widget untuk menampilkan state kosong (empty state).
///
/// Gunakan widget ini di semua halaman yang membutuhkan empty state.
class SakuEmptyState extends StatelessWidget {
  const SakuEmptyState({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  /// Judul empty state (opsional).
  final String? title;

  /// Pesan utama empty state.
  final String message;

  /// Icon kustom. Default: folder terbuka.
  final IconData? icon;

  /// Label tombol aksi (opsional, misal "Tambah Data").
  final String? actionLabel;

  /// Callback tombol aksi.
  final VoidCallback? onAction;

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
              icon ?? FontAwesomeIcons.folderOpen,
              size: 48.w,
              color: colors.textSecondary.withValues(alpha: 0.4),
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
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 24.h),
              TextButton.icon(
                onPressed: onAction,
                icon: FaIcon(
                  FontAwesomeIcons.plus,
                  size: 14.w,
                  color: colors.primary,
                ),
                label: Text(
                  actionLabel!,
                  style: TextStyleConstants.b2.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
