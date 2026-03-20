import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/history/models/category_summary_model.dart';
import 'package:app_saku_rapi/features/history/models/transaction_group_model.dart';
import 'package:app_saku_rapi/features/transaction/datasource/transaction_remote_datasource.dart';
import 'package:app_saku_rapi/features/transaction/models/category_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
// Enums & State
// ─────────────────────────────────────────────────────────────

/// Mode tampilan di History screen.
enum HistoryViewMode { listView, reportView }

/// State utama History.
class HistoryState {
  const HistoryState({
    required this.activePeriodStart,
    required this.activePeriodEnd,
    this.viewMode = HistoryViewMode.listView,
    this.filterWalletId,
    this.transactionGroups = const [],
    this.categorySummaries = const [],
    this.monthlyIncome = 0,
    this.monthlyExpense = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMoreData = true,
    this.currentPage = 0,
    this.allTransactions = const [],
  });

  /// Awal bulan aktif.
  final DateTime activePeriodStart;

  /// Akhir bulan aktif.
  final DateTime activePeriodEnd;

  /// Mode tampilan: list atau report.
  final HistoryViewMode viewMode;

  /// Filter dompet tertentu. null = semua dompet.
  final String? filterWalletId;

  /// Transaksi tergroup per tanggal (untuk list view).
  final List<TransactionGroupModel> transactionGroups;

  /// Summary per kategori (untuk donut chart).
  final List<CategorySummaryModel> categorySummaries;

  /// Total pemasukan bulan ini.
  final double monthlyIncome;

  /// Total pengeluaran bulan ini.
  final double monthlyExpense;

  /// Flag loading awal.
  final bool isLoading;

  /// Flag loading halaman berikutnya (pagination).
  final bool isLoadingMore;

  /// Apakah masih ada data halaman berikutnya.
  final bool hasMoreData;

  /// Halaman pagination saat ini.
  final int currentPage;

  /// Semua transaksi yang sudah dimuat (flat list untuk pagination).
  final List<TransactionModel> allTransactions;

