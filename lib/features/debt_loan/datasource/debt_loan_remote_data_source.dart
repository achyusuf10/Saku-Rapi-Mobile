import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/debt_loan/models/debt_loan_summary_model.dart';
import 'package:app_saku_rapi/features/debt_loan/models/debt_loan_transaction_model.dart';
import 'package:app_saku_rapi/features/debt_loan/models/settlement_history_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk fitur hutang/piutang.
///
/// Menggunakan 3 RPC utama:
/// - `get_debt_loan_summary` — aggregate per kontak
/// - `get_debt_loan_transactions_by_person` — detail transaksi per kontak
/// - `get_settlement_history` — riwayat pelunasan per transaksi
class DebtLoanRemoteDataSource {
  DebtLoanRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _tag = '[DebtLoan] [DebtLoanRemoteDataSource]';

  // ───────────────── Summary (per kontak) ─────────────────

  /// Ambil ringkasan hutang/piutang per kontak.
  Future<DataState<List<DebtLoanSummaryModel>>> getSummary({
    required String type,
    String? walletId,
  }) {
    return SupabaseHandler.call<List<DebtLoanSummaryModel>>(
      function: () async {
        AppLogger.call('$_tag getSummary: type=$type, wallet=$walletId');

        final params = <String, dynamic>{'p_type': type};
        if (walletId != null) {
          params['p_wallet_id'] = walletId;
        }

        final result = await _client.rpc(
          'get_debt_loan_summary',
          params: params,
        );

        final list = (result as List)
            .map(
              (e) => DebtLoanSummaryModel.fromMap(Map<String, dynamic>.from(e)),
            )
            .toList();

        return list;
      },
    );
  }

  // ───────────────── Transactions by Person ─────────────────

  /// Ambil semua transaksi hutang/piutang dengan satu orang.
  Future<DataState<List<DebtLoanTransactionModel>>> getTransactionsByPerson({
    String? withPerson,
    required String type,
    String? walletId,
  }) {
    return SupabaseHandler.call<List<DebtLoanTransactionModel>>(
      function: () async {
        AppLogger.call(
          '$_tag getTransactionsByPerson: person=$withPerson, type=$type',
        );

        final params = <String, dynamic>{
          'p_with_person': withPerson,
          'p_type': type,
        };
        if (walletId != null) {
          params['p_wallet_id'] = walletId;
        }

        final result = await _client.rpc(
          'get_debt_loan_transactions_by_person',
          params: params,
        );

        final list = (result as List)
            .map(
              (e) => DebtLoanTransactionModel.fromMap(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();

        return list;
      },
    );
  }

  // ───────────────── All Unpaid Transactions ─────────────────

  /// Ambil semua transaksi hutang/piutang yang belum lunas.
  Future<DataState<List<DebtLoanTransactionModel>>> getAllUnpaid({
    required String type,
  }) {
    return SupabaseHandler.call<List<DebtLoanTransactionModel>>(
      function: () async {
        AppLogger.call('$_tag getAllUnpaid: type=$type');

        final result = await _client.rpc(
          'get_all_unpaid_debt_loan',
          params: {'p_type': type},
        );

        final list = (result as List)
            .map(
              (e) => DebtLoanTransactionModel.fromMap(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();

        return list;
      },
    );
  }

  // ───────────────── Settlement History ─────────────────

  /// Ambil riwayat pelunasan untuk satu transaksi hutang/piutang.
  Future<DataState<List<SettlementHistoryModel>>> getSettlementHistory({
    required String referenceTransactionId,
  }) {
    return SupabaseHandler.call<List<SettlementHistoryModel>>(
      function: () async {
        AppLogger.call(
          '$_tag getSettlementHistory: ref=$referenceTransactionId',
        );

        final result = await _client.rpc(
          'get_settlement_history',
          params: {'p_reference_transaction_id': referenceTransactionId},
        );

        final list = (result as List)
            .map(
              (e) =>
                  SettlementHistoryModel.fromMap(Map<String, dynamic>.from(e)),
            )
            .toList();

        return list;
      },
    );
  }
}
