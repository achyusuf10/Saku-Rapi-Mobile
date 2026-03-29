import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:app_saku_rapi/features/history/controllers/history_controller.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Provider autoDispose untuk [DebtLoanSettlementFormController].
final debtLoanSettlementFormProvider =
    StateNotifierProvider.autoDispose<
      DebtLoanSettlementFormController,
      DebtLoanSettlementFormState
    >((ref) {
      return DebtLoanSettlementFormController(ref);
    });

// ───────────────── State ─────────────────

/// State untuk form pelunasan hutang/piutang.
class DebtLoanSettlementFormState {
  const DebtLoanSettlementFormState({
    this.isSubmitting = false,
    this.isDeleting = false,
  });

  final bool isSubmitting;
  final bool isDeleting;

  DebtLoanSettlementFormState copyWith({bool? isSubmitting, bool? isDeleting}) {
    return DebtLoanSettlementFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }
}

// ───────────────── Controller ─────────────────

/// Controller untuk operasi pelunasan: create, update, delete settlement.
///
/// Menghilangkan akses langsung ke [TransactionRepository] dari UI layer.
class DebtLoanSettlementFormController
    extends StateNotifier<DebtLoanSettlementFormState> {
  DebtLoanSettlementFormController(this._ref)
    : super(const DebtLoanSettlementFormState());

  final Ref _ref;

  /// Buat settlement baru (pelunasan hutang / penerimaan piutang).
  Future<DataState<Map<String, dynamic>>> settle({
    required String referenceTransactionId,
    required String settlementKind,
    required double amount,
    required String walletId,
    String? note,
  }) async {
    state = state.copyWith(isSubmitting: true);

    final result = await _ref
        .read(transactionRepositoryProvider)
        .settleDebtOrLoan(
          referenceTransactionId: referenceTransactionId,
          settlementKind: settlementKind,
          amount: amount,
          walletId: walletId,
          note: note,
        );

    state = state.copyWith(isSubmitting: false);

    if (result.isSuccess()) _refreshRelated();
    return result;
  }

  /// Update settlement yang sudah ada.
  Future<DataState<Map<String, dynamic>>> update({
    required String settlementId,
    required double amount,
    required String walletId,
    String? note,
  }) async {
    state = state.copyWith(isSubmitting: true);

    final result = await _ref
        .read(transactionRepositoryProvider)
        .updateSettlement(
          settlementId: settlementId,
          amount: amount,
          walletId: walletId,
          note: note,
        );

    state = state.copyWith(isSubmitting: false);

    if (result.isSuccess()) _refreshRelated();
    return result;
  }

  /// Hapus settlement.
  Future<DataState<Map<String, dynamic>>> delete(String settlementId) async {
    state = state.copyWith(isDeleting: true);

    final result = await _ref
        .read(transactionRepositoryProvider)
        .deleteSettlement(settlementId);

    state = state.copyWith(isDeleting: false);

    if (result.isSuccess()) _refreshRelated();
    return result;
  }

  /// Refresh controller terkait setelah operasi berhasil.
  void _refreshRelated() {
    _ref.read(walletControllerProvider.notifier).loadWallets();
    _ref.read(dashboardControllerProvider.notifier).loadDashboard();
    _ref.read(historyControllerProvider.notifier).loadTransactions();
  }
}