  HistoryState copyWith({
    DateTime? activePeriodStart,
    DateTime? activePeriodEnd,
    HistoryViewMode? viewMode,
    String? filterWalletId,
    bool clearWalletFilter = false,
    List<TransactionGroupModel>? transactionGroups,
    List<CategorySummaryModel>? categorySummaries,
    double? monthlyIncome,
    double? monthlyExpense,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMoreData,
    int? currentPage,
    List<TransactionModel>? allTransactions,
  }) {
    return HistoryState(
      activePeriodStart: activePeriodStart ?? this.activePeriodStart,
      activePeriodEnd: activePeriodEnd ?? this.activePeriodEnd,
      viewMode: viewMode ?? this.viewMode,
      filterWalletId: clearWalletFilter
          ? null
          : (filterWalletId ?? this.filterWalletId),
      transactionGroups: transactionGroups ?? this.transactionGroups,
      categorySummaries: categorySummaries ?? this.categorySummaries,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlyExpense: monthlyExpense ?? this.monthlyExpense,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      currentPage: currentPage ?? this.currentPage,
      allTransactions: allTransactions ?? this.allTransactions,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────

/// Provider utama untuk [HistoryController].
final historyControllerProvider =
    NotifierProvider<HistoryController, HistoryState>(
      () => HistoryController(),
    );

// ─────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────

/// Riverpod [Notifier] untuk mengelola state layar History.
///
/// Menangani navigasi periode, pagination, filter dompet,
/// dan agregasi data untuk list view dan report view.
class HistoryController extends Notifier<HistoryState> {
  late final TransactionRemoteDataSource _txRemote;

  static const String _tag = 'History';
  static const int _pageSize = 20;

  @override
  HistoryState build() {
    _txRemote = TransactionRemoteDataSource(client: Supabase.instance.client);

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // Load data awal secara asinkron
    Future.microtask(() => loadData());

    return HistoryState(activePeriodStart: start, activePeriodEnd: end);
  }

  /// Navigasi ke bulan sebelumnya.
  void goToPreviousPeriod() {
    final prev = DateTime(
      state.activePeriodStart.year,
      state.activePeriodStart.month - 1,
      1,
    );
    final end = DateTime(prev.year, prev.month + 1, 0, 23, 59, 59);
    state = state.copyWith(
      activePeriodStart: prev,
      activePeriodEnd: end,
      currentPage: 0,
      hasMoreData: true,
      allTransactions: [],
      transactionGroups: [],
      categorySummaries: [],
    );
    loadData();
  }

  /// Navigasi ke bulan berikutnya.
  void goToNextPeriod() {
    final next = DateTime(
      state.activePeriodStart.year,
      state.activePeriodStart.month + 1,
      1,
    );
    final end = DateTime(next.year, next.month + 1, 0, 23, 59, 59);
    state = state.copyWith(
      activePeriodStart: next,
      activePeriodEnd: end,
      currentPage: 0,
      hasMoreData: true,
      allTransactions: [],
      transactionGroups: [],
      categorySummaries: [],
    );
    loadData();
  }

  /// Ganti mode tampilan (list / report).
  void setViewMode(HistoryViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  /// Set filter dompet. null = semua.
  void setFilterWallet(String? walletId) {
    state = state.copyWith(
      filterWalletId: walletId,
      clearWalletFilter: walletId == null,
      currentPage: 0,
      hasMoreData: true,
      allTransactions: [],
      transactionGroups: [],
      categorySummaries: [],
    );
    loadData();
  }

  /// Load data sesuai periode & filter aktif.
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    AppLogger.call(
      '[$_tag] Loading data: ${state.activePeriodStart} → ${state.activePeriodEnd}',
      colorLog: ColorLog.blue,
    );

    final userId = Supabase.instance.client.auth.currentUser!.id;

    // 1. Fetch halaman pertama transaksi
    final txResult = await _txRemote.getTransactions(
      userId: userId,
      startDate: state.activePeriodStart,
      endDate: state.activePeriodEnd,
      walletId: state.filterWalletId,
      page: 0,
      limit: _pageSize,
    );

    List<TransactionModel> transactions = [];
    txResult.map(
      success: (data) => transactions = data.data,
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal fetch transaksi: ${err.message}',
          runtimeType: HistoryController,
        );
      },
    );

    // 2. Build groups dari halaman pertama
    final groups = _buildGroups(transactions);

    // 3. Hitung summary bulan ini (ambil semua untuk aggregate)
    final allTxResult = await _txRemote.getTransactions(
      userId: userId,
      startDate: state.activePeriodStart,
      endDate: state.activePeriodEnd,
      walletId: state.filterWalletId,
      page: 0,
      limit: 500,
    );

    List<TransactionModel> allMonthTx = [];
    allTxResult.map(success: (data) => allMonthTx = data.data, error: (_) {});

    double income = 0;
    double expense = 0;
    for (final tx in allMonthTx) {
      if (tx.type == 'income') income += tx.totalAmount;
      if (tx.type == 'expense') expense += tx.totalAmount;
    }

    // 4. Build category summaries untuk donut chart
    final summaries = await _buildCategorySummaries(
      transactions: allMonthTx,
      userId: userId,
      totalExpense: expense,
    );

    state = state.copyWith(
      isLoading: false,
      allTransactions: transactions,
      transactionGroups: groups,
      categorySummaries: summaries,
      monthlyIncome: income,
      monthlyExpense: expense,
      currentPage: 0,
      hasMoreData: transactions.length >= _pageSize,
    );

    AppLogger.call(
      '[$_tag] Loaded: ${transactions.length} tx, '
      'income=${income.toStringAsFixed(0)}, '
      'expense=${expense.toStringAsFixed(0)}, '
      '${summaries.length} categories',
      colorLog: ColorLog.green,
    );
  }

  /// Load halaman berikutnya (pagination infinite scroll).
  Future<void> loadMoreData() async {
    if (state.isLoadingMore || !state.hasMoreData) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;
    final userId = Supabase.instance.client.auth.currentUser!.id;

    AppLogger.call(
      '[$_tag] Loading page $nextPage...',
      colorLog: ColorLog.blue,
    );

    final txResult = await _txRemote.getTransactions(
      userId: userId,
      startDate: state.activePeriodStart,
      endDate: state.activePeriodEnd,
      walletId: state.filterWalletId,
      page: nextPage,
      limit: _pageSize,
    );

    List<TransactionModel> newTransactions = [];
    txResult.map(
      success: (data) => newTransactions = data.data,
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal load more: ${err.message}',
          runtimeType: HistoryController,
        );
      },
    );

