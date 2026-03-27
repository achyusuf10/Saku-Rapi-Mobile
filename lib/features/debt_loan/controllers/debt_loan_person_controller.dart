import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/debt_loan/models/debt_loan_transaction_model.dart';
import 'package:app_saku_rapi/features/debt_loan/repositories/debt_loan_repository.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Provider untuk [DebtLoanPersonController].
///
/// Parameter: `(withPerson, type)`.
final debtLoanPersonControllerProvider = StateNotifierProvider.autoDispose
    .family<DebtLoanPersonController, DebtLoanPersonState, (String, String)>((
      ref,
      params,
    ) {
      final (withPerson, type) = params;
      return DebtLoanPersonController(
        repository: ref.watch(debtLoanRepositoryProvider),
        withPerson: withPerson,
        type: type,
      );
    });

// ───────────────── State ─────────────────

enum DebtLoanPersonStatus { initial, loading, loaded, error }

/// State untuk daftar transaksi per orang.
class DebtLoanPersonState {
  const DebtLoanPersonState({
    this.status = DebtLoanPersonStatus.initial,
    this.transactions = const [],
    this.errorMessage,
  });

  final DebtLoanPersonStatus status;
  final List<DebtLoanTransactionModel> transactions;
  final String? errorMessage;

  /// Total principal (semua original transactions).
  double get totalPrincipal =>
      transactions.fold(0.0, (sum, t) => sum + t.totalAmount);

  /// Total settled (semua yang sudah dilunasi).
  double get totalSettled =>
      transactions.fold(0.0, (sum, t) => sum + t.totalSettled);

  /// Total remaining.
  double get totalRemaining =>
      transactions.fold(0.0, (sum, t) => sum + t.remaining);

  DebtLoanPersonState copyWith({
    DebtLoanPersonStatus? status,
    List<DebtLoanTransactionModel>? transactions,
    String? errorMessage,
  }) {
    return DebtLoanPersonState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ───────────────── Controller ─────────────────

/// Controller untuk daftar transaksi hutang/piutang per orang.
class DebtLoanPersonController extends StateNotifier<DebtLoanPersonState> {
  DebtLoanPersonController({
    required DebtLoanRepository repository,
    required this.withPerson,
    required this.type,
  }) : _repository = repository,
       super(const DebtLoanPersonState());

  final DebtLoanRepository _repository;
  final String withPerson;
  final String type;

  /// Load semua transaksi hutang/piutang dengan orang ini.
  Future<void> loadTransactions({String? walletId}) async {
    state = state.copyWith(status: DebtLoanPersonStatus.loading);

    final result = await _repository.getTransactionsByPerson(
      withPerson: withPerson,
      type: type,
      walletId: walletId,
    );

    if (result.isSuccess()) {
      state = state.copyWith(
        status: DebtLoanPersonStatus.loaded,
        transactions: result.dataSuccess()!,
      );
    } else {
      final (message, _, _, _) = result.dataError()!;
      AppLogger.call('[DebtLoan] loadTransactions error: $message');
      state = state.copyWith(
        status: DebtLoanPersonStatus.error,
        errorMessage: message,
      );
    }
  }
}
