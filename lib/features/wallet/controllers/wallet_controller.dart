import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/transaction/datasource/transaction_remote_data_source.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/features/wallet/repositories/wallet_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ───────────────── Providers ─────────────────

/// Provider singleton untuk [WalletRepository].
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository();
});

/// Provider utama untuk [WalletController] — mengelola state wallet list.
final walletControllerProvider =
    StateNotifierProvider<WalletController, WalletState>((ref) {
      final repository = ref.watch(walletRepositoryProvider);
      return WalletController(repository);
    });

/// Provider computed: total saldo wallet yang tidak di-exclude.
final walletTotalBalanceProvider = Provider<double>((ref) {
  final state = ref.watch(walletControllerProvider);
  if (state.status != WalletStatus.loaded) return 0;
  return WalletRepository.calculateTotalBalance(state.wallets);
});

/// Provider computed: wallet yang termasuk dalam total.
final includedWalletsProvider = Provider<List<WalletModel>>((ref) {
  final state = ref.watch(walletControllerProvider);
  return state.wallets.where((w) => !w.excludeFromTotal).toList();
});

/// Provider computed: wallet yang dikecualikan dari total.
final excludedWalletsProvider = Provider<List<WalletModel>>((ref) {
  final state = ref.watch(walletControllerProvider);
  return state.wallets.where((w) => w.excludeFromTotal).toList();
});

/// Provider computed: semua wallet sebagai flat list (untuk picker).
final walletListProvider = Provider<List<WalletModel>>((ref) {
  final state = ref.watch(walletControllerProvider);
  return state.wallets;
});

// ───────────────── State ─────────────────

enum WalletStatus { initial, loading, loaded, error }

/// Immutable state untuk wallet list.
class WalletState {
  const WalletState({
    this.status = WalletStatus.initial,
    this.wallets = const [],
    this.errorMessage,
  });

  final WalletStatus status;
  final List<WalletModel> wallets;
  final String? errorMessage;

  WalletState copyWith({
    WalletStatus? status,
    List<WalletModel>? wallets,
    String? errorMessage,
  }) {
    return WalletState(
      status: status ?? this.status,
      wallets: wallets ?? this.wallets,
      errorMessage: errorMessage,
    );
  }
}

// ───────────────── Controller ─────────────────

/// Controller untuk CRUD dan state management wallet.
///
/// Mengelola [WalletState] yang berisi list wallet + loading/error status.
class WalletController extends StateNotifier<WalletState> {
  WalletController(this._repository) : super(const WalletState());

  final WalletRepository _repository;

  // ───────────────── LOAD ─────────────────

  /// Fetch semua wallet dari server (atau cache offline).
  Future<void> loadWallets() async {
    state = state.copyWith(status: WalletStatus.loading);

    final result = await _repository.getWallets();

    if (result.isSuccess()) {
      state = state.copyWith(
        status: WalletStatus.loaded,
        wallets: result.dataSuccess()!,
      );
    } else {
      final (message, _, _, _) = result.dataError()!;
      state = state.copyWith(status: WalletStatus.error, errorMessage: message);
    }
  }

  // ───────────────── CREATE ─────────────────

  /// Buat wallet baru.
  Future<DataState<WalletModel>> createWallet({
    required String userId,
    required String name,
    required String icon,
    required String color,
    required double initialBalance,
    bool excludeFromTotal = false,
  }) async {
    final sortOrder = state.wallets.length;

    final result = await _repository.createWallet(
      userId: userId,
      name: name,
      icon: icon,
      color: color,
      initialBalance: initialBalance,
      excludeFromTotal: excludeFromTotal,
      sortOrder: sortOrder,
    );

    if (result.isSuccess()) {
      await loadWallets();
    }
    return result;
  }

  // ───────────────── UPDATE ─────────────────

  /// Update metadata wallet.
  Future<DataState<WalletModel>> updateWallet({
    required String walletId,
    required String name,
    required String icon,
    required String color,
    required bool excludeFromTotal,
  }) async {
    final existing = state.wallets.where((w) => w.id == walletId).firstOrNull;
    if (existing == null) {
      return const DataState.error(message: 'Wallet tidak ditemukan');
    }

    final result = await _repository.updateWallet(
      walletId: walletId,
      name: name,
      icon: icon,
      color: color,
      excludeFromTotal: excludeFromTotal,
      sortOrder: existing.sortOrder,
      existing: existing,
    );

    if (result.isSuccess()) {
      await loadWallets();
    }
    return result;
  }

  // ───────────────── DELETE ─────────────────

  /// Hapus wallet (dengan guard transaksi).
  Future<DataState<void>> deleteWallet(String walletId) async {
    final result = await _repository.deleteWallet(walletId);

    if (result.isSuccess()) {
      await loadWallets();
    }
    return result;
  }

  // ───────────────── TOGGLE ─────────────────

  /// Toggle exclude_from_total.
  Future<DataState<void>> toggleExcludeFromTotal({
    required String walletId,
    required bool exclude,
  }) async {
    final result = await _repository.toggleExcludeFromTotal(
      walletId: walletId,
      exclude: exclude,
    );

    if (result.isSuccess()) {
      await loadWallets();
    }
    return result;
  }

  // ───────────────── ADJUST BALANCE ─────────────────

  /// Sesuaikan saldo wallet ke nilai target via RPC adjustment.
  Future<DataState<Map<String, dynamic>>> adjustBalance({
    required String walletId,
    required double targetBalance,
    String? note,
  }) async {
    final result = await TransactionRemoteDataSource().createAdjustment(
      walletId: walletId,
      targetBalance: targetBalance,
      note: note,
    );

    if (result.isSuccess()) {
      await loadWallets();
    }
    return result;
  }

  // ───────────────── CACHE ─────────────────

  /// Hapus cache lokal wallet.
  void clearCache() {
    _repository.clearCache();
    state = const WalletState();
  }
}
