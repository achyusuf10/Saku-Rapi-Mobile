import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/investment/datasources/investment_local_datasource.dart';
import 'package:app_saku_rapi/features/investment/datasources/investment_remote_datasource.dart';
import 'package:app_saku_rapi/features/investment/models/asset_price_model.dart';
import 'package:app_saku_rapi/features/investment/models/investment_model.dart';
import 'package:app_saku_rapi/features/investment/repositories/investment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────

/// Provider untuk [InvestmentRepository].
final investmentRepositoryProvider = Provider<InvestmentRepository>((ref) {
  return InvestmentRepository(
    remoteDataSource: InvestmentRemoteDataSource(),
    localDataSource: InvestmentLocalDataSource(),
  );
});

/// Provider utama untuk [InvestmentController].
///
/// State berupa `AsyncValue<InvestmentState>` yang memuat daftar investasi
/// beserta harga aset terkini (BTC dan Emas).
final investmentControllerProvider =
    AsyncNotifierProvider<InvestmentController, InvestmentState>(() {
      return InvestmentController();
    });

// ─────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────

/// State gabungan untuk halaman investasi.
class InvestmentState {
  const InvestmentState({
    this.investments = const [],
    this.btcPrice,
    this.goldPrice,
    this.isPriceRefreshing = false,
  });

  /// Daftar investasi milik user, sudah disuntik [livePrice].
  final List<InvestmentModel> investments;

  /// Harga Bitcoin terkini (null jika belum berhasil di-fetch).
  final AssetPriceModel? btcPrice;

  /// Harga Emas terkini per gram (null jika belum berhasil di-fetch).
  final AssetPriceModel? goldPrice;

  /// Sedang melakukan refresh harga di background.
  final bool isPriceRefreshing;

  // ── Computed ──

  /// Total nilai portofolio seluruh aset.
  double get totalPortfolioValue =>
      investments.fold(0.0, (sum, inv) => sum + inv.currentValue);

  /// Total profit/loss absolut (IDR).
  double get totalProfitLoss =>
      investments.fold(0.0, (sum, inv) => sum + inv.profitLoss);

  /// Total modal pembelian.
  double get totalBuyCost =>
      investments.fold(0.0, (sum, inv) => sum + inv.totalBuyCost);

  /// Persentase profit/loss keseluruhan.
  double get totalProfitLossPercentage =>
      totalBuyCost > 0 ? (totalProfitLoss / totalBuyCost * 100) : 0;

  bool get isOverallProfit => totalProfitLoss >= 0;

