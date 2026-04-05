import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/global/widgets/shimmer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shimmer loading skeleton yang meniru layout investment page saat data loaded.
///
/// Menampilkan skeleton portfolio summary card + grouped asset list.
/// Menggunakan satu [ShimmerWidget.custom] sebagai parent.
class InvestmentShimmer extends StatelessWidget {
  const InvestmentShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return ShimmerWidget.custom(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Portfolio Summary Card ───
            _PortfolioSummarySkeleton(baseColor: baseColor),
            SizedBox(height: 16.h),

            // ─── Section 1 (e.g. Gold) ───
            _SectionHeaderSkeleton(baseColor: baseColor),
            SizedBox(height: 8.h),
            _AssetItemSkeleton(baseColor: baseColor),
            SizedBox(height: 8.h),
            _AssetItemSkeleton(baseColor: baseColor),
            SizedBox(height: 16.h),

            // ─── Section 2 (e.g. Bitcoin) ───
            _SectionHeaderSkeleton(baseColor: baseColor),
            SizedBox(height: 8.h),
            _AssetItemSkeleton(baseColor: baseColor),
            SizedBox(height: 16.h),

            // ─── Section 3 (e.g. Custom) ───
            _SectionHeaderSkeleton(baseColor: baseColor),
            SizedBox(height: 8.h),
            _AssetItemSkeleton(baseColor: baseColor),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Portfolio Summary Card Skeleton
// ═══════════════════════════════════════════════════════

class _PortfolioSummarySkeleton extends StatelessWidget {
  const _PortfolioSummarySkeleton({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: baseColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              _Circle(size: 16.w, color: baseColor),
              SizedBox(width: 8.w),
              _Box(width: 120.w, height: 14.h, radius: 4.r, color: baseColor),
            ],
          ),
          SizedBox(height: 8.h),
          // Total value
          _Box(width: 200.w, height: 28.h, radius: 6.r, color: baseColor),
          SizedBox(height: 12.h),
          // P&L badge
          _Box(width: 160.w, height: 28.h, radius: 8.r, color: baseColor),
          SizedBox(height: 16.h),
          // Bottom row: invested & profit
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Box(
                      width: 60.w,
                      height: 10.h,
                      radius: 3.r,
                      color: baseColor,
                    ),
                    SizedBox(height: 4.h),
                    _Box(
                      width: 100.w,
                      height: 16.h,
                      radius: 4.r,
                      color: baseColor,
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 32.h,
                color: baseColor.withValues(alpha: 0.5),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Box(
                      width: 60.w,
                      height: 10.h,
                      radius: 3.r,
                      color: baseColor,
                    ),
                    SizedBox(height: 4.h),
                    _Box(
                      width: 100.w,
                      height: 16.h,
                      radius: 4.r,
                      color: baseColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Row(
        children: [
          _Box(width: 14.w, height: 14.w, radius: 4.r, color: baseColor),
          SizedBox(width: 8.w),
          _Box(width: 80.w, height: 14.h, radius: 4.r, color: baseColor),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Asset List Item Skeleton
// ═══════════════════════════════════════════════════════

class _AssetItemSkeleton extends StatelessWidget {
  const _AssetItemSkeleton({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: baseColor,
      ),
      child: Row(
        children: [
          // Type icon badge
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              color: baseColor,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Box(width: 100.w, height: 14.h, radius: 4.r, color: baseColor),
                SizedBox(height: 4.h),
                _Box(width: 60.w, height: 10.h, radius: 3.r, color: baseColor),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Box(width: 90.w, height: 14.h, radius: 4.r, color: baseColor),
              SizedBox(height: 4.h),
              _Box(width: 60.w, height: 10.h, radius: 3.r, color: baseColor),
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
