import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/investment/datasources/investment_local_datasource.dart';
import 'package:app_saku_rapi/features/investment/datasources/investment_remote_datasource.dart';
import 'package:app_saku_rapi/features/investment/models/asset_price_model.dart';
import 'package:app_saku_rapi/features/investment/models/investment_model.dart';

/// Repository untuk fitur investasi.
///
/// Mengorkestrasi [InvestmentRemoteDataSource] (Supabase + API)
/// dan [InvestmentLocalDataSource] (cache Hive).
class InvestmentRepository {
  InvestmentRepository({
    required InvestmentRemoteDataSource remoteDataSource,
    required InvestmentLocalDataSource localDataSource,
  }) : _remote = remoteDataSource,
       _local = localDataSource;

  final InvestmentRemoteDataSource _remote;
  final InvestmentLocalDataSource _local;

  static const String _tag = 'InvestmentRepo';

  // ─────────────────────────────────────────────────────────────
  // Investasi CRUD
  // ─────────────────────────────────────────────────────────────

  /// Mengambil semua investasi milik [userId].
  ///
  /// Jika remote gagal, fallback ke cache Hive.
  Future<DataState<List<InvestmentModel>>> getInvestments({
    required String userId,
  }) async {
    final result = await _remote.getInvestments(userId: userId);

    if (result.isSuccess()) {
      final investments = result.dataSuccess()!;
      _local.saveInvestments(investments);
      AppLogger.call(
        '[$_tag] Memuat ${investments.length} investasi',
        colorLog: ColorLog.green,
      );
      return DataState<List<InvestmentModel>>.success(data: investments);
    }

    // Remote gagal — coba cache
    final cached = _local.getCachedInvestments();
    if (cached.isNotEmpty) {
      AppLogger.call(
        '[$_tag] Remote gagal, fallback cache: ${cached.length} investasi',
        colorLog: ColorLog.yellow,
      );
      return DataState<List<InvestmentModel>>.success(data: cached);
    }

    final error = result.dataError()!;
    AppLogger.logError(
      '[$_tag] Gagal memuat investasi: ${error.$1}',
      runtimeType: InvestmentRepository,
    );
    return DataState<List<InvestmentModel>>.error(message: error.$1);
  }

  /// Menambah investasi baru dan opsional memotong saldo dompet.
  ///
  /// Jika [deductFromWallet] true dan [walletId] diberikan,
  /// akan di-INSERT satu transaksi `transfer_to_asset` ke DB,
  /// yang secara otomatis mengurangi saldo dompet via trigger.
  Future<DataState<InvestmentModel>> addInvestment({
    required InvestmentModel investment,
    required bool deductFromWallet,
    String? walletId,
    required String userId,
  }) async {
    final result = await _remote.createInvestment(investment);

    if (result.isError()) {
      final error = result.dataError()!;
      AppLogger.logError(
        '[$_tag] Gagal menambah investasi: ${error.$1}',
        runtimeType: InvestmentRepository,
      );
      return DataState<InvestmentModel>.error(message: error.$1);
    }

    final created = result.dataSuccess()!;

    if (deductFromWallet && walletId != null) {
      final totalCost = investment.amount * investment.avgBuyPrice;
      final deductResult = await _remote.deductFromWallet(
        userId: userId,
        walletId: walletId,
        totalAmount: totalCost,
        assetName: investment.name,
      );

      if (deductResult.isError()) {
        AppLogger.logError(
          '[$_tag] Investasi dibuat tapi pemotongan dompet gagal',
          runtimeType: InvestmentRepository,
        );
      }
    }

    _local.clearInvestmentCache();
    AppLogger.logSuccess('[$_tag] Investasi berhasil ditambahkan');
    return DataState<InvestmentModel>.success(data: created);
  }

  /// Memperbarui investasi yang sudah ada.
  Future<DataState<InvestmentModel>> updateInvestment(
    InvestmentModel investment,
  ) async {
    final result = await _remote.updateInvestment(investment);

    if (result.isError()) {
      final error = result.dataError()!;
      AppLogger.logError(
        '[$_tag] Gagal memperbarui investasi: ${error.$1}',
        runtimeType: InvestmentRepository,
      );
      return DataState<InvestmentModel>.error(message: error.$1);
    }

    _local.clearInvestmentCache();
    AppLogger.logSuccess('[$_tag] Investasi berhasil diperbarui');
    return DataState<InvestmentModel>.success(data: result.dataSuccess()!);
  }

  /// Menghapus investasi berdasarkan [id].
  Future<DataState<void>> deleteInvestment(String id) async {
    final result = await _remote.deleteInvestment(id);

    if (result.isError()) {
      final error = result.dataError()!;
      AppLogger.logError(
        '[$_tag] Gagal menghapus investasi: ${error.$1}',
        runtimeType: InvestmentRepository,
      );
      return DataState<void>.error(message: error.$1);
    }

    _local.clearInvestmentCache();
    AppLogger.logSuccess('[$_tag] Investasi berhasil dihapus');
    return const DataState<void>.success(data: null);
  }

  // ─────────────────────────────────────────────────────────────
  // Harga aset
  // ─────────────────────────────────────────────────────────────

  /// Mengambil harga aset dari cache (jika masih valid) atau dari API.
  ///
  /// Jika [forceRefresh] true, selalu fetch dari API dan perbarui cache.
  /// Jika API gagal, fallback ke cache lama (meskipun sudah expired).
  Future<DataState<AssetPriceModel?>> getAssetPrice({
    required String assetType,
    bool forceRefresh = false,
  }) async {
    // Gunakan cache jika masih valid dan tidak diminta force-refresh
    if (!forceRefresh && !_local.isPriceCacheExpired(assetType)) {
      final cached = _local.getCachedPrice(assetType);
      if (cached != null) {
        AppLogger.call(
          '[$_tag] Menggunakan cache harga $assetType',
          colorLog: ColorLog.blue,
        );
        return DataState<AssetPriceModel?>.success(data: cached);
      }
    }

    // Fetch dari API
    final result = assetType == 'btc'
        ? await _remote.fetchBtcPriceFromApi()
        : await _remote.fetchGoldPriceFromApi();

    if (result.isSuccess()) {
      final price = result.dataSuccess()!;
      _local.savePrice(price);
      return DataState<AssetPriceModel?>.success(data: price);
    }

    // API gagal — fallback ke cache lama jika ada
    final staleCache = _local.getCachedPrice(assetType);
    if (staleCache != null) {
      AppLogger.call(
        '[$_tag] API harga $assetType gagal, pakai cache lama',
        colorLog: ColorLog.yellow,
      );
      return DataState<AssetPriceModel?>.success(data: staleCache);
    }

    final error = result.dataError()!;
    AppLogger.logError(
      '[$_tag] Gagal memuat harga $assetType: ${error.$1}',
      runtimeType: InvestmentRepository,
    );
    return DataState<AssetPriceModel?>.success(data: null);
  }
}
