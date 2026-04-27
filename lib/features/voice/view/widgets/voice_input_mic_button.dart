import 'package:app_saku_rapi/core/extensions/color_ext.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/features/voice/controllers/voice_input_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Tombol mikrofon animasi (pulse saat mendengarkan, spinner saat proses AI).
class VoiceInputMicButton extends StatelessWidget {
  const VoiceInputMicButton({
    super.key,
    required this.state,
    required this.pulseAnimation,
    required this.onStop,
  });

  final VoiceInputState state;
  final Animation<double> pulseAnimation;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final isListening = state.status == VoiceInputStatus.listening;
    final isProcessing = state.status == VoiceInputStatus.processing;

    final Color bgColor = isListening
        ? colors.expense
        : isProcessing
        ? colors.primary
        : colors.info;
    final onBgColor = bgColor.readableForeground;

    final icon = isProcessing
        ? FontAwesomeIcons.spinner
        : isListening
        ? FontAwesomeIcons.stop
        : FontAwesomeIcons.microphone;

    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        final scale = isListening ? pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: isListening ? onStop : null,
            child: Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor,
                boxShadow: [
                  if (isListening)
                    BoxShadow(
                      color: colors.expense.withValues(alpha: 0.25),
                      blurRadius: 12.r,
                      spreadRadius: 2.r,
                    ),
                ],
              ),
              child: Center(
                child: isProcessing
                    ? SizedBox(
                        width: 28.w,
                        height: 28.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.w,
                          valueColor: AlwaysStoppedAnimation(onBgColor),
                        ),
                      )
                    : FaIcon(icon, size: 28.w, color: onBgColor),
              ),
            ),
          ),
        );
      },
    );
  }
}
