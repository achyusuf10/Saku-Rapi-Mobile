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

/// Total portofolio (semua aset aktif).
final investmentTotalValueProvider = Provider<double>((ref) {
  final state = ref.watch(investmentControllerProvider);
  if (state.status != InvestmentStatus.loaded) return 0;
  return state.activeAssets.fold(0.0, (sum, a) => sum + a.currentValue);
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

/// Harga emas terbaru (by source).
final goldPriceProvider = FutureProvider.family<GoldPriceModel?, String>((
  ref,
  source,
) async {
  final repo = ref.watch(investmentRepositoryProvider);
  final result = await repo.getLatestGoldPrice(source);
  return result.isSuccess() ? result.dataSuccess() : null;
});

/// Harga Bitcoin terbaru (by source).
final bitcoinPriceProvider = FutureProvider.family<BitcoinPriceModel?, String>((
  ref,
  source,
) async {
  final repo = ref.watch(investmentRepositoryProvider);
  final result = await repo.getLatestBitcoinPrice(source);
  return result.isSuccess() ? result.dataSuccess() : null;
});

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
