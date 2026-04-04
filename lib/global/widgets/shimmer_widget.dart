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
    return Shimmer.fromColors(
      period: const Duration(milliseconds: 600),
      baseColor: !context.isDarkMode
          ? Colors.grey.shade300
          : Colors.grey.shade800,
      highlightColor: !context.isDarkMode
          ? Colors.grey.shade100
          : Colors.grey.shade700,
      child: switch (type) {
        'list' => _buildListWidget(),
        'box' => Container(
          width: width,
          decoration: BoxDecoration(
            color:
                colorWidget ??
                (!context.isDarkMode ? Colors.white : Colors.grey.shade800),
            borderRadius: BorderRadius.circular(radius),
          ),
          height: height,
        ),
        _ => child,
      },
    );
  }

  Widget _buildListWidget() {
    return ListView.separated(
      primary: isScrolled,
      separatorBuilder: (context, index) => seperatorWidget,
      shrinkWrap: true,
      scrollDirection: scrollAxis ?? Axis.vertical,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10).w,
      physics: isScrolled ? null : const NeverScrollableScrollPhysics(),
      itemBuilder: (_, __) {
        return customItemWidget ??
            Container(
              decoration: BoxDecoration(
                color: colorWidget ?? Colors.white,
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
