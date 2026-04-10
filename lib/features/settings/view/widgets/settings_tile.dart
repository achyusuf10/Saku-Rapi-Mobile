import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Tile generik untuk menu settings.
///
/// Variasi:
/// - Navigasi: [onTap] + chevron kanan
/// - Toggle: [trailing] berupa [Switch]
/// - Info: [subtitle] menampilkan nilai saat ini
///
/// Digunakan di [SettingsPage] dan bisa di-reuse di halaman lain.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.iconBackgroundColor,
  });

  /// Ikon FontAwesome di kiri.
  final IconData icon;

  /// Label utama tile.
  final String label;

  /// Teks sekunder di bawah label (opsional).
  final String? subtitle;

  /// Callback saat tile di-tap.
  final VoidCallback? onTap;

  /// Widget di sisi kanan (opsional). Jika null, tampilkan chevron.
  final Widget? trailing;

  /// Override warna ikon (default: textSecondary).
  final Color? iconColor;

  /// Override warna background ikon (default: surfaceVariant).
  final Color? iconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final effectiveIconColor = iconColor ?? colors.textSecondary;
    final effectiveBgColor = iconBackgroundColor ?? colors.surfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            // ─── Icon container ───
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: effectiveBgColor,
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: FaIcon(icon, size: 16.w, color: effectiveIconColor),
              ),
            ),
            SizedBox(width: 12.w),

            // ─── Label + subtitle ───
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyleConstants.b2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitle!,
                      style: TextStyleConstants.label2.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ─── Trailing ───
            trailing ??
                FaIcon(
                  FontAwesomeIcons.chevronRight,
                  size: 14.w,
                  color: colors.textSecondary,
                ),
          ],
        ),
      ),
    );
  }
}

/// Section header untuk pengelompokan settings tiles.
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 8.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyleConstants.label3.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Container card untuk sekelompok settings tiles.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                indent: 64.w,
                color: colors.border.withValues(alpha: 0.8),
              ),
          ],
        ],
      ),
    );
  }
}
