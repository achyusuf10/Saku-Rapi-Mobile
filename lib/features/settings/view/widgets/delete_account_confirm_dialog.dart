import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Menampilkan dialog konfirmasi untuk soft delete akun.
///
/// User harus mengetik frasa **SAYA MENGERTI** (lewat lokalisasi) sebelum
/// tombol menghapus dapat ditekan.
Future<bool?> showDeleteAccountConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => const _DeleteAccountConfirmDialogContent(),
  );
}

/// Isi dialog — [StatefulWidget] agar [TextEditingController] di-dispose aman
/// dan tidak ada setState setelah route ditutup (penyebab umum "deactivated ancestor").
class _DeleteAccountConfirmDialogContent extends StatefulWidget {
  const _DeleteAccountConfirmDialogContent();

  @override
  State<_DeleteAccountConfirmDialogContent> createState() =>
      _DeleteAccountConfirmDialogContentState();
}

class _DeleteAccountConfirmDialogContentState
    extends State<_DeleteAccountConfirmDialogContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_safeRebuildOnTextChanged);
  }

  void _safeRebuildOnTextChanged() {
    if (!mounted) return;
    setState(() {});
  }

  bool _phraseMatchesExact(String phrase, String value) =>
      value.trim() == phrase;

  @override
  void dispose() {
    _controller.removeListener(_safeRebuildOnTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final phrase = l10n.deleteAccountUnderstandPhraseExact;
    final canSubmit = _phraseMatchesExact(phrase, _controller.text);

    return AlertDialog(
      backgroundColor: colors.surface,
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      content: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.deleteAccountConfirmTitle,
              style: TextStyleConstants.h7.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              l10n.deleteAccountConfirmMessage,
              style: TextStyleConstants.b2.copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: 16.h),
            SakuTextField(
              controller: _controller,
              label: l10n.deleteAccountConfirmHint,
              textCapitalization: TextCapitalization.characters,
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: SakuButton(
                    text: l10n.deleteAccountConfirmCancel,
                    isOutlined: true,
                    onPressed: () {
                      if (!context.mounted) return;
                      Navigator.of(context).pop(false);
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: SakuButton(
                    text: l10n.deleteAccountConfirmProceed,
                    isEnabled: canSubmit,
                    backgroundColor: colors.error,
                    textColor: colors.onPrimary,
                    onPressed: () {
                      if (!context.mounted) return;
                      Navigator.of(context).pop(true);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
