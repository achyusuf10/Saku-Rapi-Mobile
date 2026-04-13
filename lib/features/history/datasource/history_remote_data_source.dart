import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/core/utils/saku_date_utils.dart';
import 'package:app_saku_rapi/features/history/models/history_models.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk fitur history.
///
/// Menggunakan RPC [get_history_transactions] untuk dual-mode pagination
/// (byDate / byCategory) dan server-side search.
class HistoryRemoteDataSource {
  HistoryRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _tag = '[History] [HistoryRemoteDataSource]';

  /// Ambil transaksi via RPC dengan dual-mode pagination dan search.
  ///
  /// [groupMode]: 'byDate' (pagination per transaksi) atau
  ///              'byCategory' (pagination per kategori).
  /// [search]: keyword pencarian server-side (notes OR category name).
  Future<DataState<HistoryResult>> getTransactions({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
    String? type,
    String? search,
    String groupMode = 'byDate',
    int limit = 30,
    int offset = 0,
  }) {
    return SupabaseHandler.call<HistoryResult>(
      function: () async {
        AppLogger.call(
          '$_tag getTransactions: $startDate - $endDate, '
          'wallet=$walletId, type=$type, search=$search, '
          'mode=$groupMode, limit=$limit, offset=$offset',
        );

        final range = SakuDateUtils.localDayRangeUtc(
          startDate: startDate,
          endDate: endDate,
        );

        final response = await _client.rpc(
          'get_history_transactions',
          params: {
            'p_start_date': range.startUtc,
            'p_end_date': range.endUtcExclusive,
            'p_wallet_id': walletId,
            'p_type': type,
            'p_search': search,
            'p_group_mode': groupMode,
            'p_limit': limit,
            'p_offset': offset,
          },
        );

        final data = response as Map<String, dynamic>;
        final txList = (data['transactions'] as List)
            .map((e) => TransactionModel.fromMap(e as Map<String, dynamic>))
            .toList();

        return HistoryResult(
          transactions: txList,
          hasMore: data['has_more'] as bool,
        );
      },
    );
  }

  /// Ambil transaksi untuk halaman report berdasarkan kategori.
  ///
  /// Menggunakan PostgREST langsung karena report page memfilter
  /// berdasarkan [categoryId] yang tidak di-support oleh RPC history.
  Future<DataState<List<TransactionModel>>> getTransactionsByCategory({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
    required String categoryId,
    String? type,
    int limit = 200,
  }) {
    return SupabaseHandler.call<List<TransactionModel>>(
      function: () async {
        AppLogger.call(
          '$_tag getTransactionsByCategory: '
          'cat=$categoryId, type=$type',
        );

        final range = SakuDateUtils.localDayRangeUtc(
          startDate: startDate,
          endDate: endDate,
        );

        var query = _client
            .from('transactions')
            .select('''
              *,
              wallet:wallets(*),
              destination_wallet:wallets!transactions_destination_wallet_id_fkey(*),
              transaction_items(*, category:categories(*))
            ''')
            .gte('date', range.startUtc)
            .lt('date', range.endUtcExclusive);

        if (walletId != null) {
          query = query.eq('wallet_id', walletId);
        }
        if (type != null) {
          query = query.eq('type', type);
        }

        final res = await query
            .order('date', ascending: false)
            .limit(limit);

        final allTx =
            res.map((e) => TransactionModel.fromMap(e)).toList();

        // Filter client-side by categoryId in transaction_items
        return allTx
            .where(
              (tx) => tx.items.any((item) => item.categoryId == categoryId),
            )
            .toList();
      },
    );
  }
}
