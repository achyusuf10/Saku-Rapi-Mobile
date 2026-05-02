import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/transaction/datasource/transaction_remote_data_source.dart';
import 'package:app_saku_rapi/features/wallet/datasource/wallet_local_data_source.dart';
import 'package:app_saku_rapi/features/wallet/datasource/wallet_remote_data_source.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';

/// Repository utama untuk fitur wallet.
///
/// Mengorkestrasikan [WalletRemoteDataSource] dan [WalletLocalDataSource]:
/// - Online: fetch dari Supabase, cache ke Hive.
/// - Offline fallback: sajikan dari Hive cache.
///
/// Validasi domain dilakukan di sini, bukan di widget.
class WalletRepository {
  WalletRepository({
    WalletRemoteDataSource? remoteDataSource,
    WalletLocalDataSource? localDataSource,
  }) : _remote = remoteDataSource ?? WalletRemoteDataSource(),
       _local = localDataSource ?? WalletLocalDataSource();

  final WalletRemoteDataSource _remote;
  final WalletLocalDataSource _local;

  static const _tag = '[Wallet] [WalletRepository]';

  // ───────────────── READ ─────────────────

  /// Ambil semua wallet. Fetch remote lalu cache; fallback ke cache jika gagal.
  Future<DataState<List<WalletModel>>> getWallets() async {
    final result = await _remote.getWallets();

    if (result.isSuccess()) {
      final wallets = result.dataSuccess()!;
      _local.cacheWallets(wallets);
      return result;
    }

    // Offline fallback
    final cached = _local.getCachedWallets();
    if (cached != null) {
      AppLogger.call('$_tag getWallets: serving from cache');
      return DataState.success(data: cached);
    }

    return result;
  }

  // ───────────────── CREATE ─────────────────

  /// Buat wallet baru setelah validasi nama unik.
  Future<DataState<WalletModel>> createWallet({
    required String userId,
    required String name,
    required String icon,
    required String color,
    required String backgroundColor,
    required double initialBalance,
    bool excludeFromTotal = false,
    int sortOrder = 0,
  }) async {
    // Validasi: nama tidak boleh kosong
    if (name.trim().isEmpty) {
      final l10n = appContext?.l10n;
      return DataState.error(
        message:
            l10n?.validationWalletNameEmpty ?? 'Nama dompet tidak boleh kosong',
      );
    }

    // Validasi: initial_balance >= 0
    if (initialBalance < 0) {
      final l10n = appContext?.l10n;
      return DataState.error(
        message:
            l10n?.validationInitialBalanceNegative ??
            'Saldo awal tidak boleh negatif',
      );
    }

    // Validasi: nama unik per user
    final dupCheck = await _isDuplicateName(name, excludeId: null);
    if (dupCheck) {
      final l10n = appContext?.l10n;
      return DataState.error(
        message:
            l10n?.validationWalletNameDuplicate ??
            'Nama dompet sudah digunakan',
      );
    }

    final wallet = WalletModel(
      id: '', // server-generated
      userId: userId,
      name: name.trim(),
      icon: icon,
      color: color,
      backgroundColor: backgroundColor,
      balance: initialBalance,
      initialBalance: initialBalance,
      currency: 'IDR',
      excludeFromTotal: excludeFromTotal,
      sortOrder: sortOrder,
      createdAt: null,
      updatedAt: null,
    );

    final result = await _remote.createWallet(wallet);
    return result;
  }

  // ───────────────── UPDATE ─────────────────

  /// Update metadata wallet (name, icon, color, excludeFromTotal).
  /// **TIDAK** mengubah balance atau initial_balance.
  Future<DataState<WalletModel>> updateWallet({
    required String walletId,
    required String name,
    required String icon,
    required String color,
    required String backgroundColor,
    required bool excludeFromTotal,
    required int sortOrder,
    required WalletModel existing,
  }) async {
    if (name.trim().isEmpty) {
      final l10n = appContext?.l10n;
      return DataState.error(
        message:
            l10n?.validationWalletNameEmpty ?? 'Nama dompet tidak boleh kosong',
      );
    }

    // Validasi: nama unik, exclude self
    final dupCheck = await _isDuplicateName(name, excludeId: walletId);
    if (dupCheck) {
      final l10n = appContext?.l10n;
      return DataState.error(
        message:
            l10n?.validationWalletNameDuplicate ??
            'Nama dompet sudah digunakan',
      );
    }

    final updated = existing.copyWith(
      name: name.trim(),
      icon: icon,
      color: color,
      backgroundColor: backgroundColor,
      excludeFromTotal: excludeFromTotal,
      sortOrder: sortOrder,
    );

    final result = await _remote.updateWallet(updated);
    return result;
  }

