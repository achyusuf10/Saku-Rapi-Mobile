import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/transaction/datasource/transaction_local_data_source.dart';
import 'package:app_saku_rapi/features/transaction/datasource/transaction_remote_data_source.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';

/// Repository utama untuk fitur transaksi.
///
/// Mengorkestrasikan [TransactionRemoteDataSource] dan
/// [TransactionLocalDataSource]:
/// - Validasi domain dilakukan di sini, bukan di widget.
/// - Write menggunakan RPC atomik.
/// - Read dengan join dan offline fallback.
class TransactionRepository {
  TransactionRepository({
    TransactionRemoteDataSource? remoteDataSource,
    TransactionLocalDataSource? localDataSource,
  }) : _remote = remoteDataSource ?? TransactionRemoteDataSource(),
       _local = localDataSource ?? TransactionLocalDataSource();

  final TransactionRemoteDataSource _remote;
  final TransactionLocalDataSource _local;

  static const _tag = '[Transaction] [TransactionRepository]';

  // ───────────────── READ ─────────────────

  /// Ambil transaksi dengan filter periode. Fallback ke cache jika gagal.
  Future<DataState<List<TransactionModel>>> getTransactions({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
    int limit = 50,
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
      _local.cacheTransactions(result.dataSuccess()!);
      return result;
    }

    // Offline fallback
    final cached = _local.getCachedTransactions();
    if (cached != null) {
      AppLogger.call('$_tag getTransactions: serving from cache');
      return DataState.success(data: cached);
    }

    return result;
  }

  /// Ambil detail satu transaksi by ID.
  Future<DataState<TransactionModel>> getTransactionById(String transactionId) {
    return _remote.getTransactionById(transactionId);
  }

  // ───────────────── VALIDATION ─────────────────

  /// Validasi input transaksi baru/edit.
  ///
  /// Mengembalikan pesan error, atau `null` jika valid.
  /// Digunakan oleh [createTransaction] dan [updateTransaction] sebelum RPC.
  static String? validateInput({
    required String walletId,
    required TransactionTypeEnum type,
    required double totalAmount,
    required List<TransactionItemModel> items,
    String? destinationWalletId,
    String? withPerson,
  }) {
    final l10n = appContext?.l10n;
    if (totalAmount <= 0) {
      return l10n?.validationAmountPositive ?? 'Nominal harus lebih dari 0';
    }

    if (type == TransactionTypeEnum.transfer) {
      if (destinationWalletId == null || destinationWalletId.isEmpty) {
        return l10n?.validationTransferNeedsDest ??
            'Transfer memerlukan dompet tujuan';
      }
      if (walletId == destinationWalletId) {
        return l10n?.transactionSameWalletError ??
            'Dompet asal dan tujuan tidak boleh sama';
      }
    }

    if (type.requiresWithPerson) {
      if (withPerson == null || withPerson.trim().isEmpty) {
        return l10n?.transactionWithPersonRequired ??
            'Nama kontak wajib diisi untuk hutang/piutang';
      }
    }

    if (items.isEmpty) {
      return l10n?.validationMinOneItem ??
          'Transaksi harus memiliki minimal 1 item';
    }

    final itemsSum = items.fold(0.0, (sum, item) => sum + item.amount);
    if ((itemsSum - totalAmount).abs() > 0.01) {
      return l10n?.validationItemsTotalMismatch('$itemsSum', '$totalAmount') ??
          'Total item ($itemsSum) tidak sama dengan total transaksi ($totalAmount)';
    }

    if (type == TransactionTypeEnum.income ||
        type == TransactionTypeEnum.expense) {
      for (final item in items) {
        if (item.categoryId == null || item.categoryId!.isEmpty) {
          return l10n?.validationCategoryRequired ??
              'Kategori wajib dipilih untuk setiap item';
        }
      }
    }

    return null;
  }

  // ───────────────── CREATE ─────────────────

