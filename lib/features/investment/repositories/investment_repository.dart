import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/investment/datasource/investment_local_data_source.dart';
import 'package:app_saku_rapi/features/investment/datasource/investment_remote_data_source.dart';
import 'package:app_saku_rapi/features/investment/models/bitcoin_price_model.dart';
import 'package:app_saku_rapi/features/investment/models/custom_asset_category_model.dart';
import 'package:app_saku_rapi/features/investment/models/custom_gold_type_model.dart';
import 'package:app_saku_rapi/features/investment/models/gold_price_model.dart';
import 'package:app_saku_rapi/features/investment/models/investment_asset_model.dart';
import 'package:app_saku_rapi/features/investment/models/investment_transaction_model.dart';

/// Repository utama untuk fitur investasi.
///
/// Mengorkestrasikan [InvestmentRemoteDataSource] dan [InvestmentLocalDataSource]:
/// - Online: fetch dari Supabase, cache ke Hive.
/// - Offline fallback: sajikan dari Hive cache.
class InvestmentRepository {
  InvestmentRepository({
    InvestmentRemoteDataSource? remoteDataSource,
    InvestmentLocalDataSource? localDataSource,
  }) : _remote = remoteDataSource ?? InvestmentRemoteDataSource(),
       _local = localDataSource ?? InvestmentLocalDataSource();

  final InvestmentRemoteDataSource _remote;
  final InvestmentLocalDataSource _local;

  static const _tag = '[Investment] [InvestmentRepository]';

  // ═══════════════════════════════════════════════════════════════
  // DASHBOARD
  // ═══════════════════════════════════════════════════════════════

  /// Ambil semua aset + data agregat. Fallback ke cache jika gagal.
  Future<DataState<List<InvestmentAssetModel>>> getDashboard() async {
    final result = await _remote.getDashboard();

    if (result.isSuccess()) {
      final assets = result.dataSuccess()!;
      _local.cacheDashboard(assets);
      return result;
    }

    // Offline fallback
    final cached = _local.getCachedDashboard();
    if (cached != null) {
      AppLogger.call('$_tag getDashboard: serving from cache');
      return DataState.success(data: cached);
    }

    return result;
  }

  // ═══════════════════════════════════════════════════════════════
  // ASSET CRUD
  // ═══════════════════════════════════════════════════════════════

