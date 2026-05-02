import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/core/utils/saku_date_utils.dart';
import 'package:app_saku_rapi/features/budget/models/budget_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk operasi CRUD budget di Supabase.
///
/// Fetch menggunakan join ke `categories` dan `wallets` agar UI bisa
/// langsung menampilkan nama/icon kategori dan wallet tanpa fetch tambahan.
/// `used_amount` dihitung otomatis oleh trigger DB `update_budget_usage()`.
class BudgetRemoteDataSource {
  BudgetRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _table = 'budgets';
  static const _tag = '[Budget] [BudgetRemoteDataSource]';

  /// Select query dengan join categories + wallets.
  static const _selectWithJoin = '*, categories(*), wallets(*)';

  String get _userId => _client.auth.currentUser!.id;
  Future<void> _syncRecurringBudgets(String today) async {
    await _client.rpc('auto_renew_budgets', params: {'p_today': today});
  }

  // ───────────────── READ ─────────────────

  /// Ambil semua budget aktif milik user (yang periode end_date >= today).
  Future<DataState<List<BudgetModel>>> getActiveBudgets() {
    return SupabaseHandler.call<List<BudgetModel>>(
      function: () async {
        AppLogger.call('$_tag getActiveBudgets');
        final today = SakuDateUtils.formatDate(DateTime.now());
        await _syncRecurringBudgets(today);

        final response = await _client
            .from(_table)
            .select(_selectWithJoin)
            .eq('user_id', _userId)
            .gte('end_date', today)
            .lte('start_date', today)
            .order('created_at', ascending: false);

        return response.map((e) => BudgetModel.fromMap(e)).toList();
      },
    );
  }

  /// Ambil semua budget milik user (termasuk expired).
  Future<DataState<List<BudgetModel>>> getAllBudgets() {
    return SupabaseHandler.call<List<BudgetModel>>(
      function: () async {
        AppLogger.call('$_tag getAllBudgets');
        final today = SakuDateUtils.formatDate(DateTime.now());
        await _syncRecurringBudgets(today);
        final response = await _client
            .from(_table)
            .select(_selectWithJoin)
            .eq('user_id', _userId)
            .order('start_date', ascending: false);

        return response.map((e) => BudgetModel.fromMap(e)).toList();
      },
    );
  }

  /// Ambil budget yang belum dimulai (start_date > today).
  Future<DataState<List<BudgetModel>>> getUpcomingBudgets() {
    return SupabaseHandler.call<List<BudgetModel>>(
      function: () async {
        AppLogger.call('$_tag getUpcomingBudgets');
        final today = SakuDateUtils.formatDate(DateTime.now());
        await _syncRecurringBudgets(today);

        final response = await _client
            .from(_table)
            .select(_selectWithJoin)
            .eq('user_id', _userId)
            .gt('start_date', today)
            .order('start_date', ascending: true);

        return response.map((e) => BudgetModel.fromMap(e)).toList();
      },
    );
  }

  /// Ambil budget yang sudah selesai (end_date < today) dengan pagination.
  Future<DataState<List<BudgetModel>>> getCompletedBudgets({
    int limit = 20,
    int offset = 0,
  }) {
    return SupabaseHandler.call<List<BudgetModel>>(
      function: () async {
        AppLogger.call(
          '$_tag getCompletedBudgets: limit=$limit offset=$offset',
        );
        final today = SakuDateUtils.formatDate(DateTime.now());
        await _syncRecurringBudgets(today);

        final response = await _client
            .from(_table)
            .select(_selectWithJoin)
            .eq('user_id', _userId)
            .lt('end_date', today)
            .order('end_date', ascending: false)
            .range(offset, offset + limit - 1);

        return response.map((e) => BudgetModel.fromMap(e)).toList();
      },
    );
  }

