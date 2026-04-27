import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Panel error di bawah field teks saat AI parse gagal atau bukan transaksi.
class TextInputErrorPanel extends StatelessWidget {
  const TextInputErrorPanel({super.key, required this.errorMessage});

  /// Kode mesin dari controller (`not_transaction`, `DAILY_QUOTA_EXCEEDED`, …).
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    // Samakan mapping pesan dengan sheet monolit sebelum refactor.
    final message = errorMessage == 'not_transaction'
        ? l10n.voiceNotTransaction
        : errorMessage == 'DAILY_QUOTA_EXCEEDED'
        ? l10n.aiQuotaExhausted
        : l10n.textInputError;

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
