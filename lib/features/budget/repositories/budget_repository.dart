import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/budget/datasource/budget_local_data_source.dart';
import 'package:app_saku_rapi/features/budget/datasource/budget_remote_data_source.dart';
import 'package:app_saku_rapi/features/budget/models/budget_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';

/// Repository utama untuk fitur budget.
///
/// Mengorkestrasikan [BudgetRemoteDataSource] dan [BudgetLocalDataSource]:
/// - Online: fetch dari Supabase, cache ke Hive.
/// - Offline fallback: sajikan dari Hive cache.
///
/// Validasi domain dilakukan di sini, bukan di widget.
class BudgetRepository {
  BudgetRepository({
    BudgetRemoteDataSource? remoteDataSource,
    BudgetLocalDataSource? localDataSource,
  }) : _remote = remoteDataSource ?? BudgetRemoteDataSource(),
       _local = localDataSource ?? BudgetLocalDataSource();

  final BudgetRemoteDataSource _remote;
  final BudgetLocalDataSource _local;

  static const _tag = '[Budget] [BudgetRepository]';

  // ───────────────── READ ─────────────────

  /// Ambil budget aktif. Fetch remote lalu cache; fallback ke cache jika gagal.
  Future<DataState<List<BudgetModel>>> getActiveBudgets() async {
    final result = await _remote.getActiveBudgets();

    if (result.isSuccess()) {
      final budgets = result.dataSuccess()!;
      _local.cacheBudgets(budgets);
      return result;
    }

    // Offline fallback
    final cached = _local.getCachedBudgets();
    if (cached != null) {
      AppLogger.call('$_tag getActiveBudgets: serving from cache');
      return DataState.success(data: cached);
    }

    return result;
  }

  /// Ambil budget yang sudah selesai (expired).
  Future<DataState<List<BudgetModel>>> getCompletedBudgets() {
    return _remote.getCompletedBudgets();
  }

