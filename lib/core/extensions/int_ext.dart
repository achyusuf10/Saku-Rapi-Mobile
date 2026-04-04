import 'package:app_saku_rapi/core/constants/app_constants.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:intl/intl.dart';

/// Extension untuk formatting nilai `int` dan `int?` sebagai mata uang.
///
/// **ATURAN:** Semua tampilan nilai uang bertipe `int` di UI SakuRapi WAJIB
/// menggunakan extension ini. DILARANG format manual langsung di widget.
///
/// Contoh:
/// ```dart
/// int price = 150000;
/// price.extToRupiah();          // → 'Rp 150.000'
/// price.extToRibuan();          // → '150.000'
/// ```
extension IntExtension on int {
  /// Locale yang digunakan untuk format angka.
  static const String _locale = 'id_ID';

  /// Format nilai sebagai mata uang Rupiah.
  ///
  /// - [withPrefix]: Jika `true` (default), tambahkan simbol mata uang.
  /// - [showDecimal]: Jika `true`, tampilkan 2 digit desimal (default: false).
  ///
  /// Contoh:
  /// ```dart
  /// 150000.extToRupiah();                      // → 'Rp 150.000'
  /// 150000.extToRupiah(withPrefix: false);     // → '150.000'
  /// 150000.extToRupiah(showDecimal: true);     // → 'Rp 150.000,00'
  /// ```
  String extToRupiah({bool withPrefix = true, bool showDecimal = false}) {
    final formatter = NumberFormat.currency(
      locale: appContext?.locale.languageCode ?? _locale,
      symbol: withPrefix ? AppConstants.currencySymbol : '',
      decimalDigits: showDecimal ? 2 : 0,
    );
    return formatter.format(this);
  }

  /// Format hanya angka ribuan tanpa prefix mata uang.
  ///
  /// Contoh:
  /// ```dart
  /// 150000.extToRibuan(); // → '150.000'
  /// ```
  String extToRibuan() {
    final formatter = NumberFormat.currency(
      locale: appContext?.locale.languageCode ?? _locale,
      symbol: '',
      decimalDigits: 0,
    );
    return formatter.format(this).trim();
  }

  /// Format nilai sebagai mata uang kompak (singkat) untuk angka besar.
  ///
  /// Contoh:
  /// ```dart
  /// 1500000.extToCompactRupiah();    // → 'Rp 1,5 jt'
  /// 75000.extToCompactRupiah();      // → 'Rp 75 rb'
  /// ```
  String extToCompactRupiah({bool withPrefix = true}) {
    final String prefix = withPrefix ? AppConstants.currencySymbol : '';

    if (this >= 1000000000) {
      final double val = this / 1000000000;
      final String formatted = _formatCompactValue(val);
      return '$prefix$formatted M';
    } else if (this >= 1000000) {
      final double val = this / 1000000;
      final String formatted = _formatCompactValue(val);
      return '$prefix$formatted jt';
    } else if (this >= 1000) {
      final double val = this / 1000;
      final String formatted = _formatCompactValue(val);
      return '$prefix$formatted rb';
    } else {
      return extToRupiah(withPrefix: withPrefix);
    }
  }

  /// Helper: format angka pecahan untuk compact display.
  String _formatCompactValue(double val) {
    if (val == val.truncateToDouble()) {
      return val.toInt().toString();
    }
    final locale = appContext?.locale.languageCode ?? _locale;
    return NumberFormat('#,##0.#', locale).format(val);
  }
}

/// Extension untuk formatting nilai `int?` (nullable) sebagai mata uang.
///
/// Jika null, mengembalikan '-' sebagai fallback.
extension NullableIntExtension on int? {
  /// Format nullable int sebagai Rupiah, return '-' jika null.
  ///
  /// Contoh:
  /// ```dart
  /// int? price = 150000;
  /// price.extToRupiah();     // → 'Rp 150.000'
  ///
  /// int? nullPrice;
  /// nullPrice.extToRupiah(); // → '-'
  /// ```
  String extToRupiah({bool withPrefix = true, bool showDecimal = false}) {
    if (this == null) return '-';
    return this!.extToRupiah(withPrefix: withPrefix, showDecimal: showDecimal);
  }

  /// Format nullable int sebagai ribuan, return '-' jika null.
  String extToRibuan() {
    if (this == null) return '-';
    return this!.extToRibuan();
  }
}
