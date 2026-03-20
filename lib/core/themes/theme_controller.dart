import 'package:app_saku_rapi/utils/services/hive_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Key Hive untuk menyimpan pilihan tema user.
const _kThemeModeKey = 'theme_mode';

/// Riverpod provider untuk mengelola ThemeMode (dark / light).
/// Baca nilai awal dari Hive, dan simpan perubahan ke Hive.
final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>((ref) {
      return ThemeController();
    });

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController() : super(_readFromHive());

  /// Baca ThemeMode tersimpan dari Hive (default: system).
  static ThemeMode _readFromHive() {
    final stored = HiveService.get<String>(key: _kThemeModeKey);
    return switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  bool get isDark => state == ThemeMode.dark;

  void toggleTheme() {
    setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    HiveService.set<String>(key: _kThemeModeKey, data: mode.name);
  }
}
