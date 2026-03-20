import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

final localeControllerProvider =
    StateNotifierProvider<LocaleController, Locale>((ref) {
      return LocaleController();
    });

class LocaleController extends StateNotifier<Locale> {
  LocaleController() : super(_getInitialLocale());

  static Locale _getInitialLocale() {
    // Default to Indonesian
    return const Locale('id', 'ID');
  }

  bool get isEnglish => state.languageCode == 'en';
  bool get isIndonesian => state.languageCode == 'id';

  void toggleLanguage() {}

  void setLanguage(Locale locale) {
    state = locale;
  }
}