  /// Cari ID budget duplikat (same category + wallet + overlapping period).
  Future<DataState<String?>> findDuplicateBudgetId({
    required String categoryId,
    String? walletId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _remote.findDuplicateBudgetId(
      categoryId: categoryId,
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // ───────────────── CREATE ─────────────────

  /// Buat budget baru setelah validasi domain.
  Future<DataState<BudgetModel>> createBudget({
    required String userId,
    required String categoryId,
    String? walletId,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
    bool isRecurring = false,
    BudgetPeriodType periodType = BudgetPeriodType.monthly,
  }) async {
    // Validasi: amount > 0
    if (amount <= 0) {
      final l10n = appContext?.l10n;
      return DataState.error(
        message:
            l10n?.validationBudgetAmountPositive ??
            'Nominal anggaran harus lebih dari 0',
      );
    }

    // Validasi: end >= start
    if (endDate.isBefore(startDate)) {
      final l10n = appContext?.l10n;
      return DataState.error(
        message:
            l10n?.validationEndBeforeStart ??
            'Tanggal akhir tidak boleh sebelum tanggal mulai',
      );
    }

    final budget = BudgetModel(
      id: '',
      userId: userId,
      categoryId: categoryId,
      walletId: walletId,
      amount: amount,
      usedAmount: 0,
      startDate: startDate,
      endDate: endDate,
      isRecurring: isRecurring,
      periodType: periodType,
    );

    return _remote.createBudget(budget);
  }

  // ───────────────── UPDATE ─────────────────

  /// Update budget (amount, category, wallet, period, recurring).
  Future<DataState<BudgetModel>> updateBudget({
    required BudgetModel existing,
    required String categoryId,
    String? walletId,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
    bool isRecurring = false,
    BudgetPeriodType periodType = BudgetPeriodType.monthly,
  }) async {
    if (amount <= 0) {
      final l10n = appContext?.l10n;
      return DataState.error(
        message:
            l10n?.validationBudgetAmountPositive ??
            'Nominal anggaran harus lebih dari 0',
      );
    }

    if (endDate.isBefore(startDate)) {
      final l10n = appContext?.l10n;
      return DataState.error(
        message:
            l10n?.validationEndBeforeStart ??
            'Tanggal akhir tidak boleh sebelum tanggal mulai',
      );
    }

    // Validasi duplikasi (exclude self)
    final dupCheck = await _remote.hasDuplicateBudget(
      categoryId: categoryId,
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
      excludeBudgetId: existing.id,
    );
    if (dupCheck.isSuccess() && dupCheck.dataSuccess() == true) {
      final l10n = appContext?.l10n;
      return DataState.error(
        message:
            l10n?.validationBudgetDuplicate ??
            'Sudah ada anggaran aktif untuk kategori dan periode yang sama',
      );
    }

    final updated = existing.copyWith(
      categoryId: categoryId,
      walletId: walletId,
      amount: amount,
      startDate: startDate,
      endDate: endDate,
      isRecurring: isRecurring,
      periodType: periodType,
    );

    return _remote.updateBudget(updated);
  }

  // ───────────────── DELETE ─────────────────

  /// Hapus budget.
  Future<DataState<void>> deleteBudget(String budgetId) {
    return _remote.deleteBudget(budgetId);
  }

  /// Ganti budget lama dengan yang baru (hapus lama, buat baru).
  Future<DataState<BudgetModel>> replaceBudget({
    required String oldBudgetId,
    required String userId,
    required String categoryId,
    String? walletId,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
    bool isRecurring = false,
    BudgetPeriodType periodType = BudgetPeriodType.monthly,
  }) async {
    // Hapus budget lama
    final deleteResult = await _remote.deleteBudget(oldBudgetId);
    if (!deleteResult.isSuccess()) {
      final l10n = appContext?.l10n;
      return DataState.error(
        message:
            l10n?.validationDeleteOldBudgetFailed ??
            'Gagal menghapus anggaran lama',
      );
    }

    // Buat budget baru
    final budget = BudgetModel(
      id: '',
      userId: userId,
      categoryId: categoryId,
      walletId: walletId,
      amount: amount,
      usedAmount: 0,
      startDate: startDate,
      endDate: endDate,
      isRecurring: isRecurring,
      periodType: periodType,
    );

    return _remote.createBudget(budget);
  }

  // ───────────────── TRANSACTIONS FOR BUDGET ─────────────────

  /// Ambil transaksi yang terkait budget.
  Future<DataState<List<TransactionModel>>> getTransactionsForBudget({
    required List<String> categoryIds,
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
  }) {
    return _remote.getTransactionsForBudget(
      categoryIds: categoryIds,
      startDate: startDate,
      endDate: endDate,
      walletId: walletId,
    );
  }

  // ───────────────── CACHE ─────────────────

  /// Cache budget list ke Hive.
  void cacheBudgetList(List<BudgetModel> budgets) {
    _local.cacheBudgets(budgets);
  }

  /// Hapus cache budget.
  void clearCache() {
    _local.clearBudgetCache();
  }

  // ───────────────── COMPUTED ─────────────────

  /// Hitung total budget dari daftar budget aktif.
  static double calculateTotalBudget(List<BudgetModel> budgets) {
    return budgets.fold(0.0, (sum, b) => sum + b.amount);
  }

  /// Hitung total terpakai dari daftar budget aktif.
  static double calculateTotalUsed(List<BudgetModel> budgets) {
    return budgets.fold(0.0, (sum, b) => sum + b.usedAmount);
  }

  /// Hitung jumlah yang masih bisa dibelanjakan.
  static double calculateSpendable(List<BudgetModel> budgets) {
    final total = calculateTotalBudget(budgets);
    final used = calculateTotalUsed(budgets);
    final remaining = total - used;
    return remaining > 0 ? remaining : 0;
  }
}
