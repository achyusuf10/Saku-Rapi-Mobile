import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/investment/datasource/investment_price_service.dart';
import 'package:app_saku_rapi/features/investment/models/asset_type_model.dart';
import 'package:app_saku_rapi/features/investment/models/investment_model.dart';
import 'package:app_saku_rapi/features/investment/repositories/investment_repository.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ═══════════════ Providers ═══════════════

/// Singleton repo provider.
final investmentRepositoryProvider = Provider<InvestmentRepository>((ref) {
  return InvestmentRepository();
});

/// Singleton price service provider.
final investmentPriceServiceProvider = Provider<InvestmentPriceService>((ref) {
  return InvestmentPriceService();
});

/// Controller utama investasi (list + CRUD).
final investmentControllerProvider =
    StateNotifierProvider<InvestmentController, InvestmentState>((ref) {
      final repository = ref.watch(investmentRepositoryProvider);
      final priceService = ref.watch(investmentPriceServiceProvider);
      return InvestmentController(repository, priceService);
    });

/// Form controller untuk create/edit investasi.
final investmentFormControllerProvider =
    StateNotifierProvider.autoDispose<
      InvestmentFormController,
      InvestmentFormState
    >((ref) {
      final repository = ref.watch(investmentRepositoryProvider);
      return InvestmentFormController(repository);
    });

// ─── Granular providers (hanya rebuild widget terkait) ───

/// Daftar investasi yang sudah di-filter (jika implementasi filter nanti).
final investmentListProvider = Provider<List<InvestmentModel>>((ref) {
  final state = ref.watch(investmentControllerProvider);
  return state.investments;
});

/// Total nilai portfolio.
final investmentTotalValueProvider = Provider<double>((ref) {
  final investments = ref.watch(investmentListProvider);
  return InvestmentRepository.calculateTotalValue(investments);
});

/// Total modal (invested).
final investmentTotalInvestedProvider = Provider<double>((ref) {
  final investments = ref.watch(investmentListProvider);
  return InvestmentRepository.calculateTotalInvested(investments);
});

/// Total P/L (absolute).
final investmentTotalPLProvider = Provider<double>((ref) {
  final investments = ref.watch(investmentListProvider);
  return InvestmentRepository.calculateTotalPL(investments);
});

/// Total P/L (percentage).
final investmentTotalPLPercentProvider = Provider<double>((ref) {
  final investments = ref.watch(investmentListProvider);
  return InvestmentRepository.calculateTotalPLPercent(investments);
});

/// Investasi per tipe.
final investmentByTypeProvider = Provider.family<List<InvestmentModel>, String>(
  (ref, type) {
    final investments = ref.watch(investmentListProvider);
    return investments.where((i) => i.type == type).toList();
  },
);

/// Ringkasan total unit per kategori.
///
/// Return list of (label, amount, unitLabel):
/// - Gold total gram
/// - Bitcoin total BTC
/// - Custom: di-group by nama (nama sama = 1 grup)
final investmentUnitSummaryProvider =
    Provider<List<({String label, double amount, String unit})>>((ref) {
      final investments = ref.watch(investmentListProvider);
      if (investments.isEmpty) return [];

      final result = <({String label, double amount, String unit})>[];

      // Gold
      final golds = investments.where((i) => i.type == 'gold');
      if (golds.isNotEmpty) {
        final total = golds.fold(0.0, (sum, i) => sum + i.amount);
        result.add((label: golds.first.name, amount: total, unit: 'gr'));
      }

      // Crypto (Bitcoin)
      final cryptos = investments.where((i) => i.type == 'crypto');
      if (cryptos.isNotEmpty) {
        final total = cryptos.fold(0.0, (sum, i) => sum + i.amount);
        result.add((
          label: cryptos.first.name,
          amount: total,
          unit: cryptos.first.symbol ?? 'BTC',
        ));
      }

      // Custom: group by name (case-insensitive)
      final customs = investments.where((i) => i.type == 'custom');
      final grouped =
          <String, ({String name, double amount, String? symbol})>{};
      for (final c in customs) {
        final key = c.name.toLowerCase();
        final existing = grouped[key];
        if (existing != null) {
          grouped[key] = (
            name: existing.name,
            amount: existing.amount + c.amount,
            symbol: existing.symbol ?? c.symbol,
          );
        } else {
          grouped[key] = (name: c.name, amount: c.amount, symbol: c.symbol);
        }
      }
      for (final entry in grouped.values) {
        result.add((
          label: entry.name,
          amount: entry.amount,
          unit: entry.symbol ?? 'unit',
        ));
      }

      return result;
    });

