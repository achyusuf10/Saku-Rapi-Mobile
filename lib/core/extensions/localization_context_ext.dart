import 'package:app_saku_rapi/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

extension AppLocalizationsX on BuildContext {
  // Getter singkat 'l10n'
  AppLocalizations get l10n => AppLocalizations.of(this);
  // TAMBAHAN BARU (untuk akses Locale)
  Locale get locale => Localizations.localeOf(this);
}
