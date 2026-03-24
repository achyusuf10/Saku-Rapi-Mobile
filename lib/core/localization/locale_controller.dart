import 'package:app_saku_rapi/utils/services/hive_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Key Hive untuk menyimpan pilihan bahasa user.
const _kLocaleKey = 'app_locale';

final localeControllerProvider =
    StateNotifierProvider<LocaleController, Locale>((ref) {
      return LocaleController();
    });

class LocaleController extends StateNotifier<Locale> {
  LocaleController() : super(_readFromHive());

  /// Baca Locale tersimpan dari Hive (default: id).
  static Locale _readFromHive() {
    final stored = HiveService.get<String>(key: _kLocaleKey);
    return switch (stored) {
      'en' => const Locale('en'),
      _ => const Locale('id'),
    };
  }

  bool get isEnglish => state.languageCode == 'en';
  bool get isIndonesian => state.languageCode == 'id';

  void toggleLanguage() {
    setLanguage(isIndonesian ? const Locale('en') : const Locale('id'));
  }

  void setLanguage(Locale locale) {
    state = locale;
    HiveService.set<String>(key: _kLocaleKey, data: locale.languageCode);
  }
}
