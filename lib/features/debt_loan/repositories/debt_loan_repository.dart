import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/debt_loan/datasource/debt_loan_remote_data_source.dart';
import 'package:app_saku_rapi/features/debt_loan/models/debt_loan_summary_model.dart';
import 'package:app_saku_rapi/features/debt_loan/models/debt_loan_transaction_model.dart';
import 'package:app_saku_rapi/features/debt_loan/models/settlement_history_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider untuk [DebtLoanRepository].
final debtLoanRepositoryProvider = Provider<DebtLoanRepository>(
  (ref) => DebtLoanRepository(),
);

/// Repository untuk fitur hutang/piutang.
///
/// Menjembatani controller ↔ remote data source.
class DebtLoanRepository {
  DebtLoanRepository({DebtLoanRemoteDataSource? remote})
    : _remote = remote ?? DebtLoanRemoteDataSource();

  final DebtLoanRemoteDataSource _remote;

  /// Ambil ringkasan per kontak.
  Future<DataState<List<DebtLoanSummaryModel>>> getSummary({
    required String type,
    String? walletId,
  }) {
    return _remote.getSummary(type: type, walletId: walletId);
  }

  /// Ambil transaksi per orang.
  Future<DataState<List<DebtLoanTransactionModel>>> getTransactionsByPerson({
    required String withPerson,
    required String type,
    String? walletId,
  }) {
    return _remote.getTransactionsByPerson(
      withPerson: withPerson,
      type: type,
      walletId: walletId,
    );
  }

  /// Ambil riwayat pelunasan per transaksi.
  Future<DataState<List<SettlementHistoryModel>>> getSettlementHistory({
    required String referenceTransactionId,
  }) {
    return _remote.getSettlementHistory(
      referenceTransactionId: referenceTransactionId,
    );
  }
}
