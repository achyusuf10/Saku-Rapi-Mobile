import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';

/// Bottom sheet untuk memilih sumber foto: Kamera atau Galeri.
///
/// Mengembalikan [ImageSource] yang dipilih user, atau `null` jika dibatalkan.
class OcrSourcePickerSheet extends StatelessWidget {
  const OcrSourcePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;

    return Container(
      padding: EdgeInsets.only(
        top: 16.h,
        left: 16.w,
        right: 16.w,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      decoration: BoxDecoration(
        color: appColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle bar ──
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: appColors.border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),

          // ── Title ──
          Text(
            l10n.ocrTitle,
            style: TextStyleConstants.h7.copyWith(
              fontWeight: FontWeight.w700,
              color: appColors.textPrimary,
            ),
          ),
          SizedBox(height: 24.h),

          // ── Options row ──
          Row(
            children: [
              Expanded(
                child: _SourceOption(
                  icon: FontAwesomeIcons.camera,
                  label: l10n.ocrCamera,
                  color: appColors.primary,
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _SourceOption(
                  icon: FontAwesomeIcons.images,
                  label: l10n.ocrGallery,
                  color: appColors.income,
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}

/// Satu opsi sumber foto (Kamera/Galeri).
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
    final appColors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: 56.r,
              height: 56.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
              ),
              child: Center(
                child: FaIcon(icon, color: color, size: 24.r),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              label,
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
