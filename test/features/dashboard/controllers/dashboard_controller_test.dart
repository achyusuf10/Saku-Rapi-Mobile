import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ─── DashboardState tests ───

  group('DashboardState', () {
    test('default state has expected initial values', () {
      const state = DashboardState();

      expect(state.status, DashboardStatus.initial);
      expect(state.recentTransactions, isEmpty);
      expect(state.currentPeriodIncome, 0);
      expect(state.currentPeriodExpense, 0);
      expect(state.previousPeriodIncome, 0);
      expect(state.previousPeriodExpense, 0);
      expect(state.chartMode, DashboardChartMode.monthly);
      expect(state.currentPeriodDaily, isEmpty);
      expect(state.previousPeriodDaily, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.isBalanceHidden, false);
    });

    test('copyWith returns new state with updated fields', () {
      const state = DashboardState();

      final updated = state.copyWith(
        status: DashboardStatus.loaded,
        currentPeriodIncome: 5000000,
        currentPeriodExpense: 3000000,
        isBalanceHidden: true,
      );

      expect(updated.status, DashboardStatus.loaded);
      expect(updated.currentPeriodIncome, 5000000);
      expect(updated.currentPeriodExpense, 3000000);
      expect(updated.isBalanceHidden, true);
      // Unchanged fields remain
      expect(updated.previousPeriodIncome, 0);
      expect(updated.previousPeriodExpense, 0);
      expect(updated.chartMode, DashboardChartMode.monthly);
      expect(updated.recentTransactions, isEmpty);
    });

    test('copyWith without args returns identical state', () {
      const state = DashboardState(
        status: DashboardStatus.loaded,
        currentPeriodIncome: 100,
      );

      final copy = state.copyWith();

      expect(copy.status, DashboardStatus.loaded);
      expect(copy.currentPeriodIncome, 100);
    });

    test('copyWith clears errorMessage when not provided', () {
      final state = const DashboardState().copyWith(
        errorMessage: 'Network error',
      );
      expect(state.errorMessage, 'Network error');

      // copyWith without errorMessage should clear it (nullable field)
      final cleared = state.copyWith(status: DashboardStatus.loaded);
      expect(cleared.errorMessage, isNull);
    });

    test('copyWith preserves chart mode when not specified', () {
      final state = const DashboardState().copyWith(
        chartMode: DashboardChartMode.weekly,
      );

      final updated = state.copyWith(currentPeriodIncome: 999);
      expect(updated.chartMode, DashboardChartMode.weekly);
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

    test('copyWith updates daily aggregation data', () {
      final dailyData = [
        {'date': '2025-07-01', 'income': 100000.0, 'expense': 50000.0},
        {'date': '2025-07-02', 'income': 0.0, 'expense': 75000.0},
      ];

      final state = const DashboardState().copyWith(
        currentPeriodDaily: dailyData,
      );

      expect(state.currentPeriodDaily, hasLength(2));
      expect(state.currentPeriodDaily[0]['income'], 100000.0);
    });
  });

  // ─── periodRanges tests ───

  group('DashboardController.periodRanges', () {
    group('monthly mode', () {
      test('returns correct first and last day of current month', () {
        final now = DateTime(2025, 7, 15);
        final (currentStart, currentEnd, _, _) =
            DashboardController.periodRanges(now, DashboardChartMode.monthly);

        expect(currentStart, DateTime(2025, 7));
        expect(currentEnd.year, 2025);
        expect(currentEnd.month, 7);
        expect(currentEnd.day, 31);
      });

      test('returns correct previous month range', () {
        final now = DateTime(2025, 7, 15);
        final (_, _, prevStart, prevEnd) = DashboardController.periodRanges(
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
        final (currentStart, _, prevStart, prevEnd) =
            DashboardController.periodRanges(now, DashboardChartMode.monthly);

        expect(currentStart, DateTime(2025, 1));
        expect(prevStart, DateTime(2024, 12));
        expect(prevEnd.year, 2024);
        expect(prevEnd.month, 12);
        expect(prevEnd.day, 31);
      });

      test('handles February in leap year', () {
        final now = DateTime(2024, 2, 15);
        final (currentStart, currentEnd, _, _) =
            DashboardController.periodRanges(now, DashboardChartMode.monthly);

        expect(currentStart, DateTime(2024, 2));
        expect(currentEnd.day, 29); // Leap year
      });

      test('handles February in non-leap year', () {
        final now = DateTime(2025, 2, 10);
        final (_, currentEnd, _, _) = DashboardController.periodRanges(
          now,
          DashboardChartMode.monthly,
        );

        expect(currentEnd.day, 28);
      });

      test('currentEnd is just before next month start', () {
        final now = DateTime(2025, 3, 20);
        final (_, currentEnd, _, _) = DashboardController.periodRanges(
          now,
          DashboardChartMode.monthly,
        );

        // Should be 2025-03-31 23:59:59.999
        expect(
          currentEnd.millisecondsSinceEpoch,
          DateTime(2025, 4).millisecondsSinceEpoch - 1,
        );
      });

      test('prevEnd is just before current month start', () {
        final now = DateTime(2025, 5, 1);
        final (currentStart, _, _, prevEnd) = DashboardController.periodRanges(
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
        // 2025-07-16 is a Wednesday (weekday = 3)
        final now = DateTime(2025, 7, 16);
        final (currentStart, currentEnd, _, _) =
            DashboardController.periodRanges(now, DashboardChartMode.weekly);

        // Monday of that week: 2025-07-14
        expect(currentStart, DateTime(2025, 7, 14));
        // Sunday end: 2025-07-20 23:59:59.999
        expect(currentEnd.year, 2025);
        expect(currentEnd.month, 7);
        expect(currentEnd.day, 20);
      });

      test('returns previous week range', () {
        final now = DateTime(2025, 7, 16); // Wednesday
        final (_, _, prevStart, prevEnd) = DashboardController.periodRanges(
          now,
          DashboardChartMode.weekly,
        );

        // Previous Monday: 2025-07-07
        expect(prevStart, DateTime(2025, 7, 7));
        // Previous Sunday end: 2025-07-13 23:59:59.999
        expect(prevEnd.year, 2025);
        expect(prevEnd.month, 7);
        expect(prevEnd.day, 13);
      });

      test('Monday now — current start is today', () {
        final now = DateTime(2025, 7, 14); // Monday
        final (currentStart, _, _, _) = DashboardController.periodRanges(
          now,
          DashboardChartMode.weekly,
        );

        expect(currentStart, DateTime(2025, 7, 14));
      });

      test('Sunday now — current start is previous Monday', () {
        final now = DateTime(2025, 7, 20); // Sunday (weekday = 7)
        final (currentStart, currentEnd, _, _) =
            DashboardController.periodRanges(now, DashboardChartMode.weekly);

        // Should be Mon 2025-07-14
        expect(currentStart, DateTime(2025, 7, 14));
        expect(currentEnd.day, 20);
      });

      test('week spanning month boundary', () {
        // 2025-07-01 is a Tuesday (weekday = 2)
        final now = DateTime(2025, 7, 1);
        final (currentStart, _, _, _) = DashboardController.periodRanges(
          now,
          DashboardChartMode.weekly,
        );

        // Monday: 2025-06-30
        expect(currentStart, DateTime(2025, 6, 30));
      });

      test('previous week range ends just before current start', () {
        final now = DateTime(2025, 7, 16);
        final (currentStart, _, _, prevEnd) = DashboardController.periodRanges(
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
        final (currentStart, currentEnd, prevStart, prevEnd) =
            DashboardController.periodRanges(now, DashboardChartMode.weekly);

        // Current week duration: ~7 days minus 1ms
        final currentDuration = currentEnd.difference(currentStart).inDays;
        expect(currentDuration, 6); // Mon 00:00 to Sun 23:59 = ~6.99 days

        // Previous week: same
        final prevDuration = prevEnd.difference(prevStart).inDays;
        expect(prevDuration, 6);
      });
    });
  });

  // ─── DashboardChartMode enum tests ───

  group('DashboardChartMode', () {
    test('has monthly and weekly values', () {
      expect(DashboardChartMode.values, hasLength(2));
      expect(
        DashboardChartMode.values,
        containsAll([DashboardChartMode.monthly, DashboardChartMode.weekly]),
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
