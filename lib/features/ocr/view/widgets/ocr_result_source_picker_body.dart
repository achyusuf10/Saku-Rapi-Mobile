import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/features/ocr/controllers/ocr_scan_controller.dart';
import 'package:app_saku_rapi/features/ocr/view/widgets/ocr_source_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Konten awal sheet: pilih sumber gambar (kamera atau galeri).
class OcrResultSourcePickerBody extends StatelessWidget {
  const OcrResultSourcePickerBody({
    super.key,
    required this.ctrl,
    required this.colors,
    required this.l10n,
  });

  final OcrScanController ctrl;
  final dynamic colors;
  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.ocrPickerTitle as String,
            style: TextStyleConstants.h7.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: OcrSourceButton(
                  icon: FontAwesomeIcons.camera,
                  label: l10n.ocrCamera as String,
                  color: colors.info,
                  onTap: () => ctrl.startFromCamera(context),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: OcrSourceButton(
                  icon: FontAwesomeIcons.images,
                  label: l10n.ocrGallery as String,
                  color: colors.primary,
                  onTap: () => ctrl.startFromGallery(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
