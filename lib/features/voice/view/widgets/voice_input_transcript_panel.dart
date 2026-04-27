import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Panel teks transkrip sementara (sebelum selesai AI parse).
class VoiceInputTranscriptPanel extends StatelessWidget {
  const VoiceInputTranscriptPanel({super.key, required this.transcript});

  /// Teks hasil speech-to-text mentah.
  final String transcript;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.voiceTranscript,
            style: TextStyleConstants.label2.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '"$transcript"',
            style: TextStyleConstants.b1.copyWith(
              color: colors.textPrimary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
