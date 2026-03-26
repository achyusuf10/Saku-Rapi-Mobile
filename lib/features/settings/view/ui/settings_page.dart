import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/localization/locale_controller.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/core/themes/theme_controller.dart';
import 'package:app_saku_rapi/features/auth/controllers/auth_controller.dart';
import 'package:app_saku_rapi/features/auth/view/widgets/profile_header_widget.dart';
import 'package:app_saku_rapi/features/settings/controllers/settings_controller.dart';
import 'package:app_saku_rapi/features/settings/view/widgets/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Halaman pengaturan / profil.
///
/// Sections:
/// 1. Profil header (avatar, nama, email)
/// 2. Akun — Kategori, Notifikasi
/// 3. Preferensi — Tema, Bahasa, Entry point transaksi
/// 4. Data — Export/Import (coming soon)
/// 5. Lainnya — App version, Logout
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = '${info.version} (${info.buildNumber})');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final themeMode = ref.watch(themeControllerProvider);
    final locale = ref.watch(localeControllerProvider);
    final entryPoint = ref.watch(entryPointProvider);

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
        padding: EdgeInsets.only(bottom: 32.h),
        children: [
          // ─── Profile Card ───
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
            child: const ProfileHeaderWidget(showChevron: false),
          ),

          // ─── AKUN ───
          SettingsSectionHeader(title: l10n.profileSectionAccount),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: FontAwesomeIcons.layerGroup,
                label: l10n.profileCategories,
                onTap: () => context.push(AppRouter.categories),
              ),
              SettingsTile(
                icon: FontAwesomeIcons.bell,
                label: l10n.profileNotifications,
                onTap: () => context.push(AppRouter.notificationSettings),
              ),
            ],
          ),

          // ─── PREFERENSI ───
          SettingsSectionHeader(title: l10n.profileSectionPreferences),
          SettingsGroup(
            children: [
              // Theme
              SettingsTile(
                icon: FontAwesomeIcons.paintbrush,
                label: l10n.profileThemeTitle,
                subtitle: _themeModeLabel(themeMode, l10n),
                onTap: () => _showThemePicker(themeMode),
              ),
              // Language
              SettingsTile(
                icon: FontAwesomeIcons.globe,
                label: l10n.profileLanguageTitle,
                subtitle: _localeLabel(locale, l10n),
                onTap: () => _showLanguagePicker(locale),
              ),
              // Entry point
              SettingsTile(
                icon: FontAwesomeIcons.bolt,
                label: l10n.profileEntryPointTitle,
                subtitle: _entryPointLabel(entryPoint, l10n),
                onTap: () => _showEntryPointPicker(entryPoint),
              ),
            ],
          ),

          // ─── DATA ───
          SettingsSectionHeader(title: l10n.profileSectionData),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: FontAwesomeIcons.fileExport,
                label: l10n.profileExportImport,
                subtitle: l10n.profileComingSoon,
                onTap: null,
                trailing: _comingSoonBadge(colors),
              ),
            ],
          ),

          // ─── LAINNYA ───
          SettingsSectionHeader(title: l10n.profileSectionOther),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: FontAwesomeIcons.circleInfo,
                label: l10n.profileAppVersion,
                trailing: Text(
                  _appVersion,
                  style: TextStyleConstants.label2.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              // Logout
              SettingsTile(
                icon: FontAwesomeIcons.rightFromBracket,
                label: l10n.profileLogout,
                iconColor: colors.error,
                trailing: const SizedBox.shrink(),
                onTap: () => _handleLogout(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────── Helpers ─────────

  Widget _comingSoonBadge(dynamic colors) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: (colors.warning as Color).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        context.l10n.profileComingSoon,
        style: TextStyleConstants.label3.copyWith(
          color: colors.warning as Color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode, dynamic l10n) {
    return switch (mode) {
      ThemeMode.system => l10n.profileThemeSystem as String,
      ThemeMode.light => l10n.profileThemeLight as String,
      ThemeMode.dark => l10n.profileThemeDark as String,
    };
  }

  String _localeLabel(Locale locale, dynamic l10n) {
    return locale.languageCode == 'en'
        ? l10n.profileLanguageEnglish as String
        : l10n.profileLanguageIndonesian as String;
  }

  String _entryPointLabel(TransactionEntryPoint ep, dynamic l10n) {
    return switch (ep) {
      TransactionEntryPoint.manual => l10n.profileEntryManual as String,
      TransactionEntryPoint.voice => l10n.profileEntryVoice as String,
      TransactionEntryPoint.scan => l10n.profileEntryScan as String,
    };
  }

  // ───────── Pickers ─────────

  void _showThemePicker(ThemeMode current) {
    final l10n = context.l10n;
    final colors = context.colors;

    showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => _OptionSheet<ThemeMode>(
        title: l10n.profileThemeTitle,
        options: ThemeMode.values,
        selected: current,
        labelBuilder: (mode) => _themeModeLabel(mode, l10n),
        iconBuilder: (mode) => switch (mode) {
          ThemeMode.system => FontAwesomeIcons.circleHalfStroke,
          ThemeMode.light => FontAwesomeIcons.sun,
          ThemeMode.dark => FontAwesomeIcons.moon,
        },
      ),
    ).then((picked) {
      if (picked != null) {
        ref.read(themeControllerProvider.notifier).setTheme(picked);
      }
    });
  }

  void _showLanguagePicker(Locale current) {
    final l10n = context.l10n;
    final colors = context.colors;

    final options = [const Locale('id'), const Locale('en')];

    showModalBottomSheet<Locale>(
      context: context,
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => _OptionSheet<Locale>(
        title: l10n.profileLanguageTitle,
        options: options,
        selected: current,
        labelBuilder: (loc) => loc.languageCode == 'en'
            ? l10n.profileLanguageEnglish
            : l10n.profileLanguageIndonesian,
        iconBuilder: (loc) => loc.languageCode == 'en'
            ? FontAwesomeIcons.flagUsa
            : FontAwesomeIcons.flag,
      ),
    ).then((picked) {
      if (picked != null) {
        ref.read(localeControllerProvider.notifier).setLanguage(picked);
      }
    });
  }

  void _showEntryPointPicker(TransactionEntryPoint current) {
    final l10n = context.l10n;
    final colors = context.colors;

    showModalBottomSheet<TransactionEntryPoint>(
      context: context,
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => _OptionSheet<TransactionEntryPoint>(
        title: l10n.profileEntryPointTitle,
        options: TransactionEntryPoint.values,
        selected: current,
        labelBuilder: (ep) => _entryPointLabel(ep, l10n),
        iconBuilder: (ep) => switch (ep) {
          TransactionEntryPoint.manual => FontAwesomeIcons.penToSquare,
          TransactionEntryPoint.voice => FontAwesomeIcons.microphone,
          TransactionEntryPoint.scan => FontAwesomeIcons.camera,
        },
      ),
    ).then((picked) {
      if (picked != null) {
        ref.read(entryPointProvider.notifier).setEntryPoint(picked);
      }
    });
  }

  // ───────── Logout ─────────

  Future<void> _handleLogout(BuildContext context) async {
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
      var res = await ref.read(authControllerProvider.notifier).signOut();
      if (!mounted) return;
      if (res == true) {
        context.go(AppRouter.login);
      }
    } finally {
      if (context.mounted) {
        context.closeOverlay();
      }
    }
  }
}

