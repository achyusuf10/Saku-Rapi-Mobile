import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/core/utils/color_utils.dart';
import 'package:app_saku_rapi/core/utils/saku_date_utils.dart';
import 'package:app_saku_rapi/features/reports/models/report_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk modul Reports & Analytics.
///
/// Semua query menerapkan rule PRD §4.2:
/// - Hanya `income` dan `expense`
/// - `settlement_kind IS NULL`
/// - Dibungkus [SupabaseHandler.call]
class ReportRemoteDataSource {
  ReportRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _tag = '[Reports] [ReportRemoteDataSource]';

  String get _userId => _client.auth.currentUser!.id;

  // ───────────────── Period Summary ─────────────────

  /// Ambil total income & expense dalam [startDate]..[endDate].
  ///
  /// Rule exclusion:
  /// - type IN ('income', 'expense')
  /// - settlement_kind IS NULL
  Future<DataState<ReportPeriodSummaryModel>> getPeriodSummary({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
  }) {
    return SupabaseHandler.call<ReportPeriodSummaryModel>(
      function: () async {
        AppLogger.call('$_tag getPeriodSummary: $startDate - $endDate');

        final range = SakuDateUtils.localDayRangeUtc(
          startDate: startDate,
          endDate: endDate,
        );

        var query = _client
            .from('transactions')
            .select('type, total_amount')
            .eq('user_id', _userId)
            .gte('date', range.startUtc)
            .lt('date', range.endUtcExclusive)
            .inFilter('type', ['income', 'expense'])
            .isFilter('settlement_kind', null);

        if (walletId != null) {
          query = query.eq('wallet_id', walletId);
        }

        final response = await query;

        double totalIncome = 0;
        double totalExpense = 0;

        for (final row in response) {
          final amount = _toDouble(row['total_amount']);
          if (row['type'] == 'income') {
            totalIncome += amount;
          } else {
            totalExpense += amount;
          }
        }

        return ReportPeriodSummaryModel(
          totalIncome: totalIncome,
          totalExpense: totalExpense,
        );
      },
    );
  }

  // ───────────────── Category Breakdown ─────────────────

  /// Ambil breakdown pengeluaran per kategori (expense only).
  ///
  /// Join transaction_items -> categories untuk nama, icon, color.
  /// Menghitung sum amount per category_id.
  Future<DataState<List<ReportCategoryBreakdownModel>>> getCategoryBreakdown({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
    String type = 'expense',
  }) {
    return SupabaseHandler.call<List<ReportCategoryBreakdownModel>>(
      function: () async {
        AppLogger.call(
          '$_tag getCategoryBreakdown: $startDate - $endDate, type=$type',
        );

        final range = SakuDateUtils.localDayRangeUtc(
          startDate: startDate,
          endDate: endDate,
        );

        var query = _client
            .from('transactions')
            .select('''
              total_amount,
              transaction_items(
                amount,
                category_id,
                categories(name, icon, color, background_color, parent_id)
              )
            ''')
            .eq('user_id', _userId)
            .eq('type', type)
            .gte('date', range.startUtc)
            .lt('date', range.endUtcExclusive)
            .isFilter('settlement_kind', null);

        if (walletId != null) {
          query = query.eq('wallet_id', walletId);
        }

        final response = await query;

        // Aggregate per category from transaction items
        final Map<String, _CategoryAgg> aggMap = {};

        for (final tx in response) {
          final items = tx['transaction_items'] as List<dynamic>? ?? [];
          for (final item in items) {
            final catId = item['category_id'] as String?;
            if (catId == null) continue;

            final amount = _toDouble(item['amount']);
            final cat = item['categories'] as Map<String, dynamic>?;

            if (aggMap.containsKey(catId)) {
              aggMap[catId]!.amount += amount;
              aggMap[catId]!.count += 1;
            } else {
              aggMap[catId] = _CategoryAgg(
                categoryId: catId,
                categoryName: cat?['name'] as String? ?? '-',
                categoryIcon: cat?['icon'] as String? ?? 'circle-question',
                categoryColor: cat?['color'] as String? ?? '#6B7280',
                categoryBackgroundColor:
                    cat?['background_color'] as String? ??
                        kSakuDefaultIconBackgroundHex,
                parentId: cat?['parent_id'] as String?,
                amount: amount,
                count: 1,
              );
            }
          }
        }

        final list = aggMap.values
            .map(
              (a) => ReportCategoryBreakdownModel(
                categoryId: a.categoryId,
                categoryName: a.categoryName,
                categoryIcon: a.categoryIcon,
                categoryColor: a.categoryColor,
                categoryBackgroundColor: a.categoryBackgroundColor,
                amount: a.amount,
                parentId: a.parentId,
                transactionCount: a.count,
              ),
            )
            .toList();

        // Sort descending by amount
        list.sort((a, b) => b.amount.compareTo(a.amount));

        return list;
      },
    );
  }

  // ───────────────── Daily Trend ─────────────────

  /// Ambil tren harian income/expense dalam [startDate]..[endDate].
  ///
  /// Returns list sorted by date ascending.
  Future<DataState<List<ReportDailyTrendModel>>> getDailyTrend({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
  }) {
    return SupabaseHandler.call<List<ReportDailyTrendModel>>(
      function: () async {
        AppLogger.call('$_tag getDailyTrend: $startDate - $endDate');

        final range = SakuDateUtils.localDayRangeUtc(
          startDate: startDate,
          endDate: endDate,
        );

        var query = _client
            .from('transactions')
            .select('type, total_amount, date')
            .eq('user_id', _userId)
            .gte('date', range.startUtc)
            .lt('date', range.endUtcExclusive)
            .inFilter('type', ['income', 'expense'])
            .isFilter('settlement_kind', null);

        if (walletId != null) {
          query = query.eq('wallet_id', walletId);
        }

        final response = await query.order('date', ascending: true);

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

        return dailyMap.entries
            .map(
              (e) => ReportDailyTrendModel(
                date: e.key,
                income: e.value['income']!,
                expense: e.value['expense']!,
              ),
            )
            .toList();
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

/// Helper class untuk agregasi kategori sementara.
class _CategoryAgg {
  _CategoryAgg({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.categoryBackgroundColor,
    this.parentId,
    required this.amount,
    required this.count,
  });

  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final String categoryBackgroundColor;
  final String? parentId;
  double amount;
  int count;
}
