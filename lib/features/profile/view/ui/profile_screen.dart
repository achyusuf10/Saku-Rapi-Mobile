import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/core/themes/theme_controller.dart';
import 'package:app_saku_rapi/features/auth/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Layar profil user — pengaturan akun, tema, dan navigasi fitur.
///
/// Menampilkan info user (avatar, nama, email), menu pengaturan,
/// dan aksi logout.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.colors;
    final l10n = context.l10n;
    final userAsync = ref.watch(authControllerProvider);
    final themeMode = ref.watch(themeControllerProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: appColors.background,
      appBar: AppBar(
        backgroundColor: appColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.profileTitle,
          style: TextStyleConstants.h7.copyWith(
            fontWeight: FontWeight.w700,
            color: appColors.textPrimary,
          ),
        ),
      ),
      body: userAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: appColors.primary)),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                FontAwesomeIcons.circleExclamation,
                color: appColors.error,
                size: 36.r,
              ),
              SizedBox(height: 12.h),
              Text(
                error.toString(),
                style: TextStyleConstants.caption.copyWith(
                  color: appColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              TextButton.icon(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).refreshProfile(),
                icon: FaIcon(FontAwesomeIcons.arrowRotateRight, size: 14.r),
                label: Text(l10n.retryButton),
              ),
            ],
          ),
        ),
        data: (user) {
          if (user == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Column(
              children: [
                // ── Avatar & Info ──
                _ProfileHeaderSection(
                  avatarUrl: user.avatarUrl,
                  fullName: user.fullName ?? user.email,
                  email: user.email,
                  memberSince: user.createdAt,
                ),

                SizedBox(height: 24.h),

                // ── Settings Section ──
                _SectionCard(
                  title: l10n.profileSettings,
                  children: [
                    _SettingsTile(
                      icon: FontAwesomeIcons.moon,
                      title: l10n.profileDarkMode,
                      trailing: Switch.adaptive(
                        value: isDark,
                        activeTrackColor: appColors.primary,
                        onChanged: (_) {
                          ref
                              .read(themeControllerProvider.notifier)
                              .toggleTheme();
                        },
                      ),
                    ),
                    _SettingsTile(
                      icon: FontAwesomeIcons.bell,
                      title: l10n.profileNotifications,
                      onTap: () => context.push(AppRouter.notificationSettings),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // ── Management Section ──
                _SectionCard(
                  title: l10n.profileSettings,
                  children: [
                    _SettingsTile(
                      icon: FontAwesomeIcons.wallet,
                      title: l10n.profileWallets,
                      onTap: () => context.push(AppRouter.walletList),
                    ),
                    _SettingsTile(
                      icon: FontAwesomeIcons.layerGroup,
                      title: l10n.profileCategories,
                      onTap: () => context.push(AppRouter.categoryList),
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // ── Logout Button ──
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleLogout(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: appColors.error,
                      side: BorderSide(color: appColors.error),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    icon: FaIcon(FontAwesomeIcons.rightFromBracket, size: 16.r),
                    label: Text(
                      l10n.profileLogout,
                      style: TextStyleConstants.b2.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 40.h),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Menampilkan dialog konfirmasi, lalu logout jika user setuju.
  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await context.showConfirmDialog(
      title: l10n.profileLogoutConfirmTitle,
      message: l10n.profileLogoutConfirmMessage,
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }
}

/// Header profil — avatar, nama, email, dan tanggal bergabung.
class _ProfileHeaderSection extends StatelessWidget {
  const _ProfileHeaderSection({
    required this.avatarUrl,
    required this.fullName,
    required this.email,
    required this.memberSince,
  });

  final String? avatarUrl;
  final String fullName;
  final String email;
  final DateTime memberSince;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;

    return Column(
      children: [
        CircleAvatar(
          radius: 42.r,
          backgroundColor: appColors.primaryLight,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl == null
              ? FaIcon(
                  FontAwesomeIcons.user,
                  size: 32.r,
                  color: appColors.primary,
                )
              : null,
        ),
        SizedBox(height: 12.h),
        Text(
          fullName,
          style: TextStyleConstants.h6.copyWith(
            fontWeight: FontWeight.w700,
            color: appColors.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          email,
          style: TextStyleConstants.caption.copyWith(
            color: appColors.textSecondary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '${l10n.profileMemberSince} ${memberSince.extToDateStringDDMMMMYYYY()}',
          style: TextStyleConstants.label2.copyWith(
            color: appColors.textSecondary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

/// Section card — container dengan judul dan list tile anak.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: appColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
            child: Text(
              title,
              style: TextStyleConstants.label1.copyWith(
                fontWeight: FontWeight.w700,
                color: appColors.textSecondary,
              ),
            ),
          ),
          ...children,
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}

/// Tile pengaturan — ikon, judul, dan trailing widget (chevron atau switch).
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: appColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Center(
                child: FaIcon(icon, size: 16.r, color: appColors.primary),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: TextStyleConstants.b2.copyWith(
                  color: appColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing ??
                FaIcon(
                  FontAwesomeIcons.chevronRight,
                  size: 14.r,
                  color: appColors.textSecondary,
                ),
          ],
        ),
      ),
    );
  }
}
