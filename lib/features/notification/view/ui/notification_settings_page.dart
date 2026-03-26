import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/notification/controllers/notification_controller.dart';
import 'package:app_saku_rapi/features/settings/view/widgets/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

/// Halaman pengaturan notifikasi.
///
/// Menampilkan toggle untuk:
/// 1. Pengingat harian (+ time picker)
/// 2. Alert anggaran (80% / 100%)
/// 3. Pengingat piutang (+ days picker)
///
/// Granular rebuild: setiap toggle hanya rebuild widget yang terkait
/// menggunakan computed providers yang di‐select.
class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  @override
  void initState() {
    super.initState();
    // Load settings dan cek permission.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(notificationControllerProvider.notifier);
      controller.loadSettings();
      controller.checkPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final status = ref.watch(
      notificationControllerProvider.select((s) => s.status),
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.notifTitle,
          style: TextStyleConstants.h6.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: status == NotificationSettingsStatus.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.only(bottom: 32.h),
              children: [
                // ─── Permission Banner ───
                const _PermissionBanner(),

                // ─── PENGINGAT HARIAN ───
                SettingsSectionHeader(title: l10n.notifReminderTitle),
                SettingsGroup(
                  children: [
                    const _ReminderToggleTile(),
                    const _ReminderTimeTile(),
                  ],
                ),

                // ─── ALERT ANGGARAN ───
                SettingsSectionHeader(title: l10n.notifBudgetTitle),
                SettingsGroup(children: [const _BudgetAlertToggleTile()]),

                // ─── PENGINGAT PIUTANG ───
                SettingsSectionHeader(title: l10n.notifDebtTitle),
                SettingsGroup(
                  children: [
                    const _DebtReminderToggleTile(),
                    const _DebtDaysBeforeTile(),
                  ],
                ),

                SizedBox(height: 24.h),

                // ─── SAVE BUTTON ───
                const _SaveButton(),
              ],
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// GRANULAR WIDGETS — Setiap widget hanya watch provider yang relevan
// ═══════════════════════════════════════════════════════════

/// Banner peringatan jika permission belum granted.
class _PermissionBanner extends ConsumerWidget {
  const _PermissionBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionStatus = ref.watch(notifPermissionStatusProvider);
    if (permissionStatus == null || permissionStatus.isGranted) {
      return const SizedBox.shrink();
    }

    final colors = context.colors;
    final l10n = context.l10n;

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.triangleExclamation,
            size: 18.w,
            color: colors.warning,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.notifTitle,
                  style: TextStyleConstants.b2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  permissionStatus.isPermanentlyDenied
                      ? 'Izin notifikasi ditolak permanen. Aktifkan di Pengaturan.'
                      : 'Izin notifikasi diperlukan untuk fitur ini.',
                  style: TextStyleConstants.label3.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          TextButton(
            onPressed: () async {
              final controller = ref.read(
                notificationControllerProvider.notifier,
              );
              if (permissionStatus.isPermanentlyDenied) {
                await openAppSettings();
              } else {
                await controller.requestPermission();
              }
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              permissionStatus.isPermanentlyDenied ? 'Pengaturan' : 'Izinkan',
              style: TextStyleConstants.label2.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Toggle tile untuk daily reminder.
class _ReminderToggleTile extends ConsumerWidget {
  const _ReminderToggleTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(isReminderEnabledProvider);
    final l10n = context.l10n;

    return SettingsTile(
      icon: FontAwesomeIcons.clockRotateLeft,
      label: l10n.notifReminderSubtitle,
      trailing: Switch.adaptive(
        value: enabled,
        onChanged: (val) {
          ref.read(notificationControllerProvider.notifier).toggleReminder(val);
        },
      ),
    );
  }
}

/// Time picker tile untuk reminder time.
class _ReminderTimeTile extends ConsumerWidget {
  const _ReminderTimeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderEnabled = ref.watch(isReminderEnabledProvider);
    final time = ref.watch(reminderTimeProvider);
    final l10n = context.l10n;
    final colors = context.colors;

    final displayTime = time != null
        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
        : '--:--';

    return SettingsTile(
      icon: FontAwesomeIcons.clock,
      label: l10n.notifReminderTime,
      subtitle: displayTime,
      onTap: reminderEnabled
          ? () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time ?? const TimeOfDay(hour: 20, minute: 0),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.fromSeed(
                        seedColor: colors.primary,
                        brightness: Theme.of(context).brightness,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                ref
                    .read(notificationControllerProvider.notifier)
                    .setReminderTime(picked);
              }
            }
          : null,
    );
  }
}

/// Toggle tile untuk budget alert.
class _BudgetAlertToggleTile extends ConsumerWidget {
  const _BudgetAlertToggleTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(isBudgetAlertEnabledProvider);
    final l10n = context.l10n;

    return SettingsTile(
      icon: FontAwesomeIcons.chartPie,
      label: l10n.notifBudgetSubtitle,
      trailing: Switch.adaptive(
        value: enabled,
        onChanged: (val) {
          ref
              .read(notificationControllerProvider.notifier)
              .toggleBudgetAlert(val);
        },
      ),
    );
  }
}

/// Toggle tile untuk debt reminder.
class _DebtReminderToggleTile extends ConsumerWidget {
  const _DebtReminderToggleTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(isDebtReminderEnabledProvider);
    final l10n = context.l10n;

    return SettingsTile(
      icon: FontAwesomeIcons.handHoldingDollar,
      label: l10n.notifDebtSubtitle,
      trailing: Switch.adaptive(
        value: enabled,
        onChanged: (val) {
          ref
              .read(notificationControllerProvider.notifier)
              .toggleDebtReminder(val);
        },
      ),
    );
  }
}

