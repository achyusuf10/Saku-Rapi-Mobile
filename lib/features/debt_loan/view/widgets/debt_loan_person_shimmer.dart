import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/global/widgets/shimmer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shimmer loading skeleton yang meniru layout debt/loan person page.
///
/// Menampilkan skeleton summary card + grouped transaction list.
/// Menggunakan satu [ShimmerWidget.custom] sebagai parent.
class DebtLoanPersonShimmer extends StatelessWidget {
  const DebtLoanPersonShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = context.colors.surfaceVariant;

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
                width: 120.w,
                height: 12.h,
                radius: 3.r,
                color: baseColor,
              ),
            ),

            // ─── Summary Card ───
            _PersonSummaryCardSkeleton(baseColor: baseColor),
            SizedBox(height: 8.h),

            // ─── Date Header + Transactions ───
            _DateHeaderSkeleton(baseColor: baseColor),
            _TransactionTileSkeleton(baseColor: baseColor),
            _TransactionTileSkeleton(baseColor: baseColor),

            _DateHeaderSkeleton(baseColor: baseColor),
            _TransactionTileSkeleton(baseColor: baseColor),
            _TransactionTileSkeleton(baseColor: baseColor),
            _TransactionTileSkeleton(baseColor: baseColor),

            _DateHeaderSkeleton(baseColor: baseColor),
            _TransactionTileSkeleton(baseColor: baseColor),

            SizedBox(height: 80.h),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Person Summary Card Skeleton
// ═══════════════════════════════════════════════════════

class _PersonSummaryCardSkeleton extends StatelessWidget {
  const _PersonSummaryCardSkeleton({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Income row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Box(width: 80.w, height: 12.h, radius: 3.r, color: baseColor),
              _Box(width: 100.w, height: 14.h, radius: 4.r, color: baseColor),
            ],
          ),
          SizedBox(height: 4.h),
          // Expense row
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
          // Total remaining
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
      color: baseColor,
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
          // Status indicator bar
          Container(
            width: 4.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 12.w),

          // Transaction info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Box(width: 140.w, height: 14.h, radius: 4.r, color: baseColor),
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
                    SizedBox(width: 8.w),
                    _Box(
                      width: 50.w,
                      height: 16.h,
                      radius: 4.r,
                      color: baseColor,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Amount + remaining
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Box(width: 80.w, height: 14.h, radius: 4.r, color: baseColor),
              SizedBox(height: 2.h),
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
