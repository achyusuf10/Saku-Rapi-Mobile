import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_chart_controller.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ─── DashboardState tests (core, tanpa chart fields) ───

  group('DashboardState', () {
    test('default state has expected initial values', () {
      const state = DashboardState();

      expect(state.status, DashboardStatus.initial);
      expect(state.recentTransactions, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.isBalanceHidden, false);
    });

    test('copyWith returns new state with updated fields', () {
      const state = DashboardState();

      final updated = state.copyWith(
        status: DashboardStatus.loaded,
        isBalanceHidden: true,
      );

      expect(updated.status, DashboardStatus.loaded);
      expect(updated.isBalanceHidden, true);
      expect(updated.recentTransactions, isEmpty);
    });

    test('copyWith without args returns identical state', () {
      const state = DashboardState(status: DashboardStatus.loaded);

      final copy = state.copyWith();

      expect(copy.status, DashboardStatus.loaded);
    });

    test('copyWith clears errorMessage when not provided', () {
      final state = const DashboardState().copyWith(
        errorMessage: 'Network error',
      );
      expect(state.errorMessage, 'Network error');

      final cleared = state.copyWith(status: DashboardStatus.loaded);
      expect(cleared.errorMessage, isNull);
    });

    test('copyWith updates recentTransactions list', () {
      final tx = TransactionModel(
        id: 'tx-1',
        userId: 'u1',
        walletId: 'w1',
        type: TransactionTypeEnum.expense,
        totalAmount: 50000,
        date: DateTime(2025, 7, 1),
        isMultiItem: false,
        items: const [],
      );

      final state = const DashboardState().copyWith(recentTransactions: [tx]);

      expect(state.recentTransactions, hasLength(1));
      expect(state.recentTransactions.first.id, 'tx-1');
    });
  });

  // ─── DashboardChartState tests ───

  group('DashboardChartState', () {
    test('default state has expected initial values', () {
      const state = DashboardChartState();

      expect(state.status, DashboardChartStatus.initial);
      expect(state.chartMode, DashboardChartMode.monthly);
      expect(state.currentPeriodIncome, 0);
      expect(state.currentPeriodExpense, 0);
      expect(state.previousPeriodIncome, 0);
      expect(state.previousPeriodExpense, 0);
      expect(state.currentPeriodDaily, isEmpty);
      expect(state.previousPeriodDaily, isEmpty);
      expect(state.month2Daily, isEmpty);
      expect(state.month3Daily, isEmpty);
      expect(state.errorMessage, isNull);
    });

    test('copyWith returns new state with updated fields', () {
      const state = DashboardChartState();

      final updated = state.copyWith(
        status: DashboardChartStatus.loaded,
        chartMode: DashboardChartMode.weekly,
        currentPeriodIncome: 5000000,
        currentPeriodExpense: 3000000,
      );

      expect(updated.status, DashboardChartStatus.loaded);
      expect(updated.chartMode, DashboardChartMode.weekly);
      expect(updated.currentPeriodIncome, 5000000);
      expect(updated.currentPeriodExpense, 3000000);
      // Unchanged fields remain
      expect(updated.previousPeriodIncome, 0);
      expect(updated.previousPeriodExpense, 0);
    });

    test('copyWith without args returns identical state', () {
      const state = DashboardChartState(
        status: DashboardChartStatus.loaded,
        currentPeriodIncome: 100,
      );

      final copy = state.copyWith();

      expect(copy.status, DashboardChartStatus.loaded);
      expect(copy.currentPeriodIncome, 100);
    });

    test('copyWith clears errorMessage when not provided', () {
      final state = const DashboardChartState().copyWith(
        errorMessage: 'Chart load error',
      );
      expect(state.errorMessage, 'Chart load error');

      final cleared = state.copyWith(status: DashboardChartStatus.loaded);
      expect(cleared.errorMessage, isNull);
    });

    test('copyWith preserves chart mode when not specified', () {
      final state = const DashboardChartState().copyWith(
        chartMode: DashboardChartMode.weekly,
      );

      final updated = state.copyWith(currentPeriodIncome: 999);
      expect(updated.chartMode, DashboardChartMode.weekly);
    });

    test('copyWith updates daily aggregation data', () {
      final dailyData = [
        {'date': '2025-07-01', 'income': 100000.0, 'expense': 50000.0},
        {'date': '2025-07-02', 'income': 0.0, 'expense': 75000.0},
      ];

      final state = const DashboardChartState().copyWith(
        currentPeriodDaily: dailyData,
      );

      expect(state.currentPeriodDaily, hasLength(2));
      expect(state.currentPeriodDaily[0]['income'], 100000.0);
    });
  });

  // ─── periodRanges tests (now on DashboardChartController) ───

  group('DashboardChartController.periodRanges', () {
    group('monthly mode', () {
      test('returns correct first and last day of current month', () {
        final now = DateTime(2025, 7, 15);
        final (
          currentStart,
          currentEnd,
          _,
          _,
        ) = DashboardChartController.periodRanges(
          now,
          DashboardChartMode.monthly,
        );

        expect(currentStart, DateTime(2025, 7));
        expect(currentEnd.year, 2025);
        expect(currentEnd.month, 7);
        expect(currentEnd.day, 31);
      });

      test('returns correct previous month range', () {
        final now = DateTime(2025, 7, 15);
        final (
          _,
          _,
          prevStart,
          prevEnd,
        ) = DashboardChartController.periodRanges(
          now,
          DashboardChartMode.monthly,
        );

        expect(prevStart, DateTime(2025, 6));
        expect(prevEnd.year, 2025);
        expect(prevEnd.month, 6);
        expect(prevEnd.day, 30);
      });

      test('handles January correctly — previous is December', () {
        final now = DateTime(2025, 1, 10);
        final (
          currentStart,
          _,
          prevStart,
          prevEnd,
        ) = DashboardChartController.periodRanges(
          now,
          DashboardChartMode.monthly,
        );

        expect(currentStart, DateTime(2025, 1));
        expect(prevStart, DateTime(2024, 12));
        expect(prevEnd.year, 2024);
        expect(prevEnd.month, 12);
        expect(prevEnd.day, 31);
      });

      test('handles February in leap year', () {
        final now = DateTime(2024, 2, 15);
        final (
          currentStart,
          currentEnd,
          _,
          _,
        ) = DashboardChartController.periodRanges(
          now,
          DashboardChartMode.monthly,
        );

        expect(currentStart, DateTime(2024, 2));
        expect(currentEnd.day, 29);
      });

      test('handles February in non-leap year', () {
        final now = DateTime(2025, 2, 10);
        final (_, currentEnd, _, _) = DashboardChartController.periodRanges(
          now,
          DashboardChartMode.monthly,
        );

        expect(currentEnd.day, 28);
      });

      test('currentEnd is just before next month start', () {
        final now = DateTime(2025, 3, 20);
        final (_, currentEnd, _, _) = DashboardChartController.periodRanges(
          now,
          DashboardChartMode.monthly,
        );

        expect(
          currentEnd.millisecondsSinceEpoch,
          DateTime(2025, 4).millisecondsSinceEpoch - 1,
        );
      });

      test('prevEnd is just before current month start', () {
        final now = DateTime(2025, 5, 1);
        final (
          currentStart,
          _,
          _,
          prevEnd,
        ) = DashboardChartController.periodRanges(
          now,
          DashboardChartMode.monthly,
        );

        expect(
          prevEnd.millisecondsSinceEpoch,
          currentStart.millisecondsSinceEpoch - 1,
        );
      });
    });

    group('weekly mode', () {
      test('returns Monday-Sunday range for current week', () {
        final now = DateTime(2025, 7, 16);
        final (
          currentStart,
          currentEnd,
          _,
          _,
        ) = DashboardChartController.periodRanges(
          now,
          DashboardChartMode.weekly,
        );

        expect(currentStart, DateTime(2025, 7, 14));
        expect(currentEnd.year, 2025);
        expect(currentEnd.month, 7);
        expect(currentEnd.day, 20);
      });

      test('returns previous week range', () {
        final now = DateTime(2025, 7, 16);
        final (
          _,
          _,
          prevStart,
          prevEnd,
        ) = DashboardChartController.periodRanges(
          now,
          DashboardChartMode.weekly,
        );

        expect(prevStart, DateTime(2025, 7, 7));
        expect(prevEnd.year, 2025);
        expect(prevEnd.month, 7);
        expect(prevEnd.day, 13);
      });

      test('Monday now — current start is today', () {
        final now = DateTime(2025, 7, 14);
        final (currentStart, _, _, _) = DashboardChartController.periodRanges(
          now,
          DashboardChartMode.weekly,
        );

        expect(currentStart, DateTime(2025, 7, 14));
      });

      test('Sunday now — current start is previous Monday', () {
        final now = DateTime(2025, 7, 20);
        final (
          currentStart,
          currentEnd,
          _,
          _,
        ) = DashboardChartController.periodRanges(
          now,
          DashboardChartMode.weekly,
        );

        expect(currentStart, DateTime(2025, 7, 14));
        expect(currentEnd.day, 20);
      });

      test('week spanning month boundary', () {
        final now = DateTime(2025, 7, 1);
        final (currentStart, _, _, _) = DashboardChartController.periodRanges(
          now,
          DashboardChartMode.weekly,
        );

        expect(currentStart, DateTime(2025, 6, 30));
      });

      test('previous week range ends just before current start', () {
        final now = DateTime(2025, 7, 16);
        final (
          currentStart,
          _,
          _,
          prevEnd,
        ) = DashboardChartController.periodRanges(
          now,
          DashboardChartMode.weekly,
        );

        expect(
          prevEnd.millisecondsSinceEpoch,
          currentStart.millisecondsSinceEpoch - 1,
        );
      });

      test('week range spans exactly 7 days', () {
        final now = DateTime(2025, 7, 16);
        final (
          currentStart,
          currentEnd,
          prevStart,
          prevEnd,
        ) = DashboardChartController.periodRanges(
          now,
          DashboardChartMode.weekly,
        );

        final currentDuration = currentEnd.difference(currentStart).inDays;
        expect(currentDuration, 6);

        final prevDuration = prevEnd.difference(prevStart).inDays;
        expect(prevDuration, 6);
      });
    });

    group('daily mode', () {
      test('returns today start to end of day', () {
        final now = DateTime(2025, 7, 16, 14, 30);
        final (
          currentStart,
          currentEnd,
          _,
          _,
        ) = DashboardChartController.periodRanges(
          now,
          DashboardChartMode.daily,
        );

        expect(currentStart, DateTime(2025, 7, 16));
        expect(currentEnd.year, 2025);
        expect(currentEnd.month, 7);
        expect(currentEnd.day, 16);
        expect(currentEnd.hour, 23);
      });

      test('returns yesterday as previous period', () {
        final now = DateTime(2025, 7, 16, 14, 30);
        final (
          _,
          _,
          prevStart,
          prevEnd,
        ) = DashboardChartController.periodRanges(
          now,
          DashboardChartMode.daily,
        );

        expect(prevStart, DateTime(2025, 7, 15));
        expect(prevEnd.year, 2025);
        expect(prevEnd.month, 7);
        expect(prevEnd.day, 15);
      });

      test('prevEnd is just before today start', () {
        final now = DateTime(2025, 7, 16);
        final (
          currentStart,
          _,
          _,
          prevEnd,
        ) = DashboardChartController.periodRanges(
          now,
          DashboardChartMode.daily,
        );

        expect(
          prevEnd.millisecondsSinceEpoch,
          currentStart.millisecondsSinceEpoch - 1,
        );
      });
    });
  });

  // ─── DashboardChartMode enum tests ───

  group('DashboardChartMode', () {
    test('has monthly, weekly, and daily values', () {
      expect(DashboardChartMode.values, hasLength(3));
      expect(
        DashboardChartMode.values,
        containsAll([
          DashboardChartMode.monthly,
          DashboardChartMode.weekly,
          DashboardChartMode.daily,
        ]),
      );
    });
  });

  // ─── DashboardChartStatus enum tests ───

  group('DashboardChartStatus', () {
    test('has 4 values', () {
      expect(DashboardChartStatus.values, hasLength(4));
      expect(
        DashboardChartStatus.values,
        containsAll([
          DashboardChartStatus.initial,
          DashboardChartStatus.loading,
          DashboardChartStatus.loaded,
          DashboardChartStatus.error,
        ]),
      );
    });
  });

  // ─── DashboardStatus enum tests ───

  group('DashboardStatus', () {
    test('has 4 values', () {
      expect(DashboardStatus.values, hasLength(4));
      expect(
        DashboardStatus.values,
        containsAll([
          DashboardStatus.initial,
          DashboardStatus.loading,
          DashboardStatus.loaded,
          DashboardStatus.error,
        ]),
      );
    });
  });
}
