import 'dart:convert';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/notification/models/notification_settings_model.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';

/// Local data source untuk cache notification settings menggunakan Hive.
class NotificationLocalDataSource {
  static const _tag = '[Notification] [NotificationLocalDataSource]';
  static const _cacheKey = 'cached_notification_settings';

  /// Simpan settings ke cache lokal.
  void cacheSettings(NotificationSettingsModel settings) {
    AppLogger.call('$_tag cacheSettings');
    HiveService.set<String>(
      key: _cacheKey,
      data: jsonEncode(settings.toFullMap()),
    );
  }

  /// Ambil settings dari cache lokal.
  NotificationSettingsModel? getCachedSettings() {
    final raw = HiveService.get<String>(key: _cacheKey);
    if (raw == null) return null;

    AppLogger.call('$_tag getCachedSettings: from cache');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return NotificationSettingsModel.fromMap(map);
  }

  /// Hapus cache.
  void clearCache() {
    AppLogger.call('$_tag clearCache');
    HiveService.delete(_cacheKey);
  }
}