    final allTx = [...state.allTransactions, ...newTransactions];
    final groups = _buildGroups(allTx);

    state = state.copyWith(
      isLoadingMore: false,
      currentPage: nextPage,
      allTransactions: allTx,
      transactionGroups: groups,
      hasMoreData: newTransactions.length >= _pageSize,
    );
  }

  /// Mengelompokkan transaksi berdasarkan tanggal (tanpa jam).
  List<TransactionGroupModel> _buildGroups(List<TransactionModel> txList) {
    final Map<DateTime, List<TransactionModel>> grouped = {};

    for (final tx in txList) {
      final dateKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
      grouped.putIfAbsent(dateKey, () => []).add(tx);
    }

    // Sort by date descending
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return sortedKeys.map((date) {
      return TransactionGroupModel.fromTransactions(
        date: date,
        transactions: grouped[date]!,
      );
    }).toList();
  }

  /// Membangun category summaries untuk donut chart.
  ///
  /// Mengagregasi amount per kategori parent dari transaction_items.
  Future<List<CategorySummaryModel>> _buildCategorySummaries({
    required List<TransactionModel> transactions,
    required String userId,
    required double totalExpense,
  }) async {
    if (totalExpense == 0) return [];

    final expenseTxs = transactions
        .where((tx) => tx.type == 'expense')
        .toList();

    if (expenseTxs.isEmpty) return [];

    // Aggregate amount per kategori via items
    final Map<String, double> categoryAmounts = {};

    for (final tx in expenseTxs) {
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
    }

    if (categoryAmounts.isEmpty) return [];

    // Ambil metadata kategori
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

    // Group child categories ke parent
    final Map<String, double> parentAmounts = {};
    final Map<String, Map<String, double>> childAmounts = {};

    for (final entry in categoryAmounts.entries) {
      final cat = categoryMap[entry.key];
      if (cat == null) continue;

      final parentId = cat.parentId ?? cat.id;
      parentAmounts.update(
        parentId,
        (v) => v + entry.value,
        ifAbsent: () => entry.value,
      );

      // Track child amounts under parent
      if (cat.parentId != null) {
        childAmounts.putIfAbsent(parentId, () => {});
        childAmounts[parentId]![cat.id] = entry.value;
      }
    }

    // Sort by amount descending
    final sorted = parentAmounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((entry) {
      final cat = categoryMap[entry.key];
      final parentTotal = entry.value;

      // Build child summaries
      final children = (childAmounts[entry.key] ?? {}).entries.map((child) {
        final childCat = categoryMap[child.key];
        return CategorySummaryModel(
          categoryId: child.key,
          categoryName: childCat?.name ?? 'Unknown',
          categoryIcon: childCat?.icon ?? 'tag',
          categoryColor: childCat?.color ?? '#6B7280',
          amount: child.value,
          percentage: parentTotal > 0 ? child.value / parentTotal : 0,
          parentId: entry.key,
        );
      }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

      return CategorySummaryModel(
        categoryId: entry.key,
        categoryName: cat?.name ?? 'Unknown',
        categoryIcon: cat?.icon ?? 'tag',
        categoryColor: cat?.color ?? '#6B7280',
        amount: parentTotal,
        percentage: totalExpense > 0 ? parentTotal / totalExpense : 0,
        childSummaries: children,
      );
    }).toList();
  }
}
