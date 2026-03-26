import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/investment/models/investment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk investasi.
///
/// Read menggunakan query langsung dengan join wallet.
/// Write create menggunakan RPC `create_investment_with_optional_wallet_deduction`
/// untuk operasi atomik (insert investment + optional transfer_to_asset).
/// Update/delete menggunakan REST langsung karena tidak melibatkan ledger.
class InvestmentRemoteDataSource {
  InvestmentRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _table = 'investments';
  static const _tag = '[Investment] [InvestmentRemoteDataSource]';

  String get _userId => _client.auth.currentUser!.id;

  // ───────────────── READ ─────────────────

  /// Ambil semua investasi user dengan join wallet name.
  Future<DataState<List<InvestmentModel>>> getInvestments() {
    return SupabaseHandler.call<List<InvestmentModel>>(
      function: () async {
        AppLogger.call('$_tag getInvestments');

        final response = await _client
            .from(_table)
            .select('''
              *,
              wallets!investments_linked_wallet_id_fkey(name)
            ''')
            .eq('user_id', _userId)
            .order('created_at', ascending: false);

        return response.map((e) => InvestmentModel.fromMap(e)).toList();
      },
    );
  }

  /// Ambil satu investasi by ID.
  Future<DataState<InvestmentModel>> getInvestmentById(String investmentId) {
    return SupabaseHandler.call<InvestmentModel>(
      function: () async {
        AppLogger.call('$_tag getInvestmentById: $investmentId');

        final response = await _client
            .from(_table)
            .select('''
              *,
              wallets!investments_linked_wallet_id_fkey(name)
            ''')
            .eq('id', investmentId)
            .eq('user_id', _userId)
            .single();

        return InvestmentModel.fromMap(response);
      },
    );
  }

  // ───────────────── CREATE (RPC) ─────────────────

  /// Buat investasi baru via RPC atomik.
  ///
  /// Jika [deductFromWallet] true dan [walletId] diisi,
  /// RPC juga membuat transaksi `transfer_to_asset` dan trigger update saldo.
  Future<DataState<Map<String, dynamic>>> createInvestment({
    required String type,
    required String name,
    String? symbol,
    required double amount,
    required double avgBuyPrice,
    double? customCurrentPrice,
    String? linkedWalletId,
    String? notes,
    required bool deductFromWallet,
  }) {
    return SupabaseHandler.call<Map<String, dynamic>>(
      function: () async {
        AppLogger.call(
          '$_tag createInvestment: name=$name, type=$type, '
          'deductWallet=$deductFromWallet',
        );

        final result = await _client.rpc(
          'create_investment_with_optional_wallet_deduction',
          params: {
            'p_type': type,
            'p_name': name,
            'p_symbol': symbol,
            'p_amount': amount,
            'p_avg_buy_price': avgBuyPrice,
            'p_custom_current_price': customCurrentPrice,
            'p_linked_wallet_id': linkedWalletId,
            'p_notes': notes,
            'p_deduct_from_wallet': deductFromWallet,
          },
        );

        return Map<String, dynamic>.from(result as Map);
      },
    );
  }

  // ───────────────── UPDATE ─────────────────

  /// Update investasi yang sudah ada (REST, tanpa ledger impact).
  Future<DataState<InvestmentModel>> updateInvestment({
    required String investmentId,
    required Map<String, dynamic> updates,
  }) {
    return SupabaseHandler.call<InvestmentModel>(
      function: () async {
        AppLogger.call('$_tag updateInvestment: $investmentId');

        final response = await _client
            .from(_table)
            .update(updates)
            .eq('id', investmentId)
            .eq('user_id', _userId)
            .select('''
              *,
              wallets!investments_linked_wallet_id_fkey(name)
            ''')
            .single();

        return InvestmentModel.fromMap(response);
      },
    );
  }

  // ───────────────── DELETE ─────────────────

  /// Hapus investasi (hard delete).
  Future<DataState<void>> deleteInvestment(String investmentId) {
    return SupabaseHandler.call<void>(
      function: () async {
        AppLogger.call('$_tag deleteInvestment: $investmentId');

        await _client
            .from(_table)
            .delete()
            .eq('id', investmentId)
            .eq('user_id', _userId);
      },
    );
  }
}