/// Distinct nama aset + symbol dari semua investasi, untuk autocomplete.
final investmentSuggestionsProvider =
    Provider<List<({String name, String? symbol})>>((ref) {
      final investments = ref.watch(investmentListProvider);
      final seen = <String>{};
      final result = <({String name, String? symbol})>[];

      for (final inv in investments) {
        final key = inv.name.toLowerCase();
        if (!seen.contains(key)) {
          seen.add(key);
          result.add((name: inv.name, symbol: inv.symbol));
        }
      }

      return result;
    });

// ═══════════════ List State ═══════════════

enum InvestmentStatus { initial, loading, loaded, error }

/// Immutable state untuk daftar investasi.
class InvestmentState {
  const InvestmentState({
    this.status = InvestmentStatus.initial,
    this.investments = const [],
    this.errorMessage,
    this.isPriceLoading = false,
  });

  final InvestmentStatus status;
  final List<InvestmentModel> investments;
  final String? errorMessage;
  final bool isPriceLoading;

  bool get isLoading => status == InvestmentStatus.loading;
  bool get isEmpty => investments.isEmpty && status == InvestmentStatus.loaded;

  InvestmentState copyWith({
    InvestmentStatus? status,
    List<InvestmentModel>? investments,
    String? errorMessage,
    bool? isPriceLoading,
  }) {
    return InvestmentState(
      status: status ?? this.status,
      investments: investments ?? this.investments,
      errorMessage: errorMessage,
      isPriceLoading: isPriceLoading ?? this.isPriceLoading,
    );
  }
}

// ═══════════════ List Controller ═══════════════

/// Controller utama untuk daftar investasi & operasi CRUD.
class InvestmentController extends StateNotifier<InvestmentState> {
  InvestmentController(this._repository, this._priceService)
    : super(const InvestmentState());

  final InvestmentRepository _repository;
  final InvestmentPriceService _priceService;

  /// Load semua investasi + fetch harga live.
  Future<void> loadInvestments() async {
    state = state.copyWith(status: InvestmentStatus.loading);

    final result = await _repository.getInvestments();

    result.map(
      success: (data) {
        state = state.copyWith(
          status: InvestmentStatus.loaded,
          investments: data.data,
        );
        // Fetch live prices in background (tanpa blocking)
        _fetchAndApplyLivePrices();
      },
      error: (error) {
        state = state.copyWith(
          status: InvestmentStatus.error,
          errorMessage: error.message,
        );
      },
    );
  }

  /// Fetch harga live dan apply ke daftar investasi.
  Future<void> _fetchAndApplyLivePrices({bool forceRefresh = false}) async {
    final prices = await _priceService.fetchAllPrices(
      forceRefresh: forceRefresh,
    );

    if (!mounted) return;

    final updated = state.investments.map((investment) {
      final livePrice = prices[investment.type];
      if (livePrice != null && livePrice > 0) {
        return investment.copyWith(livePricePerUnit: livePrice);
      }
      return investment;
    }).toList();

    state = state.copyWith(investments: updated, isPriceLoading: false);
  }

  /// Force refresh harga live (dipanggil dari UI).
  Future<void> refreshPrices() async {
    state = state.copyWith(isPriceLoading: true);
    await _fetchAndApplyLivePrices(forceRefresh: true);
  }

  /// Hapus investasi.
  Future<DataState<void>> deleteInvestment(String investmentId) async {
    final result = await _repository.deleteInvestment(investmentId);

    if (result.isSuccess()) {
      // Remove dari local state
      final updated = state.investments
          .where((i) => i.id != investmentId)
          .toList();
      state = state.copyWith(investments: updated);
      _repository.cacheInvestmentList(updated);
    }

    return result;
  }

