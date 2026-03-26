import 'dart:convert';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service untuk mengambil harga live investasi (Bitcoin & Emas).
///
/// - Bitcoin: CoinGecko free API (IDR)
/// - Emas: Supabase Edge Function `gold-price` (AI scraping)
/// - TTL cache 12 jam di Hive
class InvestmentPriceService {
  InvestmentPriceService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _tag = '[Investment] [PriceService]';

  /// TTL cache: 12 jam.
  static const _ttlMs = 12 * 60 * 60 * 1000; // 43_200_000

  // ─── Hive cache keys ───
  static const _btcPriceKey = 'investment_btc_price';
  static const _btcTimestampKey = 'investment_btc_timestamp';
  static const _goldPriceKey = 'investment_gold_price';
  static const _goldTimestampKey = 'investment_gold_timestamp';

  // ─── CoinGecko ───
  static const _coinGeckoUrl =
      'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=idr';

  // ═══════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════

  /// Ambil harga Bitcoin per 1 BTC dalam IDR.
  ///
  /// Cek cache dulu (TTL 12 jam), jika expired fetch dari CoinGecko.
  /// Jika gagal, return harga terakhir dari cache (atau null).
  Future<double?> getBitcoinPriceIDR({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _getCachedPrice(_btcPriceKey, _btcTimestampKey);
      if (cached != null) {
        AppLogger.call('$_tag BTC price from cache: $cached');
        return cached;
      }
    }

    try {
      AppLogger.call('$_tag Fetching BTC price from CoinGecko...');
      final response = await http
          .get(Uri.parse(_coinGeckoUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final btcData = data['bitcoin'] as Map<String, dynamic>?;
        final price = _toDouble(btcData?['idr']);

        if (price > 0) {
          _cachePrice(_btcPriceKey, _btcTimestampKey, price);
          AppLogger.call('$_tag BTC price fetched: $price');
          return price;
        }
      }

      AppLogger.call('$_tag CoinGecko returned status ${response.statusCode}');
    } catch (e) {
      AppLogger.call('$_tag CoinGecko error: $e');
    }

    // Fallback ke cache terakhir (tanpa TTL check)
    return _getLastCachedPrice(_btcPriceKey);
  }

  /// Ambil harga Emas per gram dalam IDR.
  ///
  /// Cek cache dulu (TTL 12 jam), jika expired fetch dari Edge Function.
  /// Jika gagal, return harga terakhir dari cache (atau null).
  Future<double?> getGoldPriceIDR({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _getCachedPrice(_goldPriceKey, _goldTimestampKey);
      if (cached != null) {
        AppLogger.call('$_tag Gold price from cache: $cached');
        return cached;
      }
    }

    try {
      AppLogger.call('$_tag Fetching gold price from Edge Function...');
      final response = await _client.functions.invoke('gold-price', body: {});

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>?;
        if (data != null && data['success'] == true) {
          final price = _toDouble(data['price_per_gram_idr']);

          if (price > 0) {
            _cachePrice(_goldPriceKey, _goldTimestampKey, price);
            AppLogger.call('$_tag Gold price fetched: $price');
            return price;
          }
        }
      }

      AppLogger.call('$_tag Gold Edge Function returned unexpected result');
    } catch (e) {
      AppLogger.call('$_tag Gold Edge Function error: $e');
    }

    // Fallback ke cache terakhir (tanpa TTL check)
    return _getLastCachedPrice(_goldPriceKey);
  }

  /// Ambil semua harga live sekaligus.
  ///
  /// Returns map: `{'crypto': btcPrice, 'gold': goldPrice}`.
  /// Value null jika gagal fetch dan tidak ada cache.
  Future<Map<String, double?>> fetchAllPrices({
    bool forceRefresh = false,
  }) async {
    final results = await Future.wait([
      getBitcoinPriceIDR(forceRefresh: forceRefresh),
      getGoldPriceIDR(forceRefresh: forceRefresh),
    ]);

    return {'crypto': results[0], 'gold': results[1]};
  }

  // ═══════════════════════════════════════════════════
  // CACHE HELPERS
  // ═══════════════════════════════════════════════════

  /// Ambil harga dari cache jika belum expired (TTL 12 jam).
  double? _getCachedPrice(String priceKey, String timestampKey) {
    final cachedTimestamp = HiveService.get<int>(key: timestampKey);
    if (cachedTimestamp == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - cachedTimestamp > _ttlMs) return null; // Expired

    final cachedPrice = HiveService.get<double>(key: priceKey);
    return cachedPrice;
  }

  /// Ambil harga terakhir dari cache (ignoring TTL) — fallback.
  double? _getLastCachedPrice(String priceKey) {
    return HiveService.get<double>(key: priceKey);
  }

  /// Simpan harga ke cache beserta timestamp.
  void _cachePrice(String priceKey, String timestampKey, double price) {
    HiveService.set<double>(key: priceKey, data: price);
    HiveService.set<int>(
      key: timestampKey,
      data: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Helper konversi ke double.
  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
