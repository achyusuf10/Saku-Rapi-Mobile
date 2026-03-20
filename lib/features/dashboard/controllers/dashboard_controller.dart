import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/transaction/datasource/transaction_remote_datasource.dart';
import 'package:app_saku_rapi/features/transaction/models/category_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────

/// Data satu kategori dalam top expenses.
class TopExpenseCategory {
  const TopExpenseCategory({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.amount,
    required this.percentage,
  });

  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final double amount;

  /// Persentase terhadap total expense bulan ini (0.0 – 1.0).
  final double percentage;
}

/// Data bar chart income vs expense per minggu.
class WeeklyChartData {
  const WeeklyChartData({
    required this.weekNumber,
    required this.income,
    required this.expense,
  });

  final int weekNumber;
  final double income;
  final double expense;
}

/// State keseluruhan dashboard.
class DashboardData {
  const DashboardData({
    required this.totalBalance,
    required this.wallets,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.topExpenseCategories,
    required this.recentTransactions,
    required this.chartData,
  });

  /// Sum saldo wallet non-excluded.
  final double totalBalance;

  /// Semua wallet user.
  final List<WalletModel> wallets;

  /// Sum pemasukan bulan ini.
  final double monthlyIncome;

  /// Sum pengeluaran bulan ini.
  final double monthlyExpense;

  /// Top 5 kategori expense bulan ini.
  final List<TopExpenseCategory> topExpenseCategories;

  /// 3 transaksi terbaru.
  final List<TransactionModel> recentTransactions;

  /// Income vs expense per minggu (4-5 titik).
  final List<WeeklyChartData> chartData;

  DashboardData copyWith({
    double? totalBalance,
    List<WalletModel>? wallets,
    double? monthlyIncome,
    double? monthlyExpense,
    List<TopExpenseCategory>? topExpenseCategories,
    List<TransactionModel>? recentTransactions,
    List<WeeklyChartData>? chartData,
  }) {
    return DashboardData(
      totalBalance: totalBalance ?? this.totalBalance,
      wallets: wallets ?? this.wallets,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlyExpense: monthlyExpense ?? this.monthlyExpense,
      topExpenseCategories: topExpenseCategories ?? this.topExpenseCategories,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      chartData: chartData ?? this.chartData,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────

/// Provider utama untuk [DashboardController].
final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardData>(
      () => DashboardController(),
    );

// ─────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────

/// Riverpod [AsyncNotifier] yang mengagregasi data dari Wallet + Transaction
/// untuk kebutuhan semua widget dashboard.
class DashboardController extends AsyncNotifier<DashboardData> {
  late final TransactionRemoteDataSource _txRemote;

  static const String _tag = 'Dashboard';

  @override
  Future<DashboardData> build() async {
    _txRemote = TransactionRemoteDataSource(client: Supabase.instance.client);

    return _fetchDashboardData();
  }

  /// Fetch ulang seluruh data dashboard (untuk pull-to-refresh).
  Future<void> refresh() async {
    // Refresh wallet juga
    await ref.read(walletControllerProvider.notifier).refresh();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchDashboardData());
  }

  /// Aggregasi semua data dashboard.
  Future<DashboardData> _fetchDashboardData() async {
    AppLogger.call(
      '[$_tag] Memulai fetch dashboard...',
      colorLog: ColorLog.blue,
    );

    final userId = Supabase.instance.client.auth.currentUser!.id;

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // 1. Wallet data (dari wallet controller)
    final walletController = ref.read(walletControllerProvider);
    final wallets = walletController.value ?? [];
    final totalBalance = wallets
        .where((w) => !w.excludeFromTotal)
        .fold(0.0, (sum, w) => sum + w.balance);

    // 2. Transaksi bulan ini (ambil semua untuk aggregate)
    final txResult = await _txRemote.getTransactions(
      userId: userId,
      startDate: firstDayOfMonth,
      endDate: lastDayOfMonth,
      page: 0,
      limit: 500, // Ambil cukup banyak untuk aggregate
    );

    List<TransactionModel> monthlyTransactions = [];
    txResult.map(
      success: (data) => monthlyTransactions = data.data,
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal fetch transaksi: ${err.message}',
          runtimeType: DashboardController,
        );
      },
    );

    // 3. Hitung monthly income & expense
    double monthlyIncome = 0;
    double monthlyExpense = 0;
    for (final tx in monthlyTransactions) {
      if (tx.type == 'income') {
        monthlyIncome += tx.totalAmount;
      } else if (tx.type == 'expense') {
        monthlyExpense += tx.totalAmount;
      }
    }

    // 4. Chart data: income vs expense per minggu
    final chartData = _buildWeeklyChartData(
      transactions: monthlyTransactions,
      firstDayOfMonth: firstDayOfMonth,
      lastDayOfMonth: lastDayOfMonth,
    );

    // 5. Top expense categories
    final topExpenses = await _buildTopExpenseCategories(
      transactions: monthlyTransactions,
      userId: userId,
      totalExpense: monthlyExpense,
    );

    // 6. Recent transactions (3 terbaru)
    final recentResult = await _txRemote.getTransactions(
      userId: userId,
      startDate: DateTime(2000),
      endDate: now,
      page: 0,
      limit: 3,
    );

    List<TransactionModel> recentTransactions = [];
    recentResult.map(
      success: (data) => recentTransactions = data.data,
      error: (_) {},
    );

    AppLogger.call(
      '[$_tag] Dashboard loaded: ${wallets.length} wallets, '
      '${monthlyTransactions.length} tx bulan ini, '
      'income=${monthlyIncome.toStringAsFixed(0)}, '
      'expense=${monthlyExpense.toStringAsFixed(0)}',
      colorLog: ColorLog.green,
    );

    return DashboardData(
      totalBalance: totalBalance,
      wallets: wallets,
      monthlyIncome: monthlyIncome,
      monthlyExpense: monthlyExpense,
      topExpenseCategories: topExpenses,
      recentTransactions: recentTransactions,
      chartData: chartData,
    );
  }

