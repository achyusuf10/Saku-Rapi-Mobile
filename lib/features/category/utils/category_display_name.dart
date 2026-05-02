import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/category/utils/category_catalog_localizations.dart';
import 'package:app_saku_rapi/l10n/app_localizations.dart';

extension CategoryModelDisplayExt on CategoryModel {
  /// Nama untuk UI: katalog global (`user_id == null`) pakai terjemahan;
  /// kategori milik user tetap nama dari DB.
  String displayTitle(AppLocalizations l10n) {
    if (userId != null) return name;
    return localizedCatalogCategoryName(l10n, name);
  }
}
