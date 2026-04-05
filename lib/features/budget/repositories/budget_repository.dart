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

  /// Ambil budget yang sudah selesai (expired) dengan pagination.
  Future<DataState<List<BudgetModel>>> getCompletedBudgets({
    int limit = 20,
    int offset = 0,
  }) {
    return _remote.getCompletedBudgets(limit: limit, offset: offset);
  }

  /// Ambil budget yang belum dimulai (upcoming).
  Future<DataState<List<BudgetModel>>> getUpcomingBudgets() {
    return _remote.getUpcomingBudgets();
  }

  /// Ambil child category IDs untuk parent category.
  Future<DataState<List<String>>> getChildCategoryIds(String parentCategoryId) {
    return _remote.getChildCategoryIds(parentCategoryId);
  }

  /// Cari ID budget duplikat (same category + wallet + overlapping period).
  Future<DataState<String?>> findDuplicateBudgetId({
    required String categoryId,
    String? walletId,
    required DateTime startDate,
    required DateTime endDate,
    String? excludeBudgetId,
  }) {
    return _remote.findDuplicateBudgetId(
      categoryId: categoryId,
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
      excludeBudgetId: excludeBudgetId,
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
    bool carryForward = false,
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
      carryForward: carryForward,
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
    bool carryForward = false,
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
    final dupCheck = await _remote.findDuplicateBudgetId(
      categoryId: categoryId,
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
      excludeBudgetId: existing.id,
    );
    if (dupCheck.isSuccess() && dupCheck.dataSuccess() != null) {
      final l10n = appContext?.l10n;
      return DataState.error(
        message:
            l10n?.validationBudgetDuplicate ??
            'Sudah ada anggaran aktif untuk kategori dan periode yang sama',
      );
    }

    final updated = BudgetModel(
      id: existing.id,
      userId: existing.userId,
      categoryId: categoryId,
      walletId: walletId,
      amount: amount,
      usedAmount: existing.usedAmount,
      startDate: startDate,
      endDate: endDate,
      periodType: periodType,
      isRecurring: isRecurring,
      carryForward: carryForward,
      notificationSent50: existing.notificationSent50,
      notificationSent80: existing.notificationSent80,
      notificationSent100: existing.notificationSent100,
      createdAt: existing.createdAt,
      updatedAt: existing.updatedAt,
      category: existing.category,
      wallet: existing.wallet,
    );

    return _remote.updateBudget(updated);
  }

  // ───────────────── DELETE ─────────────────

  /// Hapus budget.
  Future<DataState<void>> deleteBudget(String budgetId) {
    return _remote.deleteBudget(budgetId);
  }

  /// Ganti budget lama dengan yang baru secara atomik via RPC.
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
    bool carryForward = false,
  }) async {
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
      carryForward: carryForward,
    );

    return _remote.replaceBudget(oldBudgetId: oldBudgetId, newBudget: budget);
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

  /// Hitung jumlah yang masih bisa dibelanjakan (bisa negatif jika over).
  static double calculateSpendable(List<BudgetModel> budgets) {
    final total = calculateTotalBudget(budgets);
    final used = calculateTotalUsed(budgets);
    return total - used;
  }
}
