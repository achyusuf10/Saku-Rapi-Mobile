import 'dart:io';

import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';

/// Reusable bottom sheet untuk memilih sumber gambar (Kamera / Galeri).
///
/// Return [File] jika user memilih gambar, atau `null` jika dibatalkan.
///
/// Penggunaan:
/// ```dart
/// final file = await ImageSourcePickerSheet.show(context);
/// if (file != null) { /* proses gambar */ }
/// ```
class ImageSourcePickerSheet extends StatelessWidget {
  const ImageSourcePickerSheet({super.key});

  /// Menampilkan bottom sheet dan return [File] gambar yang dipilih.
  static Future<File?> show(BuildContext context) {
    return showModalBottomSheet<File>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ImageSourcePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 8.h),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 4.h),
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: colors.border.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),

            // Options row
            Row(
              children: [
                Expanded(
                  child: _SourceOption(
                    icon: FontAwesomeIcons.camera,
                    label: l10n.ocrCamera,
                    color: colors.info,
                    onTap: () => _pick(context, ImageSource.camera),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _SourceOption(
                    icon: FontAwesomeIcons.images,
                    label: l10n.ocrGallery,
                    color: colors.primary,
                    onTap: () => _pick(context, ImageSource.gallery),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final navigator = Navigator.of(context);
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: source, imageQuality: 90);
    if (xFile != null) {
      navigator.pop(File(xFile.path));
    } else {
      navigator.pop();
    }
  }
}

/// Opsi sumber gambar (kamera/galeri) dalam bentuk card.
class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: FaIcon(icon, size: 20.w, color: color),
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                label,
                style: TextStyleConstants.b2.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
