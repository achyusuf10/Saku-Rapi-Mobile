import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/investment/models/bitcoin_price_model.dart';
import 'package:app_saku_rapi/features/investment/models/custom_asset_category_model.dart';
import 'package:app_saku_rapi/features/investment/models/custom_gold_type_model.dart';
import 'package:app_saku_rapi/features/investment/models/gold_price_model.dart';
import 'package:app_saku_rapi/features/investment/models/investment_asset_model.dart';
import 'package:app_saku_rapi/features/investment/models/investment_transaction_model.dart';
import 'package:app_saku_rapi/features/investment/repositories/investment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ═══════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════

/// Singleton repository.
final investmentRepositoryProvider = Provider<InvestmentRepository>((ref) {
  return InvestmentRepository();
});

/// Dashboard (list aset + data agregat).
final investmentControllerProvider =
    StateNotifierProvider<InvestmentController, InvestmentState>((ref) {
      final repository = ref.watch(investmentRepositoryProvider);
      return InvestmentController(repository);
    });

/// Centralized prices controller - load semua harga sekaligus.
final investmentPricesProvider =
    StateNotifierProvider<InvestmentPricesController, InvestmentPricesState>((
      ref,
    ) {
      final repository = ref.watch(investmentRepositoryProvider);
      return InvestmentPricesController(repository);
    });

/// Total portofolio dengan harga efektif (sync, dari prices controller).
final investmentTotalValueProvider = Provider<double>((ref) {
  final state = ref.watch(investmentControllerProvider);
  final prices = ref.watch(investmentPricesProvider);
  if (state.status != InvestmentStatus.loaded) return 0;

  return state.activeAssets.fold(0.0, (sum, asset) {
    final effectivePrice = prices.getEffectivePrice(asset);
    return sum + (asset.totalUnits * effectivePrice);
  });
});

/// Total modal (semua aset aktif).
final investmentTotalInvestedProvider = Provider<double>((ref) {
  final state = ref.watch(investmentControllerProvider);
  if (state.status != InvestmentStatus.loaded) return 0;
  return state.activeAssets.fold(0.0, (sum, a) => sum + a.totalInvested);
});

/// Total profit/loss.
final investmentProfitLossProvider = Provider<double>((ref) {
  return ref.watch(investmentTotalValueProvider) -
      ref.watch(investmentTotalInvestedProvider);
});

/// Aset aktif saja.
final activeInvestmentAssetsProvider = Provider<List<InvestmentAssetModel>>((
  ref,
) {
  final state = ref.watch(investmentControllerProvider);
  return state.activeAssets;
});

/// Aset inaktif saja.
final inactiveInvestmentAssetsProvider = Provider<List<InvestmentAssetModel>>((
  ref,
) {
  final state = ref.watch(investmentControllerProvider);
  return state.inactiveAssets;
});

/// Transaksi per aset (di-manage per detail page).
final investmentTransactionsProvider =
    StateNotifierProvider.family<
      InvestmentTransactionsController,
      InvestmentTransactionsState,
      String
    >((ref, assetId) {
      final repository = ref.watch(investmentRepositoryProvider);
      return InvestmentTransactionsController(repository, assetId);
    });

/// Custom gold types.
final customGoldTypesProvider =
    StateNotifierProvider<
      CustomGoldTypesController,
      DataState<List<CustomGoldTypeModel>>
    >((ref) {
      final repository = ref.watch(investmentRepositoryProvider);
      return CustomGoldTypesController(repository);
    });

/// Custom asset categories.
final customAssetCategoriesProvider =
    StateNotifierProvider<
      CustomAssetCategoriesController,
      DataState<List<CustomAssetCategoryModel>>
    >((ref) {
      final repository = ref.watch(investmentRepositoryProvider);
      return CustomAssetCategoriesController(repository);
    });

// ═══════════════════════════════════════════════════════════════
// PRICES STATE & CONTROLLER
// ═══════════════════════════════════════════════════════════════

enum PricesStatus { initial, loading, loaded, error }

/// State untuk menyimpan semua harga dari database.
class InvestmentPricesState {
  const InvestmentPricesState({
    this.status = PricesStatus.initial,
    this.goldPrices = const {},
    this.bitcoinPrices = const {},
    this.errorMessage,
  });

  final PricesStatus status;

  /// Map source → GoldPriceModel (antaremas, logammulia)
  final Map<String, GoldPriceModel> goldPrices;

  /// Map source → BitcoinPriceModel (indodax, coingecko)
  final Map<String, BitcoinPriceModel> bitcoinPrices;

