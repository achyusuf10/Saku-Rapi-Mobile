import 'package:app_saku_rapi/features/reports/controllers/report_controller.dart';
import 'package:app_saku_rapi/features/reports/models/report_model.dart';
import 'package:app_saku_rapi/features/reports/repositories/report_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ─── ReportPeriodSummaryModel ───

  group('ReportPeriodSummaryModel', () {
    test('computed properties are correct', () {
      const model = ReportPeriodSummaryModel(
        totalIncome: 5000000,
        totalExpense: 3000000,
      );

      expect(model.net, 2000000);
      expect(model.total, 8000000);
      expect(model.expenseToIncomeRatio, 0.6);
    });

    test('empty factory returns zeroes', () {
      final empty = ReportPeriodSummaryModel.empty();

      expect(empty.totalIncome, 0);
      expect(empty.totalExpense, 0);
      expect(empty.net, 0);
      expect(empty.expenseToIncomeRatio, 0);
    });

    test('expenseToIncomeRatio returns 0 when income is 0', () {
      const model = ReportPeriodSummaryModel(
        totalIncome: 0,
        totalExpense: 100000,
      );

      expect(model.expenseToIncomeRatio, 0.0);
    });

    test('fromMap parses correctly', () {
      final model = ReportPeriodSummaryModel.fromMap({
        'income': 1000000.0,
        'expense': 500000.0,
      });

      expect(model.totalIncome, 1000000);
      expect(model.totalExpense, 500000);
    });

    test('copyWith updates selected fields', () {
      const model = ReportPeriodSummaryModel(
        totalIncome: 100,
        totalExpense: 50,
      );

      final updated = model.copyWith(totalExpense: 75);

      expect(updated.totalIncome, 100);
      expect(updated.totalExpense, 75);
    });
  });

  // ─── ReportCategoryBreakdownModel ───

  group('ReportCategoryBreakdownModel', () {
    test('ratioOf calculates correctly', () {
      const model = ReportCategoryBreakdownModel(
        categoryId: '1',
        categoryName: 'Makan',
        categoryIcon: 'utensils',
        categoryColor: '#EF4444',
        amount: 250000,
        transactionCount: 5,
      );

      expect(model.ratioOf(1000000), 0.25);
    });

    test('ratioOf returns 0 when total is 0', () {
      const model = ReportCategoryBreakdownModel(
        categoryId: '1',
        categoryName: 'Makan',
        categoryIcon: 'utensils',
        categoryColor: '#EF4444',
        amount: 250000,
      );

      expect(model.ratioOf(0), 0.0);
    });

    test('fromMap parses all fields', () {
      final model = ReportCategoryBreakdownModel.fromMap({
        'category_id': 'cat-123',
        'category_name': 'Transport',
        'category_icon': 'car',
        'category_color': '#3B82F6',
        'amount': 150000,
        'parent_id': 'parent-1',
        'tx_count': 3,
      });

      expect(model.categoryId, 'cat-123');
      expect(model.categoryName, 'Transport');
      expect(model.categoryIcon, 'car');
      expect(model.categoryColor, '#3B82F6');
      expect(model.amount, 150000);
      expect(model.parentId, 'parent-1');
      expect(model.transactionCount, 3);
    });

    test('fromMap handles null values gracefully', () {
      final model = ReportCategoryBreakdownModel.fromMap({});

      expect(model.categoryId, '');
      expect(model.categoryName, '-');
      expect(model.categoryIcon, 'circle-question');
      expect(model.categoryColor, '#6B7280');
      expect(model.amount, 0.0);
      expect(model.parentId, isNull);
      expect(model.transactionCount, 0);
    });
  });

  // ─── ReportDailyTrendModel ───

  group('ReportDailyTrendModel', () {
    test('net is income minus expense', () {
      const model = ReportDailyTrendModel(
        date: '2025-01-15',
        income: 500000,
        expense: 300000,
      );

      expect(model.net, 200000);
    });

    test('fromMap parses correctly', () {
      final model = ReportDailyTrendModel.fromMap({
        'date': '2025-06-01',
        'income': 100000.0,
        'expense': 75000.0,
      });

      expect(model.date, '2025-06-01');
      expect(model.income, 100000);
      expect(model.expense, 75000);
    });
  });

  // ─── ReportRepository.topNCategories ───

  group('ReportRepository.topNCategories', () {
    test('returns all when <= maxCount', () {
      final categories = List.generate(
        3,
        (i) => ReportCategoryBreakdownModel(
          categoryId: '$i',
          categoryName: 'Cat $i',
          categoryIcon: 'circle',
          categoryColor: '#000000',
          amount: (3 - i) * 100000.0,
          transactionCount: i + 1,
        ),
      );

      final result = ReportRepository.topNCategories(categories);

      expect(result.length, 3);
    });

    test('merges overflow into Lainnya entry', () {
      final categories = List.generate(
        8,
        (i) => ReportCategoryBreakdownModel(
          categoryId: '$i',
          categoryName: 'Cat $i',
          categoryIcon: 'circle',
          categoryColor: '#000000',
          amount: (8 - i) * 100000.0,
          transactionCount: 1,
        ),
      );

      final result = ReportRepository.topNCategories(categories);

      expect(result.length, 6); // 5 + Lainnya
      expect(result.last.categoryId, '__others__');
      expect(result.last.categoryName, 'Lainnya');
      // "Lainnya" should sum Cat5(300k) + Cat6(200k) + Cat7(100k) = 600k
      expect(result.last.amount, 600000);
      expect(result.last.transactionCount, 3);
    });
  });

  // ─── ReportRepository.expenseChangePercent ───

  group('ReportRepository.expenseChangePercent', () {
    test('calculates positive change', () {
      final result = ReportRepository.expenseChangePercent(
        current: 1500000,
        previous: 1000000,
      );

      expect(result, 50.0);
    });

    test('calculates negative change', () {
      final result = ReportRepository.expenseChangePercent(
        current: 500000,
        previous: 1000000,
      );

      expect(result, -50.0);
    });

    test('returns 0 when previous is 0', () {
      final result = ReportRepository.expenseChangePercent(
        current: 500000,
        previous: 0,
      );

      expect(result, 0.0);
    });
  });

  // ─── ReportState ───

  group('ReportState', () {
    test('default state has expected initial values', () {
      const state = ReportState();

      expect(state.status, ReportStatus.initial);
      expect(state.period, ReportPeriod.monthly);
      expect(state.breakdownType, ReportBreakdownType.expense);
      expect(state.summary.totalIncome, 0);
      expect(state.summary.totalExpense, 0);
      expect(state.previousSummary.totalIncome, 0);
      expect(state.categoryBreakdown, isEmpty);
      expect(state.dailyTrend, isEmpty);
      expect(state.walletId, isNull);
      expect(state.errorMessage, isNull);
    });

    test('copyWith updates selected fields', () {
      const state = ReportState();

      final updated = state.copyWith(
        status: ReportStatus.loaded,
        period: ReportPeriod.weekly,
        walletId: 'wallet-1',
      );

      expect(updated.status, ReportStatus.loaded);
      expect(updated.period, ReportPeriod.weekly);
      expect(updated.walletId, 'wallet-1');
      // Unchanged
      expect(updated.breakdownType, ReportBreakdownType.expense);
    });

    test('copyWith clearWallet sets walletId to null', () {
      final state = const ReportState().copyWith(walletId: 'w-1');
      final cleared = state.copyWith(clearWallet: true);

      expect(cleared.walletId, isNull);
    });

    test('isLoading reflects status', () {
      const loading = ReportState(status: ReportStatus.loading);
      const loaded = ReportState(status: ReportStatus.loaded);

      expect(loading.isLoading, true);
      expect(loaded.isLoading, false);
    });
  });
}
