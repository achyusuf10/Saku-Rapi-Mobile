import 'package:app_saku_rapi/core/constants/app_constants.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:intl/intl.dart';

/// Extension untuk formatting nilai `double` dan `double?` sebagai mata uang.
///
/// **ATURAN:** Semua tampilan nilai uang di UI SakuRapi WAJIB menggunakan
/// extension ini. DILARANG format manual langsung di widget.
///
/// Dengan menggunakan extension terpusat ini, perubahan format mata uang
/// di masa depan cukup dilakukan di satu tempat dan otomatis berlaku
/// ke seluruh aplikasi (future-proof untuk multi-currency).
///
/// Contoh:
/// ```dart
/// double balance = 150000.0;
/// balance.toCurrency();          // → 'Rp 150.000'
/// balance.toCompactCurrency();   // → 'Rp 150 rb'
/// balance.toThousands();         // → '150.000'
/// 0.82.toPercentage();           // → '82%'
/// ```
extension DoubleExtension on double {
  // ─────────────────────────────────────────────────────────────
  // Konfigurasi mata uang aktif (ubah di sini untuk multi-currency)
  // ─────────────────────────────────────────────────────────────

  /// Locale yang digunakan untuk format angka.
  static const String _locale = 'id_ID';

  // ─────────────────────────────────────────────────────────────
  // Format Utama
  // ─────────────────────────────────────────────────────────────

  /// Format nilai sebagai mata uang lengkap.
  ///
  /// - [withPrefix]: Jika `true` (default), tambahkan simbol mata uang di depan.
  /// - [showDecimal]: Jika `true`, tampilkan 2 digit desimal (default: false).
  ///
  /// Contoh:
  /// ```dart
  /// 150000.0.toCurrency();                  // → 'Rp 150.000'
  /// 150000.0.toCurrency(withPrefix: false); // → '150.000'
  /// 150000.5.toCurrency(showDecimal: true); // → 'Rp 150.000,50'
  /// ```
  String toCurrency({bool withPrefix = true, bool showDecimal = false}) {
    final formatter = NumberFormat.currency(
      locale: appContext?.locale.languageCode ?? _locale,
      symbol: withPrefix ? AppConstants.currencySymbol : '',
      decimalDigits: showDecimal ? 2 : 0,
    );
    return formatter.format(this);
  }

  /// Format nilai sebagai mata uang kompak (singkat) untuk angka besar.
  ///
  /// Konversi:
  /// - >= 1.000.000.000 → tampilkan dalam miliar (M)
  /// - >= 1.000.000     → tampilkan dalam juta (jt)
  /// - >= 1.000         → tampilkan dalam ribu (rb)
  /// - < 1.000          → tampilkan nilai penuh
  ///
  /// - [withPrefix]: Jika `true` (default), tambahkan simbol mata uang.
  ///
  /// Contoh:
  /// ```dart
  /// 1500000.0.toCompactCurrency();  // → 'Rp 1,5 jt'
  /// 2300000000.0.toCompactCurrency(); // → 'Rp 2,3 M'
  /// 75000.0.toCompactCurrency();    // → 'Rp 75 rb'
  /// ```
  String toCompactCurrency({bool withPrefix = true}) {
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
      return toCurrency(withPrefix: withPrefix);
    }
  }

  /// Format hanya angka ribuan tanpa prefix mata uang.
  ///
  /// Contoh:
  /// ```dart
  /// 150000.0.toThousands(); // → '150.000'
  /// 1500.5.toThousands();   // → '1.501' (dibulatkan)
  /// ```
  String toThousands() {
    final formatter = NumberFormat.currency(
      locale: appContext?.locale.languageCode ?? _locale,
      symbol: '',
      decimalDigits: 0,
    );
    return formatter.format(this).trim();
  }

  /// Format nilai sebagai persentase.
  ///
  /// - [decimalDigits]: Jumlah digit desimal (default: 0).
  /// - [withSymbol]: Jika `true` (default), tambahkan simbol `%` di belakang.
  ///
  /// Contoh:
  /// ```dart
  /// 0.8234.toPercentage();                  // → '82%'
  /// 0.8234.toPercentage(decimalDigits: 1);  // → '82,3%'
  /// 82.34.toPercentage(decimalDigits: 2);   // → '82,34%'
  /// // Catatan: jika nilai > 1, dianggap sudah dalam bentuk persentase (0-100)
  /// ```
  String toPercentage({int decimalDigits = 0, bool withSymbol = true}) {
    // Jika nilai <= 1, asumsikan bentuk desimal (0.82 → 82%)
    final double displayValue = this <= 1.0 ? this * 100 : this;
    final String symbol = withSymbol ? '%' : '';
    return '${displayValue.toStringAsFixed(decimalDigits)}$symbol';
  }

  // ─────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────

  /// Format nilai kompak: hilangkan desimal jika bulat, tampilkan 1 desimal jika tidak.
  String _formatCompactValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    // Gunakan format dengan 1 digit desimal menggunakan koma
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }
}

/// Extension untuk `double?` (nullable double).
///
/// Mengembalikan `'-'` jika nilai adalah `null`.
extension DoubleNullExtension on double? {
  /// Format nilai nullable sebagai mata uang.
  /// Mengembalikan `'-'` jika null.
  ///
  /// Contoh:
  /// ```dart
  /// double? price = null;
  /// price.toCurrencyOrDash(); // → '-'
  ///
  /// double? amount = 50000.0;
  /// amount.toCurrencyOrDash(); // → 'Rp 50.000'
  /// ```
  String toCurrencyOrDash({bool withPrefix = true, bool showDecimal = false}) {
    if (this == null) return '-';
    return this!.toCurrency(withPrefix: withPrefix, showDecimal: showDecimal);
  }

  /// Format nilai nullable sebagai mata uang kompak.
  /// Mengembalikan `'-'` jika null.
  String toCompactCurrencyOrDash({bool withPrefix = true}) {
    if (this == null) return '-';
    return this!.toCompactCurrency(withPrefix: withPrefix);
  }

  /// Format nilai nullable sebagai ribuan.
  /// Mengembalikan `'-'` jika null.
  String toThousandsOrDash() {
    if (this == null) return '-';
    return this!.toThousands();
  }

  /// Format nilai nullable sebagai persentase.
  /// Mengembalikan `'-'` jika null.
  String toPercentageOrDash({int decimalDigits = 0}) {
    if (this == null) return '-';
    return this!.toPercentage(decimalDigits: decimalDigits);
  }
}
