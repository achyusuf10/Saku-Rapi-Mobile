import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/global/widgets/shimmer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shimmer loading skeleton yang meniru layout report page saat data loaded.
///
/// Menampilkan skeleton summary card + category section + trend chart +
/// insight section. Menggunakan satu [ShimmerWidget.custom] sebagai parent.
class ReportShimmer extends StatelessWidget {
  const ReportShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = context.colors.surfaceVariant;

    return ShimmerWidget.custom(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Summary Card ───
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
              child: _SummaryCardSkeleton(baseColor: baseColor),
            ),
            SizedBox(height: 20.h),

            // ─── Category Section ───
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _CategorySectionSkeleton(baseColor: baseColor),
            ),
            SizedBox(height: 20.h),

            // ─── Trend Chart Section ───
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _TrendSectionSkeleton(baseColor: baseColor),
            ),
            SizedBox(height: 20.h),

            // ─── Insight Section ───
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _InsightSkeleton(baseColor: baseColor),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Summary Card Skeleton
// ═══════════════════════════════════════════════════════

class _SummaryCardSkeleton extends StatelessWidget {
  const _SummaryCardSkeleton({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: baseColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Net amount row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Box(width: 80.w, height: 12.h, radius: 3.r, color: baseColor),
              _Box(width: 120.w, height: 20.h, radius: 4.r, color: baseColor),
            ],
          ),
          SizedBox(height: 16.h),

          // Income row
          Row(
            children: [
              _Box(width: 60.w, height: 12.h, radius: 3.r, color: baseColor),
              const Spacer(),
              _Box(width: 100.w, height: 14.h, radius: 4.r, color: baseColor),
              SizedBox(width: 6.w),
              _Box(width: 50.w, height: 20.h, radius: 8.r, color: baseColor),
            ],
          ),
          SizedBox(height: 10.h),

          // Expense row
          Row(
            children: [
              _Box(width: 70.w, height: 12.h, radius: 3.r, color: baseColor),
              const Spacer(),
              _Box(width: 100.w, height: 14.h, radius: 4.r, color: baseColor),
              SizedBox(width: 6.w),
              _Box(width: 50.w, height: 20.h, radius: 8.r, color: baseColor),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Category Section Skeleton
// ═══════════════════════════════════════════════════════

class _CategorySectionSkeleton extends StatelessWidget {
  const _CategorySectionSkeleton({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: baseColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: icon + title + toggle buttons
          Row(
            children: [
              _Box(width: 15.w, height: 15.w, radius: 4.r, color: baseColor),
              SizedBox(width: 8.w),
              Expanded(
                child: _Box(
                  width: 120.w,
                  height: 14.h,
                  radius: 4.r,
                  color: baseColor,
                ),
              ),
              _Box(width: 32.w, height: 32.w, radius: 8.r, color: baseColor),
              SizedBox(width: 6.w),
              _Box(width: 100.w, height: 28.h, radius: 8.r, color: baseColor),
            ],
          ),
          SizedBox(height: 12.h),

          // Pie chart placeholder
          _Box(
            width: double.infinity,
            height: 280.h,
            radius: 12.r,
            color: baseColor,
          ),
          SizedBox(height: 12.h),

          // Legend row
          Row(
            children: List.generate(
              4,
              (_) => Padding(
                padding: EdgeInsets.only(right: 14.w),
                child: Row(
                  children: [
                    _Circle(size: 24.w, color: baseColor),
                    SizedBox(width: 5.w),
                    _Box(
                      width: 40.w,
                      height: 10.h,
                      radius: 3.r,
                      color: baseColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Trend Chart Section Skeleton
// ═══════════════════════════════════════════════════════

class _TrendSectionSkeleton extends StatelessWidget {
  const _TrendSectionSkeleton({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: baseColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              _Box(width: 15.w, height: 15.w, radius: 4.r, color: baseColor),
              SizedBox(width: 8.w),
              Expanded(
                child: _Box(
                  width: 100.w,
                  height: 14.h,
                  radius: 4.r,
                  color: baseColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),

          // Legend dots
          Row(
            children: [
              _Box(width: 8.w, height: 8.w, radius: 2.r, color: baseColor),
              SizedBox(width: 4.w),
              _Box(width: 50.w, height: 10.h, radius: 3.r, color: baseColor),
              SizedBox(width: 10.w),
              _Box(width: 8.w, height: 8.w, radius: 2.r, color: baseColor),
              SizedBox(width: 4.w),
              _Box(width: 50.w, height: 10.h, radius: 3.r, color: baseColor),
            ],
          ),
          SizedBox(height: 8.h),

          // Chart area
          _Box(
            width: double.infinity,
            height: 220.h,
            radius: 8.r,
            color: baseColor,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Insight Section Skeleton
// ═══════════════════════════════════════════════════════

class _InsightSkeleton extends StatelessWidget {
  const _InsightSkeleton({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        color: baseColor,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Box(width: 16.w, height: 16.w, radius: 4.r, color: baseColor),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Box(
                  width: double.infinity,
                  height: 12.h,
                  radius: 3.r,
                  color: baseColor,
                ),
                SizedBox(height: 4.h),
                _Box(width: 200.w, height: 12.h, radius: 3.r, color: baseColor),
              ],
            ),
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
