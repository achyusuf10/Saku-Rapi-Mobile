import 'package:flutter/material.dart';

/// Model untuk tabel `notification_settings`.
///
/// Skema DB:
/// - id: uuid (PK, default uuid_generate_v4())
/// - user_id: uuid (FK → auth.users)
/// - reminder_enabled: boolean (default false)
/// - reminder_time: time without time zone (default '21:00:00')
/// - budget_alert_enabled: boolean (default true)
/// - debt_reminder_enabled: boolean (default true)
/// - debt_reminder_days_before: integer (default 3)
/// - updated_at: timestamptz (default now())
class NotificationSettingsModel {
  const NotificationSettingsModel({
    required this.id,
    required this.userId,
    required this.reminderEnabled,
    required this.reminderTime,
    required this.budgetAlertEnabled,
    required this.debtReminderEnabled,
    required this.debtReminderDaysBefore,
    required this.updatedAt,
  });

  final String id;
  final String userId;

  /// Apakah reminder harian aktif.
  final bool reminderEnabled;

  /// Jam pengingat harian (misal: 21:00).
  final TimeOfDay reminderTime;

  /// Apakah notifikasi budget alert aktif.
  final bool budgetAlertEnabled;

  /// Apakah pengingat piutang jatuh tempo aktif.
  final bool debtReminderEnabled;

  /// Berapa hari sebelum jatuh tempo untuk mengirim pengingat piutang.
  final int debtReminderDaysBefore;

  /// Waktu terakhir diperbarui.
  final DateTime updatedAt;

  // ── Factory Defaults ───────────────────────────────────────

  /// Buat model dengan nilai default (digunakan sebelum data dari Supabase tersedia).
  factory NotificationSettingsModel.defaults({required String userId}) {
    return NotificationSettingsModel(
      id: '',
      userId: userId,
      reminderEnabled: false,
      reminderTime: const TimeOfDay(hour: 21, minute: 0),
      budgetAlertEnabled: true,
      debtReminderEnabled: true,
      debtReminderDaysBefore: 3,
      updatedAt: DateTime.now(),
    );
  }

  // ── Serialization ──────────────────────────────────────────

  /// Parsing dari Map Supabase.
  ///
  /// Field `reminder_time` di-parse dari string format `HH:MM:SS`.
  factory NotificationSettingsModel.fromMap(Map<String, dynamic> map) {
    return NotificationSettingsModel(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      reminderEnabled: map['reminder_enabled'] as bool? ?? false,
      reminderTime: _parseTime(map['reminder_time'] as String? ?? '21:00:00'),
      budgetAlertEnabled: map['budget_alert_enabled'] as bool? ?? true,
      debtReminderEnabled: map['debt_reminder_enabled'] as bool? ?? true,
      debtReminderDaysBefore: map['debt_reminder_days_before'] as int? ?? 3,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Konversi ke Map untuk update Supabase (excludes id & user_id).
  Map<String, dynamic> toUpdateMap() {
    return {
      'reminder_enabled': reminderEnabled,
      'reminder_time': _formatTime(reminderTime),
      'budget_alert_enabled': budgetAlertEnabled,
      'debt_reminder_enabled': debtReminderEnabled,
      'debt_reminder_days_before': debtReminderDaysBefore,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Konversi ke Map penuh (termasuk id & user_id) untuk cache Hive.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'reminder_enabled': reminderEnabled,
      'reminder_time': _formatTime(reminderTime),
      'budget_alert_enabled': budgetAlertEnabled,
      'debt_reminder_enabled': debtReminderEnabled,
      'debt_reminder_days_before': debtReminderDaysBefore,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ── CopyWith ───────────────────────────────────────────────

  NotificationSettingsModel copyWith({
    String? id,
    String? userId,
    bool? reminderEnabled,
    TimeOfDay? reminderTime,
    bool? budgetAlertEnabled,
    bool? debtReminderEnabled,
    int? debtReminderDaysBefore,
    DateTime? updatedAt,
  }) {
    return NotificationSettingsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      budgetAlertEnabled: budgetAlertEnabled ?? this.budgetAlertEnabled,
      debtReminderEnabled: debtReminderEnabled ?? this.debtReminderEnabled,
      debtReminderDaysBefore:
          debtReminderDaysBefore ?? this.debtReminderDaysBefore,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ── Private Helpers ────────────────────────────────────────

  /// Parse `'HH:MM:SS'` atau `'HH:MM'` ke [TimeOfDay].
  static TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length < 2) return const TimeOfDay(hour: 21, minute: 0);
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 21,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  /// Format [TimeOfDay] ke `'HH:MM:00'` untuk disimpan ke Supabase.
  static String _formatTime(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm:00';
  }
}
