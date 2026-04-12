import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/core/utils/saku_date_utils.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source khusus dashboard.
///
/// Mengambil data ringkasan yang diperlukan dashboard:
/// - Recent transactions (limit 5, join items + wallet + category)
/// - Period aggregation (income/expense per bulan/minggu)
///
/// Semua query dibungkus [SupabaseHandler.call].
class DashboardRemoteDataSource {
  DashboardRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _tag = '[Dashboard] [DashboardRemoteDataSource]';

  String get _userId => _client.auth.currentUser!.id;

  // ───────────────── Recent Transactions ─────────────────

  /// Ambil [limit] transaksi terbaru untuk preview di dashboard.
  ///
  /// Join dengan wallets, destination_wallet, dan transaction_items(categories).
  Future<DataState<List<TransactionModel>>> getRecentTransactions({
    int limit = 5,
  }) {
    return SupabaseHandler.call<List<TransactionModel>>(
      function: () async {
        AppLogger.call('$_tag getRecentTransactions: limit=$limit');

        final response = await _client
            .from('transactions')
            .select('''
              *,
              wallets!transactions_wallet_id_fkey(name),
              destination_wallet:wallets!transactions_destination_wallet_id_fkey(name),
              transaction_items(
                *,
                categories(name, icon, color)
              )
            ''')
            .eq('user_id', _userId)
            .order('date', ascending: false)
            .order('created_at', ascending: false)
            .limit(limit);

        return response.map((e) => TransactionModel.fromMap(e)).toList();
      },
    );
  }

  // ───────────────── Period Aggregation ─────────────────

  /// Ambil total income & expense dalam [startDate]..[endDate].
  ///
  /// Hanya menghitung type `income` dan `expense` yang bukan settlement
  /// (sesuai PRD §4.2: settlement_kind IS NULL).
  ///
  /// Returns `{ 'income': double, 'expense': double }`.
  Future<DataState<Map<String, double>>> getPeriodSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return SupabaseHandler.call<Map<String, double>>(
      function: () async {
        AppLogger.call('$_tag getPeriodSummary: $startDate - $endDate');

        final range = SakuDateUtils.localDayRangeUtc(
          startDate: startDate,
          endDate: endDate,
        );

        final response = await _client
            .from('transactions')
            .select('type, total_amount, settlement_kind')
            .eq('user_id', _userId)
            .gte('date', range.startUtc)
            .lt('date', range.endUtcExclusive)
            .inFilter('type', ['income', 'expense'])
            .isFilter('settlement_kind', null);

        double totalIncome = 0;
        double totalExpense = 0;

        for (final row in response) {
          final amount = _toDouble(row['total_amount']);
          if (row['type'] == 'income') {
            totalIncome += amount;
          } else if (row['type'] == 'expense') {
            totalExpense += amount;
          }
        }

        return {'income': totalIncome, 'expense': totalExpense};
      },
    );
  }

  /// Ambil daily aggregation income/expense dalam [startDate]..[endDate].
  ///
  /// Returns list of `{ 'date': String, 'income': double, 'expense': double }`.
  /// Digunakan untuk bar chart perbandingan periode.
  Future<DataState<List<Map<String, dynamic>>>> getDailyAggregation({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return SupabaseHandler.call<List<Map<String, dynamic>>>(
      function: () async {
        AppLogger.call('$_tag getDailyAggregation: $startDate - $endDate');

        final range = SakuDateUtils.localDayRangeUtc(
          startDate: startDate,
          endDate: endDate,
        );

        final response = await _client
            .from('transactions')
            .select('type, total_amount, date, settlement_kind')
            .eq('user_id', _userId)
            .gte('date', range.startUtc)
            .lt('date', range.endUtcExclusive)
            .inFilter('type', ['income', 'expense'])
            .isFilter('settlement_kind', null)
            .order('date', ascending: true);

        // Aggregate per date locally
        final Map<String, Map<String, double>> dailyMap = {};

        for (final row in response) {
          final dateStr = SakuDateUtils.formatDate(
            SakuDateUtils.parseRequiredTimestamp(
              row['date'],
              fieldName: 'date',
            ),
          );
          dailyMap.putIfAbsent(dateStr, () => {'income': 0.0, 'expense': 0.0});
          final amount = _toDouble(row['total_amount']);
          if (row['type'] == 'income') {
            dailyMap[dateStr]!['income'] =
                dailyMap[dateStr]!['income']! + amount;
          } else {
            dailyMap[dateStr]!['expense'] =
                dailyMap[dateStr]!['expense']! + amount;
          }
        }

        return dailyMap.entries.map((e) {
          return {
            'date': e.key,
            'income': e.value['income']!,
            'expense': e.value['expense']!,
          };
        }).toList();
      },
    );
  }

  static double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
