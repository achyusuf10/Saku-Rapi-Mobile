import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/global/widgets/shimmer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shimmer loading skeleton yang meniru layout dashboard saat data loaded.
///
/// Menggunakan satu [ShimmerWidget.custom] sebagai parent agar performa
/// tetap ringan (hindari multiple Shimmer instances per widget).
class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final baseColor = colors.surfaceVariant;

    return ShimmerWidget.custom(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Greeting ───
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: _Box(
                width: 180.w,
                height: 22.h,
                radius: 6.r,
                color: baseColor,
              ),
            ),

            // ─── Balance Card ───
            _BalanceCardSkeleton(baseColor: baseColor),
            SizedBox(height: 16.h),

            // ─── Quick Actions ───
            _QuickActionsSkeleton(baseColor: baseColor),
            SizedBox(height: 20.h),

            // ─── Wallet Section ───
            _WalletSectionSkeleton(baseColor: baseColor),
            SizedBox(height: 20.h),

            // ─── Period Summary ───
            _PeriodSummarySkeleton(baseColor: baseColor),
            SizedBox(height: 20.h),

            // ─── Chart Carousel ───
            _ChartCarouselSkeleton(baseColor: baseColor),
            SizedBox(height: 20.h),

            // ─── Recent Transactions ───
            _RecentTransactionsSkeleton(baseColor: baseColor),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Balance Card Skeleton
// ═══════════════════════════════════════════════════════

class _BalanceCardSkeleton extends StatelessWidget {
  const _BalanceCardSkeleton({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    final cardColor = baseColor.withValues(alpha: 0.6);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: baseColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Box(width: 120.w, height: 14.h, radius: 4.r, color: cardColor),
              _Box(width: 16.w, height: 16.w, radius: 8.r, color: cardColor),
            ],
          ),
          SizedBox(height: 10.h),

          // Balance amount
          _Box(width: 200.w, height: 28.h, radius: 6.r, color: cardColor),
          SizedBox(height: 16.h),

