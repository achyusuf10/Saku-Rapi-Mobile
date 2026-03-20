import 'dart:convert';

import 'package:app_saku_rapi/features/notification/models/notification_settings_model.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';

/// Local data source (Hive) untuk cache [NotificationSettingsModel].
///
/// TTL cache 24 jam — cukup bagi data settings yang jarang berubah.
class NotificationSettingsLocalDataSource {
  static const String _settingsKey = 'notif_settings_data';
  static const String _lastFetchKey = 'notif_settings_last_fetch';

  /// TTL cache: 24 jam.
  static const int _ttlMinutes = 60 * 24;

  // ── Cache Validation ───────────────────────────────────────

  /// Apakah cache sudah expired.
  bool isCacheExpired() {
    final lastFetch = HiveService.get<int>(key: _lastFetchKey);
    if (lastFetch == null) return true;

    final lastFetchTime = DateTime.fromMillisecondsSinceEpoch(lastFetch);
    return DateTime.now().difference(lastFetchTime).inMinutes >= _ttlMinutes;
  }

  // ── Read ───────────────────────────────────────────────────

  /// Ambil settings dari cache Hive. Return `null` jika belum ada.
  NotificationSettingsModel? getCachedSettings() {
    final raw = HiveService.get<String>(key: _settingsKey);
    if (raw == null) return null;

    final map = jsonDecode(raw) as Map<String, dynamic>;
    return NotificationSettingsModel.fromMap(map);
  }

  // ── Write ──────────────────────────────────────────────────

  /// Simpan settings ke cache Hive.
  void saveSettings(NotificationSettingsModel settings) {
    HiveService.set<String>(
      key: _settingsKey,
      data: jsonEncode(settings.toMap()),
    );
    HiveService.set<int>(
      key: _lastFetchKey,
      data: DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ── Delete ─────────────────────────────────────────────────

  /// Hapus cache settings.
  void clearCache() {
    HiveService.deleteAll([_settingsKey, _lastFetchKey]);
  }
}
