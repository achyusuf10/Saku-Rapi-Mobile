import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/voice/controllers/voice_input_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Panel error atau penjelasan izin ditolak untuk sheet input suara.
class VoiceInputErrorPanel extends StatelessWidget {
  const VoiceInputErrorPanel({super.key, required this.state});

  final VoiceInputState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    final message = state.status == VoiceInputStatus.permissionDenied
        ? l10n.voicePermissionExplainer
        : state.errorMessage == 'no_speech'
        ? l10n.voiceNoSpeech
        : state.errorMessage == 'not_transaction'
        ? l10n.voiceNotTransaction
        : state.errorMessage == 'DAILY_QUOTA_EXCEEDED'
        ? l10n.aiQuotaExhausted
        : l10n.voiceError;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: colors.expense.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.circleExclamation,
            size: 16.w,
            color: colors.expense,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: TextStyleConstants.b2.copyWith(color: colors.expense),
            ),
          ),
        ],
      ),
    );
  }
}
