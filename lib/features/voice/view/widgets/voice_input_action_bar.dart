import 'package:app_saku_rapi/core/extensions/color_ext.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/voice/controllers/voice_input_controller.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Tombol bawah sheet suara: batalkan/ulangi + aksi kontekstual.
class VoiceInputActionBar extends StatelessWidget {
  const VoiceInputActionBar({
    super.key,
    required this.state,
    required this.onCancel,
    required this.onRetry,
    required this.onDone,
    required this.onOpenSettings,
  });

  final VoiceInputState state;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final VoidCallback onDone;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Row(
      children: [
        Expanded(
          child: SakuButton(
            text: state.status == VoiceInputStatus.done
                ? l10n.voiceRetryButton
                : l10n.confirmCancel,
            onPressed: state.status == VoiceInputStatus.done
                ? onRetry
                : onCancel,
            isOutlined: true,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(child: _buildMainAction(colors, l10n)),
      ],
    );
  }

  Widget _buildMainAction(dynamic colors, dynamic l10n) {
    if (state.status == VoiceInputStatus.permissionDenied) {
      return SakuButton(
        text: l10n.voiceOpenSettings,
        onPressed: onOpenSettings,
      );
    }

    if (state.status == VoiceInputStatus.error) {
      final buttonColor = colors.info as Color;
      return SakuButton(
        text: l10n.retryButton,
        onPressed: onRetry,
        backgroundColor: buttonColor,
        textColor: buttonColor.readableForeground,
      );
    }

    if (state.status == VoiceInputStatus.done) {
      final buttonColor = colors.success as Color;
      return SakuButton(
        text: l10n.voiceContinueButton,
        onPressed: onDone,
        backgroundColor: buttonColor,
        textColor: buttonColor.readableForeground,
      );
    }

    return SakuButton(text: l10n.voicePleaseWait, onPressed: null);
  }
}
