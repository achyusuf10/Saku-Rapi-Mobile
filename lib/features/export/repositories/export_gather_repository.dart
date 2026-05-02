import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/debt_loan/models/debt_loan_transaction_model.dart';
import 'package:app_saku_rapi/features/debt_loan/repositories/debt_loan_repository.dart';
import 'package:app_saku_rapi/features/export/models/export_cancel_signal.dart';
import 'package:app_saku_rapi/features/export/models/export_cancelled_exception.dart';
import 'package:app_saku_rapi/features/export/models/export_gathered_data_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/features/transaction/repositories/transaction_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [TransactionRepository] + [DebtLoanRepository] untuk export.
final exportGatherRepositoryProvider = Provider<ExportGatherRepository>(
  (ref) => ExportGatherRepository(
    transactionRepository: TransactionRepository(),
    debtLoanRepository: ref.read(debtLoanRepositoryProvider),
  ),
);

/// Mengorkestrasikan pengambilan data untuk export Excel (chunk + hutang global).
class ExportGatherRepository {
  ExportGatherRepository({
    required TransactionRepository transactionRepository,
    required DebtLoanRepository debtLoanRepository,
  })  : _transactions = transactionRepository,
        _debtLoan = debtLoanRepository;

  static const _tag = '[Export] [ExportGatherRepository]';
  static const _chunkSize = 100;

  final TransactionRepository _transactions;
  final DebtLoanRepository _debtLoan;

  /// Mengumpulkan transaksi periode (income/expense + transfer dipisah) dan
  /// opsional seluruh hutang/piutang. Melempar [ExportCancelledException] jika
  /// [signal.isCancelled].
  Future<ExportGatheredDataModel> gatherForExport({
    required DateTime periodStartLocal,
    required DateTime periodEndLocal,
    required bool includeDebtSheet,
    required ExportCancelSignal signal,
  }) async {
    final incomeExpense = <TransactionModel>[];
    final transfers = <TransactionModel>[];
    var partialPeriod = false;

    var offset = 0;
    while (true) {
      if (signal.isCancelled) {
        throw ExportCancelledException();
      }

      final state = await _transactions.getTransactions(
        startDate: periodStartLocal,
        endDate: periodEndLocal,
        limit: _chunkSize,
        offset: offset,
      );

      if (!state.isSuccess()) {
        AppLogger.call('$_tag chunk failed offset=$offset');
        final err = state.dataError();
        throw Exception(err?.$1 ?? 'getTransactions failed');
      }

      final batch = state.dataSuccess()!;
      for (final t in batch) {
        switch (t.type) {
          case TransactionTypeEnum.income:
          case TransactionTypeEnum.expense:
            incomeExpense.add(t);
            break;
          case TransactionTypeEnum.transfer:
            transfers.add(t);
            break;
          default:
            break;
        }
      }

      if (batch.length < _chunkSize) break;
      if (signal.stopChunks) {
        partialPeriod = true;
        break;
      }
      offset += _chunkSize;
    }

    final debtRows = <DebtLoanTransactionModel>[];
    if (includeDebtSheet && !signal.isCancelled) {
      await _loadAllDebtLoan(target: debtRows, signal: signal);
    }

    return ExportGatheredDataModel(
      incomeExpenseForPeriod: incomeExpense,
      transfersForPeriod: transfers,
      debtLoanRows: debtRows,
      isPartialPeriod: partialPeriod,
    );
  }

  Future<void> _loadAllDebtLoan({
    required List<DebtLoanTransactionModel> target,
    required ExportCancelSignal signal,
  }) async {
    for (final type in const ['debt', 'loan']) {
      if (signal.isCancelled) throw ExportCancelledException();

      final sumState = await _debtLoan.getSummary(type: type);
      if (!sumState.isSuccess()) {
        AppLogger.call('$_tag getSummary failed type=$type');
        final err = sumState.dataError();
        throw Exception(err?.$1 ?? 'getSummary failed');
      }
      final summaries = sumState.dataSuccess()!;

      for (final summary in summaries) {
        if (signal.isCancelled) throw ExportCancelledException();

        final txState = await _debtLoan.getTransactionsByPerson(
          withPerson: summary.withPerson,
          type: type,
        );
        if (!txState.isSuccess()) {
          AppLogger.call(
            '$_tag getTransactionsByPerson failed person=${summary.withPerson}',
          );
          final err = txState.dataError();
          throw Exception(err?.$1 ?? 'getTransactionsByPerson failed');
        }
        target.addAll(txState.dataSuccess()!);
      }
    }
  }
}
