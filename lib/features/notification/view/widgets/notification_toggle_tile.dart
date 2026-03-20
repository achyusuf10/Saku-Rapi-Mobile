import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/global/widgets/saku_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Tile toggle untuk pengaturan notifikasi.
///
/// Menampilkan ikon, judul, subjudul, dan Switch yang bisa diubah.
/// Mendukung slot [trailing] opsional untuk widget tambahan
/// (misal: tombol pilih jam atau input hari).
class NotificationToggleTile extends StatelessWidget {
  const NotificationToggleTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.trailing,
  });

  /// Ikon FontAwesome di sisi kiri.
  final IconData icon;

  /// Judul utama.
  final String title;

  /// Deskripsi singkat di bawah judul.
  final String subtitle;

  /// Nilai toggle saat ini.
  final bool value;

  /// Callback saat toggle diubah.
  final ValueChanged<bool> onChanged;

  /// Widget tambahan yang ditampilkan di bawah judul + subtitle
  /// **hanya saat toggle aktif** (opsional).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SakuCard(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: FaIcon(icon, size: 18.r, color: colors.primary),
                ),
              ),
              SizedBox(width: 12.w),

              // Title + Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyleConstants.b1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyleConstants.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Switch
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: colors.primary,
              ),
            ],
          ),

          // Trailing widget (visible when enabled only)
          if (value && trailing != null) ...[
            SizedBox(height: 12.h),
            Divider(color: colors.border, height: 1),
            SizedBox(height: 12.h),
            trailing!,
          ],
        ],
      ),
    );
  }
}