  /// Refresh daftar investasi.
  Future<void> refresh() => loadInvestments();

  /// Hapus dari local state semua investasi yang menggunakan asset type ini.
  /// Dipanggil setelah asset type di-soft-delete.
  void removeByAssetTypeId(String assetTypeId) {
    final updated = state.investments
        .where((inv) => inv.assetTypeId != assetTypeId)
        .toList();
    state = state.copyWith(investments: updated);
    _repository.cacheInvestmentList(updated);
  }

  /// Hapus cache.
  void clearCache() {
    _repository.clearCache();
  }
}

// ═══════════════ Form State ═══════════════

/// Status form investasi.
enum InvestmentFormStatus { idle, saving, saved, error }

/// Immutable state untuk form investasi.
class InvestmentFormState {
  const InvestmentFormState({
    this.status = InvestmentFormStatus.idle,
    this.type = 'gold',
    this.name = '',
    this.symbol = 'XAU',
    this.amount = 0,
    this.avgBuyPrice = 0,
    this.customCurrentPrice,
    this.linkedWallet,
    this.assetType,
    this.notes,
    this.deductFromWallet = false,
    this.errorMessage,
    this.existingInvestment,
  });

  final InvestmentFormStatus status;
  final String type;
  final String name;
  final String? symbol;
  final double amount;
  final double avgBuyPrice;
  final double? customCurrentPrice;
  final WalletModel? linkedWallet;
  final AssetTypeModel? assetType;
  final String? notes;
  final bool deductFromWallet;
  final String? errorMessage;
  final InvestmentModel? existingInvestment;

  bool get isEditing => existingInvestment != null;
  bool get isSaving => status == InvestmentFormStatus.saving;

  /// Estimasi total biaya.
  double get estimatedCost => amount * avgBuyPrice;

  /// Apakah saldo wallet cukup.
  bool get isWalletSufficient {
    if (!deductFromWallet || linkedWallet == null) return true;
    return linkedWallet!.balance >= estimatedCost;
  }

  InvestmentFormState copyWith({
    InvestmentFormStatus? status,
    String? type,
    String? name,
    String? symbol,
    double? amount,
    double? avgBuyPrice,
    double? customCurrentPrice,
    bool clearCustomCurrentPrice = false,
    WalletModel? linkedWallet,
    bool clearLinkedWallet = false,
    AssetTypeModel? assetType,
    bool clearAssetType = false,
    String? notes,
    bool clearNotes = false,
    bool? deductFromWallet,
    String? errorMessage,
    bool clearError = false,
    InvestmentModel? existingInvestment,
  }) {
    return InvestmentFormState(
      status: status ?? this.status,
      type: type ?? this.type,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      amount: amount ?? this.amount,
      avgBuyPrice: avgBuyPrice ?? this.avgBuyPrice,
      customCurrentPrice: clearCustomCurrentPrice
          ? null
          : (customCurrentPrice ?? this.customCurrentPrice),
      linkedWallet: clearLinkedWallet
          ? null
          : (linkedWallet ?? this.linkedWallet),
      assetType: clearAssetType ? null : (assetType ?? this.assetType),
      notes: clearNotes ? null : (notes ?? this.notes),
      deductFromWallet: deductFromWallet ?? this.deductFromWallet,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      existingInvestment: existingInvestment ?? this.existingInvestment,
    );
  }
}

// ═══════════════ Form Controller ═══════════════

/// Controller untuk form create/edit investasi.
class InvestmentFormController extends StateNotifier<InvestmentFormState> {
  InvestmentFormController(this._repository)
    : super(const InvestmentFormState());

  final InvestmentRepository _repository;

  // ─── Init for Edit ───

  /// Load existing investment data ke form.
  void loadExisting(InvestmentModel investment) {
    state = InvestmentFormState(
      type: investment.type,
      name: investment.name,
      symbol: investment.symbol,
      amount: investment.amount,
      avgBuyPrice: investment.avgBuyPrice,
      customCurrentPrice: investment.customCurrentPrice,
      notes: investment.notes,
      existingInvestment: investment,
      // Saat edit, tidak perlu deduct wallet lagi
      deductFromWallet: false,
    );
  }

  // ─── Setters ───

