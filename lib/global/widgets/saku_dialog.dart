import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Dialog global modern SakuRapi.
///
/// Menampilkan dialog dengan animasi fade + scale, icon header,
/// title, content widget, dan button positif/negatif yang opsional.
///
/// Jika [onTapPositive] null, button positif tidak ditampilkan.
/// Jika [onTapNegative] null, button negatif tidak ditampilkan.
///
/// ```dart
/// SakuDialog.show(
///   context,
///   title: 'Hapus?',
///   content: Text('Yakin hapus data ini?'),
///   labelPositive: 'Hapus',
///   onTapPositive: () { ... },
///   labelNegative: 'Batal',
///   onTapNegative: () => Navigator.pop(context),
/// );
/// ```
class SakuDialog extends StatelessWidget {
  const SakuDialog({
    super.key,
    required this.title,
    required this.content,
    this.onTapPositive,
    this.onTapNegative,
    this.labelPositive,
    this.labelNegative,
    this.icon,
    this.positiveColor,
  });

  final String title;
  final Widget content;
  final VoidCallback? onTapPositive;
  final VoidCallback? onTapNegative;
  final String? labelPositive;
  final String? labelNegative;

  /// Icon di header. Default: `Icons.help_outline_rounded`.
  final IconData? icon;

  /// Warna button positif. Default: `colors.primary`.
  final Color? positiveColor;

  /// Shortcut untuk menampilkan dialog.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required Widget content,
    VoidCallback? onTapPositive,
    VoidCallback? onTapNegative,
    String? labelPositive,
    String? labelNegative,
    IconData? icon,
    Color? positiveColor,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'SakuDialog',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder:
          (
            BuildContext transitionContext,
            Animation<double> anim,
            Animation<double> secondaryAnim,
            Widget child,
          ) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
              child: ScaleTransition(
                scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                child: child,
              ),
            );
          },
      pageBuilder:
          (
            BuildContext pageContext,
            Animation<double> primaryAnim,
            Animation<double> secondaryAnim,
          ) {
            return Center(
              child: SakuDialog(
                title: title,
                content: content,
                onTapPositive: onTapPositive,
                onTapNegative: onTapNegative,
                labelPositive: labelPositive,
                labelNegative: labelNegative,
                icon: icon,
                positiveColor: positiveColor,
              ),
            );
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasPositive = onTapPositive != null;
    final hasNegative = onTapNegative != null;
    final effectivePositiveColor = positiveColor ?? colors.primary;
    final positiveTextColor =
        ThemeData.estimateBrightnessForColor(effectivePositiveColor) ==
            Brightness.dark
        ? Colors.white
        : const Color(0xFF0F172A);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 340.w),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon header
              Container(
                width: 56.r,
                height: 56.r,
                decoration: BoxDecoration(
                  color: effectivePositiveColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? Icons.help_outline_rounded,
                  color: effectivePositiveColor,
                  size: 28.r,
                ),
              ),
              SizedBox(height: 16.h),

              // Title
              Text(
                title,
                style: TextStyleConstants.h6.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),

              // Content
              content,
              SizedBox(height: 24.h),

              // Buttons
              if (hasPositive || hasNegative)
                Row(
                  children: [
                    if (hasNegative)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onTapNegative,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            side: BorderSide(
                              color: colors.textSecondary.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            labelNegative ?? '',
                            style: TextStyleConstants.b2.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    if (hasNegative && hasPositive) SizedBox(width: 12.w),
                    if (hasPositive)
                      Expanded(
                        child: FilledButton(
                          onPressed: onTapPositive,
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            backgroundColor: effectivePositiveColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            labelPositive ?? '',
                            style: TextStyleConstants.b2.copyWith(
                              fontWeight: FontWeight.w600,
                              color: positiveTextColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
