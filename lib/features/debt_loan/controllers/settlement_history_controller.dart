import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/debt_loan/models/settlement_history_model.dart';
import 'package:app_saku_rapi/features/debt_loan/repositories/debt_loan_repository.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Provider untuk [SettlementHistoryController].
///
/// Parameter: referenceTransactionId.
final settlementHistoryControllerProvider = StateNotifierProvider.autoDispose
    .family<SettlementHistoryController, SettlementHistoryState, String>((
      ref,
      referenceTransactionId,
    ) {
      return SettlementHistoryController(
        repository: ref.watch(debtLoanRepositoryProvider),
        referenceTransactionId: referenceTransactionId,
      );
    });

// ───────────────── State ─────────────────

enum SettlementHistoryStatus { initial, loading, loaded, error }

/// State untuk riwayat pelunasan satu transaksi.
class SettlementHistoryState {
  const SettlementHistoryState({
    this.status = SettlementHistoryStatus.initial,
    this.settlements = const [],
    this.errorMessage,
  });

  final SettlementHistoryStatus status;
  final List<SettlementHistoryModel> settlements;
  final String? errorMessage;

  /// Total yang sudah dilunasi.
  double get totalSettled =>
      settlements.fold(0.0, (sum, s) => sum + s.totalAmount);

  SettlementHistoryState copyWith({
    SettlementHistoryStatus? status,
    List<SettlementHistoryModel>? settlements,
    String? errorMessage,
  }) {
    return SettlementHistoryState(
      status: status ?? this.status,
      settlements: settlements ?? this.settlements,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ───────────────── Controller ─────────────────

/// Controller untuk riwayat pelunasan per transaksi hutang/piutang.
class SettlementHistoryController
    extends StateNotifier<SettlementHistoryState> {
  SettlementHistoryController({
    required DebtLoanRepository repository,
    required this.referenceTransactionId,
  }) : _repository = repository,
       super(const SettlementHistoryState());

  final DebtLoanRepository _repository;
  final String referenceTransactionId;

  /// Load riwayat pelunasan.
  Future<void> loadHistory() async {
    state = state.copyWith(status: SettlementHistoryStatus.loading);

    final result = await _repository.getSettlementHistory(
      referenceTransactionId: referenceTransactionId,
    );

    if (result.isSuccess()) {
      state = state.copyWith(
        status: SettlementHistoryStatus.loaded,
        settlements: result.dataSuccess()!,
      );
    } else {
      final (message, _, _, _) = result.dataError()!;
      AppLogger.call('[DebtLoan] loadHistory error: $message');
      state = state.copyWith(
        status: SettlementHistoryStatus.error,
        errorMessage: message,
      );
    }
  }
}
