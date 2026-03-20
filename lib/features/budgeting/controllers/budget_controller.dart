import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/budgeting/datasource/budget_local_datasource.dart';
import 'package:app_saku_rapi/features/budgeting/datasource/budget_remote_datasource.dart';
import 'package:app_saku_rapi/features/budgeting/models/budget_model.dart';
import 'package:app_saku_rapi/features/budgeting/repositories/budget_repository.dart';
import 'package:app_saku_rapi/features/notification/controllers/notification_settings_controller.dart';
import 'package:app_saku_rapi/global/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────

/// Provider untuk [BudgetRepository].
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(
    remoteDataSource: BudgetRemoteDataSource(client: Supabase.instance.client),
    localDataSource: BudgetLocalDataSource(),
  );
});

/// Provider utama untuk [BudgetController].
///
/// State berupa `AsyncValue<BudgetState>` yang memuat list budget
/// dan summary untuk bulan/periode yang dipilih.
final budgetControllerProvider =
    AsyncNotifierProvider<BudgetController, BudgetState>(() {
      return BudgetController();
    });

// ─────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────

/// State gabungan untuk halaman budget.
class BudgetState {
  const BudgetState({this.budgets = const [], this.summary, DateTime? period})
    : period = period;

  /// Daftar budget aktif untuk periode terpilih.
  final List<BudgetModel> budgets;

  /// Ringkasan keseluruhan (total anggaran, total terpakai, sisa hari).
  final BudgetSummaryModel? summary;

  /// Periode yang sedang dilihat.
  final DateTime? period;

  BudgetState copyWith({
    List<BudgetModel>? budgets,
    BudgetSummaryModel? summary,
    DateTime? period,
  }) {
    return BudgetState(
      budgets: budgets ?? this.budgets,
      summary: summary ?? this.summary,
      period: period ?? this.period,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────

/// Riverpod [AsyncNotifier] untuk mengelola CRUD budget + summary.
class BudgetController extends AsyncNotifier<BudgetState> {
  late final BudgetRepository _repository;

  static const String _tag = 'Budget';

  @override
  Future<BudgetState> build() async {
    _repository = ref.watch(budgetRepositoryProvider);
    final now = DateTime.now();
    return _fetchAll(DateTime(now.year, now.month));
  }

  /// Fetch budget list + summary untuk [period].
  Future<BudgetState> _fetchAll(DateTime period) async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    AppLogger.call(
      '[$_tag] Fetching budgets untuk ${period.year}-${period.month}…',
      colorLog: ColorLog.blue,
    );

    final results = await Future.wait([
      _repository.getBudgets(userId: userId, period: period),
      _repository.getBudgetSummary(userId: userId, period: period),
    ]);

    final budgetResult = results[0] as DataState<List<BudgetModel>>;
    final summaryResult = results[1] as DataState<BudgetSummaryModel>;

    final budgets = budgetResult.isSuccess()
        ? budgetResult.dataSuccess()!
        : <BudgetModel>[];

    final summary = summaryResult.isSuccess()
        ? summaryResult.dataSuccess()
        : null;

    AppLogger.call(
      '[$_tag] Loaded: ${budgets.length} budget, summary=${summary != null}',
      colorLog: ColorLog.green,
    );

    // Cek dan tampilkan budget alert jika budget alert aktif di settings.
    _checkBudgetAlerts(budgets);

    return BudgetState(budgets: budgets, summary: summary, period: period);
  }

  /// Refresh data (pull-to-refresh atau setelah CRUD).
  Future<void> refresh() async {
    final period = state.value?.period ?? DateTime.now();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchAll(period));
  }

  /// Pindah periode (misal ganti bulan).
  Future<void> changePeriod(DateTime period) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchAll(period));
  }

  /// Membuat budget baru.
  Future<DataState<BudgetModel>> addBudget(BudgetModel budget) async {
    final result = await _repository.createBudget(budget);

    if (result.isSuccess()) {
      await refresh();
    }

    return result;
  }

  /// Memperbarui budget.
  Future<DataState<BudgetModel>> editBudget(BudgetModel budget) async {
    final result = await _repository.updateBudget(budget);

    if (result.isSuccess()) {
      await refresh();
    }

    return result;
  }

  /// Menghapus budget.
  Future<DataState<void>> removeBudget(String budgetId) async {
    final result = await _repository.deleteBudget(budgetId);

    if (result.isSuccess()) {
      await refresh();
    }

    return result;
  }

  // ─────────────────────────────────────────────────────────────
  // Budget Alert
  // ─────────────────────────────────────────────────────────────

  /// Cek setiap budget apakah perlu menampilkan notifikasi.
  ///
  /// Notifikasi hanya ditampilkan jika:
  /// - Budget alert aktif di [NotificationSettingsController]
  /// - `notificationSent80` == false && usagePercentage >= 80%
  /// - `notificationSent100` == false && usagePercentage >= 100%
  ///
  /// Flag `notification_sent_*` dikelola oleh DB trigger;
  /// Flutter hanya membaca nilai dan menampilkan notifikasi.
  void _checkBudgetAlerts(List<BudgetModel> budgets) {
    // Cek apakah budget alert aktif (gunakan default true jika belum loaded)
    final notifSettings = ref
        .read(notificationSettingsControllerProvider)
        .value;
    final alertEnabled = notifSettings?.budgetAlertEnabled ?? true;
    if (!alertEnabled) return;

    final notifService = NotificationService();
    for (final budget in budgets) {
      final pct = budget.usagePercentage;

      if (!budget.notificationSent80 && pct >= 0.8 && pct < 1.0) {
        final category = budget.categoryName ?? '';
        notifService.showBudgetAlert(
          budgetId: budget.id,
          categoryName: category,
          percentage: 80,
          title: 'Peringatan Anggaran',
          body: 'Anggaran $category sudah 80% terpakai!',
        );
        AppLogger.call(
          '[$_tag] Budget alert 80% fired for: $category',
          colorLog: ColorLog.yellow,
        );
      }

      if (!budget.notificationSent100 && pct >= 1.0) {
        final category = budget.categoryName ?? '';
        notifService.showBudgetAlert(
          budgetId: budget.id,
          categoryName: category,
          percentage: 100,
          title: 'Anggaran Habis!',
          body: 'Anggaran $category sudah habis!',
        );
        AppLogger.call(
          '[$_tag] Budget alert 100% fired for: $category',
          colorLog: ColorLog.red,
        );
      }
    }
  }
}
