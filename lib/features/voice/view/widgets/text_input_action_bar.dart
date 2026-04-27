import 'package:app_saku_rapi/core/extensions/color_ext.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/voice/controllers/text_input_controller.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Baris tombol bawah: batalkan (outline) + aksi utama (analisis / loading / lanjut).
class TextInputActionBar extends StatelessWidget {
  const TextInputActionBar({
    super.key,
    required this.state,
    required this.onCancel,
    required this.onSubmit,
    required this.onRetry,
    required this.onDone,
  });

  final TextInputState state;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final VoidCallback onRetry;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Row(
      children: [
        Expanded(
          child: SakuButton(
            text: l10n.confirmCancel,
            onPressed: onCancel,
            isOutlined: true,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(child: _buildMainAction(colors, l10n)),
      ],
    );
  }

  /// Tombol kanan mengikuti [TextInputStatus] (idle / proses / error / selesai).
  Widget _buildMainAction(dynamic colors, dynamic l10n) {
    if (state.status == TextInputStatus.processing) {
      return SakuButton(text: '', onPressed: null, isLoading: true);
    }

    if (state.status == TextInputStatus.error) {
      final buttonColor = colors.info as Color;
      return SakuButton(
        text: l10n.retryButton,
        onPressed: onRetry,
        backgroundColor: buttonColor,
        textColor: buttonColor.readableForeground,
      );
    }

    if (state.status == TextInputStatus.done) {
      final buttonColor = colors.success as Color;
      return SakuButton(
        text: l10n.voiceContinueButton,
        onPressed: onDone,
        backgroundColor: buttonColor,
        textColor: buttonColor.readableForeground,
      );
    }

    return SakuButton(text: l10n.textInputSubmit, onPressed: onSubmit);
  }
}