// ───────────────── Generic Option Bottom Sheet ─────────────────

/// Bottom sheet generik untuk memilih satu opsi dari list.
///
/// Digunakan untuk theme picker, language picker, dan entry point picker.
class _OptionSheet<T> extends StatelessWidget {
  const _OptionSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.labelBuilder,
    required this.iconBuilder,
  });

  final String title;
  final List<T> options;
  final T selected;
  final String Function(T) labelBuilder;
  final IconData Function(T) iconBuilder;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),

          // Title
          Text(
            title,
            style: TextStyleConstants.h7.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),

          // Options
          ...options.map((option) {
            final isSelected = option == selected;
            return InkWell(
              onTap: () => Navigator.pop(context, option),
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                margin: EdgeInsets.only(bottom: 4.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
                  border: isSelected
                      ? Border.all(color: colors.primary.withValues(alpha: 0.5))
                      : null,
                ),
                child: Row(
                  children: [
                    FaIcon(
                      iconBuilder(option),
                      size: 16.w,
                      color: isSelected ? colors.primary : colors.textSecondary,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        labelBuilder(option),
                        style: TextStyleConstants.b2.copyWith(
                          color: isSelected
                              ? colors.primary
                              : colors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (isSelected)
                      FaIcon(
                        FontAwesomeIcons.circleCheck,
                        size: 18.w,
                        color: colors.primary,
                      ),
                  ],
                ),
              ),
            );
          }),

          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }
}
