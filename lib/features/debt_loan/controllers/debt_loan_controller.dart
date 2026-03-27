import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/debt_loan/models/debt_loan_summary_model.dart';
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
    this.status = DebtLoanStatus.initial,
    this.summaries = const [],
    this.selectedWalletId,
    this.errorMessage,
  });

  final DebtLoanStatus status;
  final List<DebtLoanSummaryModel> summaries;
  final String? selectedWalletId;
  final String? errorMessage;

  /// Kontak dengan hutang/piutang belum lunas.
  List<DebtLoanSummaryModel> get unpaid =>
      summaries.where((s) => s.hasUnpaid).toList();

  /// Kontak yang sudah lunas semua.
  List<DebtLoanSummaryModel> get paid =>
      summaries.where((s) => !s.hasUnpaid).toList();

  /// Total sisa seluruh kontak.
  double get totalRemaining =>
      summaries.fold(0.0, (sum, s) => sum + s.remaining);

  DebtLoanState copyWith({
    DebtLoanStatus? status,
    List<DebtLoanSummaryModel>? summaries,
    String? selectedWalletId,
    String? errorMessage,
    bool clearWalletId = false,
  }) {
    return DebtLoanState(
      status: status ?? this.status,
      summaries: summaries ?? this.summaries,
      selectedWalletId: clearWalletId
          ? null
          : (selectedWalletId ?? this.selectedWalletId),
      errorMessage: errorMessage ?? this.errorMessage,
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
    state = state.copyWith(status: DebtLoanStatus.loading);

    final result = await _repository.getSummary(
      type: type,
      walletId: state.selectedWalletId,
    );

    if (result.isSuccess()) {
      state = state.copyWith(
        status: DebtLoanStatus.loaded,
        summaries: result.dataSuccess()!,
      );
    } else {
      final (message, _, _, _) = result.dataError()!;
      AppLogger.call('[DebtLoan] loadSummary error: $message');
      state = state.copyWith(
        status: DebtLoanStatus.error,
        errorMessage: message,
      );
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