/// Tile untuk memilih berapa hari sebelum jatuh tempo.
class _DebtDaysBeforeTile extends ConsumerWidget {
  const _DebtDaysBeforeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtEnabled = ref.watch(isDebtReminderEnabledProvider);
    final days = ref.watch(debtReminderDaysProvider);
    final l10n = context.l10n;
    final colors = context.colors;

    return SettingsTile(
      icon: FontAwesomeIcons.calendarDay,
      label: l10n.notifDebtDaysBefore(days),
      onTap: debtEnabled
          ? () {
              _showDaysPicker(context, ref, days, colors);
            }
          : null,
    );
  }

  void _showDaysPicker(
    BuildContext context,
    WidgetRef ref,
    int current,
    dynamic colors,
  ) {
    final options = [1, 2, 3, 5, 7];

    showModalBottomSheet<int>(
      context: context,
      backgroundColor: colors.surface as Color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: (colors.border as Color),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              context.l10n.notifDebtTitle,
              style: TextStyleConstants.h7.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            ...options.map((days) {
              final isSelected = days == current;
              return InkWell(
                onTap: () => Navigator.pop(context, days),
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  margin: EdgeInsets.only(bottom: 4.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (colors.primary as Color).withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12.r),
                    border: isSelected
                        ? Border.all(
                            color: (colors.primary as Color).withValues(
                              alpha: 0.5,
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.calendarDay,
                        size: 16.w,
                        color: isSelected
                            ? colors.primary as Color
                            : colors.textSecondary as Color,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          context.l10n.notifDebtDaysBefore(days),
                          style: TextStyleConstants.b2.copyWith(
                            color: isSelected
                                ? colors.primary as Color
                                : colors.textPrimary as Color,
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
                          color: colors.primary as Color,
                        ),
                    ],
                  ),
                ),
              );
            }),
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
      ),
    ).then((picked) {
      if (picked != null) {
        ref
            .read(notificationControllerProvider.notifier)
            .setDebtReminderDaysBefore(picked);
      }
    });
  }
}

/// Tombol simpan settings.
class _SaveButton extends ConsumerWidget {
  const _SaveButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaving = ref.watch(
      notificationControllerProvider.select((s) => s.isSaving),
    );
    final colors = context.colors;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: FilledButton(
        onPressed: isSaving ? null : () => _handleSave(context, ref),
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          minimumSize: Size(double.infinity, 48.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: isSaving
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.surface,
                ),
              )
            : Text(
                l10n.notifSave,
                style: TextStyleConstants.b2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.surface,
                ),
              ),
      ),
    );
  }

  Future<void> _handleSave(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final controller = ref.read(notificationControllerProvider.notifier);

    // Cek permission sebelum save jika reminder enabled.
    final state = ref.read(notificationControllerProvider);
    if (state.settings?.reminderEnabled == true) {
      final permStatus = state.permissionStatus;
      if (permStatus == null || !permStatus.isGranted) {
        final result = await controller.requestPermission();
        if (!result.isGranted) {
          if (!context.mounted) return;
          context.showAppAlert(
            'Izin notifikasi diperlukan untuk mengaktifkan pengingat.',
            alertType: AlertTypeEnum.warning,
          );
          return;
        }
      }
    }

    final success = await controller.saveSettings(
      reminderTitle: l10n.notifReminderTitle,
      reminderBody: l10n.notifReminderSubtitle,
    );

    if (!context.mounted) return;

    context.showAppAlert(
      success ? l10n.notifSaveSuccess : l10n.notifSaveError,
      alertType: success ? AlertTypeEnum.success : AlertTypeEnum.error,
    );
  }
}
