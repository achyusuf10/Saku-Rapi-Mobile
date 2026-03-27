import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk transaksi.
///
/// Semua write menggunakan RPC atomik sesuai `02_DATABASE.md` §3.2:
/// - `create_transaction_with_items`
/// - `update_transaction_with_items`
/// - `delete_transaction`
/// - `create_adjustment_transaction`
/// - `settle_debt_or_loan`
///
/// Read menggunakan query langsung dengan join.
class TransactionRemoteDataSource {
  TransactionRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _table = 'transactions';
  static const _tag = '[Transaction] [TransactionRemoteDataSource]';

  String get _userId => _client.auth.currentUser!.id;

  // ───────────────── READ ─────────────────

  /// Ambil transaksi dengan join items, wallet, dan category.
  /// Mendukung filter period dan wallet.
  Future<DataState<List<TransactionModel>>> getTransactions({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
    int limit = 50,
    int offset = 0,
  }) {
    return SupabaseHandler.call<List<TransactionModel>>(
      function: () async {
        AppLogger.call(
          '$_tag getTransactions: $startDate - $endDate, wallet=$walletId',
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

  /// Ambil satu transaksi by ID dengan join lengkap.
  Future<DataState<TransactionModel>> getTransactionById(String transactionId) {
    return SupabaseHandler.call<TransactionModel>(
      function: () async {
        AppLogger.call('$_tag getTransactionById: $transactionId');

        final response = await _client
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
            .eq('id', transactionId)
            .eq('user_id', _userId)
            .single();

        return TransactionModel.fromMap(response);
      },
    );
  }

  // ───────────────── CREATE (RPC) ─────────────────

  /// Buat transaksi + items secara atomik via RPC.
  Future<DataState<Map<String, dynamic>>> createTransaction({
    required String walletId,
    String? destinationWalletId,
    required String type,
    required double totalAmount,
    required DateTime date,
    String? merchantName,
    String? note,
    String? attachmentUrl,
    String? withPerson,
    String? contactId,
    String? status,
    DateTime? dueDate,
    required bool isMultiItem,
    String? referenceTransactionId,
    String? settlementKind,
    required List<TransactionItemModel> items,
  }) {
    return SupabaseHandler.call<Map<String, dynamic>>(
      function: () async {
        AppLogger.call(
          '$_tag createTransaction: type=$type, amount=$totalAmount',
        );

        final result = await _client.rpc(
          'create_transaction_with_items',
          params: {
            'p_wallet_id': walletId,
            'p_destination_wallet_id': destinationWalletId,
            'p_type': type,
            'p_total_amount': totalAmount,
            'p_date': date.toIso8601String(),
            'p_merchant_name': merchantName,
            'p_note': note,
            'p_attachment_url': attachmentUrl,
            'p_with_person': withPerson,
            'p_contact_id': contactId,
            'p_status': status,
            'p_due_date': dueDate?.toIso8601String(),
            'p_is_multi_item': isMultiItem,
            'p_reference_transaction_id': referenceTransactionId,
            'p_settlement_kind': settlementKind,
            'p_items': items.map((i) => i.toRpcMap()).toList(),
          },
        );

        return Map<String, dynamic>.from(result as Map);
      },
    );
  }

  // ───────────────── UPDATE (RPC) ─────────────────

  /// Update transaksi + items secara atomik via RPC.
  Future<DataState<Map<String, dynamic>>> updateTransaction({
    required String transactionId,
    required String walletId,
    String? destinationWalletId,
    required String type,
    required double totalAmount,
    required DateTime date,
    String? merchantName,
    String? note,
    String? attachmentUrl,
    String? withPerson,
    String? contactId,
    String? status,
    DateTime? dueDate,
    required bool isMultiItem,
    String? referenceTransactionId,
    String? settlementKind,
    required List<TransactionItemModel> items,
  }) {
    return SupabaseHandler.call<Map<String, dynamic>>(
      function: () async {
        AppLogger.call('$_tag updateTransaction: id=$transactionId');

        final result = await _client.rpc(
          'update_transaction_with_items',
          params: {
            'p_transaction_id': transactionId,
            'p_wallet_id': walletId,
            'p_destination_wallet_id': destinationWalletId,
            'p_type': type,
            'p_total_amount': totalAmount,
            'p_date': date.toIso8601String(),
            'p_merchant_name': merchantName,
            'p_note': note,
            'p_attachment_url': attachmentUrl,
            'p_with_person': withPerson,
            'p_contact_id': contactId,
            'p_status': status,
            'p_due_date': dueDate?.toIso8601String(),
            'p_is_multi_item': isMultiItem,
            'p_reference_transaction_id': referenceTransactionId,
            'p_settlement_kind': settlementKind,
            'p_items': items.map((i) => i.toRpcMap()).toList(),
          },
        );

        return Map<String, dynamic>.from(result as Map);
      },
    );
  }

  // ───────────────── DELETE (RPC) ─────────────────

  /// Hapus transaksi via RPC. Trigger akan reverse saldo wallet.
  Future<DataState<Map<String, dynamic>>> deleteTransaction(
    String transactionId,
  ) {
    return SupabaseHandler.call<Map<String, dynamic>>(
      function: () async {
        AppLogger.call('$_tag deleteTransaction: id=$transactionId');

        final result = await _client.rpc(
          'delete_transaction',
          params: {'p_transaction_id': transactionId},
        );

        return Map<String, dynamic>.from(result as Map);
      },
    );
  }

  // ───────────────── ADJUSTMENT (RPC) ─────────────────

  /// Buat transaksi penyesuaian saldo via RPC.
  Future<DataState<Map<String, dynamic>>> createAdjustment({
    required String walletId,
    required double targetBalance,
    DateTime? date,
    String? note,
  }) {
    return SupabaseHandler.call<Map<String, dynamic>>(
      function: () async {
        AppLogger.call(
          '$_tag createAdjustment: wallet=$walletId, target=$targetBalance',
        );

        final result = await _client.rpc(
          'create_adjustment_transaction',
          params: {
            'p_wallet_id': walletId,
            'p_target_balance': targetBalance,
            'p_date': (date ?? DateTime.now()).toIso8601String(),
            'p_note': note,
          },
        );

        return Map<String, dynamic>.from(result as Map);
      },
    );
  }

  // ───────────────── SETTLEMENT (RPC) ─────────────────

  /// Lunasi hutang / tagih piutang via RPC `settle_debt_or_loan`.
  ///
  /// [referenceTransactionId] — ID transaksi debt/loan asal.
  /// [settlementKind] — `debt_payment` atau `loan_collection`.
  /// [amount] — jumlah pelunasan (tidak boleh melebihi sisa principal).
  /// [walletId] — wallet yang digunakan untuk bayar/terima.
  Future<DataState<Map<String, dynamic>>> settleDebtOrLoan({
    required String referenceTransactionId,
    required String settlementKind,
    required double amount,
    required String walletId,
    DateTime? date,
    String? note,
  }) {
    return SupabaseHandler.call<Map<String, dynamic>>(
      function: () async {
        AppLogger.call(
          '$_tag settleDebtOrLoan: ref=$referenceTransactionId, '
          'kind=$settlementKind, amount=$amount',
        );

        final result = await _client.rpc(
          'settle_debt_or_loan',
          params: {
            'p_reference_transaction_id': referenceTransactionId,
            'p_settlement_kind': settlementKind,
            'p_amount': amount,
            'p_wallet_id': walletId,
            'p_date': (date ?? DateTime.now()).toIso8601String(),
            'p_note': note,
          },
        );

        return Map<String, dynamic>.from(result as Map);
      },
    );
  }
}
