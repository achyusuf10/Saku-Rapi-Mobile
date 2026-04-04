import 'dart:convert';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';

/// Local data source untuk cache wallet menggunakan Hive (encrypted box).
class WalletLocalDataSource {
  static const _tag = '[Wallet] [WalletLocalDataSource]';
  static const _cacheKey = 'cached_wallets';

  /// Simpan daftar wallet ke cache lokal.
  void cacheWallets(List<WalletModel> wallets) {
    AppLogger.call('$_tag cacheWallets: ${wallets.length} wallets');
    final jsonList = wallets.map((e) => e.toFullMap()).toList();
    HiveService.set<String>(key: _cacheKey, data: jsonEncode(jsonList));
  }

  /// Ambil daftar wallet dari cache lokal.
  /// Mengembalikan `null` jika cache kosong.
  List<WalletModel>? getCachedWallets() {
    final raw = HiveService.get<String>(key: _cacheKey);
    if (raw == null) return null;

    AppLogger.call('$_tag getCachedWallets: from cache');
    final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
    return jsonList
        .map((e) => WalletModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Hapus cache wallet.
  void clearWalletCache() {
    AppLogger.call('$_tag clearWalletCache');
    HiveService.delete(_cacheKey);
  }
}
