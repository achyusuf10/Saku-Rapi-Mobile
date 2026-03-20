import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Tampilan teks real-time dari hasil speech recognition.
///
/// Menampilkan [text] dengan animasi fade saat berubah.
/// Jika [text] kosong, tampilkan placeholder "...".
class VoiceResultText extends StatelessWidget {
  const VoiceResultText({super.key, required this.text});

  /// Teks hasil speech recognition (real-time).
  final String text;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final hasText = text.isNotEmpty;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 60.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: appColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: hasText
              ? appColors.primary.withValues(alpha: 0.3)
              : appColors.border,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          hasText ? text : '...',
          key: ValueKey(hasText ? 'text' : 'placeholder'),
          style: TextStyleConstants.b1.copyWith(
            color: hasText ? appColors.textPrimary : appColors.textSecondary,
            fontWeight: hasText ? FontWeight.w500 : FontWeight.w400,
            fontStyle: hasText ? FontStyle.normal : FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
