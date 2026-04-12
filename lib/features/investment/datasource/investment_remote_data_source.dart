import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/core/utils/saku_date_utils.dart';
import 'package:app_saku_rapi/features/investment/models/bitcoin_price_model.dart';
import 'package:app_saku_rapi/features/investment/models/custom_asset_category_model.dart';
import 'package:app_saku_rapi/features/investment/models/custom_gold_type_model.dart';
import 'package:app_saku_rapi/features/investment/models/gold_price_model.dart';
import 'package:app_saku_rapi/features/investment/models/investment_asset_model.dart';
import 'package:app_saku_rapi/features/investment/models/investment_transaction_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk operasi investasi di Supabase.
///
/// Semua request dibungkus [SupabaseHandler.call] agar return type
/// konsisten `DataState<T>`.
class InvestmentRemoteDataSource {
  InvestmentRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _tag = '[Investment] [InvestmentRemoteDataSource]';

  String get _userId => _client.auth.currentUser!.id;

  // ═══════════════════════════════════════════════════════════════
  // DASHBOARD
  // ═══════════════════════════════════════════════════════════════

  /// Ambil semua aset beserta data agregat via RPC.
  Future<DataState<List<InvestmentAssetModel>>> getDashboard() {
    return SupabaseHandler.call<List<InvestmentAssetModel>>(
      function: () async {
        AppLogger.call('$_tag getDashboard');
        final response = await _client.rpc('get_investment_dashboard');
        final List<dynamic> data = response as List<dynamic>;
        return data
            .map((e) => InvestmentAssetModel.fromMap(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ASSET CRUD via RPC
  // ═══════════════════════════════════════════════════════════════

  /// Buat aset baru + transaksi awal (atomic via RPC).
  Future<DataState<Map<String, dynamic>>> createAsset({
    required String type,
    required String name,
    String? goldType,
    String? customGoldTypeId,
    String? customCategoryId,
    String unitLabel = 'unit',
    String priceSource = 'manual',
    double currentPrice = 0,
    required double units,
    required double pricePerUnit,
    double fee = 0,
    DateTime? date,
    String? note,
    bool deductWallet = false,
    String? walletId,
  }) {
    return SupabaseHandler.call<Map<String, dynamic>>(
      function: () async {
        AppLogger.call('$_tag createAsset: $name ($type)');
        final response = await _client.rpc(
          'create_investment_asset',
          params: {
            'p_type': type,
            'p_name': name,
            'p_gold_type': goldType,
            'p_custom_gold_type_id': customGoldTypeId,
            'p_custom_category_id': customCategoryId,
            'p_unit_label': unitLabel,
            'p_price_source': priceSource,
            'p_current_price': currentPrice,
            'p_units': units,
            'p_price_per_unit': pricePerUnit,
            'p_fee': fee,
            'p_date': SakuDateUtils.formatTimestamp(date ?? DateTime.now()),
            'p_note': note,
            'p_deduct_wallet': deductWallet,
            'p_wallet_id': walletId,
          },
        );
        return response as Map<String, dynamic>;
      },
    );
  }

  /// Top up aset eksisting (tambah buy row) via RPC.
  Future<DataState<Map<String, dynamic>>> topupAsset({
    required String assetId,
    required double units,
    required double pricePerUnit,
    double fee = 0,
    DateTime? date,
    String? note,
    bool deductWallet = false,
    String? walletId,
  }) {
    return SupabaseHandler.call<Map<String, dynamic>>(
      function: () async {
        AppLogger.call('$_tag topupAsset: $assetId');
        final response = await _client.rpc(
          'topup_investment',
          params: {
            'p_asset_id': assetId,
            'p_units': units,
            'p_price_per_unit': pricePerUnit,
            'p_fee': fee,
            'p_date': SakuDateUtils.formatTimestamp(date ?? DateTime.now()),
            'p_note': note,
            'p_deduct_wallet': deductWallet,
            'p_wallet_id': walletId,
          },
        );
        return response as Map<String, dynamic>;
      },
    );
  }

  /// Jual unit aset via RPC.
  Future<DataState<Map<String, dynamic>>> sellAsset({
    required String assetId,
    required double units,
    required double pricePerUnit,
    DateTime? date,
    String? note,
    bool creditWallet = false,
    String? walletId,
  }) {
    return SupabaseHandler.call<Map<String, dynamic>>(
      function: () async {
        AppLogger.call('$_tag sellAsset: $assetId');
        final response = await _client.rpc(
          'sell_investment',
          params: {
            'p_asset_id': assetId,
            'p_units': units,
            'p_price_per_unit': pricePerUnit,
            'p_date': SakuDateUtils.formatTimestamp(date ?? DateTime.now()),
            'p_note': note,
            'p_credit_wallet': creditWallet,
            'p_wallet_id': walletId,
          },
        );
        return response as Map<String, dynamic>;
      },
    );
  }

  /// Edit transaksi buy via RPC.
  Future<DataState<Map<String, dynamic>>> editTransaction({
    required String transactionId,
    required double units,
    required double pricePerUnit,
    double fee = 0,
    DateTime? date,
    String? note,
    bool deductWallet = false,
    String? walletId,
  }) {
    return SupabaseHandler.call<Map<String, dynamic>>(
      function: () async {
        AppLogger.call('$_tag editTransaction: $transactionId');
        final response = await _client.rpc(
          'edit_investment_transaction',
          params: {
            'p_transaction_id': transactionId,
            'p_units': units,
            'p_price_per_unit': pricePerUnit,
            'p_fee': fee,
            'p_date': SakuDateUtils.formatTimestamp(date ?? DateTime.now()),
            'p_note': note,
            'p_deduct_wallet': deductWallet,
            'p_wallet_id': walletId,
          },
        );
        return response as Map<String, dynamic>;
      },
    );
  }

  /// Hapus transaksi buy via RPC.
  Future<DataState<Map<String, dynamic>>> deleteTransaction(
    String transactionId,
  ) {
    return SupabaseHandler.call<Map<String, dynamic>>(
      function: () async {
        AppLogger.call('$_tag deleteTransaction: $transactionId');
        final response = await _client.rpc(
          'delete_investment_transaction',
          params: {'p_transaction_id': transactionId},
        );
        return response as Map<String, dynamic>;
      },
    );
  }

  /// Hapus master aset beserta semua transaksi (CASCADE) via RPC.
  Future<DataState<Map<String, dynamic>>> deleteAsset({
    required String assetId,
    bool revertWallet = false,
  }) {
    return SupabaseHandler.call<Map<String, dynamic>>(
      function: () async {
        AppLogger.call('$_tag deleteAsset: $assetId revert=$revertWallet');
        final response = await _client.rpc(
          'delete_investment_asset',
          params: {'p_asset_id': assetId, 'p_revert_wallet': revertWallet},
        );
        return response as Map<String, dynamic>;
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ASSET SETTINGS UPDATE (direct table update, no RPC needed)
  // ═══════════════════════════════════════════════════════════════

  /// Update metadata aset (name, price_source, current_price, gold_type, dll).
  Future<DataState<InvestmentAssetModel>> updateAsset(
    InvestmentAssetModel asset,
  ) {
    return SupabaseHandler.call<InvestmentAssetModel>(
      function: () async {
        AppLogger.call('$_tag updateAsset: ${asset.id}');
        final response = await _client
            .from('investment_assets')
            .update(asset.toUpdateMap())
            .eq('id', asset.id)
            .select()
            .single();
        return InvestmentAssetModel.fromMap(response);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TRANSACTIONS (READ)
  // ═══════════════════════════════════════════════════════════════

  /// Ambil transaksi untuk satu aset, filter by direction.
  Future<DataState<List<InvestmentTransactionModel>>> getTransactions({
    required String assetId,
    String? direction,
  }) {
    return SupabaseHandler.call<List<InvestmentTransactionModel>>(
      function: () async {
        AppLogger.call('$_tag getTransactions: asset=$assetId dir=$direction');
        var query = _client
            .from('investment_transactions')
            .select()
            .eq('asset_id', assetId);

        if (direction != null) {
          query = query.eq('direction', direction);
        }

        final response = await query.order('date', ascending: false);
        return (response as List)
            .map(
              (e) =>
                  InvestmentTransactionModel.fromMap(e as Map<String, dynamic>),
            )
            .toList();
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PRICES
  // ═══════════════════════════════════════════════════════════════

  /// Ambil harga emas terbaru per source.
  Future<DataState<GoldPriceModel?>> getLatestGoldPrice(String source) {
    return SupabaseHandler.call<GoldPriceModel?>(
      function: () async {
        AppLogger.call('$_tag getLatestGoldPrice: $source');
        final response = await _client
            .from('gold_prices')
            .select()
            .eq('source', source)
            .order('fetched_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (response == null) return null;
        return GoldPriceModel.fromMap(response);
      },
    );
  }

  /// Ambil harga Bitcoin terbaru per source.
  Future<DataState<BitcoinPriceModel?>> getLatestBitcoinPrice(String source) {
    return SupabaseHandler.call<BitcoinPriceModel?>(
      function: () async {
        AppLogger.call('$_tag getLatestBitcoinPrice: $source');
        final response = await _client
            .from('bitcoin_prices')
            .select()
            .eq('source', source)
            .maybeSingle();

        if (response == null) return null;
        return BitcoinPriceModel.fromMap(response);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CUSTOM GOLD TYPES
  // ═══════════════════════════════════════════════════════════════

  /// Ambil semua jenis emas custom milik user.
  Future<DataState<List<CustomGoldTypeModel>>> getCustomGoldTypes() {
    return SupabaseHandler.call<List<CustomGoldTypeModel>>(
      function: () async {
        AppLogger.call('$_tag getCustomGoldTypes');
        final response = await _client
            .from('custom_gold_types')
            .select()
            .eq('user_id', _userId)
            .order('created_at');
        return (response as List)
            .map((e) => CustomGoldTypeModel.fromMap(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  /// Buat jenis emas custom baru.
  Future<DataState<CustomGoldTypeModel>> createCustomGoldType(String name) {
    return SupabaseHandler.call<CustomGoldTypeModel>(
      function: () async {
        AppLogger.call('$_tag createCustomGoldType: $name');
        final response = await _client
            .from('custom_gold_types')
            .insert({'user_id': _userId, 'name': name})
            .select()
            .single();
        return CustomGoldTypeModel.fromMap(response);
      },
    );
  }

  /// Update nama jenis emas custom.
  Future<DataState<CustomGoldTypeModel>> updateCustomGoldType({
    required String id,
    required String name,
  }) {
    return SupabaseHandler.call<CustomGoldTypeModel>(
      function: () async {
        AppLogger.call('$_tag updateCustomGoldType: $id');
        final response = await _client
            .from('custom_gold_types')
            .update({'name': name})
            .eq('id', id)
            .select()
            .single();
        return CustomGoldTypeModel.fromMap(response);
      },
    );
  }

  /// Hapus jenis emas custom.
  Future<DataState<void>> deleteCustomGoldType(String id) {
    return SupabaseHandler.call<void>(
      function: () async {
        AppLogger.call('$_tag deleteCustomGoldType: $id');
        await _client.from('custom_gold_types').delete().eq('id', id);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CUSTOM ASSET CATEGORIES
  // ═══════════════════════════════════════════════════════════════

  /// Ambil semua kategori aset custom milik user.
  Future<DataState<List<CustomAssetCategoryModel>>> getCustomAssetCategories() {
    return SupabaseHandler.call<List<CustomAssetCategoryModel>>(
      function: () async {
        AppLogger.call('$_tag getCustomAssetCategories');
        final response = await _client
            .from('custom_asset_categories')
            .select()
            .eq('user_id', _userId)
            .order('created_at');
        return (response as List)
            .map(
              (e) =>
                  CustomAssetCategoryModel.fromMap(e as Map<String, dynamic>),
            )
            .toList();
      },
    );
  }

  /// Buat kategori aset custom baru.
  Future<DataState<CustomAssetCategoryModel>> createCustomAssetCategory({
    required String name,
    required String unitLabel,
  }) {
    return SupabaseHandler.call<CustomAssetCategoryModel>(
      function: () async {
        AppLogger.call('$_tag createCustomAssetCategory: $name ($unitLabel)');
        final response = await _client
            .from('custom_asset_categories')
            .insert({'user_id': _userId, 'name': name, 'unit_label': unitLabel})
            .select()
            .single();
        return CustomAssetCategoryModel.fromMap(response);
      },
    );
  }

  /// Update kategori aset custom (nama + satuan).
  Future<DataState<CustomAssetCategoryModel>> updateCustomAssetCategory({
    required String id,
    required String name,
    required String unitLabel,
  }) {
    return SupabaseHandler.call<CustomAssetCategoryModel>(
      function: () async {
        AppLogger.call('$_tag updateCustomAssetCategory: $id');
        final response = await _client
            .from('custom_asset_categories')
            .update({'name': name, 'unit_label': unitLabel})
            .eq('id', id)
            .select()
            .single();
        return CustomAssetCategoryModel.fromMap(response);
      },
    );
  }

  /// Hapus kategori aset custom.
  Future<DataState<void>> deleteCustomAssetCategory(String id) {
    return SupabaseHandler.call<void>(
      function: () async {
        AppLogger.call('$_tag deleteCustomAssetCategory: $id');
        await _client.from('custom_asset_categories').delete().eq('id', id);
      },
    );
  }

  /// Update current_price pada aset (untuk manual input harga jual custom).
  Future<DataState<void>> updateCurrentPrice({
    required String assetId,
    required double price,
  }) {
    return SupabaseHandler.call<void>(
      function: () async {
        AppLogger.call('$_tag updateCurrentPrice: $assetId → $price');
        await _client
            .from('investment_assets')
            .update({'current_price': price})
            .eq('id', assetId);
      },
    );
  }
}
