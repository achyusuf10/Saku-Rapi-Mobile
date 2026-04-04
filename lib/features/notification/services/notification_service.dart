import 'dart:io';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

/// Abstraksi untuk flutter_local_notifications.
///
/// Singleton — inisialisasi sekali di main(), lalu digunakan di mana saja.
/// Semua operasi schedule menggunakan TZDateTime (Asia/Jakarta).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _tag = '[Notification] [NotificationService]';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── Notification IDs ───
  /// ID tetap untuk daily reminder — cancel/re‐schedule pakai ID ini.
  static const int dailyReminderId = 1001;

  /// Base ID untuk budget alert. Gunakan hash dari budgetId agar unik.
  static const int budgetAlertBaseId = 2000;

  // ─── Channel ───
  static const _reminderChannel = AndroidNotificationChannel(
    'saku_rapi_reminder',
    'Pengingat Harian',
    description: 'Pengingat untuk mencatat transaksi harian',
    importance: Importance.high,
  );

  static const _budgetChannel = AndroidNotificationChannel(
    'saku_rapi_budget',
    'Alert Anggaran',
    description: 'Notifikasi saat anggaran mendekati atau melebihi batas',
    importance: Importance.high,
  );

  // ───────────────── Init ─────────────────

  /// Inisialisasi plugin. Panggil sekali di main().
  Future<void> init() async {
    if (_initialized) return;

    AppLogger.call('$_tag init');

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(settings);

    // Buat notification channels di Android.
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          _reminderChannel.id,
          _reminderChannel.name,
          description: _reminderChannel.description,
          importance: _reminderChannel.importance,
        ),
      );
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          _budgetChannel.id,
          _budgetChannel.name,
          description: _budgetChannel.description,
          importance: _budgetChannel.importance,
        ),
      );
    }

    _initialized = true;
    AppLogger.logSuccess('$_tag initialized');
  }

  // ───────────────── Permission ─────────────────

  /// Request notification permission (Android 13+).
  ///
  /// Return: `granted`, `denied`, atau `permanentlyDenied`.
  Future<PermissionStatus> requestPermission() async {
    AppLogger.call('$_tag requestPermission');

    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      AppLogger.call('$_tag permission status: $status');
      return status;
    }

    // iOS: request via plugin.
    if (Platform.isIOS) {
      final iosPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return (granted ?? false)
          ? PermissionStatus.granted
          : PermissionStatus.denied;
    }

    return PermissionStatus.granted;
  }

  /// Cek apakah permission sudah granted tanpa request.
  Future<bool> isPermissionGranted() async {
    if (Platform.isAndroid) {
      return await Permission.notification.isGranted;
    }
    return true;
  }

  // ───────────────── Show (instant) ─────────────────

  /// Tampilkan notifikasi instan (untuk budget alert).
  Future<void> showBudgetAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    AppLogger.call('$_tag showBudgetAlert: id=$id');

    const androidDetails = AndroidNotificationDetails(
      'saku_rapi_budget',
      'Alert Anggaran',
      channelDescription:
          'Notifikasi saat anggaran mendekati atau melebihi batas',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details);
  }

  // ───────────────── Schedule ─────────────────

  /// Jadwalkan daily reminder pada jam tertentu.
  ///
  /// Cancel reminder lama lalu schedule baru (hindari duplikat).
  Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    AppLogger.call('$_tag scheduleDailyReminder: ${time.hour}:${time.minute}');

    // Cancel dulu yang lama.
    await _plugin.cancel(dailyReminderId);

    const androidDetails = AndroidNotificationDetails(
      'saku_rapi_reminder',
      'Pengingat Harian',
      channelDescription: 'Pengingat untuk mencatat transaksi harian',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      dailyReminderId,
      title,
      body,
      _nextInstanceOfTime(time),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    AppLogger.logSuccess('$_tag daily reminder scheduled');
  }

  /// Batalkan daily reminder.
  Future<void> cancelDailyReminder() async {
    AppLogger.call('$_tag cancelDailyReminder');
    await _plugin.cancel(dailyReminderId);
  }

  /// Batalkan semua notifikasi.
  Future<void> cancelAll() async {
    AppLogger.call('$_tag cancelAll');
    await _plugin.cancelAll();
  }

  // ───────────────── Helpers ─────────────────

  /// Hitung TZDateTime berikutnya untuk jam [time] (hari ini atau besok).
  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final jakarta = tz.getLocation('Asia/Jakarta');
    final now = tz.TZDateTime.now(jakarta);
    var scheduled = tz.TZDateTime(
      jakarta,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Generate notification ID dari budget ID (hash → positive int).
  static int budgetAlertId(String budgetId, {bool is100 = false}) {
    final base = budgetId.hashCode.abs() % 100000;
    return budgetAlertBaseId + base + (is100 ? 1 : 0);
  }
}
