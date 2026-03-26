import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/notification/datasource/notification_local_data_source.dart';
import 'package:app_saku_rapi/features/notification/datasource/notification_remote_data_source.dart';
import 'package:app_saku_rapi/features/notification/models/notification_settings_model.dart';
import 'package:app_saku_rapi/features/notification/services/notification_service.dart';

/// Repository untuk fitur notification.
///
/// Mengorkestrasikan remote + local data source + NotificationService
/// untuk sinkronisasi settings dan penjadwalan notifikasi.
class NotificationRepository {
  NotificationRepository({
    NotificationRemoteDataSource? remoteDataSource,
    NotificationLocalDataSource? localDataSource,
    NotificationService? notificationService,
  }) : _remote = remoteDataSource ?? NotificationRemoteDataSource(),
       _local = localDataSource ?? NotificationLocalDataSource(),
       _notifService = notificationService ?? NotificationService.instance;

  final NotificationRemoteDataSource _remote;
  final NotificationLocalDataSource _local;
  final NotificationService _notifService;

  static const _tag = '[Notification] [NotificationRepository]';

  // ───────────────── READ ─────────────────

  /// Ambil notification settings. Fetch remote lalu cache; fallback ke cache.
  Future<DataState<NotificationSettingsModel>> getSettings() async {
    final result = await _remote.getSettings();

    if (result.isSuccess()) {
      final settings = result.dataSuccess()!;
      _local.cacheSettings(settings);
      return result;
    }

    // Offline fallback
    final cached = _local.getCachedSettings();
    if (cached != null) {
      AppLogger.call('$_tag getSettings: serving from cache');
      return DataState.success(data: cached);
    }

    return result;
  }

  // ───────────────── UPDATE ─────────────────

  /// Simpan settings ke remote lalu cache, dan sinkronkan jadwal notifikasi.
  Future<DataState<NotificationSettingsModel>> saveSettings(
    NotificationSettingsModel settings, {
    required String reminderTitle,
    required String reminderBody,
  }) async {
    final result = await _remote.updateSettings(settings);

    if (result.isSuccess()) {
      final saved = result.dataSuccess()!;
      _local.cacheSettings(saved);

      // Sinkronkan scheduled notifications.
      await _syncSchedule(
        saved,
        reminderTitle: reminderTitle,
        reminderBody: reminderBody,
      );

      return result;
    }

    return result;
  }

  // ───────────────── Budget Alert ─────────────────

  /// Kirim notifikasi budget alert dan tandai flag di DB.
  Future<void> sendBudgetAlert({
    required String budgetId,
    required String categoryName,
    required bool is80,
    required String title,
    required String body,
  }) async {
    AppLogger.call('$_tag sendBudgetAlert: $budgetId (is80=$is80)');

    final id = NotificationService.budgetAlertId(budgetId, is100: !is80);

    await _notifService.showBudgetAlert(id: id, title: title, body: body);

    // Tandai flag di DB agar tidak dikirim ulang.
    await _remote.markBudgetNotificationSent(budgetId: budgetId, is80: is80);
  }

  // ───────────────── Sync Schedule ─────────────────

  /// Sinkronkan jadwal notifikasi berdasarkan settings terbaru.
  Future<void> _syncSchedule(
    NotificationSettingsModel settings, {
    required String reminderTitle,
    required String reminderBody,
  }) async {
    // Daily reminder
    if (settings.reminderEnabled && settings.reminderTime != null) {
      await _notifService.scheduleDailyReminder(
        time: settings.reminderTime!,
        title: reminderTitle,
        body: reminderBody,
      );
    } else {
      await _notifService.cancelDailyReminder();
    }
  }

  /// Re‐sync jadwal dari cached settings (dipanggil saat boot/WorkManager).
  Future<void> reSyncFromCache({
    required String reminderTitle,
    required String reminderBody,
  }) async {
    final cached = _local.getCachedSettings();
    if (cached == null) return;

    await _syncSchedule(
      cached,
      reminderTitle: reminderTitle,
      reminderBody: reminderBody,
    );
  }

  /// Cek dan kirim budget alert untuk budget yang melewati threshold.
  ///
  /// Dipanggil setelah budget list di-refresh.
  /// [budgets] harus berisi budget aktif yang sudah di-fetch.
  Future<void> checkAndSendBudgetAlerts({
    required List<BudgetAlertData> budgets,
    required bool budgetAlertEnabled,
    required String Function(String categoryName) alert80Body,
    required String Function(String categoryName) alert100Body,
    required String alertTitle,
  }) async {
    if (!budgetAlertEnabled) return;

    final hasPermission = await _notifService.isPermissionGranted();
    if (!hasPermission) return;

    for (final budget in budgets) {
      // 100% check (check first — jika 100% maka skip 80%)
      if (budget.isOverBudget && !budget.notificationSent100) {
        await sendBudgetAlert(
          budgetId: budget.id,
          categoryName: budget.categoryName,
          is80: false,
          title: alertTitle,
          body: alert100Body(budget.categoryName),
        );
      }
      // 80% check
      else if (budget.isNearLimit &&
          !budget.isOverBudget &&
          !budget.notificationSent80) {
        await sendBudgetAlert(
          budgetId: budget.id,
          categoryName: budget.categoryName,
          is80: true,
          title: alertTitle,
          body: alert80Body(budget.categoryName),
        );
      }
    }
  }

  /// Clear cache.
  void clearCache() {
    _local.clearCache();
  }
}

/// Data minimal budget yang dibutuhkan untuk alert check.
class BudgetAlertData {
  const BudgetAlertData({
    required this.id,
    required this.categoryName,
    required this.isNearLimit,
    required this.isOverBudget,
    required this.notificationSent80,
    required this.notificationSent100,
  });

  final String id;
  final String categoryName;
  final bool isNearLimit;
  final bool isOverBudget;
  final bool notificationSent80;
  final bool notificationSent100;
}
