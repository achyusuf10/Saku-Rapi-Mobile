import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerWidget extends StatelessWidget {
  final String type;

  /// * --- Variable For Custom Type
  final Widget child;

  /// * --- Variable For Box Type

  final double? height;
  final double? width;
  final double radius;

  final int length;

  /// * --- Variable For List Type

  /// EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
  ///
  /// Padding buat list
  final EdgeInsets? padding;
  final bool isScrolled;
  final Color? colorWidget;
  final Axis? scrollAxis;
  final Widget seperatorWidget;

  /// * Jika Ingin Menggunakan Item Widget yang berbeda, isi widget ini
  /// * Default Widget Seperti ini
  final Widget? customItemWidget;
  const ShimmerWidget.list({
    super.key,
    this.length = 2,
    this.padding,
    this.isScrolled = false,
    this.customItemWidget,
    this.colorWidget,
    this.height = 50,
    this.width = 100,
    this.scrollAxis,
    this.radius = 5,
    this.seperatorWidget = const SizedBox(height: 10),
  }) : type = 'list',
       child = const SizedBox();
  const ShimmerWidget.box({
    super.key,
    this.height = double.infinity,
    this.width = double.infinity,
    this.radius = 8,
    this.colorWidget,
    this.scrollAxis,
  }) : type = 'box',
       customItemWidget = null,
       isScrolled = false,
       padding = null,
       length = 2,
       child = const SizedBox(),
       seperatorWidget = const SizedBox();

  const ShimmerWidget.custom({super.key, required this.child})
    : type = 'custom',
      scrollAxis = null,
      customItemWidget = null,
      isScrolled = false,
      padding = null,
      length = 2,
      height = 0,
      width = 0,
      colorWidget = null,
      seperatorWidget = const SizedBox(),
      radius = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Shimmer.fromColors(
      period: const Duration(milliseconds: 600),
      baseColor: colors.surfaceVariant,
      highlightColor: colors.surface,
      child: switch (type) {
        'list' => _buildListWidget(context),
        'box' => Container(
          width: width,
          decoration: BoxDecoration(
            color: colorWidget ?? colors.surface,
            borderRadius: BorderRadius.circular(radius),
          ),
          height: height,
        ),
        _ => child,
      },
    );
  }

  Widget _buildListWidget(BuildContext context) {
    final colors = context.colors;
    return ListView.separated(
      primary: isScrolled,
      separatorBuilder: (context, index) => seperatorWidget,
      shrinkWrap: true,
      scrollDirection: scrollAxis ?? Axis.vertical,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10).w,
      physics: isScrolled ? null : const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return customItemWidget ??
            Container(
              decoration: BoxDecoration(
                color: colorWidget ?? colors.surface,
                borderRadius: BorderRadius.all(Radius.circular(radius)),
              ),
              height: height ?? 50.w,
              width: width ?? 100.w,
            );
      },
      itemCount: length,
    );
  }
}
