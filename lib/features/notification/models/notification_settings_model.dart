import 'package:flutter/material.dart';

/// Model data untuk pengaturan notifikasi user.
///
/// Merepresentasikan satu record dari tabel `public.notification_settings`.
/// Setiap user punya tepat satu row (di-seed saat user pertama kali register).
class NotificationSettingsModel {
  const NotificationSettingsModel({
    required this.id,
    required this.userId,
    this.reminderEnabled = false,
    this.reminderTime,
    this.budgetAlertEnabled = true,
    this.debtReminderEnabled = true,
    this.debtReminderDaysBefore = 3,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;

  /// Aktifkan pengingat harian catat transaksi.
  final bool reminderEnabled;

  /// Jam pengingat harian (nullable — belum diset).
  final TimeOfDay? reminderTime;

  /// Aktifkan alert saat budget 80% / 100%.
  final bool budgetAlertEnabled;

  /// Aktifkan pengingat piutang sebelum jatuh tempo.
  final bool debtReminderEnabled;

  /// Berapa hari sebelum jatuh tempo reminder dikirim.
  final int debtReminderDaysBefore;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ───────────────── Factory ─────────────────

  factory NotificationSettingsModel.fromMap(Map<String, dynamic> map) {
    return NotificationSettingsModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      reminderEnabled: (map['reminder_enabled'] as bool?) ?? false,
      reminderTime: _parseTime(map['reminder_time'] as String?),
      budgetAlertEnabled: (map['budget_alert_enabled'] as bool?) ?? true,
      debtReminderEnabled: (map['debt_reminder_enabled'] as bool?) ?? true,
      debtReminderDaysBefore: (map['debt_reminder_days_before'] as int?) ?? 3,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Map untuk UPDATE — hanya field yang boleh diubah user.
  Map<String, dynamic> toUpdateMap() {
    return {
      'reminder_enabled': reminderEnabled,
      'reminder_time': reminderTime != null
          ? '${reminderTime!.hour.toString().padLeft(2, '0')}:${reminderTime!.minute.toString().padLeft(2, '0')}:00'
          : null,
      'budget_alert_enabled': budgetAlertEnabled,
      'debt_reminder_enabled': debtReminderEnabled,
      'debt_reminder_days_before': debtReminderDaysBefore,
    };
  }

  /// Map lengkap untuk local cache (Hive).
  Map<String, dynamic> toFullMap() {
    return {
      'id': id,
      'user_id': userId,
      'reminder_enabled': reminderEnabled,
      'reminder_time': reminderTime != null
          ? '${reminderTime!.hour.toString().padLeft(2, '0')}:${reminderTime!.minute.toString().padLeft(2, '0')}:00'
          : null,
      'budget_alert_enabled': budgetAlertEnabled,
      'debt_reminder_enabled': debtReminderEnabled,
      'debt_reminder_days_before': debtReminderDaysBefore,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  NotificationSettingsModel copyWith({
    String? id,
    String? userId,
    bool? reminderEnabled,
    TimeOfDay? reminderTime,
    bool clearReminderTime = false,
    bool? budgetAlertEnabled,
    bool? debtReminderEnabled,
    int? debtReminderDaysBefore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationSettingsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: clearReminderTime
          ? null
          : (reminderTime ?? this.reminderTime),
      budgetAlertEnabled: budgetAlertEnabled ?? this.budgetAlertEnabled,
      debtReminderEnabled: debtReminderEnabled ?? this.debtReminderEnabled,
      debtReminderDaysBefore:
          debtReminderDaysBefore ?? this.debtReminderDaysBefore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ───────────────── Helpers ─────────────────

  /// Parse "HH:mm:ss" → TimeOfDay.
  static TimeOfDay? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
