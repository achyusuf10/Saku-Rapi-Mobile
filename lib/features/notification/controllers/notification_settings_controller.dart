import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/notification/datasource/notification_settings_local_datasource.dart';
import 'package:app_saku_rapi/features/notification/datasource/notification_settings_remote_datasource.dart';
import 'package:app_saku_rapi/features/notification/models/notification_settings_model.dart';
import 'package:app_saku_rapi/features/notification/repositories/notification_settings_repository.dart';
import 'package:app_saku_rapi/global/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────

/// Provider untuk [NotificationSettingsRepository].
final notificationSettingsRepositoryProvider =
    Provider<NotificationSettingsRepository>((ref) {
      return NotificationSettingsRepository(
        remoteDataSource: NotificationSettingsRemoteDataSource(
          client: Supabase.instance.client,
        ),
        localDataSource: NotificationSettingsLocalDataSource(),
      );
    });

/// Provider utama untuk [NotificationSettingsController].
final notificationSettingsControllerProvider =
    AsyncNotifierProvider<
      NotificationSettingsController,
      NotificationSettingsModel
    >(() {
      return NotificationSettingsController();
    });

// ─────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────

/// Riverpod [AsyncNotifier] untuk mengelola notification settings.
///
/// Bertanggung jawab:
/// 1. Load settings dari Supabase / Hive cache.
/// 2. Simpan perubahan ke Supabase dan cache.
/// 3. Re-schedule / cancel notifikasi berdasarkan pengaturan baru.
class NotificationSettingsController
    extends AsyncNotifier<NotificationSettingsModel> {
  late final NotificationSettingsRepository _repository;

  static const String _tag = 'NotificationSettings';

  @override
  Future<NotificationSettingsModel> build() async {
    _repository = ref.watch(notificationSettingsRepositoryProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    final result = await _repository.getSettings(userId: userId);

    if (result.isSuccess()) {
      return result.dataSuccess()!;
    }

    // Fallback ke default jika Supabase tidak tersedia.
    AppLogger.call(
      '[$_tag] Using default settings as fallback',
      colorLog: ColorLog.yellow,
    );
    return NotificationSettingsModel.defaults(userId: userId);
  }

  // ── Save Settings ──────────────────────────────────────────

  /// Simpan [updated] settings, perbarui cache, dan reschedule notifikasi.
  ///
  /// Return `true` jika berhasil disimpan ke Supabase.
  Future<bool> saveSettings(NotificationSettingsModel updated) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    AppLogger.call('[$_tag] Saving settings…', colorLog: ColorLog.blue);

    final result = await _repository.updateSettings(
      userId: userId,
      settings: updated,
    );

    if (result.isSuccess()) {
      final saved = result.dataSuccess()!;
      state = AsyncData(saved);
      await _applyNotificationSchedules(saved);
      return true;
    }

    AppLogger.logError(
      '[$_tag] Save failed: ${result.dataError()?.$1}',
      stackTrace: result.dataError()?.$3,
    );
    return false;
  }

  // ── Getters ────────────────────────────────────────────────

  /// Kembalikan model saat ini, atau `null` jika belum loaded.
  NotificationSettingsModel? get current => state.value;

  /// Shortcut: apakah budget alert aktif.
  bool get isBudgetAlertEnabled => state.value?.budgetAlertEnabled ?? true;

  /// Shortcut: apakah debt reminder aktif.
  bool get isDebtReminderEnabled => state.value?.debtReminderEnabled ?? true;

  /// Shortcut: berapa hari sebelum jatuh tempo.
  int get debtReminderDaysBefore => state.value?.debtReminderDaysBefore ?? 3;

  // ── Internal ───────────────────────────────────────────────

  /// Terapkan jadwal notifikasi sesuai [settings] yang baru disimpan.
  Future<void> _applyNotificationSchedules(
    NotificationSettingsModel settings,
  ) async {
    final notifService = NotificationService();

    // Daily reminder
    if (settings.reminderEnabled) {
      // Judul dan body tidak bisa diambil dari l10n di sini (no context),
      // sehingga teks hardcode di setelan; teks sesungguhnya di-set dari UI
      // atau dikirim melalui parameter.
      await notifService.scheduleDailyReminder(
        time: settings.reminderTime,
        title: 'SakuRapi',
        body: 'Jangan lupa catat pengeluaranmu hari ini! 📒',
      );
    } else {
      await notifService.cancelDailyReminder();
    }

    AppLogger.call(
      '[$_tag] Notification schedules applied '
      '(reminder=${settings.reminderEnabled}, '
      'budget=${settings.budgetAlertEnabled}, '
      'debt=${settings.debtReminderEnabled})',
      colorLog: ColorLog.green,
    );
  }

  // ── Request Permission ─────────────────────────────────────

  /// Minta izin notifikasi dari OS.
  Future<bool> requestPermission() async {
    return NotificationService().requestPermission();
  }

  // ── Quick Toggles (used directly from UI without full save) ──

  /// Toggle reminder lokal (state only, belum disimpan ke Supabase).
  void toggleReminder({required bool enabled}) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(reminderEnabled: enabled));
  }

  /// Ubah jam reminder lokal (state only, belum disimpan ke Supabase).
  void setReminderTime(TimeOfDay time) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(reminderTime: time));
  }

  /// Toggle budget alert lokal.
  void toggleBudgetAlert({required bool enabled}) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(budgetAlertEnabled: enabled));
  }

  /// Toggle debt reminder lokal.
  void toggleDebtReminder({required bool enabled}) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(debtReminderEnabled: enabled));
  }

  /// Ubah nilai daysBefore lokal.
  void setDebtReminderDaysBefore(int days) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(debtReminderDaysBefore: days));
  }
}
