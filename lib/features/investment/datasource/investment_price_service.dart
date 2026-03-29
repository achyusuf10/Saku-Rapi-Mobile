import 'dart:convert';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service untuk mengambil harga live investasi (Bitcoin & Emas).
///
/// - Bitcoin: CoinGecko free API (IDR) + TTL cache 12 jam di Hive
/// - Emas: Supabase Edge Function `gold-price` (server-side 1-day cache)
///   Flutter hanya menyimpan Hive fallback untuk offline.
class InvestmentPriceService {
  InvestmentPriceService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _tag = '[Investment] [PriceService]';

  /// TTL cache BTC: 12 jam.
  static const _btcTtlMs = 12 * 60 * 60 * 1000; // 43_200_000

  // ─── Hive cache keys ───
  static const _btcPriceKey = 'investment_btc_price';
  static const _btcTimestampKey = 'investment_btc_timestamp';
  static const _goldPriceKey = 'investment_gold_price';

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
      final cached = _getCachedBtcPrice();
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
          _cacheBtcPrice(price);
          AppLogger.call('$_tag BTC price fetched: $price');
          return price;
        }
      }

      AppLogger.call('$_tag CoinGecko returned status ${response.statusCode}');
    } catch (e) {
      AppLogger.call('$_tag CoinGecko error: $e');
    }

    // Fallback: harga terakhir dari Hive (offline)
    return HiveService.get<double>(key: _btcPriceKey);
  }

  /// Ambil harga Emas Antam (buyback) per gram dalam IDR.
  ///
  /// Edge Function `gold-price` sudah menerapkan server-side 1-day cache
  /// di tabel `gold_prices_cache`. Flutter TIDAK perlu TTL sendiri —
  /// cukup panggil Edge Function, dan simpan hasilnya di Hive sebagai
  /// fallback offline.
  Future<double?> getGoldPriceIDR({bool forceRefresh = false}) async {
    try {
      AppLogger.call('$_tag Fetching gold price from Edge Function...');
      final response = await _client.functions.invoke('gold-price', body: {});

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>?;
        if (data != null && data['success'] == true) {
          final price = _toDouble(data['price_per_gram_idr']);
          final cached = data['cached'] == true;

          if (price > 0) {
            // Simpan ke Hive untuk fallback offline
            HiveService.set<double>(key: _goldPriceKey, data: price);
            AppLogger.call(
              '$_tag Gold price fetched: $price'
              '${cached ? ' (server cache)' : ' (fresh from AI)'}',
            );
            return price;
          }
        }
      }

      AppLogger.call('$_tag Gold Edge Function returned unexpected result');
    } catch (e) {
      AppLogger.call('$_tag Gold Edge Function error: $e');
    }

    // Fallback: harga terakhir dari Hive (offline)
    final fallback = HiveService.get<double>(key: _goldPriceKey);
    if (fallback != null) {
      AppLogger.call('$_tag Gold price from offline cache: $fallback');
    }
    return fallback;
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
  // CACHE HELPERS (BTC only — gold cache is server-side)
  // ═══════════════════════════════════════════════════

  /// Ambil harga BTC dari cache jika belum expired (TTL 12 jam).
  double? _getCachedBtcPrice() {
    final cachedTimestamp = HiveService.get<int>(key: _btcTimestampKey);
    if (cachedTimestamp == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - cachedTimestamp > _btcTtlMs) return null; // Expired

    return HiveService.get<double>(key: _btcPriceKey);
  }

  /// Simpan harga BTC ke cache beserta timestamp.
  void _cacheBtcPrice(double price) {
    HiveService.set<double>(key: _btcPriceKey, data: price);
    HiveService.set<int>(
      key: _btcTimestampKey,
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
