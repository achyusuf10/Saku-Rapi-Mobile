import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk operasi CRUD wallet di Supabase.
///
/// Semua request dibungkus [SupabaseHandler.call] agar return type
/// konsisten `DataState<T>`.
class WalletRemoteDataSource {
  WalletRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _table = 'wallets';
  static const _tag = '[Wallet] [WalletRemoteDataSource]';

  String get _userId => _client.auth.currentUser!.id;

  // ───────────────── READ ─────────────────

  /// Ambil semua wallet milik user, diurutkan sesuai [sort_order].
  Future<DataState<List<WalletModel>>> getWallets() {
    return SupabaseHandler.call<List<WalletModel>>(
      function: () async {
        AppLogger.call('$_tag getWallets');
        final response = await _client
            .from(_table)
            .select()
            .eq('user_id', _userId)
            .order('sort_order', ascending: true)
            .order('created_at', ascending: true);

        return response.map((e) => WalletModel.fromMap(e)).toList();
      },
    );
  }

  // ───────────────── CREATE ─────────────────

  /// Buat wallet baru. `balance` diset = `initial_balance` pada insert.
  Future<DataState<WalletModel>> createWallet(WalletModel wallet) {
    return SupabaseHandler.call<WalletModel>(
      function: () async {
        AppLogger.call('$_tag createWallet: ${wallet.name}');
        final response = await _client
            .from(_table)
            .insert(wallet.toInsertMap())
            .select()
            .single();

        return WalletModel.fromMap(response);
      },
    );
  }

  // ───────────────── UPDATE ─────────────────

  /// Update metadata wallet (name, icon, color, exclude_from_total, sort_order).
  /// **TIDAK** mengubah balance — itu hanya lewat trigger.
  Future<DataState<WalletModel>> updateWallet(WalletModel wallet) {
    return SupabaseHandler.call<WalletModel>(
      function: () async {
        AppLogger.call('$_tag updateWallet: ${wallet.id}');
        final response = await _client
            .from(_table)
            .update(wallet.toUpdateMap())
            .eq('id', wallet.id)
            .select()
            .single();

        return WalletModel.fromMap(response);
      },
    );
  }

  /// Toggle flag exclude_from_total.
  Future<DataState<void>> toggleExcludeFromTotal({
    required String walletId,
    required bool exclude,
  }) {
    return SupabaseHandler.call<void>(
      function: () async {
        AppLogger.call('$_tag toggleExcludeFromTotal: $walletId → $exclude');
        await _client
            .from(_table)
            .update({'exclude_from_total': exclude})
            .eq('id', walletId);
      },
    );
  }

  // ───────────────── DELETE ─────────────────

  /// Hapus wallet berdasarkan ID.
  Future<DataState<void>> deleteWallet(String walletId) {
    return SupabaseHandler.call<void>(
      function: () async {
        AppLogger.call('$_tag deleteWallet: $walletId');
        await _client.from(_table).delete().eq('id', walletId);
      },
    );
  }

  // ───────────────── GUARD ─────────────────

  /// Cek apakah wallet memiliki transaksi.
  /// Digunakan sebagai guard sebelum delete.
  Future<DataState<bool>> hasTransactions(String walletId) {
    return SupabaseHandler.call<bool>(
      function: () async {
        AppLogger.call('$_tag hasTransactions: $walletId');
        final response = await _client
            .from('transactions')
            .select('id')
            .or('wallet_id.eq.$walletId,destination_wallet_id.eq.$walletId')
            .limit(1);

        return (response as List).isNotEmpty;
      },
    );
  }
}
