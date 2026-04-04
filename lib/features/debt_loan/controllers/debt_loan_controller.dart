import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/debt_loan/models/debt_loan_summary_model.dart';
import 'package:app_saku_rapi/features/debt_loan/models/debt_loan_transaction_model.dart';
import 'package:app_saku_rapi/features/debt_loan/repositories/debt_loan_repository.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Provider untuk [DebtLoanController].
final debtLoanControllerProvider =
    StateNotifierProvider.autoDispose<DebtLoanController, DebtLoanState>(
      (ref) =>
          DebtLoanController(repository: ref.watch(debtLoanRepositoryProvider)),
    );

// ───────────────── State ─────────────────

enum DebtLoanStatus { initial, loading, loaded, error }

/// State untuk list hutang/piutang (halaman utama).
class DebtLoanState {
  const DebtLoanState({
    this.debtStatus = DebtLoanStatus.initial,
    this.loanStatus = DebtLoanStatus.initial,
    this.debtSummaries = const [],
    this.loanSummaries = const [],
    this.selectedWalletId,
    this.debtError,
    this.loanError,
  });

  final DebtLoanStatus debtStatus;
  final DebtLoanStatus loanStatus;
  final List<DebtLoanSummaryModel> debtSummaries;
  final List<DebtLoanSummaryModel> loanSummaries;
  final String? selectedWalletId;
  final String? debtError;
  final String? loanError;

  /// Ambil status berdasarkan type.
  DebtLoanStatus statusFor(String type) =>
      type == 'debt' ? debtStatus : loanStatus;

  /// Ambil summaries berdasarkan type.
  List<DebtLoanSummaryModel> summariesFor(String type) =>
      type == 'debt' ? debtSummaries : loanSummaries;

  /// Ambil error berdasarkan type.
  String? errorFor(String type) => type == 'debt' ? debtError : loanError;

  DebtLoanState copyWith({
    DebtLoanStatus? debtStatus,
    DebtLoanStatus? loanStatus,
    List<DebtLoanSummaryModel>? debtSummaries,
    List<DebtLoanSummaryModel>? loanSummaries,
    String? selectedWalletId,
    String? debtError,
    String? loanError,
    bool clearWalletId = false,
  }) {
    return DebtLoanState(
      debtStatus: debtStatus ?? this.debtStatus,
      loanStatus: loanStatus ?? this.loanStatus,
      debtSummaries: debtSummaries ?? this.debtSummaries,
      loanSummaries: loanSummaries ?? this.loanSummaries,
      selectedWalletId: clearWalletId
          ? null
          : (selectedWalletId ?? this.selectedWalletId),
      debtError: debtError ?? this.debtError,
      loanError: loanError ?? this.loanError,
    );
  }
}

// ───────────────── Controller ─────────────────

/// Controller untuk list hutang/piutang (grouped by person).
class DebtLoanController extends StateNotifier<DebtLoanState> {
  DebtLoanController({required DebtLoanRepository repository})
    : _repository = repository,
      super(const DebtLoanState());

  final DebtLoanRepository _repository;

  /// Load summary untuk type tertentu (debt/loan).
  Future<void> loadSummary(String type) async {
    if (type == 'debt') {
      state = state.copyWith(debtStatus: DebtLoanStatus.loading);
    } else {
      state = state.copyWith(loanStatus: DebtLoanStatus.loading);
    }

    final result = await _repository.getSummary(
      type: type,
      walletId: state.selectedWalletId,
    );

    if (result.isSuccess()) {
      if (type == 'debt') {
        state = state.copyWith(
          debtStatus: DebtLoanStatus.loaded,
          debtSummaries: result.dataSuccess()!,
        );
      } else {
        state = state.copyWith(
          loanStatus: DebtLoanStatus.loaded,
          loanSummaries: result.dataSuccess()!,
        );
      }
    } else {
      final (message, _, _, _) = result.dataError()!;
      AppLogger.call('[DebtLoan] loadSummary error: $message');
      if (type == 'debt') {
        state = state.copyWith(
          debtStatus: DebtLoanStatus.error,
          debtError: message,
        );
      } else {
        state = state.copyWith(
          loanStatus: DebtLoanStatus.error,
          loanError: message,
        );
      }
    }
  }

  /// Set wallet filter dan reload.
  void setWalletFilter(String? walletId, String type) {
    if (walletId == state.selectedWalletId) return;
    state = state.copyWith(
      selectedWalletId: walletId,
      clearWalletId: walletId == null,
    );
    loadSummary(type);
  }
}

// ═══════════════════════════════════════════════════════════════════
// UnpaidTransactionsController — state untuk picker transaksi unpaid.
// ═══════════════════════════════════════════════════════════════════

/// Provider autoDispose.family untuk [UnpaidTransactionsController].
///
/// Parameter: type ('debt' | 'loan').
final unpaidTransactionsControllerProvider = StateNotifierProvider.autoDispose
    .family<UnpaidTransactionsController, UnpaidTransactionsState, String>((
      ref,
      type,
    ) {
      final repository = ref.watch(debtLoanRepositoryProvider);
      final controller = UnpaidTransactionsController(repository);
      controller.load(type);
      return controller;
    });

/// State untuk daftar transaksi hutang/piutang yang belum lunas.
class UnpaidTransactionsState {
  const UnpaidTransactionsState({
    this.transactions = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  final List<DebtLoanTransactionModel> transactions;
  final bool isLoading;
  final String? errorMessage;

  UnpaidTransactionsState copyWith({
    List<DebtLoanTransactionModel>? transactions,
    bool? isLoading,
    String? errorMessage,
  }) {
    return UnpaidTransactionsState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Controller untuk memuat daftar transaksi unpaid.
class UnpaidTransactionsController
    extends StateNotifier<UnpaidTransactionsState> {
  UnpaidTransactionsController(this._repository)
    : super(const UnpaidTransactionsState());

  final DebtLoanRepository _repository;

  /// Load daftar transaksi belum lunas.
  Future<void> load(String type) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.getAllUnpaid(type: type);

    if (result.isSuccess()) {
      state = state.copyWith(
        transactions: result.dataSuccess()!,
        isLoading: false,
      );
    } else {
      final (message, _, _, _) = result.dataError()!;
      AppLogger.call('[DebtLoan] loadUnpaid error: $message');
      state = state.copyWith(errorMessage: message, isLoading: false);
    }
  }
}
