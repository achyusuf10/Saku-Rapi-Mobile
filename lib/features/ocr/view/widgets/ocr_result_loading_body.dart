import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Konten tengah sheet saat gambar sedang diproses atau AI sedang menganalisis.
class OcrResultLoadingBody extends StatelessWidget {
  const OcrResultLoadingBody({
    super.key,
    required this.message,
    required this.colors,
  });

  /// Teks di bawah spinner (sudah dilokalisasi oleh caller).
  final String message;

  /// Token tema.
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 60.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40.w,
            height: 40.w,
            child: CircularProgressIndicator(
              strokeWidth: 3.w,
              valueColor: AlwaysStoppedAnimation(colors.accent),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            message,
            style: TextStyleConstants.b2.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