  /// Ambil satu budget berdasarkan ID.
  Future<DataState<BudgetModel>> getBudgetById(String budgetId) {
    return SupabaseHandler.call<BudgetModel>(
      function: () async {
        AppLogger.call('$_tag getBudgetById: $budgetId');
        final response = await _client
            .from(_table)
            .select(_selectWithJoin)
            .eq('id', budgetId)
            .single();

        return BudgetModel.fromMap(response);
      },
    );
  }

  // ───────────────── CREATE ─────────────────

  /// Buat budget baru. Mengembalikan budget yang sudah disimpan dengan join.
  Future<DataState<BudgetModel>> createBudget(BudgetModel budget) {
    return SupabaseHandler.call<BudgetModel>(
      function: () async {
        AppLogger.call('$_tag createBudget: cat=${budget.categoryId}');
        final inserted = await _client
            .from(_table)
            .insert(budget.toInsertMap())
            .select()
            .single();

        // Fetch ulang dengan join agar dapat relasi kategori/wallet
        final response = await _client
            .from(_table)
            .select(_selectWithJoin)
            .eq('id', inserted['id'] as String)
            .single();

        return BudgetModel.fromMap(response);
      },
    );
  }

  // ───────────────── UPDATE ─────────────────

  /// Update budget (amount, category, wallet, period, recurring).
  Future<DataState<BudgetModel>> updateBudget(BudgetModel budget) {
    return SupabaseHandler.call<BudgetModel>(
      function: () async {
        AppLogger.call('$_tag updateBudget: ${budget.id}');
        await _client
            .from(_table)
            .update(budget.toUpdateMap())
            .eq('id', budget.id);

        // Fetch ulang dengan join
        final response = await _client
            .from(_table)
            .select(_selectWithJoin)
            .eq('id', budget.id)
            .single();

        return BudgetModel.fromMap(response);
      },
    );
  }

  // ───────────────── DELETE ─────────────────

  /// Hapus budget berdasarkan ID.
  Future<DataState<void>> deleteBudget(String budgetId) {
    return SupabaseHandler.call<void>(
      function: () async {
        AppLogger.call('$_tag deleteBudget: $budgetId');
        await _client.from(_table).delete().eq('id', budgetId);
      },
    );
  }

  /// Ganti budget lama secara atomik via RPC (DELETE old + INSERT new).
  Future<DataState<BudgetModel>> replaceBudget({
    required String oldBudgetId,
    required BudgetModel newBudget,
  }) {
    return SupabaseHandler.call<BudgetModel>(
      function: () async {
        AppLogger.call('$_tag replaceBudget: $oldBudgetId → new');
        final result = await _client.rpc(
          'replace_budget',
          params: {
            'p_old_budget_id': oldBudgetId,
            'p_user_id': newBudget.userId,
            'p_category_id': newBudget.categoryId,
            'p_wallet_id': newBudget.walletId,
            'p_amount': newBudget.amount,
            'p_start_date': SakuDateUtils.formatDate(newBudget.startDate),
            'p_end_date': SakuDateUtils.formatDate(newBudget.endDate),
            'p_is_recurring': newBudget.isRecurring,
            'p_period_type': newBudget.periodType.value,
            'p_carry_forward': newBudget.carryForward,
          },
        );

        final newId = (result as Map<String, dynamic>)['id'] as String;

        // Fetch with join
        final response = await _client
            .from(_table)
            .select(_selectWithJoin)
            .eq('id', newId)
            .single();

        return BudgetModel.fromMap(response);
      },
    );
  }

  /// Ambil child category IDs untuk parent category.
  Future<DataState<List<String>>> getChildCategoryIds(String parentCategoryId) {
    return SupabaseHandler.call<List<String>>(
      function: () async {
        AppLogger.call('$_tag getChildCategoryIds: $parentCategoryId');
        final response = await _client
            .from('categories')
            .select('id')
            .eq('parent_id', parentCategoryId);

        return (response as List)
            .map((e) => (e as Map<String, dynamic>)['id'] as String)
            .toList();
      },
    );
  }

  // ───────────────── GUARD ─────────────────

