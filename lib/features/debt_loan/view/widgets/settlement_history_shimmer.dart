import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/global/widgets/shimmer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shimmer loading skeleton yang meniru layout settlement history page.
///
/// Menampilkan skeleton summary + grouped settlement tiles.
/// Menggunakan satu [ShimmerWidget.custom] sebagai parent.
class SettlementHistoryShimmer extends StatelessWidget {
  const SettlementHistoryShimmer({super.key});

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
            // ─── Result count ───
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              child: _Box(
                width: 100.w,
                height: 12.h,
                radius: 3.r,
                color: baseColor,
              ),
            ),

            // ─── Summary ───
            _SummarySkeleton(baseColor: baseColor),
            SizedBox(height: 8.h),

            // ─── Date Header + Settlement Tiles ───
            _DateHeaderSkeleton(baseColor: baseColor),
            _SettlementTileSkeleton(baseColor: baseColor),
            _SettlementTileSkeleton(baseColor: baseColor),

            _DateHeaderSkeleton(baseColor: baseColor),
            _SettlementTileSkeleton(baseColor: baseColor),
            _SettlementTileSkeleton(baseColor: baseColor),
            _SettlementTileSkeleton(baseColor: baseColor),

            _DateHeaderSkeleton(baseColor: baseColor),
            _SettlementTileSkeleton(baseColor: baseColor),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Summary Skeleton
// ═══════════════════════════════════════════════════════

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Box(width: 80.w, height: 12.h, radius: 3.r, color: baseColor),
              _Box(width: 100.w, height: 14.h, radius: 4.r, color: baseColor),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Box(width: 80.w, height: 12.h, radius: 3.r, color: baseColor),
              _Box(width: 100.w, height: 14.h, radius: 4.r, color: baseColor),
            ],
          ),
          SizedBox(height: 4.h),
          _Box(width: double.infinity, height: 1, radius: 0, color: baseColor),
          SizedBox(height: 4.h),
          Align(
            alignment: Alignment.centerRight,
            child: _Box(
              width: 120.w,
              height: 16.h,
              radius: 4.r,
              color: baseColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Date Header Skeleton
// ═══════════════════════════════════════════════════════

class _DateHeaderSkeleton extends StatelessWidget {
  const _DateHeaderSkeleton({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      color: baseColor.withValues(alpha: 0.5),
      child: Row(
        children: [
          _Box(width: 28.w, height: 28.h, radius: 4.r, color: baseColor),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Box(width: 80.w, height: 12.h, radius: 3.r, color: baseColor),
                SizedBox(height: 2.h),
                _Box(width: 60.w, height: 10.h, radius: 3.r, color: baseColor),
              ],
            ),
          ),
          _Box(width: 80.w, height: 14.h, radius: 4.r, color: baseColor),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Settlement Tile Skeleton
// ═══════════════════════════════════════════════════════

class _SettlementTileSkeleton extends StatelessWidget {
  const _SettlementTileSkeleton({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          // Circle avatar icon
          _Circle(size: 36.w, color: baseColor),
          SizedBox(width: 12.w),

          // Title + subtitle + wallet
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Box(width: 120.w, height: 14.h, radius: 4.r, color: baseColor),
                SizedBox(height: 4.h),
                _Box(width: 160.w, height: 10.h, radius: 3.r, color: baseColor),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    _Box(
                      width: 10.w,
                      height: 10.w,
                      radius: 2.r,
                      color: baseColor,
                    ),
                    SizedBox(width: 4.w),
                    _Box(
                      width: 60.w,
                      height: 10.h,
                      radius: 3.r,
                      color: baseColor,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Amount
          _Box(width: 80.w, height: 14.h, radius: 4.r, color: baseColor),
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
