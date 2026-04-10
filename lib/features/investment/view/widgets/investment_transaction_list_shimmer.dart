import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/global/widgets/shimmer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shimmer loading skeleton untuk transaction list di investment detail page.
///
/// Meniru layout [_TransactionItem] dalam tab Buy/Sell history.
/// Menggunakan satu [ShimmerWidget.custom] sebagai parent.
class InvestmentTransactionListShimmer extends StatelessWidget {
  const InvestmentTransactionListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = context.colors.surfaceVariant;

    return ShimmerWidget.custom(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          children: List.generate(5, (i) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _TransactionItemSkeleton(baseColor: baseColor),
            );
          }),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Transaction Item Skeleton
// ═══════════════════════════════════════════════════════

class _TransactionItemSkeleton extends StatelessWidget {
  const _TransactionItemSkeleton({required this.baseColor});
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
          // Leading icon
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              color: baseColor,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Box(width: 80.w, height: 14.h, radius: 4.r, color: baseColor),
                SizedBox(height: 2.h),
                _Box(width: 100.w, height: 10.h, radius: 3.r, color: baseColor),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Box(width: 90.w, height: 14.h, radius: 4.r, color: baseColor),
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
