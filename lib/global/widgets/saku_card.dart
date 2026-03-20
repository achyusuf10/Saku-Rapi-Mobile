import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Kontainer kartu elegan global SakuRapi.
///
/// Menggunakan `context.colors.surface` sebagai warna background kartu
/// dengan box-shadow sangat soft sehingga terlihat melayang tipis
/// di atas `context.colors.background`.
///
/// Opsional support [onTap] untuk kartu yang bisa diklik.
class SakuCard extends StatelessWidget {
  const SakuCard({super.key, required this.child, this.padding, this.onTap});

  /// Konten di dalam kartu.
  final Widget child;

  /// Padding internal kartu. Default: `16.r` di semua sisi.
  final EdgeInsetsGeometry? padding;

  /// Callback ketika kartu ditekan. `null` = tidak bisa diklik.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    final container = Container(
      padding: padding ?? EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: appColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return container;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: container,
    );
  }
}
