import 'package:app_saku_rapi/core/ads/ads_config.dart';
import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service singleton untuk mengelola siklus hidup iklan di SakuRapi.
///
/// Tanggung jawab:
/// - Inisialisasi AdMob SDK (dipanggil sekali saat bootstrap).
/// - Preload & reload interstitial ad.
/// - Menentukan kapan interstitial harus tampil (setiap N simpan).
///
/// Penggunaan:
/// ```dart
/// // Di bootstrap()
/// await AdsService.instance.init();
///
/// // Setelah simpan transaksi berhasil
/// await AdsService.instance.incrementAndMaybeShowInterstitial(context);
/// ```
class AdsService {
  AdsService._();

  static final AdsService instance = AdsService._();

  static const _saveCounterKey = 'ads_save_counter';

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  // ─── Init ───────────────────────────────────────────────

  Future<void> init() async {
    if (!AdsConfig.adsEnabled) return;
    try {
      await MobileAds.instance.initialize();
      AppLogger.call('[Ads] [AdsService] AdMob SDK initialized');
      _preloadInterstitial();
    } catch (e) {
      AppLogger.logError(
        '[Ads] [AdsService] Failed to init AdMob: $e',
        runtimeType: AdsService,
      );
    }
  }

  // ─── Interstitial ───────────────────────────────────────

  void _preloadInterstitial() {
    if (_isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: AdsConfig.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          AppLogger.call('[Ads] [AdsService] Interstitial preloaded');
          ad.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          AppLogger.logError(
            '[Ads] [AdsService] Interstitial failed to load: ${error.message}',
            runtimeType: AdsService,
          );
        },
      ),
    );
  }

  /// Tambah counter simpan transaksi. Jika sudah mencapai threshold,
  /// tampilkan interstitial (jika sudah siap) lalu reset counter.
  ///
  /// Harus dipanggil hanya jika [adsEligibleProvider] == true.
  Future<void> incrementAndMaybeShowInterstitial(BuildContext context) async {
    if (!AdsConfig.adsEnabled) return;

    final current = HiveService.get<int>(key: _saveCounterKey) ?? 0;
    final next = current + 1;

    if (next >= AdsConfig.interstitialEveryNSaves) {
      HiveService.set(key: _saveCounterKey, data: 0);
      await _showInterstitial(context);
    } else {
      HiveService.set(key: _saveCounterKey, data: next);
    }
  }

  Future<void> _showInterstitial(BuildContext context) async {
    final ad = _interstitialAd;
    if (ad == null) {
      AppLogger.call(
        '[Ads] [AdsService] Interstitial not ready, skipping',
      );
      _preloadInterstitial();
      return;
    }

    _interstitialAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _preloadInterstitial();
        AppLogger.call('[Ads] [AdsService] Interstitial dismissed, preloading next');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _preloadInterstitial();
        AppLogger.logError(
          '[Ads] [AdsService] Interstitial failed to show: ${error.message}',
          runtimeType: AdsService,
        );
      },
    );

    if (context.mounted) {
      await ad.show();
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
