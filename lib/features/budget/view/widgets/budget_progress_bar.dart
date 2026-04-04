import 'dart:math';

import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Progress bar untuk budget usage yang reusable.
///
/// Menampilkan bar horizontal dengan warna yang berubah sesuai persentase:
/// - Hijau (< 60%): aman
/// - Kuning (60–79%): waspada
/// - Oranye (80–99%): mendekati limit
/// - Merah (>= 100%): over budget
class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    super.key,
    required this.ratio,
    this.expectedRatio,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.animate = true,
  });

  /// Rasio pemakaian (0.0 – ~∞). Contoh: 0.75 = 75%.
  final double ratio;

  /// Rasio perkiraan progress berdasarkan waktu (0.0 – 1.0).
  /// Jika diberikan, akan menampilkan marker vertikal pada posisi ini.
  final double? expectedRatio;

  /// Tinggi bar. Default: 6.
  final double? height;

  /// Warna background bar (track). Default: surfaceVariant.
  final Color? backgroundColor;

  /// Warna foreground bar. Default: otomatis berdasarkan rasio.
  final Color? foregroundColor;

  /// Border radius bar. Default: pill.
  final double? borderRadius;

  /// Animasi transisi. Default: true.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final barHeight = height ?? 6.h;
    final radius = borderRadius ?? barHeight / 2;
    final bgColor = backgroundColor ?? colors.surfaceVariant;
    final fgColor = foregroundColor ?? _colorForRatio(ratio, colors);
    // Clamp display value to 1.0 max for the bar width
    final clampedRatio = ratio.clamp(0.0, 1.0);
    // Marker height taller than bar for visibility
    final markerHeight = barHeight + 8.h;

    return SizedBox(
      height: markerHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final fillWidth = maxWidth * clampedRatio;

          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Background track
              Container(
                height: barHeight,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),

              // Foreground fill
              animate
                  ? AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      width: max(0, fillWidth),
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: fgColor,
                        borderRadius: BorderRadius.circular(radius),
                      ),
                    )
                  : Container(
                      width: max(0, fillWidth),
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: fgColor,
                        borderRadius: BorderRadius.circular(radius),
                      ),
                    ),

              // Expected progress marker
              if (expectedRatio != null && expectedRatio! > 0)
                Positioned(
                  left: (maxWidth * expectedRatio!.clamp(0.0, 1.0)) - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2.w,
                    decoration: BoxDecoration(
                      color: colors.textSecondary.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(1.r),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Warna otomatis berdasarkan rasio pemakaian.
  static Color _colorForRatio(double ratio, dynamic colors) {
    if (ratio >= 1.0) return colors.error as Color;
    if (ratio >= 0.8) return colors.warning as Color;
    if (ratio >= 0.6) return const Color(0xFFF59E0B); // amber
    return colors.income as Color;
  }

  /// Helper statis untuk mendapatkan warna budget dari luar widget.
  static Color colorForRatio(double ratio, BuildContext context) {
    final colors = context.colors;
    if (ratio >= 1.0) return colors.error;
    if (ratio >= 0.8) return colors.warning;
    if (ratio >= 0.6) return const Color(0xFFF59E0B);
    return colors.income;
  }
}
