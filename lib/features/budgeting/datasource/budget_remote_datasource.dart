import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/budgeting/models/budget_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Data source untuk operasi CRUD budget ke Supabase.
///
/// Semua fungsi dibungkus dengan [SupabaseHandler.call] dan
/// mengembalikan [DataState<T>] sesuai aturan arsitektur.
///
/// **PENTING:** `used_amount` dikelola oleh Trigger DB.
/// Flutter hanya READ, tidak pernah WRITE `used_amount`.
class BudgetRemoteDataSource {
  BudgetRemoteDataSource({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  static const String _table = 'budgets';

  /// Query select dengan JOIN kategori dan wallet.
  static const String _selectWithJoin =
      '*, categories(name, icon, color), wallets(name)';

  /// Mengambil semua budget milik user, opsional filter berdasarkan [period].
  ///
  /// Jika [period] diberikan, hanya budget yang aktif pada bulan tersebut
  /// yang dikembalikan (start_date <= akhir bulan DAN end_date >= awal bulan).
  Future<DataState<List<BudgetModel>>> getBudgets({
    required String userId,
    DateTime? period,
  }) {
    return SupabaseHandler.call<List<BudgetModel>>(
      function: () async {
        var query = _client
            .from(_table)
            .select(_selectWithJoin)
            .eq('user_id', userId);

        if (period != null) {
          final firstDay = DateTime(period.year, period.month, 1);
          final lastDay = DateTime(period.year, period.month + 1, 0);

          query = query
              .lte('start_date', lastDay.toIso8601String().split('T').first)
              .gte('end_date', firstDay.toIso8601String().split('T').first);
        }

        final response = await query.order('created_at', ascending: false);

        return response.map(BudgetModel.fromMap).toList();
      },
    );
  }

  /// Mengambil ringkasan budget bulanan: total anggaran, total terpakai,
  /// sisa hari di bulan ini.
  ///
  /// Dihitung di sisi Flutter dari list budget aktif (bukan RPC).
  Future<DataState<BudgetSummaryModel>> getBudgetSummary({
    required String userId,
    required DateTime period,
  }) {
    return SupabaseHandler.call<BudgetSummaryModel>(
      function: () async {
        final firstDay = DateTime(period.year, period.month, 1);
        final lastDay = DateTime(period.year, period.month + 1, 0);

        final response = await _client
            .from(_table)
            .select('amount, used_amount')
            .eq('user_id', userId)
            .lte('start_date', lastDay.toIso8601String().split('T').first)
            .gte('end_date', firstDay.toIso8601String().split('T').first);

        double totalAmount = 0;
        double totalUsed = 0;
        for (final row in response) {
          totalAmount += (row['amount'] as num).toDouble();
          totalUsed += (row['used_amount'] as num).toDouble();
        }

        final now = DateTime.now();
        final daysRemaining = now.isAfter(lastDay)
            ? 0
            : lastDay.difference(DateTime(now.year, now.month, now.day)).inDays;

        return BudgetSummaryModel(
          totalAmount: totalAmount,
          totalUsedAmount: totalUsed,
          daysRemainingInMonth: daysRemaining,
        );
      },
    );
  }

  /// Membuat budget baru. Mengembalikan budget yang baru dibuat (+ JOIN).
  Future<DataState<BudgetModel>> createBudget(BudgetModel budget) {
    return SupabaseHandler.call<BudgetModel>(
      function: () async {
        final response = await _client
            .from(_table)
            .insert(budget.toMap())
            .select(_selectWithJoin)
            .single();

        return BudgetModel.fromMap(response);
      },
    );
  }

  /// Memperbarui budget. Mengembalikan budget yang sudah diperbarui (+ JOIN).
  Future<DataState<BudgetModel>> updateBudget(BudgetModel budget) {
    return SupabaseHandler.call<BudgetModel>(
      function: () async {
        final response = await _client
            .from(_table)
            .update(budget.toMap())
            .eq('id', budget.id)
            .select(_selectWithJoin)
            .single();

        return BudgetModel.fromMap(response);
      },
    );
  }

  /// Menghapus budget berdasarkan [budgetId].
  Future<DataState<void>> deleteBudget(String budgetId) {
    return SupabaseHandler.call<void>(
      function: () async {
        await _client.from(_table).delete().eq('id', budgetId);
      },
    );
  }
}
