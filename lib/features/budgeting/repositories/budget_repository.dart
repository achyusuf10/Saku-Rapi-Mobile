import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/budgeting/datasource/budget_local_datasource.dart';
import 'package:app_saku_rapi/features/budgeting/datasource/budget_remote_datasource.dart';
import 'package:app_saku_rapi/features/budgeting/models/budget_model.dart';

/// Orkestrator utama untuk fitur Budgeting.
///
/// Menangani smart-fetch (remote + cache fallback) dan CRUD budget.
class BudgetRepository {
  BudgetRepository({
    required BudgetRemoteDataSource remoteDataSource,
    required BudgetLocalDataSource localDataSource,
  }) : _remote = remoteDataSource,
       _local = localDataSource;

  final BudgetRemoteDataSource _remote;
  final BudgetLocalDataSource _local;

  static const String _tag = 'Budget';

  /// Mengambil semua budget milik user, opsional filter [period].
  Future<DataState<List<BudgetModel>>> getBudgets({
    required String userId,
    DateTime? period,
  }) async {
    final result = await _remote.getBudgets(userId: userId, period: period);

    return result.map(
      success: (data) {
        _local.saveBudgets(data.data);
        AppLogger.call(
          '[$_tag] Berhasil memuat ${data.data.length} budget',
          colorLog: ColorLog.green,
        );
        return DataState<List<BudgetModel>>.success(data: data.data);
      },
      error: (err) {
        // Fallback ke cache
        final cached = _local.getCachedBudgets();
        if (cached.isNotEmpty) {
          AppLogger.call(
            '[$_tag] Remote gagal, fallback cache: ${cached.length} budget',
            colorLog: ColorLog.yellow,
          );
          return DataState<List<BudgetModel>>.success(data: cached);
        }

        AppLogger.logError(
          '[$_tag] Gagal memuat budget: ${err.message}',
          runtimeType: BudgetRepository,
        );
        return DataState<List<BudgetModel>>.error(message: err.message);
      },
    );
  }

  /// Mengambil ringkasan budget bulanan.
  Future<DataState<BudgetSummaryModel>> getBudgetSummary({
    required String userId,
    required DateTime period,
  }) async {
    final result = await _remote.getBudgetSummary(
      userId: userId,
      period: period,
    );

    return result.map(
      success: (data) {
        _local.saveSummary(data.data);
        AppLogger.call(
          '[$_tag] Summary: total=${data.data.totalAmount}, used=${data.data.totalUsedAmount}',
          colorLog: ColorLog.green,
        );
        return DataState<BudgetSummaryModel>.success(data: data.data);
      },
      error: (err) {
        final cached = _local.getCachedSummary();
        if (cached != null) {
          AppLogger.call(
            '[$_tag] Summary remote gagal, fallback cache',
            colorLog: ColorLog.yellow,
          );
          return DataState<BudgetSummaryModel>.success(data: cached);
        }

        AppLogger.logError(
          '[$_tag] Gagal memuat summary: ${err.message}',
          runtimeType: BudgetRepository,
        );
        return DataState<BudgetSummaryModel>.error(message: err.message);
      },
    );
  }

  /// Membuat budget baru.
  Future<DataState<BudgetModel>> createBudget(BudgetModel budget) async {
    final result = await _remote.createBudget(budget);

    return result.map(
      success: (data) {
        AppLogger.logSuccess('[$_tag] Budget berhasil dibuat');
        return DataState<BudgetModel>.success(data: data.data);
      },
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal membuat budget: ${err.message}',
          runtimeType: BudgetRepository,
        );
        return DataState<BudgetModel>.error(message: err.message);
      },
    );
  }

  /// Memperbarui budget yang sudah ada.
  Future<DataState<BudgetModel>> updateBudget(BudgetModel budget) async {
    final result = await _remote.updateBudget(budget);

    return result.map(
      success: (data) {
        AppLogger.logSuccess('[$_tag] Budget berhasil diupdate');
        return DataState<BudgetModel>.success(data: data.data);
      },
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal mengupdate budget: ${err.message}',
          runtimeType: BudgetRepository,
        );
        return DataState<BudgetModel>.error(message: err.message);
      },
    );
  }

  /// Menghapus budget.
  Future<DataState<void>> deleteBudget(String budgetId) async {
    final result = await _remote.deleteBudget(budgetId);

    return result.map(
      success: (_) {
        AppLogger.logSuccess('[$_tag] Budget berhasil dihapus');
        _local.clearCache();
        return const DataState<void>.success(data: null);
      },
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal menghapus budget: ${err.message}',
          runtimeType: BudgetRepository,
        );
        return DataState<void>.error(message: err.message);
      },
    );
  }
}
