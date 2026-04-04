import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Base bottom sheet global SakuRapi.
///
/// Menyediakan styling konsisten: rounded corners, drag handle, title,
/// warna surface, dan padding keyboard-aware.
///
/// ```dart
/// SakuBottomSheet.show<bool>(
///   context: context,
///   title: 'Judul',
///   child: MyContent(),
/// );
/// ```
class SakuBottomSheet extends StatelessWidget {
  const SakuBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.trailing,
  });

  /// Konten utama bottom sheet.
  final Widget child;

  /// Title opsional di header.
  final String? title;

  /// Widget trailing di samping title (misal: counter "2/3").
  final Widget? trailing;

  /// Shortcut untuk menampilkan bottom sheet.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    Widget? trailing,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (_) => SakuBottomSheet(
        title: title,
        trailing: trailing,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ──
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // ── Title row ──
            if (title != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: TextStyleConstants.h7.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
              SizedBox(height: 16.h),
            ],

            // ── Content ──
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}
