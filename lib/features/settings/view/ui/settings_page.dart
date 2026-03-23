import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/auth/controllers/auth_controller.dart';
import 'package:app_saku_rapi/features/auth/view/widgets/profile_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Halaman pengaturan / profil.
///
/// Berisi profile header, pengaturan tema/bahasa/notifikasi, dan tombol logout.
/// Profile header menggunakan [ProfileHeaderWidget] yang reusable.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.profileSettings,
          style: TextStyleConstants.h6.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        children: [
          // Profile card (reusable widget)
          const ProfileHeaderWidget(),
          SizedBox(height: 24.h),

          // Category management
          _SettingsTile(
            icon: FontAwesomeIcons.layerGroup,
            label: l10n.categoryTitle,
            onTap: () => context.push(AppRouter.categories),
          ),
          SizedBox(height: 12.h),

          // Logout button
          _SettingsLogoutTile(
            label: l10n.profileLogout,
            onTap: () => _handleLogout(context, ref),
          ),
        ],
      ),
    );
  }

  /// Menangani proses logout dengan dialog konfirmasi.
  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;

    final confirmed = await context.showConfirmDialog(
      title: l10n.profileLogoutConfirmTitle,
      message: l10n.profileLogoutConfirmMessage,
      confirmLabel: l10n.profileLogout,
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    context.showLoadingOverlay();

    try {
      await ref.read(authControllerProvider.notifier).signOut();
    } finally {
      if (context.mounted) {
        context.closeOverlay();
      }
    }
    // GoRouter redirect otomatis ke login via refreshListenable
  }
}

/// Tile generik untuk menu settings.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: FaIcon(icon, size: 16.w, color: colors.primary),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: TextStyleConstants.b2.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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

/// Tile logout di settings page.
class _SettingsLogoutTile extends StatelessWidget {
  const _SettingsLogoutTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.rightFromBracket,
                  size: 16.w,
                  color: colors.error,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: TextStyleConstants.b2.copyWith(
                  color: colors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
