import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/notification/controllers/notification_settings_controller.dart';
import 'package:app_saku_rapi/features/notification/models/notification_settings_model.dart';
import 'package:app_saku_rapi/features/notification/view/widgets/notification_toggle_tile.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Layar pengaturan notifikasi.
///
/// Menampilkan 3 toggle:
/// 1. Reminder harian + pilihan jam
/// 2. Budget alert (80% / 100%)
/// 3. Pengingat piutang + input hari sebelum jatuh tempo
///
/// Tombol "Simpan" menyimpan ke Supabase dan me-reschedule notifikasi.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsControllerProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notifTitle), centerTitle: true),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            err.toString(),
            style: TextStyleConstants.b2.copyWith(color: context.colors.error),
          ),
        ),
        data: (settings) => _SettingsBody(settings: settings),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────

class _SettingsBody extends ConsumerStatefulWidget {
  const _SettingsBody({required this.settings});

  final NotificationSettingsModel settings;

  @override
  ConsumerState<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends ConsumerState<_SettingsBody> {
  late final TextEditingController _daysCtrl;

  @override
  void initState() {
    super.initState();
    _daysCtrl = TextEditingController(
      text: widget.settings.debtReminderDaysBefore.toString(),
    );
    _daysCtrl.addListener(_onDaysChanged);
  }

  @override
  void dispose() {
    _daysCtrl.removeListener(_onDaysChanged);
    _daysCtrl.dispose();
    super.dispose();
  }

  void _onDaysChanged() {
    final days = int.tryParse(_daysCtrl.text.trim());
    if (days != null && days > 0) {
      ref
          .read(notificationSettingsControllerProvider.notifier)
          .setDebtReminderDaysBefore(days);
    }
  }

  // ── Save ─────────────────────────────────────────────────

  Future<void> _onSave() async {
    final current = ref.read(notificationSettingsControllerProvider).value;
    if (current == null) return;

    context.showLoadingOverlay();
    try {
      final success = await ref
          .read(notificationSettingsControllerProvider.notifier)
          .saveSettings(current);

      if (!mounted) return;
      context.closeOverlay();

      if (success) {
        context.showAppAlert(context.l10n.notifSaveSuccess);
      } else {
        context.showAppAlert(
          context.l10n.notifSaveError,
          alertType: AlertTypeEnum.error,
        );
      }
    } catch (_) {
      if (!mounted) return;
      context.closeOverlay();
      context.showAppAlert(
        context.l10n.notifSaveError,
        alertType: AlertTypeEnum.error,
      );
    }
  }

  // ── Time Picker ───────────────────────────────────────────

  Future<void> _pickTime() async {
    final current = ref.read(notificationSettingsControllerProvider).value;
    if (current == null) return;

    final picked = await showTimePicker(
      context: context,
      initialTime: current.reminderTime,
    );
    if (picked != null) {
      ref
          .read(notificationSettingsControllerProvider.notifier)
          .setReminderTime(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(notificationSettingsControllerProvider);
    final settings = settingsAsync.value ?? widget.settings;
    final l10n = context.l10n;
    final colors = context.colors;

    final timeLabel =
        '${settings.reminderTime.hour.toString().padLeft(2, '0')}'
        ':${settings.reminderTime.minute.toString().padLeft(2, '0')}';

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      children: [
        // ── 1. Daily Reminder ────────────────────────────────
        NotificationToggleTile(
          icon: FontAwesomeIcons.bell,
          title: l10n.notifReminderTitle,
          subtitle: l10n.notifReminderSubtitle,
          value: settings.reminderEnabled,
          onChanged: (val) => ref
              .read(notificationSettingsControllerProvider.notifier)
              .toggleReminder(enabled: val),
          trailing: GestureDetector(
            onTap: _pickTime,
            child: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.clock,
                  size: 14.r,
                  color: colors.primary,
                ),
                SizedBox(width: 8.w),
                Text(
                  '${l10n.notifReminderTime}: $timeLabel',
                  style: TextStyleConstants.b2.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4.w),
                FaIcon(
                  FontAwesomeIcons.chevronRight,
                  size: 12.r,
                  color: colors.primary,
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 12.h),

        // ── 2. Budget Alert ──────────────────────────────────
        NotificationToggleTile(
          icon: FontAwesomeIcons.chartPie,
          title: l10n.notifBudgetTitle,
          subtitle: l10n.notifBudgetSubtitle,
          value: settings.budgetAlertEnabled,
          onChanged: (val) => ref
              .read(notificationSettingsControllerProvider.notifier)
              .toggleBudgetAlert(enabled: val),
        ),

        SizedBox(height: 12.h),

        // ── 3. Debt Reminder ─────────────────────────────────
        NotificationToggleTile(
          icon: FontAwesomeIcons.handshake,
          title: l10n.notifDebtTitle,
          subtitle: l10n.notifDebtSubtitle,
          value: settings.debtReminderEnabled,
          onChanged: (val) => ref
              .read(notificationSettingsControllerProvider.notifier)
              .toggleDebtReminder(enabled: val),
          trailing: Row(
            children: [
              Text(
                l10n.notifDebtDaysBefore(settings.debtReminderDaysBefore),
                style: TextStyleConstants.b2.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              // Stepper -
              _StepperButton(
                icon: FontAwesomeIcons.minus,
                onTap: settings.debtReminderDaysBefore > 1
                    ? () => ref
                          .read(notificationSettingsControllerProvider.notifier)
                          .setDebtReminderDaysBefore(
                            settings.debtReminderDaysBefore - 1,
                          )
                    : null,
                colors: colors,
              ),
              SizedBox(width: 8.w),
              Text(
                '${settings.debtReminderDaysBefore}',
                style: TextStyleConstants.b1.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(width: 8.w),
              // Stepper +
              _StepperButton(
                icon: FontAwesomeIcons.plus,
                onTap: settings.debtReminderDaysBefore < 30
                    ? () => ref
                          .read(notificationSettingsControllerProvider.notifier)
                          .setDebtReminderDaysBefore(
                            settings.debtReminderDaysBefore + 1,
                          )
                    : null,
                colors: colors,
              ),
            ],
          ),
        ),

        SizedBox(height: 32.h),

        // ── Save Button ──────────────────────────────────────
        SakuButton(text: l10n.notifSave, onPressed: _onSave),

        SizedBox(height: 24.h),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stepper Button
// ─────────────────────────────────────────────────────────────

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.colors,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28.r,
        height: 28.r,
        decoration: BoxDecoration(
          color: isEnabled
              ? (colors.primary as Color).withValues(alpha: 0.12)
              : (colors.border as Color).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Center(
          child: FaIcon(
            icon,
            size: 12.r,
            color: isEnabled
                ? colors.primary as Color
                : colors.textSecondary as Color,
          ),
        ),
      ),
    );
  }
}
