import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/features/ocr/controllers/ocr_scan_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Konten sheet saat OCR atau AI mengembalikan error (termasuk kuota habis).
class OcrResultErrorBody extends StatelessWidget {
  const OcrResultErrorBody({
    super.key,
    required this.state,
    required this.colors,
    required this.l10n,
  });

  /// State scan berisi [OcrScanState.errorMessage] kode mesin.
  final OcrScanState state;

  final dynamic colors;
  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    // Map kode error → copy + ikon (sama seperti implementasi sheet sebelum refactor).
    late final String message;
    late final IconData icon;
    if (state.errorMessage == 'NOT_TRANSACTION') {
      message = l10n.ocrNotTransaction as String;
      icon = FontAwesomeIcons.imagePortrait;
    } else if (state.errorMessage == 'NO_TEXT') {
      message = l10n.ocrNoText as String;
      icon = FontAwesomeIcons.triangleExclamation;
    } else if (state.errorMessage == 'PARSE_FAILED') {
      message = l10n.ocrImageBlurry as String;
      icon = FontAwesomeIcons.triangleExclamation;
    } else if (state.errorMessage == 'DAILY_QUOTA_EXCEEDED') {
      message = l10n.aiQuotaExhausted as String;
      icon = FontAwesomeIcons.circleExclamation;
    } else {
      message = l10n.ocrErrorGeneric as String;
      icon = FontAwesomeIcons.triangleExclamation;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 48.w, color: colors.expense),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyleConstants.b1.copyWith(color: colors.textPrimary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
