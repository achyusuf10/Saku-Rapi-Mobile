import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/features/auth/controllers/auth_controller.dart';
import 'package:app_saku_rapi/features/auth/models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Widget header profil user yang reusable.
///
/// Menampilkan avatar, nama lengkap, dan email user.
/// Digunakan di halaman Settings dan halaman lain yang
/// membutuhkan info profil.
///
/// Mengambil data dari [currentUserProvider] secara otomatis.
class ProfileHeaderWidget extends ConsumerWidget {
  const ProfileHeaderWidget({super.key, this.onTap, this.showChevron = true});

  /// Callback saat card profil ditekan (opsional).
  final VoidCallback? onTap;

  /// Apakah menampilkan ikon chevron di sisi kanan.
  final bool showChevron;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            // Avatar
            _ProfileAvatar(user: user),
            SizedBox(width: 12.w),

            // Name & email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.fullName ?? user?.email ?? '-',
                    style: TextStyleConstants.b1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user?.email != null && user?.fullName != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      user!.email,
                      style: TextStyleConstants.label2.copyWith(
                        color: colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Chevron
            if (showChevron)
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

/// Widget avatar profil user.
///
/// Menampilkan foto dari [CachedNetworkImage] jika `avatarUrl` tersedia,
/// atau fallback ke ikon default.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final avatarUrl = user?.avatarUrl;

    return CircleAvatar(
      radius: 24.r,
      backgroundColor: colors.primaryLight,
      child: avatarUrl != null && avatarUrl.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl,
                width: 48.r,
                height: 48.r,
                fit: BoxFit.cover,
                placeholder: (context, url) => FaIcon(
                  FontAwesomeIcons.user,
                  color: colors.primary,
                  size: 20.w,
                ),
                errorWidget: (context, url, error) => FaIcon(
                  FontAwesomeIcons.user,
                  color: colors.primary,
                  size: 20.w,
                ),
              ),
            )
          : FaIcon(FontAwesomeIcons.user, color: colors.primary, size: 20.w),
    );
  }
}