  final String? errorMessage;

  bool get isLoading => status == PricesStatus.loading;
  bool get isLoaded => status == PricesStatus.loaded;

  /// Ambil harga emas per gram (buyPrice = harga buyback).
  double? getGoldPrice(String source) => goldPrices[source]?.buyPrice;

  /// Ambil harga Bitcoin dalam IDR.
  double? getBitcoinPrice(String source) => bitcoinPrices[source]?.priceIdr;

  /// Ambil harga efektif untuk sebuah aset.
  double getEffectivePrice(InvestmentAssetModel asset) {
    // Manual atau custom → gunakan harga tersimpan
    if (asset.priceSource == 'manual' || asset.type == InvestmentType.custom) {
      return asset.currentPrice;
    }

    // Gold → ambil dari goldPrices (buyPrice)
    if (asset.type == InvestmentType.gold) {
      return getGoldPrice(asset.priceSource) ?? asset.currentPrice;
    }

    // Bitcoin → ambil dari bitcoinPrices
    if (asset.type == InvestmentType.bitcoin) {
      return getBitcoinPrice(asset.priceSource) ?? asset.currentPrice;
    }

    return asset.currentPrice;
  }

  InvestmentPricesState copyWith({
    PricesStatus? status,
    Map<String, GoldPriceModel>? goldPrices,
    Map<String, BitcoinPriceModel>? bitcoinPrices,
    String? errorMessage,
  }) {
    return InvestmentPricesState(
      status: status ?? this.status,
      goldPrices: goldPrices ?? this.goldPrices,
      bitcoinPrices: bitcoinPrices ?? this.bitcoinPrices,
      errorMessage: errorMessage,
    );
  }
}

/// Controller untuk load semua harga sekaligus.
class InvestmentPricesController extends StateNotifier<InvestmentPricesState> {
  InvestmentPricesController(this._repository)
    : super(const InvestmentPricesState());

  final InvestmentRepository _repository;

