import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk fitur history.
///
/// Read-only query ke `transactions` dengan join items, wallet, category.
/// Write (delete/update) tetap dilakukan via [TransactionRemoteDataSource].
class HistoryRemoteDataSource {
  HistoryRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _table = 'transactions';
  static const _tag = '[History] [HistoryRemoteDataSource]';

  String get _userId => _client.auth.currentUser!.id;

  /// Ambil transaksi dengan filter period, wallet, dan pagination.
  ///
  /// Query sesuai PRD §7.8: hanya date range + wallet filter ke backend.
  /// Grouping/type filter dilakukan lokal.
  Future<DataState<List<TransactionModel>>> getTransactions({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
    int limit = 30,
    int offset = 0,
  }) {
    return SupabaseHandler.call<List<TransactionModel>>(
      function: () async {
        AppLogger.call(
          '$_tag getTransactions: $startDate - $endDate, '
          'wallet=$walletId, limit=$limit, offset=$offset',
        );

        var query = _client
            .from(_table)
            .select('''
              *,
              wallets!transactions_wallet_id_fkey(name),
              destination_wallet:wallets!transactions_destination_wallet_id_fkey(name),
              transaction_items(
                *,
                categories(name, icon, color)
              )
            ''')
            .eq('user_id', _userId)
            .gte('date', startDate.toIso8601String())
            .lte('date', endDate.toIso8601String());

        if (walletId != null) {
          query = query.eq('wallet_id', walletId);
        }

        final response = await query
            .order('date', ascending: false)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

        return response.map((e) => TransactionModel.fromMap(e)).toList();
      },
    );
  }
}