  InvestmentState copyWith({
    List<InvestmentModel>? investments,
    AssetPriceModel? btcPrice,
    AssetPriceModel? goldPrice,
    bool? isPriceRefreshing,
    bool clearBtcPrice = false,
    bool clearGoldPrice = false,
  }) {
    return InvestmentState(
      investments: investments ?? this.investments,
      btcPrice: clearBtcPrice ? null : (btcPrice ?? this.btcPrice),
      goldPrice: clearGoldPrice ? null : (goldPrice ?? this.goldPrice),
      isPriceRefreshing: isPriceRefreshing ?? this.isPriceRefreshing,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────

/// Riverpod [AsyncNotifier] untuk mengelola CRUD investasi dan harga aset.
class InvestmentController extends AsyncNotifier<InvestmentState> {
  late final InvestmentRepository _repository;

  static const String _tag = 'Investment';

  @override
  Future<InvestmentState> build() async {
    _repository = ref.watch(investmentRepositoryProvider);
    return _fetchAll();
  }

  /// Fetch investasi dan kedua harga aset secara paralel.
  Future<InvestmentState> _fetchAll({bool forceRefreshPrices = false}) async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    AppLogger.call(
      '[$_tag] Memuat investasi dan harga aset…',
      colorLog: ColorLog.blue,
    );

    final results = await Future.wait([
      _repository.getInvestments(userId: userId),
      _repository.getAssetPrice(
        assetType: 'btc',
        forceRefresh: forceRefreshPrices,
      ),
      _repository.getAssetPrice(
        assetType: 'gold',
        forceRefresh: forceRefreshPrices,
      ),
    ]);

    final investmentsResult = results[0] as DataState<List<InvestmentModel>>;
    final btcResult = results[1] as DataState<AssetPriceModel?>;
    final goldResult = results[2] as DataState<AssetPriceModel?>;

    final btcPrice = btcResult.dataSuccess() ?? btcResult.dataSuccess();
    final goldPrice = goldResult.dataSuccess() ?? goldResult.dataSuccess();

    List<InvestmentModel> investments = investmentsResult.isSuccess()
        ? investmentsResult.dataSuccess()!
        : [];

    // Suntikkan livePrice ke masing-masing investasi
    investments = _injectLivePrices(
      investments: investments,
      btcPrice: btcResult.dataSuccess(),
      goldPrice: goldResult.dataSuccess(),
    );

    AppLogger.call(
      '[$_tag] Loaded: ${investments.length} investasi, '
      'BTC=${btcPrice?.priceIdr}, Gold=${goldPrice?.priceIdr}',
      colorLog: ColorLog.green,
    );

    return InvestmentState(
      investments: investments,
      btcPrice: btcPrice,
      goldPrice: goldPrice,
    );
  }

  /// Menyuntikkan `livePrice` ke investasi berdasarkan tipe aset.
  List<InvestmentModel> _injectLivePrices({
    required List<InvestmentModel> investments,
    AssetPriceModel? btcPrice,
    AssetPriceModel? goldPrice,
  }) {
    return investments.map((inv) {
      switch (inv.type) {
        case InvestmentType.btc:
          return btcPrice != null
              ? inv.copyWith(livePrice: btcPrice.priceIdr)
              : inv.copyWith(clearLivePrice: true);
        case InvestmentType.gold:
          return goldPrice != null
              ? inv.copyWith(livePrice: goldPrice.priceIdr)
              : inv.copyWith(clearLivePrice: true);
        case InvestmentType.custom:
          // Custom selalu pakai customCurrentPrice (sudah di getter)
          return inv.copyWith(clearLivePrice: true);
      }
    }).toList();
  }

  /// Refresh penuh (investasi + harga).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchAll());
  }

  /// Refresh harga aset saja (tanpa reload investasi), jalankan di background.
  Future<void> refreshPrices() async {
    final currentData = state.value;
    if (currentData == null) return;

    // Tandai sedang refresh harga
    state = AsyncData(currentData.copyWith(isPriceRefreshing: true));

    final results = await Future.wait([
      _repository.getAssetPrice(assetType: 'btc', forceRefresh: true),
      _repository.getAssetPrice(assetType: 'gold', forceRefresh: true),
    ]);

    final btcResult = results[0];
    final goldResult = results[1];

    final latestState = state.value ?? currentData;
    final investments = _injectLivePrices(
      investments: latestState.investments,
      btcPrice: btcResult.dataSuccess(),
      goldPrice: goldResult.dataSuccess(),
    );

    state = AsyncData(
      latestState.copyWith(
        investments: investments,
        btcPrice: btcResult.dataSuccess() ?? latestState.btcPrice,
        goldPrice: goldResult.dataSuccess() ?? latestState.goldPrice,
        isPriceRefreshing: false,
      ),
    );
  }

  /// Menambah investasi baru.
  Future<DataState<InvestmentModel>> addInvestment({
    required InvestmentModel investment,
    required bool deductFromWallet,
    String? walletId,
    required String userId,
  }) async {
    final result = await _repository.addInvestment(
      investment: investment,
      deductFromWallet: deductFromWallet,
      walletId: walletId,
      userId: userId,
    );

    if (result.isSuccess()) {
      await refresh();
    }

    return result;
  }

  /// Memperbarui investasi yang sudah ada.
  Future<DataState<InvestmentModel>> editInvestment(
    InvestmentModel investment,
  ) async {
    final result = await _repository.updateInvestment(investment);

    if (result.isSuccess()) {
      await refresh();
    }

    return result;
  }

  /// Menghapus investasi.
  Future<DataState<void>> removeInvestment(String id) async {
    final result = await _repository.deleteInvestment(id);

    if (result.isSuccess()) {
      await refresh();
    }

    return result;
  }
}