  /// Buat transaksi baru setelah validasi domain.
  ///
  /// Rules validasi:
  /// - `totalAmount > 0` (kecuali adjustment)
  /// - `type == transfer` → wajib `destinationWalletId`, tidak boleh sama
  /// - `type in (debt, loan)` → wajib `withPerson`
  /// - items minimal 1, sum(items.amount) == totalAmount
  /// - category wajib untuk income/expense items
  Future<DataState<Map<String, dynamic>>> createTransaction({
    required String walletId,
    String? destinationWalletId,
    required TransactionTypeEnum type,
    required double totalAmount,
    required DateTime date,
    String? merchantName,
    String? note,
    String? attachmentUrl,
    String? withPerson,
    String? contactId,
    String? debtStatus,
    DateTime? dueDate,
    required List<TransactionItemModel> items,
    String? referenceTransactionId,
    String? settlementKind,
  }) async {
    final validationError = validateInput(
      walletId: walletId,
      type: type,
      totalAmount: totalAmount,
      items: items,
      destinationWalletId: destinationWalletId,
      withPerson: withPerson,
    );

    if (validationError != null) {
      return DataState.error(message: validationError);
    }

    return _remote.createTransaction(
      walletId: walletId,
      destinationWalletId: destinationWalletId,
      type: type.toDbValue(),
      totalAmount: totalAmount,
      date: date,
      merchantName: merchantName,
      note: note,
      attachmentUrl: attachmentUrl,
      withPerson: withPerson,
      status: debtStatus,
      dueDate: dueDate,
      isMultiItem: items.length > 1,
      referenceTransactionId: referenceTransactionId,
      settlementKind: settlementKind,
      items: items,
      contactId: contactId,
    );
  }

  // ───────────────── UPDATE ─────────────────

  /// Update transaksi dan items. Validasi domain identik dengan create.
  Future<DataState<Map<String, dynamic>>> updateTransaction({
    required String transactionId,
    required String walletId,
    String? destinationWalletId,
    required TransactionTypeEnum type,
    required double totalAmount,
    required DateTime date,
    String? merchantName,
    String? note,
    String? attachmentUrl,
    String? withPerson,
    String? contactId,
    String? debtStatus,
    DateTime? dueDate,
    required List<TransactionItemModel> items,
    String? referenceTransactionId,
    String? settlementKind,
  }) async {
    final validationError = validateInput(
      walletId: walletId,
      type: type,
      totalAmount: totalAmount,
      items: items,
      destinationWalletId: destinationWalletId,
      withPerson: withPerson,
    );

    if (validationError != null) {
      return DataState.error(message: validationError);
    }

    return _remote.updateTransaction(
      transactionId: transactionId,
      walletId: walletId,
      destinationWalletId: destinationWalletId,
      type: type.toDbValue(),
      totalAmount: totalAmount,
      date: date,
      merchantName: merchantName,
      note: note,
      attachmentUrl: attachmentUrl,
      withPerson: withPerson,
      status: debtStatus,
      dueDate: dueDate,
      isMultiItem: items.length > 1,
      referenceTransactionId: referenceTransactionId,
      settlementKind: settlementKind,
      items: items,
      contactId: contactId,
    );
  }

  // ───────────────── DELETE ─────────────────

  /// Hapus transaksi via RPC. Trigger akan reverse saldo wallet.
  Future<DataState<Map<String, dynamic>>> deleteTransaction(
    String transactionId,
  ) {
    return _remote.deleteTransaction(transactionId);
  }

  // ───────────────── ADJUSTMENT ─────────────────

  /// Buat transaksi penyesuaian saldo.
  Future<DataState<Map<String, dynamic>>> createAdjustment({
    required String walletId,
    required double targetBalance,
    DateTime? date,
    String? note,
  }) {
    return _remote.createAdjustment(
      walletId: walletId,
      targetBalance: targetBalance,
      date: date,
      note: note,
    );
  }

  // ───────────────── SETTLEMENT ─────────────────

  /// Lunasi hutang atau tagih piutang.
  ///
  /// Validasi:
  /// - amount > 0
  /// - walletId tidak kosong
  /// - referenceTransactionId tidak kosong
  /// Selebihnya divalidasi oleh RPC (sisa principal, ownership, dsb).
  Future<DataState<Map<String, dynamic>>> settleDebtOrLoan({
    required String referenceTransactionId,
    required String settlementKind,
    required double amount,
    required String walletId,
    DateTime? date,
    String? note,
  }) {
    if (amount <= 0) {
      return Future.value(
        const DataState.error(message: 'Nominal pelunasan harus lebih dari 0'),
      );
    }

    return _remote.settleDebtOrLoan(
      referenceTransactionId: referenceTransactionId,
      settlementKind: settlementKind,
      amount: amount,
      walletId: walletId,
      date: date,
      note: note,
    );
  }

  // ───────────────── CACHE ─────────────────

  void clearCache() {
    _local.clearTransactionCache();
  }
}
