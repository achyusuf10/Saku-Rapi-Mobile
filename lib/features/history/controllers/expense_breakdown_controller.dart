import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/history/models/category_summary_model.dart';
import 'package:app_saku_rapi/features/transaction/datasource/transaction_remote_datasource.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────

/// State untuk layar Expense Breakdown.
class ExpenseBreakdownState {
  const ExpenseBreakdownState({
    required this.category,
    required this.periodStart,
    required this.periodEnd,
    this.transactions = const [],
    this.lastMonthAmount = 0,
    this.dailyAverage = 0,
    this.isLoading = false,
  });

  /// Empty state sebelum init dipanggil.
  factory ExpenseBreakdownState.empty() => ExpenseBreakdownState(
    category: CategorySummaryModel(
      categoryId: '',
      categoryName: '',
      categoryIcon: '',
      categoryColor: '',
      amount: 0,
      percentage: 0,
    ),
    periodStart: DateTime.now(),
    periodEnd: DateTime.now(),
  );

  /// Kategori yang sedang di-drill-down.
  final CategorySummaryModel category;

  /// Awal periode.
  final DateTime periodStart;

  /// Akhir periode.
  final DateTime periodEnd;

  /// Transaksi di kategori ini pada periode aktif.
  final List<TransactionModel> transactions;

  /// Total amount kategori ini bulan lalu (untuk perbandingan).
  final double lastMonthAmount;

  /// Rata-rata pengeluaran harian kategori ini.
  final double dailyAverage;

  /// Flag loading.
  final bool isLoading;

  ExpenseBreakdownState copyWith({
    CategorySummaryModel? category,
    DateTime? periodStart,
    DateTime? periodEnd,
    List<TransactionModel>? transactions,
    double? lastMonthAmount,
    double? dailyAverage,
    bool? isLoading,
  }) {
    return ExpenseBreakdownState(
      category: category ?? this.category,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      transactions: transactions ?? this.transactions,
      lastMonthAmount: lastMonthAmount ?? this.lastMonthAmount,
      dailyAverage: dailyAverage ?? this.dailyAverage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Provider Family
// ─────────────────────────────────────────────────────────────

/// Parameter untuk expense breakdown provider.
class BreakdownParams {
  const BreakdownParams({
    required this.category,
    required this.periodStart,
    required this.periodEnd,
  });

  final CategorySummaryModel category;
  final DateTime periodStart;
  final DateTime periodEnd;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BreakdownParams &&
          runtimeType == other.runtimeType &&
          category.categoryId == other.category.categoryId &&
          periodStart == other.periodStart;

  @override
  int get hashCode => category.categoryId.hashCode ^ periodStart.hashCode;
}

/// Provider untuk [ExpenseBreakdownController].
final expenseBreakdownControllerProvider =
    NotifierProvider<ExpenseBreakdownController, ExpenseBreakdownState>(
      () => ExpenseBreakdownController(),
    );

// ─────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────

/// Controller untuk drill-down expense breakdown per kategori.
///
/// Menghitung stats: vs bulan lalu, rata-rata harian,
/// dan list transaksi di kategori ini.
class ExpenseBreakdownController extends Notifier<ExpenseBreakdownState> {
  late final TransactionRemoteDataSource _txRemote;

  static const String _tag = 'ExpenseBreakdown';

  @override
  ExpenseBreakdownState build() {
    _txRemote = TransactionRemoteDataSource(client: Supabase.instance.client);
    return ExpenseBreakdownState.empty();
  }

  /// Inisialisasi breakdown dengan parameter yang diberikan.
  void init(BreakdownParams params) {
    state = ExpenseBreakdownState(
      category: params.category,
      periodStart: params.periodStart,
      periodEnd: params.periodEnd,
      isLoading: true,
    );
    _loadBreakdownData();
  }

  /// Load semua data breakdown: transaksi bulan ini, bulan lalu, stats.
  Future<void> _loadBreakdownData() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final category = state.category;
    final periodStart = state.periodStart;
    final periodEnd = state.periodEnd;
    final categoryId = category.categoryId;
    final childIds = category.childSummaries.map((c) => c.categoryId).toList();
    final allCategoryIds = [categoryId, ...childIds];

    AppLogger.call(
      '[$_tag] Loading breakdown for "${category.categoryName}"',
      colorLog: ColorLog.blue,
    );

    // 1. Fetch semua transaksi expense bulan ini
    final txResult = await _txRemote.getTransactions(
      userId: userId,
      startDate: periodStart,
      endDate: periodEnd,
      page: 0,
      limit: 500,
    );

    List<TransactionModel> allExpenseTx = [];
    txResult.map(
      success: (data) {
        allExpenseTx = data.data.where((tx) => tx.type == 'expense').toList();
      },
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal fetch transaksi: ${err.message}',
          runtimeType: ExpenseBreakdownController,
        );
      },
    );

    // Filter transaksi berdasarkan kategori (via transaction_items)
    final List<TransactionModel> categoryTransactions = [];
    for (final tx in allExpenseTx) {
      final itemsResult = await _txRemote.getTransactionItems(tx.id);
      bool hasCategory = false;
      itemsResult.map(
        success: (data) {
          hasCategory = data.data.any(
            (item) =>
                item.categoryId != null &&
                allCategoryIds.contains(item.categoryId),
          );
        },
        error: (_) {},
      );
      if (hasCategory) categoryTransactions.add(tx);
    }

    // 2. Fetch bulan lalu untuk perbandingan
    final lastMonthStart = DateTime(periodStart.year, periodStart.month - 1, 1);
    final lastMonthEnd = DateTime(
      lastMonthStart.year,
      lastMonthStart.month + 1,
      0,
      23,
      59,
      59,
    );

    final lastResult = await _txRemote.getTransactions(
      userId: userId,
      startDate: lastMonthStart,
      endDate: lastMonthEnd,
      page: 0,
      limit: 500,
    );

    // Compute last month amount via items
    double lastMonthAmount = 0;
    List<TransactionModel> lastExpenseAll = [];
    lastResult.map(
      success: (data) {
        lastExpenseAll = data.data.where((tx) => tx.type == 'expense').toList();
      },
      error: (_) {},
    );

    for (final tx in lastExpenseAll) {
      final itemsResult = await _txRemote.getTransactionItems(tx.id);
      itemsResult.map(
        success: (data) {
          for (final item in data.data) {
            if (item.categoryId != null &&
                allCategoryIds.contains(item.categoryId)) {
              lastMonthAmount += item.amount;
            }
          }
        },
        error: (_) {},
      );
    }

    // 3. Hitung rata-rata harian
    final daysInMonth = periodEnd.day;
    final dailyAvg = daysInMonth > 0 ? category.amount / daysInMonth : 0.0;

    state = state.copyWith(
      transactions: categoryTransactions,
      lastMonthAmount: lastMonthAmount,
      dailyAverage: dailyAvg,
      isLoading: false,
    );

    AppLogger.call(
      '[$_tag] Breakdown loaded: ${categoryTransactions.length} tx, '
      'lastMonth=${lastMonthAmount.toStringAsFixed(0)}, '
      'dailyAvg=${dailyAvg.toStringAsFixed(0)}',
      colorLog: ColorLog.green,
    );
  }
}
