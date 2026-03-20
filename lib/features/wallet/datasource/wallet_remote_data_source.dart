import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Data source untuk operasi CRUD wallet ke Supabase.
///
/// Semua fungsi dibungkus dengan [SupabaseHandler.call] dan
/// mengembalikan [DataState<T>] sesuai aturan arsitektur.
class WalletRemoteDataSource {
  WalletRemoteDataSource({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  static const String _table = 'wallets';
  static const String _txTable = 'transactions';

  /// Mengambil semua wallet milik user yang sedang login,
  /// diurutkan berdasarkan `sort_order` lalu `created_at`.
  Future<DataState<List<WalletModel>>> getWallets() {
    return SupabaseHandler.call<List<WalletModel>>(
      function: () async {
        final response = await _client
            .from(_table)
            .select()
            .order('sort_order', ascending: true)
            .order('created_at', ascending: true);

        return response.map(WalletModel.fromMap).toList();
      },
    );
  }

  /// Mengambil satu wallet berdasarkan [walletId].
  Future<DataState<WalletModel>> getWalletById(String walletId) {
    return SupabaseHandler.call<WalletModel>(
      function: () async {
        final response = await _client
            .from(_table)
            .select()
            .eq('id', walletId)
            .single();

        return WalletModel.fromMap(response);
      },
    );
  }

  /// Membuat wallet baru. Mengembalikan wallet yang baru dibuat.
  Future<DataState<WalletModel>> createWallet(WalletModel wallet) {
    return SupabaseHandler.call<WalletModel>(
      function: () async {
        final response = await _client
            .from(_table)
            .insert(wallet.toMap())
            .select()
            .single();

        return WalletModel.fromMap(response);
      },
    );
  }

  /// Memperbarui data wallet. Mengembalikan wallet yang sudah diperbarui.
  Future<DataState<WalletModel>> updateWallet(WalletModel wallet) {
    return SupabaseHandler.call<WalletModel>(
      function: () async {
        final response = await _client
            .from(_table)
            .update(wallet.toMap())
            .eq('id', wallet.id)
            .select()
            .single();

        return WalletModel.fromMap(response);
      },
    );
  }

  /// Menghapus wallet berdasarkan [walletId].
  Future<DataState<void>> deleteWallet(String walletId) {
    return SupabaseHandler.call<void>(
      function: () async {
        await _client.from(_table).delete().eq('id', walletId);
      },
    );
  }

  /// Menyesuaikan saldo wallet dengan cara menyisipkan transaksi
  /// bertipe `adjustment`.
  ///
  /// [walletId] — wallet yang dikoreksi.
  /// [delta] — selisih saldo (actual - current). Bisa positif/negatif.
  ///
  /// Trigger DB `update_wallet_balance` akan otomatis mengubah
  /// kolom `balance` pada tabel wallets.
  Future<DataState<void>> adjustBalance({
    required String walletId,
    required String userId,
    required double delta,
  }) {
    return SupabaseHandler.call<void>(
      function: () async {
        await _client.from(_txTable).insert({
          'user_id': userId,
          'wallet_id': walletId,
          'type': 'adjustment',
          'total_amount': delta,
        });
      },
    );
  }
}
