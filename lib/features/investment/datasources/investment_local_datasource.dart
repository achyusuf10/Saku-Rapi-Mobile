import 'dart:convert';

import 'package:app_saku_rapi/features/investment/models/asset_price_model.dart';
import 'package:app_saku_rapi/features/investment/models/investment_model.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';

/// Cache lokal untuk data investasi dan harga aset menggunakan Hive.
///
/// - Investasi: offline-first fallback jika Supabase tidak tersedia.
/// - Harga aset: TTL 60 menit untuk menghindari API call yang berlebihan.
class InvestmentLocalDataSource {
  static const String _keyInvestments = 'investments_data';
  static const String _keyInvestmentsFetch = 'investments_last_fetch';

  static const String _keyBtcPrice = 'btc_price_cache';
  static const String _keyBtcFetch = 'btc_price_last_fetch';

  static const String _keyGoldPrice = 'gold_price_cache';
  static const String _keyGoldFetch = 'gold_price_last_fetch';

  /// TTL cache harga aset: 60 menit.
  static const int _ttlMinutes = 60;

  // ─────────────────────────────────────────────────────────────
  // Investasi cache
  // ─────────────────────────────────────────────────────────────

  bool isInvestmentCacheExpired() => _isExpired(_keyInvestmentsFetch);

  List<InvestmentModel> getCachedInvestments() {
    final raw = HiveService.get<String>(key: _keyInvestments);
    if (raw == null) return [];

    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => InvestmentModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  void saveInvestments(List<InvestmentModel> investments) {
    final raw = jsonEncode(investments.map(_investmentToCache).toList());
    HiveService.set<String>(key: _keyInvestments, data: raw);
    HiveService.set<int>(
      key: _keyInvestmentsFetch,
      data: DateTime.now().millisecondsSinceEpoch,
    );
  }

  void clearInvestmentCache() {
    HiveService.delete(_keyInvestments);
    HiveService.delete(_keyInvestmentsFetch);
  }

  // ─────────────────────────────────────────────────────────────
  // Harga aset cache
  // ─────────────────────────────────────────────────────────────

  bool isPriceCacheExpired(String assetType) {
    final key = assetType == 'btc' ? _keyBtcFetch : _keyGoldFetch;
    return _isExpired(key);
  }

  AssetPriceModel? getCachedPrice(String assetType) {
    final key = assetType == 'btc' ? _keyBtcPrice : _keyGoldPrice;
    final raw = HiveService.get<String>(key: key);
    if (raw == null) return null;

    return AssetPriceModel.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  void savePrice(AssetPriceModel price) {
    final dataKey = price.assetType == 'btc' ? _keyBtcPrice : _keyGoldPrice;
    final fetchKey = price.assetType == 'btc' ? _keyBtcFetch : _keyGoldFetch;

    HiveService.set<String>(key: dataKey, data: jsonEncode(price.toMap()));
    HiveService.set<int>(
      key: fetchKey,
      data: DateTime.now().millisecondsSinceEpoch,
    );
  }

  void clearPriceCache(String assetType) {
    final dataKey = assetType == 'btc' ? _keyBtcPrice : _keyGoldPrice;
    final fetchKey = assetType == 'btc' ? _keyBtcFetch : _keyGoldFetch;
    HiveService.delete(dataKey);
    HiveService.delete(fetchKey);
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────

  bool _isExpired(String fetchKey) {
    final lastFetch = HiveService.get<int>(key: fetchKey);
    if (lastFetch == null) return true;

    final lastFetchTime = DateTime.fromMillisecondsSinceEpoch(lastFetch);
    return DateTime.now().difference(lastFetchTime).inMinutes >= _ttlMinutes;
  }

  /// Konversi model ke Map JSON-serializable untuk cache.
  Map<String, dynamic> _investmentToCache(InvestmentModel inv) {
    return {
      'id': inv.id,
      'user_id': inv.userId,
      'type': inv.type.value,
      'name': inv.name,
      'symbol': inv.symbol,
      'amount': inv.amount,
      'avg_buy_price': inv.avgBuyPrice,
      'custom_current_price': inv.customCurrentPrice,
      'linked_wallet_id': inv.linkedWalletId,
      'notes': inv.notes,
      'created_at': inv.createdAt.toIso8601String(),
      'updated_at': inv.updatedAt.toIso8601String(),
    };
  }
}
