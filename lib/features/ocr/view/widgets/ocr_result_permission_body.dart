import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/features/ocr/controllers/ocr_scan_controller.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Konten sheet saat izin kamera/galeri ditolak.
class OcrResultPermissionBody extends StatelessWidget {
  const OcrResultPermissionBody({
    super.key,
    required this.ctrl,
    required this.isPermanent,
    required this.colors,
    required this.l10n,
  });

  /// Controller untuk membuka pengaturan sistem bila izin permanen ditolak.
  final OcrScanController ctrl;

  /// True jika user memilih "jangan tanya lagi" di OS.
  final bool isPermanent;

  final dynamic colors;
  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            FontAwesomeIcons.cameraRotate,
            size: 48.w,
            color: colors.expense,
          ),
          SizedBox(height: 16.h),
          Text(
            l10n.ocrPermissionDenied as String,
            style: TextStyleConstants.h7.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.ocrPermissionExplainer as String,
            style: TextStyleConstants.b2.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (isPermanent) ...[
            SizedBox(height: 20.h),
            SakuButton(
              text: l10n.voiceOpenSettings as String,
              onPressed: ctrl.openSettings,
              icon: FaIcon(FontAwesomeIcons.gear, size: 14.w),
            ),
          ],
        ],
      ),
    );
  }
}