  // ───────────────── DELETE ─────────────────

  /// Hapus wallet dengan guard: blokir jika wallet memiliki transaksi.
  Future<DataState<void>> deleteWallet(String walletId) async {
    // Guard: cek apakah wallet punya transaksi
    final hasResult = await _remote.hasTransactions(walletId);
    if (hasResult.isSuccess() && hasResult.dataSuccess() == true) {
      final l10n = appContext?.l10n;
      return DataState.error(
        message:
            l10n?.validationWalletHasTransactions ??
            'Dompet tidak bisa dihapus karena masih memiliki transaksi. '
                'Hapus transaksi terlebih dahulu.',
      );
    }

    final result = await _remote.deleteWallet(walletId);
    return result;
  }

  // ───────────────── TOGGLE ─────────────────

  /// Toggle exclude_from_total.
  Future<DataState<void>> toggleExcludeFromTotal({
    required String walletId,
    required bool exclude,
  }) async {
    final result = await _remote.toggleExcludeFromTotal(
      walletId: walletId,
      exclude: exclude,
    );
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
    return result;
  }

  // ───────────────── COMPUTED ─────────────────

  /// Hitung total saldo dari wallet yang tidak di-exclude.
  static double calculateTotalBalance(List<WalletModel> wallets) {
    return wallets
        .where((w) => !w.excludeFromTotal)
        .fold(0.0, (sum, w) => sum + w.balance);
  }

  /// Cache helper
  void clearCache() {
    _local.clearWalletCache();
  }

  /// Simpan list wallet langsung ke cache lokal (tanpa fetch remote).
  void cacheWalletList(List<WalletModel> wallets) {
    _local.cacheWallets(wallets);
  }

  List<String> getIncludedWalletDisplayOrder() {
    return _local.getIncludedWalletDisplayOrder();
  }

  void saveIncludedWalletDisplayOrder(List<String> orderedIncludedWalletIds) {
    _local.setIncludedWalletDisplayOrder(orderedIncludedWalletIds);
  }

  /// Gabungkan daftar wallet: yang `excludeFromTotal == false` mengikuti
  /// [savedIncludedOrderIds] (by id, id yang tidak ada di list di-skip),
  /// sisanya di akhir diurut [sortOrder] lalu nama. Wallet excluded tetap
  /// di bagian akhir, diurut [sortOrder] lalu nama.
  static List<WalletModel> mergeWalletsWithLocalIncludedOrder(
    List<WalletModel> wallets,
    List<String> savedIncludedOrderIds,
  ) {
    if (wallets.isEmpty) return wallets;

    final byId = {for (final w in wallets) w.id: w};
    final included = wallets.where((w) => !w.excludeFromTotal).toList();
    final excluded = wallets.where((w) => w.excludeFromTotal).toList();

    final includedIdSet = included.map((w) => w.id).toSet();
    final orderedIncluded = <WalletModel>[];
    final seen = <String>{};

    for (final id in savedIncludedOrderIds) {
      if (!includedIdSet.contains(id) || seen.contains(id)) continue;
      final w = byId[id];
      if (w != null) {
        orderedIncluded.add(w);
        seen.add(id);
      }
    }

    final remainder = included.where((w) => !seen.contains(w.id)).toList()
      ..sort((a, b) {
        final c = a.sortOrder.compareTo(b.sortOrder);
        if (c != 0) return c;
        return a.name.compareTo(b.name);
      });
    orderedIncluded.addAll(remainder);

    excluded.sort((a, b) {
      final c = a.sortOrder.compareTo(b.sortOrder);
      if (c != 0) return c;
      return a.name.compareTo(b.name);
    });

    return [...orderedIncluded, ...excluded];
  }

  // ───────────────── PRIVATE ─────────────────

  /// Cek duplikasi nama wallet per user (case-insensitive).
  Future<bool> _isDuplicateName(String name, {String? excludeId}) async {
    final result = await _remote.getWallets();
    if (!result.isSuccess()) return false;

    final wallets = result.dataSuccess()!;
    final nameLower = name.trim().toLowerCase();

    return wallets.any(
      (w) =>
          w.name.toLowerCase() == nameLower &&
          (excludeId == null || w.id != excludeId),
    );
  }
}
