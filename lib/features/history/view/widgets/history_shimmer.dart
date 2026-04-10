import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/global/widgets/shimmer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shimmer loading skeleton yang meniru layout history page saat data loaded.
///
/// Menampilkan skeleton summary card + grouped transaction list.
/// Menggunakan satu [ShimmerWidget.custom] sebagai parent.
class HistoryShimmer extends StatelessWidget {
  const HistoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = context.colors.surfaceVariant;

    return ShimmerWidget.custom(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Summary Card ───
            _SummaryCardSkeleton(baseColor: baseColor),
            SizedBox(height: 12.h),

            // ─── Grouped Transaction List ───
            _TransactionGroupSkeleton(baseColor: baseColor),
            SizedBox(height: 12.h),
            _TransactionGroupSkeleton(baseColor: baseColor, itemCount: 2),
            SizedBox(height: 12.h),
            _TransactionGroupSkeleton(baseColor: baseColor, itemCount: 4),
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: baseColor,
        ),
        child: Column(
          children: [
            // Income / Expense row
            Row(
              children: [
                // Income
                _Circle(size: 32.w, color: baseColor),
                SizedBox(width: 8.w),
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
                        width: 90.w,
                        height: 14.h,
                        radius: 4.r,
                        color: baseColor,
                      ),
                    ],
                  ),
                ),
                // Divider
                Container(width: 1, height: 36.h, color: baseColor),
                SizedBox(width: 12.w),
                // Expense
                _Circle(size: 32.w, color: baseColor),
                SizedBox(width: 8.w),
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
                        width: 90.w,
                        height: 14.h,
                        radius: 4.r,
                        color: baseColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            // Transaction count
            _Box(width: 100.w, height: 10.h, radius: 3.r, color: baseColor),
            SizedBox(height: 8.h),
            // Report button
            Align(
              alignment: Alignment.centerRight,
              child: _Box(
                width: 100.w,
                height: 28.h,
                radius: 8.r,
                color: baseColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Transaction Group Skeleton
// ═══════════════════════════════════════════════════════

class _TransactionGroupSkeleton extends StatelessWidget {
  const _TransactionGroupSkeleton({
    required this.baseColor,
    this.itemCount = 3,
  });
  final Color baseColor;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Box(
                      width: 120.w,
                      height: 14.h,
                      radius: 4.r,
                      color: baseColor,
                    ),
                    SizedBox(height: 2.h),
                    _Box(
                      width: 60.w,
                      height: 10.h,
                      radius: 3.r,
                      color: baseColor,
                    ),
                  ],
                ),
              ),
              _Box(width: 80.w, height: 12.h, radius: 3.r, color: baseColor),
            ],
          ),
          SizedBox(height: 6.h),

          // Transaction card
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              color: baseColor,
            ),
            child: Column(
              children: List.generate(itemCount, (i) {
                return Column(
                  children: [
                    _TransactionTileSkeleton(baseColor: baseColor),
                    if (i < itemCount - 1)
                      Divider(
                        height: 1,
                        indent: 70.w,
                        color: baseColor.withValues(alpha: 0.3),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Transaction Tile Skeleton
// ═══════════════════════════════════════════════════════

class _TransactionTileSkeleton extends StatelessWidget {
  const _TransactionTileSkeleton({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          _Circle(size: 42.w, color: baseColor),
          SizedBox(width: 12.w),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Box(width: 80.w, height: 14.h, radius: 4.r, color: baseColor),
              SizedBox(height: 2.h),
              _Box(width: 40.w, height: 10.h, radius: 3.r, color: baseColor),
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
