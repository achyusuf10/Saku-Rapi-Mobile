import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Card utama SakuRapi.
///
/// Gunakan widget ini untuk semua container card di aplikasi.
class SakuCard extends StatelessWidget {
  const SakuCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.backgroundColor,
    this.border,
    this.elevation,
  });

  /// Konten di dalam card.
  final Widget child;

  /// Padding konten. Default: 16 semua sisi.
  final EdgeInsetsGeometry? padding;

  /// Margin luar card.
  final EdgeInsetsGeometry? margin;

  /// Callback saat card di-tap.
  final VoidCallback? onTap;

  /// Border radius. Default: 12.
  final double? borderRadius;

  /// Background color kustom.
  final Color? backgroundColor;

  /// Border kustom.
  final BoxBorder? border;

  /// Elevasi shadow.
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = borderRadius ?? 12.r;
    final shadowAlpha = context.isDarkMode ? 0.15 : 0.06;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: colors.border),
        boxShadow: [
          if ((elevation ?? 0) > 0)
            BoxShadow(
              color: Colors.black.withValues(alpha: shadowAlpha),
              blurRadius: elevation! * 2,
              offset: Offset(0, elevation!),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: padding ?? EdgeInsets.all(16.w),
            child: child,
          ),
        ),
      ),
    );
  }
}
