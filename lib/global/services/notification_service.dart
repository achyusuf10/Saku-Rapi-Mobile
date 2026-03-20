import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Singleton service wrapper untuk [FlutterLocalNotificationsPlugin].
///
/// Mengelola 3 channel notifikasi terpisah:
/// - **Channel 1** (`saku_rapi_budget_alert`)  — Budget Alert 80% & 100%
/// - **Channel 2** (`saku_rapi_reminder`)      — Reminder harian catat transaksi
/// - **Channel 3** (`saku_rapi_debt_reminder`) — Piutang jatuh tempo
class NotificationService {
  // ── Channel IDs ────────────────────────────────────────────
  static const int _budgetAlertChannelId = 1;
  static const int _debtReminderChannelId = 3;

  static const String _budgetAlertChannelKey = 'saku_rapi_budget_alert';
  static const String _reminderChannelKey = 'saku_rapi_reminder';
  static const String _debtChannelKey = 'saku_rapi_debt_reminder';

  /// ID tetap untuk daily reminder (cukup satu karena diganti setiap reschedule).
  static const int _dailyReminderId = 100001;

  static const String _tag = 'Notification';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── Singleton ──────────────────────────────────────────────
  static final NotificationService _instance = NotificationService._();

  /// Akses singleton global.
  factory NotificationService() => _instance;
  NotificationService._();

  // ── Initialization ─────────────────────────────────────────

  /// Inisialisasi plugin notification. Wajib dipanggil di `main()`.
  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    AppLogger.call('[$_tag] Plugin initialized', colorLog: ColorLog.green);
  }

  /// Minta izin notifikasi (Android 13+ / iOS).
  ///
  /// Kembalikan `true` jika izin diberikan.
  Future<bool> requestPermission() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    bool granted = false;
    if (androidPlugin != null) {
      granted = await androidPlugin.requestNotificationsPermission() ?? false;
    } else if (iosPlugin != null) {
      granted =
          await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    AppLogger.call(
      '[$_tag] Permission granted: $granted',
      colorLog: granted ? ColorLog.green : ColorLog.red,
    );
    return granted;
  }

  // ── Budget Alert ───────────────────────────────────────────

  /// Tampilkan notifikasi budget alert (80% atau 100%) secara langsung.
  ///
  /// [budgetId] digunakan sebagai basis ID unik notifikasi.
  /// [percentage] harus bernilai 80 atau 100.
  Future<void> showBudgetAlert({
    required String budgetId,
    required String categoryName,
    required double percentage,
    required String title,
    required String body,
  }) async {
    final int id =
        (budgetId.hashCode.abs() % 90000) +
        (percentage >= 100 ? 10000 : 0) +
        _budgetAlertChannelId * 100000;

    final details = _buildDetails(
      channelId: _budgetAlertChannelKey,
      channelName: 'Budget Alert',
      channelDescription: 'Notifikasi batas anggaran 80% dan 100%',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _plugin.show(id, title, body, details);

    AppLogger.call(
      '[$_tag] Budget alert shown: $categoryName '
      '${percentage.toStringAsFixed(0)}%',
      colorLog: ColorLog.blue,
    );
  }

  // ── Daily Reminder ─────────────────────────────────────────

  /// Jadwalkan pengingat harian berulang setiap hari pada [time].
  ///
  /// Jika sudah ada reminder terjadwal sebelumnya, otomatis dibatalkan
  /// terlebih dahulu sebelum menjadwalkan yang baru.
  Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    await cancelDailyReminder();

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Jika waktunya sudah lewat hari ini, jadwalkan untuk besok.
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final details = _buildDetails(
      channelId: _reminderChannelKey,
      channelName: 'Reminder Harian',
      channelDescription: 'Pengingat harian untuk mencatat transaksi',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    await _plugin.zonedSchedule(
      _dailyReminderId,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    AppLogger.call(
      '[$_tag] Daily reminder scheduled at '
      '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
      colorLog: ColorLog.green,
    );
  }

  /// Batalkan pengingat harian.
  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_dailyReminderId);
    AppLogger.call('[$_tag] Daily reminder cancelled', colorLog: ColorLog.blue);
  }

  // ── Debt Reminder ──────────────────────────────────────────

  /// Jadwalkan notifikasi piutang jatuh tempo [daysBefore] hari sebelum [dueDate].
  ///
  /// Jika tanggal pengingat sudah lewat, notifikasi tidak dijadwalkan.
  Future<void> scheduleDebtReminder({
    required String transactionId,
    required String personName,
    required double amount,
    required DateTime dueDate,
    required int daysBefore,
    required String title,
    required String body,
  }) async {
    final reminderDate = dueDate.subtract(Duration(days: daysBefore));

    if (reminderDate.isBefore(DateTime.now())) {
      AppLogger.call(
        '[$_tag] Debt reminder skipped — date in the past: $reminderDate',
        colorLog: ColorLog.yellow,
      );
      return;
    }

    final int id =
        (transactionId.hashCode.abs() % 90000) +
        _debtReminderChannelId * 100000;

    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      reminderDate,
      tz.local,
    );

    final details = _buildDetails(
      channelId: _debtChannelKey,
      channelName: 'Pengingat Piutang',
      channelDescription: 'Notifikasi H-N sebelum jatuh tempo piutang',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    AppLogger.call(
      '[$_tag] Debt reminder scheduled for "$personName" on $reminderDate',
      colorLog: ColorLog.green,
    );
  }

  /// Batalkan notifikasi piutang untuk [transactionId].
  Future<void> cancelDebtReminder(String transactionId) async {
    final int id =
        (transactionId.hashCode.abs() % 90000) +
        _debtReminderChannelId * 100000;

    await _plugin.cancel(id);

    AppLogger.call(
      '[$_tag] Debt reminder cancelled for: $transactionId',
      colorLog: ColorLog.blue,
    );
  }

  // ── Internal Helpers ───────────────────────────────────────

  NotificationDetails _buildDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
    required Importance importance,
    required Priority priority,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: importance,
        priority: priority,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
