import 'package:app_saku_rapi/core/ads/ads_config.dart';
import 'package:app_saku_rapi/features/auth/controllers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider yang menentukan apakah iklan harus ditampilkan untuk user saat ini.
///
/// Aturan:
/// - `AdsConfig.adsEnabled` harus `true` (feature flag global)
/// - `UserModel.showAds` harus `true` (user belum beli no-ads)
/// - Jika user belum login (null), default tampilkan iklan.
final adsEligibleProvider = Provider<bool>((ref) {
  if (!AdsConfig.adsEnabled) return false;

  final user = ref.watch(currentUserProvider);
  // Jika user null (belum login atau loading), default tampilkan iklan.
  return user?.showAds ?? true;
});
