import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/wallet/datasource/wallet_remote_data_source.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/features/wallet/repositories/wallet_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────

/// Provider placeholder untuk [WalletRepository].
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(
    remoteDataSource: WalletRemoteDataSource(client: Supabase.instance.client),
  );
});

/// Provider utama untuk [WalletController].
///
/// State berupa `AsyncValue<List<WalletModel>>`:
/// - `AsyncLoading` saat fetch awal
/// - `AsyncData([...])` jika berhasil
/// - `AsyncError(...)` jika gagal
final walletControllerProvider =
    AsyncNotifierProvider<WalletController, List<WalletModel>>(() {
      return WalletController();
    });

// ─────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────

/// Riverpod [AsyncNotifier] untuk mengelola daftar wallet user.
///
/// Menyediakan CRUD + adjustBalance.
class WalletController extends AsyncNotifier<List<WalletModel>> {
  late final WalletRepository _repository;

  static const String _tag = 'Wallet';

  @override
  Future<List<WalletModel>> build() async {
    _repository = ref.watch(walletRepositoryProvider);
    return _fetchWallets();
  }

  /// Memuat ulang seluruh daftar wallet dari server.
  Future<List<WalletModel>> _fetchWallets() async {
    AppLogger.call('[$_tag] Memulai fetch wallet...', colorLog: ColorLog.blue);

    final result = await _repository.getWallets();

    return result.map(
      success: (data) {
        AppLogger.call(
          '[$_tag] Fetch berhasil: ${data.data.length} wallet',
          colorLog: ColorLog.green,
        );
        return data.data;
      },
      error: (err) {
        AppLogger.logError(
          '[$_tag] Fetch gagal: ${err.message}',
          runtimeType: WalletController,
        );
        throw Exception(err.message);
      },
    );
  }

  /// Refresh daftar wallet (bisa dipanggil dari UI pull-to-refresh).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchWallets());
  }

  // ───────────────── Computed helpers ─────────────────

  /// Wallet yang **dimasukkan** dalam total saldo.
  List<WalletModel> get includedWallets =>
      (state.value ?? []).where((w) => !w.excludeFromTotal).toList();

  /// Wallet yang **dikecualikan** dari total saldo.
  List<WalletModel> get excludedWallets =>
      (state.value ?? []).where((w) => w.excludeFromTotal).toList();

  /// Total saldo dari wallet yang dimasukkan.
  double get totalBalance =>
      includedWallets.fold(0, (sum, w) => sum + w.balance);

  // ───────────────── CRUD Operations ─────────────────

  /// Menambah wallet baru.
  ///
  /// Mengembalikan [DataState] agar caller (UI) bisa menentukan
  /// aksi lanjutan (pop, snackbar, dsb).
  Future<DataState<WalletModel>> addWallet(WalletModel wallet) async {
    AppLogger.call(
      '[$_tag] Menambah wallet "${wallet.name}"...',
      colorLog: ColorLog.blue,
    );

    final result = await _repository.createWallet(wallet);

    result.map(
      success: (data) {
        AppLogger.call(
          '[$_tag] Wallet "${data.data.name}" berhasil ditambahkan',
          colorLog: ColorLog.green,
        );
        final current = state.value ?? [];
        state = AsyncData([...current, data.data]);
      },
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal menambah wallet: ${err.message}',
          runtimeType: WalletController,
        );
      },
    );

    return result;
  }

  /// Memperbarui wallet yang sudah ada.
  Future<DataState<WalletModel>> editWallet(WalletModel wallet) async {
    AppLogger.call(
      '[$_tag] Memperbarui wallet "${wallet.name}"...',
      colorLog: ColorLog.blue,
    );

    final result = await _repository.updateWallet(wallet);

    result.map(
      success: (data) {
        AppLogger.call(
          '[$_tag] Wallet "${data.data.name}" berhasil diperbarui',
          colorLog: ColorLog.green,
        );
        final current = state.value ?? [];
        state = AsyncData(
          current.map((w) => w.id == data.data.id ? data.data : w).toList(),
        );
      },
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal memperbarui wallet: ${err.message}',
          runtimeType: WalletController,
        );
      },
    );

    return result;
  }

  /// Menghapus wallet berdasarkan [walletId].
  Future<DataState<String>> removeWallet(String walletId) async {
    AppLogger.call(
      '[$_tag] Menghapus wallet ($walletId)...',
      colorLog: ColorLog.blue,
    );

    final result = await _repository.deleteWallet(walletId);

    result.map(
      success: (_) {
        AppLogger.call(
          '[$_tag] Wallet ($walletId) berhasil dihapus',
          colorLog: ColorLog.green,
        );
        final current = state.value ?? [];
        state = AsyncData(current.where((w) => w.id != walletId).toList());
      },
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal menghapus wallet ($walletId): ${err.message}',
          runtimeType: WalletController,
        );
      },
    );

    return result;
  }

  /// Menyesuaikan saldo wallet.
  ///
  /// [walletId] — wallet yang dikoreksi.
  /// [actualBalance] — saldo sebenarnya yang diinput user.
  ///
  /// Menghitung delta lalu membuat transaksi adjustment.
  /// Setelah berhasil, fetch ulang wallet agar saldo terupdate.
  Future<DataState<void>> adjustBalance({
    required String walletId,
    required double actualBalance,
  }) async {
    final current = state.value ?? [];
    final wallet = current.firstWhere((w) => w.id == walletId);
    final delta = actualBalance - wallet.balance;

    if (delta == 0) {
      return const DataState.success(data: null);
    }

    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    AppLogger.call(
      '[$_tag] Menyesuaikan saldo "${wallet.name}": '
      'current=${wallet.balance}, actual=$actualBalance, delta=$delta',
      colorLog: ColorLog.blue,
    );

    final result = await _repository.adjustBalance(
      walletId: walletId,
      userId: userId,
      delta: delta,
    );

    result.map(
      success: (_) {
        AppLogger.call(
          '[$_tag] Saldo "${wallet.name}" berhasil disesuaikan',
          colorLog: ColorLog.green,
        );
      },
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal menyesuaikan saldo: ${err.message}',
          runtimeType: WalletController,
        );
      },
    );

    // Refresh wallet list agar saldo terupdate dari DB trigger.
    if (result.isSuccess()) {
      state = await AsyncValue.guard(() => _fetchWallets());
    }

    return result;
  }
}
