import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/voice/controllers/voice_input_controller.dart';
import 'package:flutter/material.dart';

/// Judul / status besar di atas tombol mikrofon (mengikuti [VoiceInputStatus]).
class VoiceInputStatusText extends StatelessWidget {
  const VoiceInputStatusText({super.key, required this.state});

  final VoiceInputState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    final (String text, Color color) = switch (state.status) {
      VoiceInputStatus.idle => (l10n.voiceTapToSpeak, colors.textSecondary),
      VoiceInputStatus.initializing => (
        l10n.voiceInitializing,
        colors.textSecondary,
      ),
      VoiceInputStatus.listening => (l10n.voiceListening, colors.info),
      VoiceInputStatus.processing => (l10n.voiceAnalyzingAi, colors.primary),
      VoiceInputStatus.done => (l10n.voicePreviewTitle, colors.success),
      VoiceInputStatus.error => (l10n.voiceError, colors.expense),
      VoiceInputStatus.permissionDenied => (
        l10n.voicePermissionDenied,
        colors.expense,
      ),
    };

    return Text(
      text,
      style: TextStyleConstants.h6.copyWith(color: color),
      textAlign: TextAlign.center,
    );
  }
}