  /// Cek duplikasi: budget aktif dengan kategori + wallet + periode overlapping.
  Future<DataState<bool>> hasDuplicateBudget({
    required String categoryId,
    String? walletId,
    required DateTime startDate,
    required DateTime endDate,
    String? excludeBudgetId,
  }) {
    return SupabaseHandler.call<bool>(
      function: () async {
        AppLogger.call('$_tag hasDuplicateBudget: cat=$categoryId');
        final startStr = SakuDateUtils.formatDate(startDate);
        final endStr = SakuDateUtils.formatDate(endDate);

        var query = _client
            .from(_table)
            .select('id')
            .eq('user_id', _userId)
            .eq('category_id', categoryId)
            .lte('start_date', endStr)
            .gte('end_date', startStr);

        if (walletId != null) {
          query = query.eq('wallet_id', walletId);
        } else {
          query = query.isFilter('wallet_id', null);
        }

        if (excludeBudgetId != null) {
          query = query.neq('id', excludeBudgetId);
        }

        final response = await query.limit(1);
        return (response as List).isNotEmpty;
      },
    );
  }

  /// Cari ID budget duplikat (aktif, same category+wallet+overlapping period).
  /// Return null jika tidak ada duplikat.
  Future<DataState<String?>> findDuplicateBudgetId({
    required String categoryId,
    String? walletId,
    required DateTime startDate,
    required DateTime endDate,
    String? excludeBudgetId,
  }) {
    return SupabaseHandler.call<String?>(
      function: () async {
        AppLogger.call('$_tag findDuplicateBudgetId: cat=$categoryId');
        final startStr = SakuDateUtils.formatDate(startDate);
        final endStr = SakuDateUtils.formatDate(endDate);

        var query = _client
            .from(_table)
            .select('id')
            .eq('user_id', _userId)
            .eq('category_id', categoryId)
            .lte('start_date', endStr)
            .gte('end_date', startStr);

        if (walletId != null) {
          query = query.eq('wallet_id', walletId);
        } else {
          query = query.isFilter('wallet_id', null);
        }

        if (excludeBudgetId != null) {
          query = query.neq('id', excludeBudgetId);
        }

        final response = await query.limit(1);
        final list = response as List;
        return list.isNotEmpty ? list.first['id'] as String : null;
      },
    );
  }

  // ───────────────── TRANSACTIONS FOR BUDGET ─────────────────

  /// Ambil transaksi yang terkait budget (berdasarkan category, wallet, & periode).
  /// [categoryIds] harus berisi budget.categoryId + child category IDs jika budget adalah parent.
  Future<DataState<List<TransactionModel>>> getTransactionsForBudget({
    required List<String> categoryIds,
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
  }) {
    return SupabaseHandler.call<List<TransactionModel>>(
      function: () async {
        AppLogger.call(
          '$_tag getTransactionsForBudget: categories=$categoryIds, '
          '$startDate - $endDate, wallet=$walletId',
        );

        final range = SakuDateUtils.localDayRangeUtc(
          startDate: startDate,
          endDate: endDate,
        );

        var query = _client
            .from('transactions')
            .select('''
              *,
              wallets!transactions_wallet_id_fkey(name),
              destination_wallet:wallets!transactions_destination_wallet_id_fkey(name),
              transaction_items!inner(
                *,
                categories(name, icon, color, background_color)
              )
            ''')
            .eq('user_id', _userId)
            .eq('type', 'expense')
            .isFilter('settlement_kind', null)
            .gte('date', range.startUtc)
            .lt('date', range.endUtcExclusive)
            .inFilter('transaction_items.category_id', categoryIds);

        if (walletId != null) {
          query = query.eq('wallet_id', walletId);
        }

        final response = await query
            .order('date', ascending: false)
            .order('created_at', ascending: false);

        return (response as List)
            .map((e) => TransactionModel.fromMap(e as Map<String, dynamic>))
            .toList();
      },
    );
  }
}
