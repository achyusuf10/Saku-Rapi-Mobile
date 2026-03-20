import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/notification/datasource/notification_settings_local_datasource.dart';
import 'package:app_saku_rapi/features/notification/datasource/notification_settings_remote_datasource.dart';
import 'package:app_saku_rapi/features/notification/models/notification_settings_model.dart';

/// Repository orkestrator untuk [NotificationSettingsModel].
///
/// Menggabungkan remote (Supabase) dan local (Hive) data source:
/// - Fetch: cek cache → jika expired atau kosong, ambil dari Supabase
/// - Update: selalu kirim ke Supabase, lalu perbarui cache lokal
class NotificationSettingsRepository {
  NotificationSettingsRepository({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final NotificationSettingsRemoteDataSource remoteDataSource;
  final NotificationSettingsLocalDataSource localDataSource;

  static const String _tag = 'NotificationSettings';

  // ── Fetch ──────────────────────────────────────────────────

  /// Ambil settings untuk [userId].
  ///
  /// Prioritas: cache valid → Supabase → fallback ke cache stale.
  Future<DataState<NotificationSettingsModel>> getSettings({
    required String userId,
  }) async {
    // Cek cache lokal terlebih dahulu
    if (!localDataSource.isCacheExpired()) {
      final cached = localDataSource.getCachedSettings();
      if (cached != null) {
        AppLogger.call(
          '[$_tag] Settings loaded from cache',
          colorLog: ColorLog.green,
        );
        return DataState.success(data: cached);
      }
    }

    AppLogger.call(
      '[$_tag] Fetching settings from Supabase…',
      colorLog: ColorLog.blue,
    );

    final result = await remoteDataSource.getOrCreate(userId);

    result.map(
      success: (data) {
        localDataSource.saveSettings(data.data);
        AppLogger.call(
          '[$_tag] Settings fetched and cached',
          colorLog: ColorLog.green,
        );
      },
      error: (err) {
        AppLogger.logError(
          '[$_tag] Fetch failed: ${err.message}',
          stackTrace: err.stackTrace,
        );
        // Fallback ke stale cache jika ada
        final stale = localDataSource.getCachedSettings();
        if (stale != null) {
          AppLogger.call(
            '[$_tag] Using stale cache as fallback',
            colorLog: ColorLog.yellow,
          );
        }
      },
    );

    // Kembalikan stale cache jika remote gagal
    if (result.isError()) {
      final stale = localDataSource.getCachedSettings();
      if (stale != null) return DataState.success(data: stale);
    }

    return result;
  }

  // ── Update ─────────────────────────────────────────────────

  /// Simpan [settings] ke Supabase dan perbarui cache lokal.
  Future<DataState<NotificationSettingsModel>> updateSettings({
    required String userId,
    required NotificationSettingsModel settings,
  }) async {
    AppLogger.call(
      '[$_tag] Updating settings for user $userId…',
      colorLog: ColorLog.blue,
    );

    final result = await remoteDataSource.update(
      userId: userId,
      settings: settings,
    );

    result.map(
      success: (data) {
        localDataSource.saveSettings(data.data);
        AppLogger.call(
          '[$_tag] Settings updated and cached',
          colorLog: ColorLog.green,
        );
      },
      error: (err) {
        AppLogger.logError(
          '[$_tag] Update failed: ${err.message}',
          stackTrace: err.stackTrace,
        );
      },
    );

    return result;
  }
}
