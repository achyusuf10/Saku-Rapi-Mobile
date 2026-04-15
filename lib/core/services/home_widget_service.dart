import 'dart:convert';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/home_widget/home_widget_constants.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:home_widget/home_widget.dart';

/// Service untuk sinkronisasi data wallet ke Android Home Widget.
///
/// Dipanggil setiap kali data wallet berubah (CRUD, adjustBalance, sync).
/// Data disimpan di SharedPreferences `HomeWidgetPreferences` agar bisa
/// dibaca oleh native Android WidgetProvider.
class HomeWidgetService {
  HomeWidgetService._();

  /// Sync semua wallet data ke home widget.
  ///
  /// Serialize [wallets] ke JSON string, simpan via `home_widget`,
  /// lalu trigger broadcast update ke semua widget instance.
  static Future<void> syncWalletData(List<WalletModel> wallets) async {
    try {
      final walletsJson = wallets
          .map(
            (w) => {
              'id': w.id,
              'name': w.name,
              'balance': w.balance,
              'icon': w.icon,
              'color': w.color,
              'excludeFromTotal': w.excludeFromTotal,
              'sortOrder': w.sortOrder,
            },
          )
          .toList();

      await HomeWidget.saveWidgetData<String>(
        HomeWidgetConstants.walletDataKey,
        jsonEncode(walletsJson),
      );

      await HomeWidget.updateWidget(
        qualifiedAndroidName: HomeWidgetConstants.androidQualifiedName,
      );

      AppLogger.call(
        '[Sync] [HomeWidget] Synced ${wallets.length} wallets to widget',
      );
    } catch (e) {
      AppLogger.logError(
        'Failed to sync wallet data to home widget: $e',
        runtimeType: HomeWidgetService,
      );
    }
  }

  /// Simpan konfigurasi wallet yang dipilih untuk widget tertentu.
  static Future<void> saveWidgetConfig(
    int appWidgetId,
    List<String> walletIds,
  ) async {
    try {
      await HomeWidget.saveWidgetData<String>(
        '${HomeWidgetConstants.configKeyPrefix}$appWidgetId',
        jsonEncode(walletIds),
      );
    } catch (e) {
      AppLogger.logError(
        'Failed to save widget config: $e',
        runtimeType: HomeWidgetService,
      );
    }
  }

  /// Ambil konfigurasi wallet yang dipilih.
  static Future<List<String>?> getWidgetConfig(int appWidgetId) async {
    try {
      final raw = await HomeWidget.getWidgetData<String>(
        '${HomeWidgetConstants.configKeyPrefix}$appWidgetId',
      );
      if (raw == null) return null;
      return (jsonDecode(raw) as List).cast<String>();
    } catch (e) {
      AppLogger.logError(
        'Failed to read widget config: $e',
        runtimeType: HomeWidgetService,
      );
      return null;
    }
  }
}