  /// Buat aset baru + first buy transaction (atomic).
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
  }) async {
    return _remote.createAsset(
      type: type,
      name: name,
      goldType: goldType,
      customGoldTypeId: customGoldTypeId,
      customCategoryId: customCategoryId,
      unitLabel: unitLabel,
      priceSource: priceSource,
      currentPrice: currentPrice,
      units: units,
      pricePerUnit: pricePerUnit,
      fee: fee,
      date: date,
      note: note,
      deductWallet: deductWallet,
      walletId: walletId,
    );
  }

  /// Top up aset eksisting.
  Future<DataState<Map<String, dynamic>>> topupAsset({
    required String assetId,
    required double units,
    required double pricePerUnit,
    double fee = 0,
    DateTime? date,
    String? note,
    bool deductWallet = false,
    String? walletId,
  }) async {
    return _remote.topupAsset(
      assetId: assetId,
      units: units,
      pricePerUnit: pricePerUnit,
      fee: fee,
      date: date,
      note: note,
      deductWallet: deductWallet,
      walletId: walletId,
    );
  }

  /// Jual unit aset.
  Future<DataState<Map<String, dynamic>>> sellAsset({
    required String assetId,
    required double units,
    required double pricePerUnit,
    DateTime? date,
    String? note,
    bool creditWallet = false,
    String? walletId,
  }) async {
    return _remote.sellAsset(
      assetId: assetId,
      units: units,
      pricePerUnit: pricePerUnit,
      date: date,
      note: note,
      creditWallet: creditWallet,
      walletId: walletId,
    );
  }

  /// Edit transaksi buy.
  Future<DataState<Map<String, dynamic>>> editTransaction({
    required String transactionId,
    required double units,
    required double pricePerUnit,
    double fee = 0,
    DateTime? date,
    String? note,
    bool deductWallet = false,
    String? walletId,
  }) async {
    return _remote.editTransaction(
      transactionId: transactionId,
      units: units,
      pricePerUnit: pricePerUnit,
      fee: fee,
      date: date,
      note: note,
      deductWallet: deductWallet,
      walletId: walletId,
    );
  }

  /// Hapus transaksi buy.
  Future<DataState<Map<String, dynamic>>> deleteTransaction(
    String transactionId,
  ) async {
    return _remote.deleteTransaction(transactionId);
  }

  /// Hapus master aset beserta semua transaksi.
  Future<DataState<Map<String, dynamic>>> deleteAsset({
    required String assetId,
    bool revertWallet = false,
  }) async {
    return _remote.deleteAsset(assetId: assetId, revertWallet: revertWallet);
  }

  /// Update metadata aset (settings).
  Future<DataState<InvestmentAssetModel>> updateAsset(
    InvestmentAssetModel asset,
  ) async {
    return _remote.updateAsset(asset);
  }

  /// Update current_price pada aset (manual input harga jual custom).
  Future<DataState<void>> updateCurrentPrice({
    required String assetId,
    required double price,
  }) async {
    return _remote.updateCurrentPrice(assetId: assetId, price: price);
  }

  // ═══════════════════════════════════════════════════════════════
  // TRANSACTIONS
  // ═══════════════════════════════════════════════════════════════

  /// Ambil transaksi untuk satu aset.
  Future<DataState<List<InvestmentTransactionModel>>> getTransactions({
    required String assetId,
    String? direction,
  }) async {
    return _remote.getTransactions(assetId: assetId, direction: direction);
  }

  // ═══════════════════════════════════════════════════════════════
  // PRICES
  // ═══════════════════════════════════════════════════════════════

  /// Ambil harga emas terbaru.
  Future<DataState<GoldPriceModel?>> getLatestGoldPrice(String source) async {
    return _remote.getLatestGoldPrice(source);
  }

  /// Ambil harga Bitcoin terbaru.
  Future<DataState<BitcoinPriceModel?>> getLatestBitcoinPrice(
    String source,
  ) async {
    return _remote.getLatestBitcoinPrice(source);
  }

  // ═══════════════════════════════════════════════════════════════
  // CUSTOM GOLD TYPES
  // ═══════════════════════════════════════════════════════════════

  Future<DataState<List<CustomGoldTypeModel>>> getCustomGoldTypes() async {
    return _remote.getCustomGoldTypes();
  }

  Future<DataState<CustomGoldTypeModel>> createCustomGoldType(
    String name,
  ) async {
    return _remote.createCustomGoldType(name);
  }

  Future<DataState<CustomGoldTypeModel>> updateCustomGoldType({
    required String id,
    required String name,
  }) async {
    return _remote.updateCustomGoldType(id: id, name: name);
  }

  Future<DataState<void>> deleteCustomGoldType(String id) async {
    return _remote.deleteCustomGoldType(id);
  }

  // ═══════════════════════════════════════════════════════════════
  // CUSTOM ASSET CATEGORIES
  // ═══════════════════════════════════════════════════════════════

  Future<DataState<List<CustomAssetCategoryModel>>>
  getCustomAssetCategories() async {
    return _remote.getCustomAssetCategories();
  }

  Future<DataState<CustomAssetCategoryModel>> createCustomAssetCategory({
    required String name,
    required String unitLabel,
  }) async {
    return _remote.createCustomAssetCategory(name: name, unitLabel: unitLabel);
  }

  Future<DataState<CustomAssetCategoryModel>> updateCustomAssetCategory({
    required String id,
    required String name,
    required String unitLabel,
  }) async {
    return _remote.updateCustomAssetCategory(
      id: id,
      name: name,
      unitLabel: unitLabel,
    );
  }

  Future<DataState<void>> deleteCustomAssetCategory(String id) async {
    return _remote.deleteCustomAssetCategory(id);
  }

  // ═══════════════════════════════════════════════════════════════
  // CACHE
  // ═══════════════════════════════════════════════════════════════

  void clearCache() {
    _local.clearDashboardCache();
  }

  void cacheDashboard(List<InvestmentAssetModel> assets) {
    _local.cacheDashboard(assets);
  }
}
