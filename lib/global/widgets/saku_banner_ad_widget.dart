import 'package:app_saku_rapi/core/ads/ads_config.dart';
import 'package:app_saku_rapi/core/ads/ads_eligibility_provider.dart';
import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Widget banner iklan di bagian bawah halaman.
///
/// Otomatis menyembunyikan diri jika:
/// - Ads tidak diaktifkan ([AdsConfig.adsEnabled] == false)
/// - User sudah beli no-ads ([adsEligibleProvider] == false)
/// - Gagal memuat iklan (silent fail — tidak crash, tidak tampil placeholder)
///
/// Contoh penggunaan:
/// ```dart
/// Column(
///   children: [
///     Expanded(child: content),
///     const SakuBannerAdWidget(),
///   ],
/// )
/// ```
class SakuBannerAdWidget extends ConsumerStatefulWidget {
  const SakuBannerAdWidget({super.key});

  @override
  ConsumerState<SakuBannerAdWidget> createState() => _SakuBannerAdWidgetState();
}

class _SakuBannerAdWidgetState extends ConsumerState<SakuBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    if (!AdsConfig.adsEnabled) return;

    final ad = BannerAd(
      adUnitId: AdsConfig.bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() => _isAdLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          AppLogger.logError(
            '[Ads] [SakuBannerAdWidget] Banner failed: ${error.message}',
            runtimeType: SakuBannerAdWidget,
          );
        },
      ),
    );

    ad.load();
    _bannerAd = ad;
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eligible = ref.watch(adsEligibleProvider);

    if (!eligible || !_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