  /// Load semua harga dari database (gold + bitcoin).
  Future<void> loadPrices() async {
    state = state.copyWith(status: PricesStatus.loading);

    try {
      // Fetch semua harga secara parallel
      final results = await Future.wait([
        _repository.getLatestGoldPrice('antaremas'),
        _repository.getLatestGoldPrice('logammulia'),
        _repository.getLatestBitcoinPrice('indodax'),
        _repository.getLatestBitcoinPrice('coingecko'),
      ]);

      final goldPrices = <String, GoldPriceModel>{};
      final bitcoinPrices = <String, BitcoinPriceModel>{};

      // Gold prices
      final antaremas = results[0] as DataState<GoldPriceModel?>;
      final logammulia = results[1] as DataState<GoldPriceModel?>;
      if (antaremas.isSuccess() && antaremas.dataSuccess() != null) {
        goldPrices['antaremas'] = antaremas.dataSuccess()!;
      }
      if (logammulia.isSuccess() && logammulia.dataSuccess() != null) {
        goldPrices['logammulia'] = logammulia.dataSuccess()!;
      }

      // Bitcoin prices
      final indodax = results[2] as DataState<BitcoinPriceModel?>;
      final coingecko = results[3] as DataState<BitcoinPriceModel?>;
      if (indodax.isSuccess() && indodax.dataSuccess() != null) {
        bitcoinPrices['indodax'] = indodax.dataSuccess()!;
      }
      if (coingecko.isSuccess() && coingecko.dataSuccess() != null) {
        bitcoinPrices['coingecko'] = coingecko.dataSuccess()!;
      }

      state = state.copyWith(
        status: PricesStatus.loaded,
        goldPrices: goldPrices,
        bitcoinPrices: bitcoinPrices,
      );
    } catch (e) {
      state = state.copyWith(
        status: PricesStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Refresh harga.
  Future<void> refresh() => loadPrices();
}

// ═══════════════════════════════════════════════════════════════
// DASHBOARD STATE & CONTROLLER
// ═══════════════════════════════════════════════════════════════

enum InvestmentStatus { initial, loading, loaded, error }

/// Immutable state untuk investment dashboard.
class InvestmentState {
  const InvestmentState({
    this.status = InvestmentStatus.initial,
    this.assets = const [],
    this.errorMessage,
  });

  final InvestmentStatus status;
  final List<InvestmentAssetModel> assets;
  final String? errorMessage;

  List<InvestmentAssetModel> get activeAssets =>
      assets.where((a) => a.isActive).toList();

  List<InvestmentAssetModel> get inactiveAssets =>
      assets.where((a) => !a.isActive).toList();

  /// Group aset aktif berdasarkan type.
  Map<InvestmentType, List<InvestmentAssetModel>> get groupedActiveAssets {
    final active = activeAssets;
    return {
      for (final type in InvestmentType.values)
        if (active.any((a) => a.type == type))
          type: active.where((a) => a.type == type).toList(),
    };
  }

  InvestmentState copyWith({
    InvestmentStatus? status,
    List<InvestmentAssetModel>? assets,
    String? errorMessage,
  }) {
    return InvestmentState(
      status: status ?? this.status,
      assets: assets ?? this.assets,
      errorMessage: errorMessage,
    );
  }
}

/// Controller dashboard investasi.
class InvestmentController extends StateNotifier<InvestmentState> {
  InvestmentController(this._repository) : super(const InvestmentState());

  final InvestmentRepository _repository;

  /// Load semua aset dari server/cache.
  Future<void> loadDashboard() async {
    state = state.copyWith(status: InvestmentStatus.loading);

    final result = await _repository.getDashboard();

    if (result.isSuccess()) {
      state = state.copyWith(
        status: InvestmentStatus.loaded,
        assets: result.dataSuccess()!,
      );
    } else {
      final (message, _, _, _) = result.dataError()!;
      state = state.copyWith(
        status: InvestmentStatus.error,
        errorMessage: message,
      );
    }
  }

  /// Buat aset baru lalu refresh dashboard.
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
    final result = await _repository.createAsset(
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

    if (result.isSuccess()) {
      await loadDashboard();
    }
    return result;
  }

  /// Top up aset lalu refresh dashboard.
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
    final result = await _repository.topupAsset(
      assetId: assetId,
      units: units,
      pricePerUnit: pricePerUnit,
      fee: fee,
      date: date,
      note: note,
      deductWallet: deductWallet,
      walletId: walletId,
    );

    if (result.isSuccess()) {
      await loadDashboard();
    }
    return result;
  }

  /// Jual unit aset lalu refresh dashboard.
  Future<DataState<Map<String, dynamic>>> sellAsset({
    required String assetId,
    required double units,
    required double pricePerUnit,
    DateTime? date,
    String? note,
    bool creditWallet = false,
    String? walletId,
  }) async {
    final result = await _repository.sellAsset(
      assetId: assetId,
      units: units,
      pricePerUnit: pricePerUnit,
      date: date,
      note: note,
      creditWallet: creditWallet,
      walletId: walletId,
    );

    if (result.isSuccess()) {
      await loadDashboard();
    }
    return result;
  }

  /// Edit transaksi buy lalu refresh dashboard.
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
    final result = await _repository.editTransaction(
      transactionId: transactionId,
      units: units,
      pricePerUnit: pricePerUnit,
      fee: fee,
      date: date,
      note: note,
      deductWallet: deductWallet,
      walletId: walletId,
    );

    if (result.isSuccess()) {
      await loadDashboard();
    }
    return result;
  }

  /// Hapus transaksi buy lalu refresh dashboard.
  Future<DataState<Map<String, dynamic>>> deleteTransaction(
    String transactionId,
  ) async {
    final result = await _repository.deleteTransaction(transactionId);

    if (result.isSuccess()) {
      await loadDashboard();
    }
    return result;
  }

  /// Hapus master aset lalu refresh dashboard.
  Future<DataState<Map<String, dynamic>>> deleteAsset({
    required String assetId,
    bool revertWallet = false,
  }) async {
    final result = await _repository.deleteAsset(
      assetId: assetId,
      revertWallet: revertWallet,
    );

    if (result.isSuccess()) {
      await loadDashboard();
    }
    return result;
  }

  /// Update metadata aset lalu refresh dashboard.
  Future<DataState<InvestmentAssetModel>> updateAsset(
    InvestmentAssetModel asset,
  ) async {
    final result = await _repository.updateAsset(asset);

    if (result.isSuccess()) {
      await loadDashboard();
    }
    return result;
  }

  /// Update current_price lalu refresh dashboard.
  Future<DataState<void>> updateCurrentPrice({
    required String assetId,
    required double price,
  }) async {
    final result = await _repository.updateCurrentPrice(
      assetId: assetId,
      price: price,
    );

    if (result.isSuccess()) {
      await loadDashboard();
    }
    return result;
  }

  void clearCache() {
    _repository.clearCache();
    state = const InvestmentState();
  }
}

// ═══════════════════════════════════════════════════════════════
// TRANSACTIONS CONTROLLER (per asset)
// ═══════════════════════════════════════════════════════════════

class InvestmentTransactionsState {
  const InvestmentTransactionsState({
    this.status = InvestmentStatus.initial,
    this.buyTransactions = const [],
    this.sellTransactions = const [],
    this.errorMessage,
  });

