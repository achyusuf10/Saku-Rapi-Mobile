import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/global/widgets/shimmer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shimmer loading skeleton yang meniru layout budget page saat data loaded.
///
/// Menampilkan skeleton gauge summary + budget group cards.
/// Menggunakan satu [ShimmerWidget.custom] sebagai parent.
class BudgetShimmer extends StatelessWidget {
  const BudgetShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return ShimmerWidget.custom(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.h),

            // ─── Summary Card (Gauge) ───
            _BudgetSummaryCardSkeleton(baseColor: baseColor),
            SizedBox(height: 20.h),

            // ─── Add Budget Button ───
            _Box(
              width: double.infinity,
              height: 44.h,
              radius: 12.r,
              color: baseColor,
            ),
            SizedBox(height: 20.h),

            // ─── Section Title ───
            _Box(width: 120.w, height: 16.h, radius: 4.r, color: baseColor),
            SizedBox(height: 12.h),

            // ─── Budget Group Cards ───
            _BudgetGroupSkeleton(baseColor: baseColor),
            SizedBox(height: 12.h),
            _BudgetGroupSkeleton(baseColor: baseColor, hasChildren: true),
            SizedBox(height: 12.h),
            _BudgetGroupSkeleton(baseColor: baseColor),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Budget Summary Card Skeleton (Gauge)
// ═══════════════════════════════════════════════════════

class _BudgetSummaryCardSkeleton extends StatelessWidget {
  const _BudgetSummaryCardSkeleton({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: baseColor,
      ),
      child: Column(
        children: [
          // Gauge placeholder (semicircle area)
          _Box(width: 180.w, height: 110.h, radius: 90.r, color: baseColor),
          SizedBox(height: 4.h),
          // Spendable label
          _Box(width: 80.w, height: 12.h, radius: 3.r, color: baseColor),
          SizedBox(height: 4.h),
          // Spendable amount
          _Box(width: 140.w, height: 20.h, radius: 4.r, color: baseColor),
          SizedBox(height: 20.h),

          // Stats row: Budget / Spent / Remaining
          Row(
            children: [
              Expanded(child: _StatItemSkeleton(baseColor: baseColor)),
              Container(width: 1, height: 32.h, color: baseColor),
              Expanded(child: _StatItemSkeleton(baseColor: baseColor)),
              Container(width: 1, height: 32.h, color: baseColor),
              Expanded(child: _StatItemSkeleton(baseColor: baseColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItemSkeleton extends StatelessWidget {
  const _StatItemSkeleton({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Box(width: 60.w, height: 14.h, radius: 3.r, color: baseColor),
        SizedBox(height: 2.h),
        _Box(width: 40.w, height: 10.h, radius: 3.r, color: baseColor),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// Budget Group Card Skeleton
// ═══════════════════════════════════════════════════════

class _BudgetGroupSkeleton extends StatelessWidget {
  const _BudgetGroupSkeleton({
    required this.baseColor,
    this.hasChildren = false,
  });
  final Color baseColor;
  final bool hasChildren;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: baseColor,
      ),
      child: Column(
        children: [
          // Parent budget row
          _BudgetRowSkeleton(baseColor: baseColor, isParent: true),

          // Child rows (if any)
          if (hasChildren) ...[
            Divider(height: 1, color: baseColor.withValues(alpha: 0.3)),
            Padding(
              padding: EdgeInsets.only(left: 36.w),
              child: Column(
                children: [
                  _BudgetRowSkeleton(baseColor: baseColor, isParent: false),
                  Divider(height: 1, color: baseColor.withValues(alpha: 0.2)),
                  _BudgetRowSkeleton(baseColor: baseColor, isParent: false),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BudgetRowSkeleton extends StatelessWidget {
  const _BudgetRowSkeleton({required this.baseColor, required this.isParent});
  final Color baseColor;
  final bool isParent;

  @override
  Widget build(BuildContext context) {
    final iconSize = isParent ? 42.w : 34.w;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      child: Column(
        children: [
          Row(
            children: [
              // Category icon
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isParent ? 12.r : 10.r),
                  color: baseColor,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Box(
                      width: 100.w,
                      height: isParent ? 14.h : 12.h,
                      radius: 4.r,
                      color: baseColor,
                    ),
                    SizedBox(height: 4.h),
                    _Box(
                      width: 60.w,
                      height: 10.h,
                      radius: 3.r,
                      color: baseColor,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Box(
                    width: 80.w,
                    height: isParent ? 14.h : 12.h,
                    radius: 4.r,
                    color: baseColor,
                  ),
                  SizedBox(height: 4.h),
                  _Box(
                    width: 50.w,
                    height: 10.h,
                    radius: 3.r,
                    color: baseColor,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // Progress bar
          _Box(
            width: double.infinity,
            height: isParent ? 6.h : 4.h,
            radius: 3.r,
            color: baseColor,
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