          // Income / Expense row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    color: cardColor,
                  ),
                  child: Row(
                    children: [
                      _Circle(size: 24.w, color: cardColor),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Box(
                              width: 40.w,
                              height: 10.h,
                              radius: 3.r,
                              color: cardColor,
                            ),
                            SizedBox(height: 4.h),
                            _Box(
                              width: 60.w,
                              height: 12.h,
                              radius: 3.r,
                              color: cardColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    color: cardColor,
                  ),
                  child: Row(
                    children: [
                      _Circle(size: 24.w, color: cardColor),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Box(
                              width: 40.w,
                              height: 10.h,
                              radius: 3.r,
                              color: cardColor,
                            ),
                            SizedBox(height: 4.h),
                            _Box(
                              width: 60.w,
                              height: 12.h,
                              radius: 3.r,
                              color: cardColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
// Quick Actions Skeleton
// ═══════════════════════════════════════════════════════

class _QuickActionsSkeleton extends StatelessWidget {
  const _QuickActionsSkeleton({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          4,
          (_) => Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                children: [
                  _Circle(size: 48.w, color: baseColor),
                  SizedBox(height: 6.h),
                  _Box(
                    width: 48.w,
                    height: 10.h,
                    radius: 3.r,
                    color: baseColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Wallet Section Skeleton
// ═══════════════════════════════════════════════════════

class _WalletSectionSkeleton extends StatelessWidget {
  const _WalletSectionSkeleton({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Box(width: 100.w, height: 16.h, radius: 4.r, color: baseColor),
              _Box(width: 60.w, height: 14.h, radius: 4.r, color: baseColor),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Wallet cards horizontal
        SizedBox(
          height: 100.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: 3,
            separatorBuilder: (context, index) => SizedBox(width: 10.w),
            itemBuilder: (context, index) =>
                _WalletCardSkeleton(baseColor: baseColor),
          ),
        ),
      ],
    );
  }
}

class _WalletCardSkeleton extends StatelessWidget {
  const _WalletCardSkeleton({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160.w,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: baseColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _Circle(size: 24.w, color: baseColor),
              SizedBox(width: 8.w),
              _Box(width: 80.w, height: 12.h, radius: 3.r, color: baseColor),
            ],
          ),
          _Box(width: 100.w, height: 16.h, radius: 4.r, color: baseColor),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Period Summary Skeleton
// ═══════════════════════════════════════════════════════

class _PeriodSummarySkeleton extends StatelessWidget {
  const _PeriodSummarySkeleton({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: baseColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            _Box(width: 150.w, height: 16.h, radius: 4.r, color: baseColor),
            SizedBox(height: 14.h),

            // Income / Expense / Net row
            Row(
              children: List.generate(
                3,
                (_) => Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Circle(size: 6.w, color: baseColor),
                          SizedBox(width: 6.w),
                          _Box(
                            width: 40.w,
                            height: 10.h,
                            radius: 3.r,
                            color: baseColor,
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Padding(
                        padding: EdgeInsets.only(left: 12.w),
                        child: _Box(
                          width: 70.w,
                          height: 14.h,
                          radius: 4.r,
                          color: baseColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Change badge
            _Box(width: 180.w, height: 24.h, radius: 8.r, color: baseColor),
            SizedBox(height: 12.h),

            // See full report
            Align(
              alignment: Alignment.centerRight,
              child: _Box(
                width: 120.w,
                height: 14.h,
                radius: 4.r,
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
// Chart Carousel Skeleton
// ═══════════════════════════════════════════════════════

class _ChartCarouselSkeleton extends StatelessWidget {
  const _ChartCarouselSkeleton({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: baseColor,
        ),
        child: Column(
          children: [
            // Header row
            Row(
              children: [
                _Box(width: 24.w, height: 24.w, radius: 6.r, color: baseColor),
                SizedBox(width: 8.w),
                Expanded(
                  child: Center(
                    child: _Box(
                      width: 140.w,
                      height: 16.h,
                      radius: 4.r,
                      color: baseColor,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                _Box(width: 24.w, height: 24.w, radius: 6.r, color: baseColor),
                SizedBox(width: 8.w),
                _Box(width: 70.w, height: 24.h, radius: 16.r, color: baseColor),
              ],
            ),
            SizedBox(height: 12.h),

            // Chart area
            _Box(
              width: double.infinity,
              height: 400.w,
              radius: 12.r,
              color: baseColor,
            ),
            SizedBox(height: 8.h),

            // Dot indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Box(width: 18.w, height: 6.w, radius: 3.r, color: baseColor),
                SizedBox(width: 6.w),
                _Circle(size: 6.w, color: baseColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Recent Transactions Skeleton
// ═══════════════════════════════════════════════════════

class _RecentTransactionsSkeleton extends StatelessWidget {
  const _RecentTransactionsSkeleton({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Box(width: 140.w, height: 16.h, radius: 4.r, color: baseColor),
              _Box(width: 60.w, height: 14.h, radius: 4.r, color: baseColor),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Date label
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: _Box(width: 80.w, height: 12.h, radius: 3.r, color: baseColor),
        ),
        SizedBox(height: 8.h),

        // Transaction card with 3 items
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              color: baseColor,
            ),
            child: Column(
              children: List.generate(3, (i) {
                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Row(
                        children: [
                          _Circle(size: 40.w, color: baseColor),
                          SizedBox(width: 12.w),
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
                                SizedBox(height: 4.h),
                                _Box(
                                  width: 80.w,
                                  height: 10.h,
                                  radius: 3.r,
                                  color: baseColor,
                                ),
                              ],
                            ),
                          ),
                          _Box(
                            width: 80.w,
                            height: 14.h,
                            radius: 4.r,
                            color: baseColor,
                          ),
                        ],
                      ),
                    ),
                    if (i < 2)
                      Divider(
                        height: 1,
                        indent: 40.w,
                        color: baseColor.withValues(alpha: 0.3),
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
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
