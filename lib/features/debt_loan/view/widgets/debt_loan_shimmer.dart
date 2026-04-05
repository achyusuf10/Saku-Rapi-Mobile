import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/global/widgets/shimmer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shimmer loading skeleton yang meniru layout debt/loan list saat data loaded.
///
/// Menampilkan skeleton section header + person tiles.
/// Menggunakan satu [ShimmerWidget.custom] sebagai parent.
class DebtLoanShimmer extends StatelessWidget {
  const DebtLoanShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return ShimmerWidget.custom(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Section Header (Unpaid) ───
            _SectionHeaderSkeleton(baseColor: baseColor),

            // ─── Person Tiles ───
            _PersonTileSkeleton(baseColor: baseColor),
            _PersonTileSkeleton(baseColor: baseColor),
            _PersonTileSkeleton(baseColor: baseColor),

            // ─── Section Header (Paid) ───
            _SectionHeaderSkeleton(baseColor: baseColor),

            // ─── Person Tiles ───
            _PersonTileSkeleton(baseColor: baseColor),
            _PersonTileSkeleton(baseColor: baseColor),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Section Header Skeleton
// ═══════════════════════════════════════════════════════

class _SectionHeaderSkeleton extends StatelessWidget {
  const _SectionHeaderSkeleton({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      color: baseColor.withValues(alpha: 0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Box(width: 80.w, height: 12.h, radius: 3.r, color: baseColor),
          _Box(width: 100.w, height: 14.h, radius: 4.r, color: baseColor),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Person Tile Skeleton
// ═══════════════════════════════════════════════════════

class _PersonTileSkeleton extends StatelessWidget {
  const _PersonTileSkeleton({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          // Avatar
          _Circle(size: 40.w, color: baseColor),
          SizedBox(width: 12.w),

          // Name + count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Box(width: 120.w, height: 14.h, radius: 4.r, color: baseColor),
                SizedBox(height: 4.h),
                _Box(width: 80.w, height: 10.h, radius: 3.r, color: baseColor),
              ],
            ),
          ),

          // Amount + remaining label
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Box(width: 90.w, height: 14.h, radius: 4.r, color: baseColor),
              SizedBox(height: 4.h),
              _Box(width: 50.w, height: 10.h, radius: 3.r, color: baseColor),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Primitive shape widgets
// ═══════════════════════════════════════════════════════

class _Box extends StatelessWidget {
  const _Box({
    required this.width,
    required this.height,
    required this.radius,
    required this.color,
  });

  final double width;
  final double height;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: color,
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
