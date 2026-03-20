import 'dart:convert';
import 'dart:io';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/investment/models/asset_price_model.dart';
import 'package:app_saku_rapi/features/investment/models/investment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk semua operasi Supabase terkait investasi.
///
/// Harga BTC diambil dari CoinGecko free API (no key).
/// Harga Emas diambil dari goldprice.org (no key, best-effort).
class InvestmentRemoteDataSource {
  InvestmentRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _table = 'investments';
  static const String _txTable = 'transactions';
  static const String _tag = 'Investment';

  // ─────────────────────────────────────────────────────────────
  // CRUD
  // ─────────────────────────────────────────────────────────────

  Future<DataState<List<InvestmentModel>>> getInvestments({
    required String userId,
  }) {
    return SupabaseHandler.call<List<InvestmentModel>>(
      function: () async {
        final response = await _client
            .from(_table)
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        return (response as List<dynamic>)
            .map((e) => InvestmentModel.fromMap(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<DataState<InvestmentModel>> createInvestment(
    InvestmentModel investment,
  ) {
    return SupabaseHandler.call<InvestmentModel>(
      function: () async {
        final response = await _client
            .from(_table)
            .insert(investment.toMap())
            .select()
            .single();

        return InvestmentModel.fromMap(response);
      },
    );
  }

  Future<DataState<InvestmentModel>> updateInvestment(
    InvestmentModel investment,
  ) {
    return SupabaseHandler.call<InvestmentModel>(
      function: () async {
        final response = await _client
            .from(_table)
            .update(investment.toMap())
            .eq('id', investment.id)
            .select()
            .single();

        return InvestmentModel.fromMap(response);
      },
    );
  }

  Future<DataState<void>> deleteInvestment(String id) {
    return SupabaseHandler.call<void>(
      function: () async {
        await _client.from(_table).delete().eq('id', id);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Wallet deduction (via trigger DB)
  // ─────────────────────────────────────────────────────────────

  /// Memotong saldo dompet dengan insert transaksi tipe `transfer_to_asset`.
  ///
  /// Trigger DB `trg_update_wallet_balance` secara otomatis mengurangi
  /// saldo dompet saat transaksi bertipe ini di-INSERT.
  Future<DataState<void>> deductFromWallet({
    required String userId,
    required String walletId,
    required double totalAmount,
    required String assetName,
  }) {
    return SupabaseHandler.call<void>(
      function: () async {
        await _client.from(_txTable).insert({
          'user_id': userId,
          'wallet_id': walletId,
          'type': 'transfer_to_asset',
          'total_amount': totalAmount,
          'date': DateTime.now().toIso8601String(),
          'note': 'Pembelian $assetName',
          'is_multi_item': false,
        });

        AppLogger.call(
          '[$_tag] Saldo dompet dipotong: Rp${totalAmount.toStringAsFixed(0)}',
          colorLog: ColorLog.green,
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Live price API
  // ─────────────────────────────────────────────────────────────

  /// Mengambil harga BTC/IDR dari CoinGecko free API.
  Future<DataState<AssetPriceModel>> fetchBtcPriceFromApi() {
    return SupabaseHandler.call<AssetPriceModel>(
      function: () async {
        final client = HttpClient();
        try {
          final uri = Uri.parse(
            'https://api.coingecko.com/api/v3/simple/price'
            '?ids=bitcoin&vs_currencies=idr',
          );
          final request = await client.getUrl(uri);
          request.headers.set('Accept', 'application/json');

          final response = await request.close();

          if (response.statusCode != 200) {
            throw Exception('CoinGecko API error: HTTP ${response.statusCode}');
          }

          final body = await response.transform(utf8.decoder).join();
          final data = jsonDecode(body) as Map<String, dynamic>;
          final price = (data['bitcoin']['idr'] as num).toDouble();

          AppLogger.call(
            '[$_tag] BTC/IDR = Rp${price.toStringAsFixed(0)}',
            colorLog: ColorLog.green,
          );

          return AssetPriceModel(
            assetType: 'btc',
            priceIdr: price,
            fetchedAt: DateTime.now(),
          );
        } finally {
          client.close(force: false);
        }
      },
    );
  }

  /// Mengambil harga Emas/IDR per gram dari goldprice.org.
  ///
  /// Jika API gagal, mengembalikan [DataState.error] sehingga
  /// controller bisa fallback ke [InvestmentModel.customCurrentPrice].
  ///
  /// **Konversi:** goldprice.org mengembalikan harga per troy ounce (31.1g).
  Future<DataState<AssetPriceModel>> fetchGoldPriceFromApi() {
    return SupabaseHandler.call<AssetPriceModel>(
      function: () async {
        final client = HttpClient();
        try {
          final uri = Uri.parse(
            'https://data-asg.goldprice.org/GetData/XAU-IDR/1',
          );
          final request = await client.getUrl(uri);
          request.headers.set('Accept', 'application/json');
          request.headers.set('X-Requested-With', 'XMLHttpRequest');

          final response = await request.close();

          if (response.statusCode != 200) {
            throw Exception('GoldPrice API error: HTTP ${response.statusCode}');
          }

          final body = await response.transform(utf8.decoder).join();
          final data = jsonDecode(body) as Map<String, dynamic>;

          // payload[1] = ask price per troy ounce dalam IDR
          final payload = data['payload'] as List<dynamic>;
          final rawPrice = payload[1].toString().replaceAll(',', '');
          final pricePerOunce = double.parse(rawPrice);

          // 1 troy ounce = 31.1034768 gram
          const gramsPerOunce = 31.1034768;
          final pricePerGram = pricePerOunce / gramsPerOunce;

          AppLogger.call(
            '[$_tag] Emas/IDR = Rp${pricePerGram.toStringAsFixed(0)}/gram',
            colorLog: ColorLog.green,
          );

          return AssetPriceModel(
            assetType: 'gold',
            priceIdr: pricePerGram,
            fetchedAt: DateTime.now(),
          );
        } finally {
          client.close(force: false);
        }
      },
    );
  }
}