  void setType(String type) {
    // Auto-set default symbol for gold/crypto
    String? symbol = state.symbol;
    if (type == 'gold') {
      symbol = 'XAU';
    } else if (type == 'crypto') {
      symbol = 'BTC';
    } else if (state.type != 'custom') {
      // Switching to custom from gold/crypto: clear auto symbol
      symbol = null;
    }
    state = state.copyWith(
      type: type,
      symbol: symbol,
      clearAssetType: type != 'custom',
      clearError: true,
    );
  }

  void setName(String name) {
    state = state.copyWith(name: name, clearError: true);
  }

  void setSymbol(String? symbol) {
    state = state.copyWith(symbol: symbol);
  }

  void setAmount(double amount) {
    state = state.copyWith(amount: amount, clearError: true);
  }

  void setAvgBuyPrice(double price) {
    state = state.copyWith(avgBuyPrice: price, clearError: true);
  }

  void setCustomCurrentPrice(double? price) {
    if (price == null) {
      state = state.copyWith(clearCustomCurrentPrice: true);
    } else {
      state = state.copyWith(customCurrentPrice: price);
    }
  }

  void setLinkedWallet(WalletModel? wallet) {
    if (wallet == null) {
      state = state.copyWith(clearLinkedWallet: true);
    } else {
      state = state.copyWith(linkedWallet: wallet);
    }
  }

  void setNotes(String? notes) {
    if (notes == null || notes.isEmpty) {
      state = state.copyWith(clearNotes: true);
    } else {
      state = state.copyWith(notes: notes);
    }
  }

  void setDeductFromWallet(bool value) {
    state = state.copyWith(deductFromWallet: value, clearError: true);
  }

  /// Set jenis aset kustom. Auto-populate nama & symbol dari asset type.
  void setAssetType(AssetTypeModel? assetType) {
    if (assetType == null) {
      state = state.copyWith(clearAssetType: true);
    } else {
      state = state.copyWith(
        assetType: assetType,
        name: assetType.name,
        symbol: assetType.symbol,
      );
    }
  }

  // ─── Submit ───

  /// Submit form (create atau update).
  Future<DataState<dynamic>> submit() async {
    if (state.isSaving) {
      return DataState.error(message: 'Sedang menyimpan...');
    }

    state = state.copyWith(
      status: InvestmentFormStatus.saving,
      clearError: true,
    );

    try {
      if (state.isEditing) {
        return await _update();
      } else {
        return await _create();
      }
    } catch (e) {
      state = state.copyWith(
        status: InvestmentFormStatus.error,
        errorMessage: e.toString(),
      );
      return DataState.error(message: e.toString());
    }
  }

  Future<DataState<dynamic>> _create() async {
    final result = await _repository.createInvestment(
      type: state.type,
      name: state.name,
      symbol: state.symbol,
      amount: state.amount,
      avgBuyPrice: state.avgBuyPrice,
      customCurrentPrice: state.customCurrentPrice,
      linkedWalletId: state.linkedWallet?.id,
      assetTypeId: state.assetType?.id,
      notes: state.notes,
      deductFromWallet: state.deductFromWallet,
      walletBalance: state.linkedWallet?.balance,
    );

    result.map(
      success: (_) {
        state = state.copyWith(status: InvestmentFormStatus.saved);
      },
      error: (error) {
        state = state.copyWith(
          status: InvestmentFormStatus.error,
          errorMessage: error.message,
        );
      },
    );

    return result;
  }

  Future<DataState<dynamic>> _update() async {
    final result = await _repository.updateInvestment(
      investmentId: state.existingInvestment!.id,
      name: state.name,
      symbol: state.symbol,
      amount: state.amount,
      avgBuyPrice: state.avgBuyPrice,
      customCurrentPrice: state.customCurrentPrice,
      linkedWalletId: state.linkedWallet?.id,
      assetTypeId: state.assetType?.id,
      notes: state.notes,
    );

    result.map(
      success: (_) {
        state = state.copyWith(status: InvestmentFormStatus.saved);
      },
      error: (error) {
        state = state.copyWith(
          status: InvestmentFormStatus.error,
          errorMessage: error.message,
        );
      },
    );

    return result;
  }
}
