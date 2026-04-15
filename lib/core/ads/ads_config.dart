import 'dart:io';

import 'package:app_saku_rapi/core/config/app_flavor.dart';
import 'package:flutter/foundation.dart';

/// Konfigurasi terpusat untuk Google AdMob di SakuRapi.
///
/// Semua unit ID dan konstanta ads diambil dari sini.
/// Untuk release:
///   - Ganti [_androidBannerIdProd], [_iosBannerIdProd], dst.
///     dengan ID asli dari AdMob console.
///   - Ganti [_androidAppIdProd] / [_iosAppIdProd] di AndroidManifest.xml / Info.plist.
abstract class AdsConfig {
  AdsConfig._();

  // ─── Test IDs (dipakai saat dev / debug) ───────────────

  static const _androidBannerIdTest = 'ca-app-pub-3940256099942544/6300978111';
  static const _iosBannerIdTest = 'ca-app-pub-3940256099942544/2934735716';

  static const _androidNativeIdTest = 'ca-app-pub-3940256099942544/2247696110';
  static const _iosNativeIdTest = 'ca-app-pub-3940256099942544/3986624511';

  static const _androidInterstitialIdTest =
      'ca-app-pub-3940256099942544/1033173712';
  static const _iosInterstitialIdTest =
      'ca-app-pub-3940256099942544/4411468910';

  // ─── Production IDs (isi setelah app diapprove AdMob) ───

  static const _androidBannerIdProd = 'ca-app-pub-3400518842205048/5422856872';
  static const _iosBannerIdProd = 'GANTI_BANNER_ID_IOS_PROD';

  static const _androidNativeIdProd = 'ca-app-pub-3400518842205048/4388976809';
  static const _iosNativeIdProd = 'GANTI_NATIVE_ID_IOS_PROD';

  static const _androidInterstitialIdProd =
      'ca-app-pub-3400518842205048/6554928961';
  static const _iosInterstitialIdProd = 'GANTI_INTERSTITIAL_ID_IOS_PROD';

  // ─── Feature flag ───────────────────────────────────────

  /// Matikan semua ads sekaligus (override global).
  /// Berguna untuk release build yang belum punya AdMob approval.
  static const bool adsEnabled = true;

  // ─── Frekuensi ──────────────────────────────────────────

  /// Tampilkan native ad setiap N kelompok tanggal di History.
  static const int nativeAdEveryNGroups = 10;

  /// Tampilkan interstitial setiap N kali simpan transaksi.
  static const int interstitialEveryNSaves = 3;

  // ─── Unit ID getters ────────────────────────────────────

  /// Apakah sedang dalam mode test (dev atau debug build).
  static bool get _useTestIds => AppFlavorConfig.isDev || kDebugMode;

  static String get bannerUnitId {
    if (Platform.isAndroid) {
      return _useTestIds ? _androidBannerIdTest : _androidBannerIdProd;
    }
    return _useTestIds ? _iosBannerIdTest : _iosBannerIdProd;
  }

  static String get nativeUnitId {
    if (Platform.isAndroid) {
      return _useTestIds ? _androidNativeIdTest : _androidNativeIdProd;
    }
    return _useTestIds ? _iosNativeIdTest : _iosNativeIdProd;
  }

  static String get interstitialUnitId {
    if (Platform.isAndroid) {
      return _useTestIds
          ? _androidInterstitialIdTest
          : _androidInterstitialIdProd;
    }
    return _useTestIds ? _iosInterstitialIdTest : _iosInterstitialIdProd;
  }
}
