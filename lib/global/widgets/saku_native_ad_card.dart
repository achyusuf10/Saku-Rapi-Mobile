import 'package:app_saku_rapi/core/ads/ads_config.dart';
import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Card native ad yang menyatu dengan daftar transaksi.
///
/// Digunakan di [TransactionDateGroupedList] setiap [AdsConfig.nativeAdEveryNGroups] kelompok.
/// Silent fail — jika iklan gagal dimuat, widget menghilang tanpa error.
///
/// Catatan: widget ini **tidak** memeriksa [adsEligibleProvider] secara internal.
/// Pemanggil wajib memeriksa eligibility sebelum menyisipkan widget ini ke list.
class SakuNativeAdCard extends StatefulWidget {
  const SakuNativeAdCard({super.key});

  @override
  State<SakuNativeAdCard> createState() => _SakuNativeAdCardState();
}

class _SakuNativeAdCardState extends State<SakuNativeAdCard> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    final ad = NativeAd(
      adUnitId: AdsConfig.nativeUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() => _isAdLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          AppLogger.logError(
            '[Ads] [SakuNativeAdCard] Native failed: ${error.message}',
            runtimeType: SakuNativeAdCard,
          );
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Colors.transparent,
        cornerRadius: 12,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFF3B82F6),
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black87,
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black54,
          style: NativeTemplateFontStyle.italic,
          size: 12.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black38,
          style: NativeTemplateFontStyle.normal,
          size: 11.0,
        ),
      ),
    );

    ad.load();
    _nativeAd = ad;
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 80.h, maxHeight: 120.h),
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }
}