  final InvestmentStatus status;
  final List<InvestmentTransactionModel> buyTransactions;
  final List<InvestmentTransactionModel> sellTransactions;
  final String? errorMessage;

  InvestmentTransactionsState copyWith({
    InvestmentStatus? status,
    List<InvestmentTransactionModel>? buyTransactions,
    List<InvestmentTransactionModel>? sellTransactions,
    String? errorMessage,
  }) {
    return InvestmentTransactionsState(
      status: status ?? this.status,
      buyTransactions: buyTransactions ?? this.buyTransactions,
      sellTransactions: sellTransactions ?? this.sellTransactions,
      errorMessage: errorMessage,
    );
  }
}

class InvestmentTransactionsController
    extends StateNotifier<InvestmentTransactionsState> {
  InvestmentTransactionsController(this._repository, this._assetId)
    : super(const InvestmentTransactionsState());

  final InvestmentRepository _repository;
  final String _assetId;

  /// Load semua transaksi (buy + sell) untuk aset ini.
  Future<void> loadTransactions() async {
    state = state.copyWith(status: InvestmentStatus.loading);

    final buyResult = await _repository.getTransactions(
      assetId: _assetId,
      direction: 'buy',
    );
    final sellResult = await _repository.getTransactions(
      assetId: _assetId,
      direction: 'sell',
    );

    if (buyResult.isSuccess() && sellResult.isSuccess()) {
      state = state.copyWith(
        status: InvestmentStatus.loaded,
        buyTransactions: buyResult.dataSuccess()!,
        sellTransactions: sellResult.dataSuccess()!,
      );
    } else {
      final msg = buyResult.isError()
          ? buyResult.dataError()!.$1
          : sellResult.dataError()!.$1;
      state = state.copyWith(status: InvestmentStatus.error, errorMessage: msg);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// CUSTOM GOLD TYPES CONTROLLER
// ═══════════════════════════════════════════════════════════════

class CustomGoldTypesController
    extends StateNotifier<DataState<List<CustomGoldTypeModel>>> {
  CustomGoldTypesController(this._repository)
    : super(const DataState.success(data: []));

  final InvestmentRepository _repository;

  Future<void> load() async {
    final result = await _repository.getCustomGoldTypes();
    state = result;
  }

  Future<DataState<CustomGoldTypeModel>> create(String name) async {
    final result = await _repository.createCustomGoldType(name);
    if (result.isSuccess()) await load();
    return result;
  }

  Future<DataState<CustomGoldTypeModel>> update({
    required String id,
    required String name,
  }) async {
    final result = await _repository.updateCustomGoldType(id: id, name: name);
    if (result.isSuccess()) await load();
    return result;
  }

  Future<DataState<void>> delete(String id) async {
    final result = await _repository.deleteCustomGoldType(id);
    if (result.isSuccess()) await load();
    return result;
  }
}

// ═══════════════════════════════════════════════════════════════
// CUSTOM ASSET CATEGORIES CONTROLLER
// ═══════════════════════════════════════════════════════════════

class CustomAssetCategoriesController
    extends StateNotifier<DataState<List<CustomAssetCategoryModel>>> {
  CustomAssetCategoriesController(this._repository)
    : super(const DataState.success(data: []));

  final InvestmentRepository _repository;

  Future<void> load() async {
    final result = await _repository.getCustomAssetCategories();
    state = result;
  }

  Future<DataState<CustomAssetCategoryModel>> create({
    required String name,
    required String unitLabel,
  }) async {
    final result = await _repository.createCustomAssetCategory(
      name: name,
      unitLabel: unitLabel,
    );
    if (result.isSuccess()) await load();
    return result;
  }

  Future<DataState<CustomAssetCategoryModel>> update({
    required String id,
    required String name,
    required String unitLabel,
  }) async {
    final result = await _repository.updateCustomAssetCategory(
      id: id,
      name: name,
      unitLabel: unitLabel,
    );
    if (result.isSuccess()) await load();
    return result;
  }

  Future<DataState<void>> delete(String id) async {
    final result = await _repository.deleteCustomAssetCategory(id);
    if (result.isSuccess()) await load();
    return result;
  }
}
