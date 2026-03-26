import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/budget/controllers/budget_controller.dart';
import 'package:app_saku_rapi/features/notification/controllers/notification_controller.dart';
import 'package:app_saku_rapi/features/notification/repositories/notification_repository.dart';
import 'package:app_saku_rapi/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider yang memantau budget list dan mengirim alert jika threshold terlampaui.
///
/// Digunakan via `ref.listen()` di widget yang tepat (misal dashboard),
/// atau dipanggil manual setelah budget refresh.
///
/// Tidak menyimpan state sendiri — cukup side-effect (kirim notifikasi).
final budgetAlertCheckerProvider = Provider<BudgetAlertChecker>((ref) {
  final notifRepo = ref.watch(notificationRepositoryProvider);
  return BudgetAlertChecker(notifRepo);
});

class BudgetAlertChecker {
  const BudgetAlertChecker(this._notifRepo);

  final NotificationRepository _notifRepo;
  static const _tag = '[Notification] [BudgetAlertChecker]';

  /// Cek semua budget aktif dan kirim alert jika belum dikirim.
  ///
  /// Panggil setelah `budgetController.loadBudgets()` selesai.
  Future<void> checkBudgets({
    required BudgetState budgetState,
    required bool budgetAlertEnabled,
    required AppLocalizations l10n,
  }) async {
    if (budgetState.status != BudgetStatus.loaded) return;
    if (!budgetAlertEnabled) return;

    AppLogger.call('$_tag checkBudgets: ${budgetState.budgets.length} budgets');

    final alertData = budgetState.budgets
        .where((b) => b.isActive && (b.isNearLimit || b.isOverBudget))
        .map(
          (b) => BudgetAlertData(
            id: b.id,
            categoryName: b.category?.name ?? 'Unknown',
            isNearLimit: b.isNearLimit,
            isOverBudget: b.isOverBudget,
            notificationSent80: b.notificationSent80,
            notificationSent100: b.notificationSent100,
          ),
        )
        .toList();

    if (alertData.isEmpty) return;

    await _notifRepo.checkAndSendBudgetAlerts(
      budgets: alertData,
      budgetAlertEnabled: budgetAlertEnabled,
      alertTitle: l10n.notifBudgetTitle,
      alert80Body: (cat) => l10n.notifBudgetAlert80(cat),
      alert100Body: (cat) => l10n.notifBudgetAlert100(cat),
    );
  }
}
