import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Widget loading indicator utama SakuRapi.
///
/// Gunakan widget ini untuk loading state di semua halaman.
class SakuLoadingIndicator extends StatelessWidget {
  const SakuLoadingIndicator({
    super.key,
    this.size,
    this.strokeWidth,
    this.color,
    this.message,
  });

  /// Ukuran indikator. Default: 40.
  final double? size;

  /// Ketebalan stroke. Default: 3.
  final double? strokeWidth;

  /// Warna indikator. Default: primary.
  final Color? color;

  /// Pesan di bawah indikator (opsional).
  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final indicatorSize = size ?? 40.w;
    final indicatorStroke = strokeWidth ?? 3.w;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: indicatorSize,
            height: indicatorSize,
            child: CircularProgressIndicator(
              strokeWidth: indicatorStroke,
              color: color ?? colors.primary,
              strokeCap: StrokeCap.round,
            ),
          ),
          if (message != null) ...[
            SizedBox(height: 16.h),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14.sp,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
