import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/transaction/datasource/transaction_local_datasource.dart';
import 'package:app_saku_rapi/features/transaction/datasource/transaction_remote_datasource.dart';
import 'package:app_saku_rapi/features/transaction/models/category_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_form_state.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';

/// Repository utama untuk fitur transaksi.
///
/// Orkestrator yang memanggil [TransactionRemoteDataSource] dan
/// [TransactionLocalDataSource], menangani hasilnya via `.map()` dari [DataState].
class TransactionRepository {
  TransactionRepository({
    required TransactionRemoteDataSource remoteDataSource,
    required TransactionLocalDataSource localDataSource,
  }) : _remote = remoteDataSource,
       _local = localDataSource;

  final TransactionRemoteDataSource _remote;
  final TransactionLocalDataSource _local;

  static const String _tag = 'Transaction';

  // ─────────────────────────────────────────────────────────────
  // Save
  // ─────────────────────────────────────────────────────────────

  /// Menyimpan transaksi baru secara atomik (transaction + items via RPC).
  ///
  /// Setelah berhasil, hapus draft lokal.
  Future<DataState<TransactionModel>> saveTransaction({
    required TransactionFormState formState,
    required String userId,
  }) async {
    AppLogger.call(
      '[$_tag] Menyimpan transaksi: type=${formState.type}, '
      'total=${formState.totalAmount}',
      colorLog: ColorLog.blue,
    );

    final result = await _remote.saveTransaction(
      formState: formState,
      userId: userId,
    );

    result.map(
      success: (data) {
        AppLogger.logSuccess(
          '[$_tag] Transaksi berhasil disimpan: id=${data.data.id}',
        );
        _local.clearDraft();
      },
      error: (err) {
        AppLogger.logError('[$_tag] Gagal menyimpan transaksi: ${err.message}');
      },
    );

    return result;
  }

  // ─────────────────────────────────────────────────────────────
  // Read
  // ─────────────────────────────────────────────────────────────

  /// Mengambil daftar transaksi dengan filter range tanggal dan paginasi.
  Future<DataState<List<TransactionModel>>> getTransactions({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
    int page = 0,
    int limit = 20,
  }) async {
    AppLogger.call(
      '[$_tag] Fetch transaksi: '
      '${startDate.toIso8601String()} → ${endDate.toIso8601String()}, '
      'page=$page',
      colorLog: ColorLog.blue,
    );

    final result = await _remote.getTransactions(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      walletId: walletId,
      page: page,
      limit: limit,
    );

    result.map(
      success: (data) {
        AppLogger.call(
          '[$_tag] Fetch berhasil: ${data.data.length} transaksi',
          colorLog: ColorLog.green,
        );
      },
      error: (err) {
        AppLogger.logError('[$_tag] Fetch gagal: ${err.message}');
      },
    );

    return result;
  }

  /// Mengambil semua item dari satu transaksi.
  Future<DataState<List<TransactionItemModel>>> getTransactionItems(
    String transactionId,
  ) async {
    final result = await _remote.getTransactionItems(transactionId);

    result.map(
      success: (_) {},
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal fetch items ($transactionId): ${err.message}',
        );
      },
    );

    return result;
  }

  // ─────────────────────────────────────────────────────────────
  // Delete
  // ─────────────────────────────────────────────────────────────

  /// Menghapus transaksi (items terhapus otomatis via CASCADE).
  Future<DataState<bool>> deleteTransaction(String transactionId) async {
    AppLogger.call(
      '[$_tag] Menghapus transaksi ($transactionId)...',
      colorLog: ColorLog.blue,
    );

    final result = await _remote.deleteTransaction(transactionId);

    result.map(
      success: (_) {
        AppLogger.logSuccess(
          '[$_tag] Transaksi ($transactionId) berhasil dihapus',
        );
      },
      error: (err) {
        AppLogger.logError('[$_tag] Gagal menghapus transaksi: ${err.message}');
      },
    );

    return result;
  }

  // ─────────────────────────────────────────────────────────────
  // Update
  // ─────────────────────────────────────────────────────────────

  /// Memperbarui transaksi beserta item-itemnya.
  Future<DataState<TransactionModel>> updateTransaction({
    required TransactionModel transaction,
    required List<TransactionItemModel> items,
  }) async {
    AppLogger.call(
      '[$_tag] Memperbarui transaksi ${transaction.id}...',
      colorLog: ColorLog.blue,
    );

    final result = await _remote.updateTransaction(
      transaction: transaction,
      items: items,
    );

    result.map(
      success: (data) {
        AppLogger.logSuccess(
          '[$_tag] Transaksi ${data.data.id} berhasil diperbarui',
        );
      },
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal memperbarui transaksi: ${err.message}',
        );
      },
    );

    return result;
  }

  // ─────────────────────────────────────────────────────────────
  // Categories
  // ─────────────────────────────────────────────────────────────

  /// Mengambil daftar kategori (default + milik user) tidak tersembunyi.
  Future<DataState<List<CategoryModel>>> getCategories({
    required String userId,
    String? type,
  }) async {
    final result = await _remote.getCategories(userId: userId, type: type);

    result.map(
      success: (data) {
        AppLogger.call(
          '[$_tag] Kategori dimuat: ${data.data.length}',
          colorLog: ColorLog.green,
        );
      },
      error: (err) {
        AppLogger.logError('[$_tag] Gagal memuat kategori: ${err.message}');
      },
    );

    return result;
  }

  // ─────────────────────────────────────────────────────────────
  // Draft
  // ─────────────────────────────────────────────────────────────

  /// Simpan draft form lokal ke Hive.
  void saveDraft(TransactionFormState formState) => _local.saveDraft(formState);

  /// Muat draft form dari Hive.
  TransactionFormState? loadDraft() => _local.loadDraft();

  /// Hapus draft tersimpan.
  void clearDraft() => _local.clearDraft();
}
