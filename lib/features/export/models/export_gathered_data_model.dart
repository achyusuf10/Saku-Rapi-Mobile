import 'package:app_saku_rapi/features/debt_loan/models/debt_loan_transaction_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';

/// Snapshot data yang sudah dikumpulkan sebelum pembentukan workbook Excel.
class ExportGatheredDataModel {
  const ExportGatheredDataModel({
    required this.incomeExpenseForPeriod,
    required this.transfersForPeriod,
    required this.debtLoanRows,
    required this.isPartialPeriod,
  });

  /// Hanya [TransactionTypeEnum.income] dan [TransactionTypeEnum.expense] dalam periode.
  final List<TransactionModel> incomeExpenseForPeriod;

  /// Hanya transfer dalam periode (jika opsi aktif).
  final List<TransactionModel> transfersForPeriod;

  /// Seluruh baris hutang/piutang dari buku (bukan filter periode), bisa kosong.
  final List<DebtLoanTransactionModel> debtLoanRows;

  /// True jika pengambilan chunk periode dihentikan lewat partial.
  final bool isPartialPeriod;
}
