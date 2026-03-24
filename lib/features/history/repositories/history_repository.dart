import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/history/datasource/history_local_data_source.dart';
import 'package:app_saku_rapi/features/history/datasource/history_remote_data_source.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';

/// Repository untuk fitur history transaksi.
///
/// Mengorkestrasikan [HistoryRemoteDataSource] dan [HistoryLocalDataSource].
/// - Read: fetch dari Supabase dengan fallback ke cache lokal.
/// - Write (delete/update): delegasi ke [TransactionRepository].
class HistoryRepository {
  HistoryRepository({
    HistoryRemoteDataSource? remoteDataSource,
    HistoryLocalDataSource? localDataSource,
  }) : _remote = remoteDataSource ?? HistoryRemoteDataSource(),
       _local = localDataSource ?? HistoryLocalDataSource();

  final HistoryRemoteDataSource _remote;
  final HistoryLocalDataSource _local;

  static const _tag = '[History] [HistoryRepository]';

  /// Ambil transaksi dengan filter period dan wallet.
  /// Fallback ke cache jika remote gagal.
  Future<DataState<List<TransactionModel>>> getTransactions({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
    int limit = 30,
    int offset = 0,
  }) async {
    final result = await _remote.getTransactions(
      startDate: startDate,
      endDate: endDate,
      walletId: walletId,
      limit: limit,
      offset: offset,
    );

    if (result.isSuccess()) {
      // Cache halaman pertama saja untuk fallback offline
      if (offset == 0) {
        _local.cacheTransactions(result.dataSuccess()!);
      }
      return result;
    }

    // Offline fallback — hanya untuk halaman pertama
    if (offset == 0) {
      final cached = _local.getCachedTransactions();
      if (cached != null) {
        AppLogger.call('$_tag getTransactions: serving from cache');
        return DataState.success(data: cached);
      }
    }

    return result;
  }

  /// Hapus cache lokal.
  void clearCache() {
    _local.clearCache();
  }
}