  /// Mengelompokkan transaksi ke minggu-minggu dalam bulan ini.
  List<WeeklyChartData> _buildWeeklyChartData({
    required List<TransactionModel> transactions,
    required DateTime firstDayOfMonth,
    required DateTime lastDayOfMonth,
  }) {
    // Hitung jumlah minggu dalam bulan
    final totalDays = lastDayOfMonth.day;
    final weekCount = ((totalDays - 1) ~/ 7) + 1;

    final incomeByWeek = List<double>.filled(weekCount, 0);
    final expenseByWeek = List<double>.filled(weekCount, 0);

    for (final tx in transactions) {
      if (tx.type != 'income' && tx.type != 'expense') continue;

      final dayOfMonth = tx.date.day;
      final weekIndex = ((dayOfMonth - 1) ~/ 7).clamp(0, weekCount - 1);

      if (tx.type == 'income') {
        incomeByWeek[weekIndex] += tx.totalAmount;
      } else {
        expenseByWeek[weekIndex] += tx.totalAmount;
      }
    }

    return List.generate(weekCount, (i) {
      return WeeklyChartData(
        weekNumber: i + 1,
        income: incomeByWeek[i],
        expense: expenseByWeek[i],
      );
    });
  }

  /// Mengagregasi top 5 kategori expense menggunakan transaction_items.
  Future<List<TopExpenseCategory>> _buildTopExpenseCategories({
    required List<TransactionModel> transactions,
    required String userId,
    required double totalExpense,
  }) async {
    if (totalExpense == 0) return [];

    // Ambil items dari semua transaksi expense
    final expenseTransactions = transactions
        .where((tx) => tx.type == 'expense')
        .toList();

    // Aggregate amount per kategori — menggunakan transaction header saja
    // untuk transaksi single-item, dan items untuk multi-item
    final Map<String, double> categoryAmounts = {};

    for (final tx in expenseTransactions) {
      if (tx.isMultiItem) {
        // Ambil items untuk multi-item transaksi
        final itemsResult = await _txRemote.getTransactionItems(tx.id);
        itemsResult.map(
          success: (data) {
            for (final item in data.data) {
              if (item.categoryId != null) {
                categoryAmounts.update(
                  item.categoryId!,
                  (v) => v + item.amount,
                  ifAbsent: () => item.amount,
                );
              }
            }
          },
          error: (_) {},
        );
      } else {
        // Single item: ambil items untuk mendapatkan categoryId
        final itemsResult = await _txRemote.getTransactionItems(tx.id);
        itemsResult.map(
          success: (data) {
            if (data.data.isNotEmpty) {
              final item = data.data.first;
              if (item.categoryId != null) {
                categoryAmounts.update(
                  item.categoryId!,
                  (v) => v + tx.totalAmount,
                  ifAbsent: () => tx.totalAmount,
                );
              }
            }
          },
          error: (_) {},
        );
      }
    }

    if (categoryAmounts.isEmpty) return [];

    // Ambil kategori metadata
    final catResult = await _txRemote.getCategories(userId: userId);
    Map<String, CategoryModel> categoryMap = {};
    catResult.map(
      success: (data) {
        for (final cat in data.data) {
          categoryMap[cat.id] = cat;
        }
      },
      error: (_) {},
    );

    // Sort by amount descending
    final sorted = categoryAmounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Top 5
    return sorted.take(5).map((entry) {
      final cat = categoryMap[entry.key];
      return TopExpenseCategory(
        categoryId: entry.key,
        categoryName: cat?.name ?? 'Unknown',
        categoryIcon: cat?.icon ?? 'tag',
        categoryColor: cat?.color ?? '#6B7280',
        amount: entry.value,
        percentage: entry.value / totalExpense,
      );
    }).toList();
  }
}
