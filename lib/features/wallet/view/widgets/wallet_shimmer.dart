import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/global/widgets/shimmer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shimmer loading skeleton yang meniru layout wallet page saat data loaded.
///
/// Menampilkan skeleton summary card + wallet tile list.
/// Menggunakan satu [ShimmerWidget.custom] sebagai parent.
class WalletShimmer extends StatelessWidget {
  const WalletShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final baseColor = colors.surfaceVariant;

    return ShimmerWidget.custom(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 80.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Summary Card ───
            _WalletSummaryCardSkeleton(baseColor: baseColor),
            SizedBox(height: 24.h),

            // ─── Section Header (Included) ───
            _Box(width: 100.w, height: 14.h, radius: 4.r, color: baseColor),
            SizedBox(height: 8.h),

            // ─── Wallet Tiles ───
            _WalletTileSkeleton(baseColor: baseColor),
            SizedBox(height: 8.h),
            _WalletTileSkeleton(baseColor: baseColor),
            SizedBox(height: 8.h),
            _WalletTileSkeleton(baseColor: baseColor),
            SizedBox(height: 16.h),

            // ─── Section Header (Excluded) ───
            _Box(width: 100.w, height: 14.h, radius: 4.r, color: baseColor),
            SizedBox(height: 8.h),

            // ─── Excluded Wallet Tiles ───
            _WalletTileSkeleton(baseColor: baseColor),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Wallet Summary Card Skeleton
// ═══════════════════════════════════════════════════════

class _WalletSummaryCardSkeleton extends StatelessWidget {
  const _WalletSummaryCardSkeleton({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            children: [
              _Box(width: 14.w, height: 14.w, radius: 4.r, color: baseColor),
              SizedBox(width: 8.w),
              _Box(width: 100.w, height: 14.h, radius: 4.r, color: baseColor),
            ],
          ),
          SizedBox(height: 10.h),
          // Balance amount
          _Box(width: 180.w, height: 24.h, radius: 6.r, color: baseColor),
          SizedBox(height: 16.h),
          // Wallet count chip
          _Box(width: 120.w, height: 32.h, radius: 12.r, color: baseColor),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Wallet Tile Skeleton
// ═══════════════════════════════════════════════════════

class _WalletTileSkeleton extends StatelessWidget {
  const _WalletTileSkeleton({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: baseColor,
      ),
      child: Row(
        children: [
          // Wallet icon
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
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
          _Box(width: 90.w, height: 14.h, radius: 4.r, color: baseColor),
          SizedBox(width: 4.w),
          _Box(width: 16.w, height: 16.w, radius: 4.r, color: baseColor),
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
