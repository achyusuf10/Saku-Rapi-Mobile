import 'dart:async';

import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/history/models/history_models.dart';
import 'package:app_saku_rapi/features/reports/controllers/report_controller.dart';
import 'package:app_saku_rapi/features/reports/models/report_model.dart';
import 'package:app_saku_rapi/features/reports/repositories/report_repository.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

class _MockReportRepository extends Mock implements ReportRepository {}

// ─── Data helpers ─────────────────────────────────────────────────────────────

final _emptySummary = DataState<ReportPeriodSummaryModel>.success(
  data: const ReportPeriodSummaryModel(totalIncome: 0, totalExpense: 0),
);

final _summaryError =
    DataState<ReportPeriodSummaryModel>.error(message: 'Summary failed');

final _emptyBreakdown =
    DataState<List<ReportCategoryBreakdownModel>>.success(data: []);

final _emptyTrend =
    DataState<List<ReportDailyTrendModel>>.success(data: []);

// ─── Stub helpers ─────────────────────────────────────────────────────────────

/// Stubs all 4 report repo methods to return fast success values.
void _stubAll(_MockReportRepository repo) {
  when(
    () => repo.getPeriodSummary(
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
      walletId: any(named: 'walletId'),
    ),
  ).thenAnswer((_) async => _emptySummary);

  when(
    () => repo.getCategoryBreakdown(
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
      walletId: any(named: 'walletId'),
      type: any(named: 'type'),
    ),
  ).thenAnswer((_) async => _emptyBreakdown);

  when(
    () => repo.getDailyTrend(
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
      walletId: any(named: 'walletId'),
    ),
  ).thenAnswer((_) async => _emptyTrend);
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late _MockReportRepository repo;

  setUpAll(() async {
    registerFallbackValue(DateTime.now());
    await initializeDateFormatting('id', null);
  });

  setUp(() {
    repo = _MockReportRepository();
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Basic load paths
  // ═══════════════════════════════════════════════════════════════════════════

  group('loadReport — basic paths', () {
    test('initial state is ReportStatus.initial', () {
      _stubAll(repo);
      final controller = ReportController(repo);
      expect(controller.state.status, ReportStatus.initial);
      controller.dispose();
    });

    test('sets status to loaded on success', () async {
      _stubAll(repo);
      final controller = ReportController(repo);

      await controller.loadReport();

      expect(controller.state.status, ReportStatus.loaded);
      expect(controller.state.categoryBreakdown, isEmpty);
      expect(controller.state.dailyTrend, isEmpty);
      controller.dispose();
    });

    test('sets status to error when getPeriodSummary fails', () async {
      when(
        () => repo.getPeriodSummary(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          walletId: any(named: 'walletId'),
        ),
      ).thenAnswer((_) async => _summaryError);

      when(
        () => repo.getCategoryBreakdown(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          walletId: any(named: 'walletId'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => _emptyBreakdown);

      when(
        () => repo.getDailyTrend(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          walletId: any(named: 'walletId'),
        ),
      ).thenAnswer((_) async => _emptyTrend);

      final controller = ReportController(repo);

      await controller.loadReport();

      expect(controller.state.status, ReportStatus.error);
      expect(controller.state.errorMessage, 'Summary failed');
      controller.dispose();
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Generation counter — stale parallel responses discarded
  // ═══════════════════════════════════════════════════════════════════════════

  group('generation counter — stale parallel responses discarded', () {
    test('stale first loadReport is discarded when second completes first',
        () async {
      // Slow first load: trend request is held in a completer
      final slowTrendCompleter = Completer<DataState<List<ReportDailyTrendModel>>>();
      var trendCallCount = 0;

      when(
        () => repo.getPeriodSummary(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          walletId: any(named: 'walletId'),
        ),
      ).thenAnswer((_) async => _emptySummary);

      when(
        () => repo.getCategoryBreakdown(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          walletId: any(named: 'walletId'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => _emptyBreakdown);

      when(
        () => repo.getDailyTrend(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          walletId: any(named: 'walletId'),
        ),
      ).thenAnswer((_) {
        trendCallCount++;
        // First two calls belong to loadReport #1 (gen=1) via Future.wait;
        // BUT getDailyTrend is called once per loadReport.
        // First call: slow (from first loadReport)
        if (trendCallCount == 1) return slowTrendCompleter.future;
        // Subsequent: fast
        return Future.value(_emptyTrend);
      });

      final controller = ReportController(repo);

      // First loadReport (gen=1) — stays in flight (getDailyTrend is slow)
      final future1 = controller.loadReport();
      expect(controller.state.status, ReportStatus.loading);

      // Second loadReport (gen=2) — completes fast
      await controller.loadReport();
      expect(controller.state.status, ReportStatus.loaded);

      // Complete stale first load with error (gen=1 < current gen=2)
      slowTrendCompleter.complete(_emptyTrend);
      await future1;

      // State must remain loaded — stale first load was discarded
      expect(controller.state.status, ReportStatus.loaded);
      controller.dispose();
    });

    test('concurrent loadReport calls: only latest result is applied',
        () async {
      final completer1 = Completer<DataState<ReportPeriodSummaryModel>>();
      final completer2 = Completer<DataState<ReportPeriodSummaryModel>>();
      var summaryCallCount = 0;

      when(
        () => repo.getPeriodSummary(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          walletId: any(named: 'walletId'),
        ),
      ).thenAnswer((_) {
        summaryCallCount++;
        // Calls 1 & 2 = first loadReport (current+prev period)
        if (summaryCallCount <= 2) return completer1.future;
        // Calls 3 & 4 = second loadReport
        return completer2.future;
      });

      when(
        () => repo.getCategoryBreakdown(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          walletId: any(named: 'walletId'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => _emptyBreakdown);

      when(
        () => repo.getDailyTrend(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          walletId: any(named: 'walletId'),
        ),
      ).thenAnswer((_) async => _emptyTrend);

      final controller = ReportController(repo);

      // First load (gen=1) — all summary calls blocked
      final future1 = controller.loadReport();

      // Second load (gen=2) — its summary calls are also blocked
      final future2 = controller.loadReport();

      // Complete second load's summary first (fresh)
      completer2.complete(_emptySummary);
      await future2;
      expect(controller.state.status, ReportStatus.loaded);

      // Complete first load's summary (stale gen=1)
      completer1.complete(_summaryError);
      await future1;

      // Error from stale first load must NOT overwrite loaded state
      expect(controller.state.status, ReportStatus.loaded);
      controller.dispose();
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Debounce — rapid period/subperiod switches coalesce into one request
  // ═══════════════════════════════════════════════════════════════════════════

  group('debounce — rapid switching coalesces', () {
    test('rapid setSubPeriod calls result in exactly one set of repo calls',
        () {
      fakeAsync((async) {
        var trendCallCount = 0;
        _stubAll(repo);
        // Override getDailyTrend to count calls
        when(
          () => repo.getDailyTrend(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            walletId: any(named: 'walletId'),
          ),
        ).thenAnswer((_) async {
          trendCallCount++;
          return _emptyTrend;
        });

        final controller = ReportController(repo);

        // Rapid sub-period switching
        controller.setSubPeriod(0);
        controller.setSubPeriod(1);
        controller.setSubPeriod(2);
        controller.setSubPeriod(3);

        // Loading should be set immediately
        expect(controller.state.status, ReportStatus.loading);
        // No repo calls yet
        expect(trendCallCount, 0);

        // Advance past debounce window
        async.elapse(const Duration(milliseconds: 400));
        async.flushMicrotasks();

        // Only ONE getDailyTrend call — rapid switches were coalesced
        expect(trendCallCount, 1);
        expect(controller.state.status, ReportStatus.loaded);
        controller.dispose();
      });
    });

    test('rapid setPeriod changes result in exactly one set of repo calls', () {
      fakeAsync((async) {
        var trendCallCount = 0;
        _stubAll(repo);
        when(
          () => repo.getDailyTrend(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            walletId: any(named: 'walletId'),
          ),
        ).thenAnswer((_) async {
          trendCallCount++;
          return _emptyTrend;
        });

        final controller = ReportController(repo);

        // Rapid period changes
        controller.setPeriod(AppPeriod.yearly);
        controller.setPeriod(AppPeriod.weekly);
        controller.setPeriod(AppPeriod.daily);
        controller.setPeriod(AppPeriod.monthly);

        expect(controller.state.status, ReportStatus.loading);
        expect(trendCallCount, 0);

        async.elapse(const Duration(milliseconds: 400));
        async.flushMicrotasks();

        expect(trendCallCount, 1);
        controller.dispose();
      });
    });

    test('loadReport() cancels a pending debounce timer', () {
      fakeAsync((async) {
        var trendCallCount = 0;
        _stubAll(repo);
        when(
          () => repo.getDailyTrend(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            walletId: any(named: 'walletId'),
          ),
        ).thenAnswer((_) async {
          trendCallCount++;
          return _emptyTrend;
        });

        final controller = ReportController(repo);

        // Start debounce via setSubPeriod
        controller.setSubPeriod(0);
        expect(trendCallCount, 0); // timer pending

        // Immediate loadReport cancels debounce
        controller.loadReport();
        async.flushMicrotasks();

        async.elapse(const Duration(milliseconds: 500));
        async.flushMicrotasks();

        // Only 1 call (from immediate loadReport, not debounce)
        expect(trendCallCount, 1);
        controller.dispose();
      });
    });

    test('debounce does not fire after dispose', () {
      fakeAsync((async) {
        _stubAll(repo);
        final controller = ReportController(repo);

        controller.setSubPeriod(0);
        controller.dispose(); // dispose before timer fires

        async.elapse(const Duration(milliseconds: 400));
        async.flushMicrotasks();

        verifyNever(
          () => repo.getDailyTrend(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            walletId: any(named: 'walletId'),
          ),
        );
      });
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // _reloadCategoryOnly — staleness guard (tested via setBreakdownType)
  // ═══════════════════════════════════════════════════════════════════════════

  group('_reloadCategoryOnly — staleness guard', () {
    test(
        'rapid expense↔income toggle: stale category result is discarded',
        () async {
      // Initial load
      _stubAll(repo);
      final controller = ReportController(repo);
      await controller.loadReport();
      expect(controller.state.status, ReportStatus.loaded);

      // Prepare: first getCategoryBreakdown call is slow
      final slowBreakdownCompleter =
          Completer<DataState<List<ReportCategoryBreakdownModel>>>();
      var breakdownCallCount = 0;

      when(
        () => repo.getCategoryBreakdown(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          walletId: any(named: 'walletId'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) {
        breakdownCallCount++;
        if (breakdownCallCount == 1) return slowBreakdownCompleter.future;
        return Future.value(_emptyBreakdown);
      });

      // First toggle: expense → income (gen N+1), stays in flight
      final firstToggleFuture =
          controller.setBreakdownType(ReportBreakdownType.income);
      expect(controller.state.isCategoryLoading, isTrue);

      // Second toggle before first completes: income → expense (gen N+2)
      await controller.setBreakdownType(ReportBreakdownType.expense);
      // Second toggle completed with empty breakdown
      expect(controller.state.isCategoryLoading, isFalse);

      // Complete stale first toggle
      slowBreakdownCompleter.complete(_emptyBreakdown);
      await firstToggleFuture;

      // isCategoryLoading must still be false — stale result was discarded
      expect(controller.state.isCategoryLoading, isFalse);
      controller.dispose();
    });

    test('setBreakdownType no-op when same type is set again', () async {
      _stubAll(repo);
      final controller = ReportController(repo);
      await controller.loadReport();

      var extraCallCount = 0;
      when(
        () => repo.getCategoryBreakdown(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          walletId: any(named: 'walletId'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async {
        extraCallCount++;
        return _emptyBreakdown;
      });

      // Set same type again (expense → expense) — should be a no-op
      await controller.setBreakdownType(ReportBreakdownType.expense);

      expect(extraCallCount, 0);
      controller.dispose();
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Immediate-load actions (no debounce)
  // ═══════════════════════════════════════════════════════════════════════════

  group('immediate-load actions — no debounce', () {
    test('setWalletFilter fires loadReport without debounce delay', () async {
      _stubAll(repo);
      final controller = ReportController(repo);

      await controller.setWalletFilter('wallet-1');

      expect(controller.state.status, ReportStatus.loaded);
      expect(controller.state.walletId, 'wallet-1');

      // Verify at least one trend call was made (confirms load ran)
      verify(
        () => repo.getDailyTrend(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          walletId: any(named: 'walletId'),
        ),
      ).called(1);
      controller.dispose();
    });

    test('setCustomRange fires loadReport without debounce delay', () async {
      _stubAll(repo);
      final controller = ReportController(repo);

      await controller.setCustomRange(
        DateTime(2025, 1, 1),
        DateTime(2025, 1, 31),
      );

      expect(controller.state.status, ReportStatus.loaded);
      expect(controller.state.period, AppPeriod.custom);

      verify(
        () => repo.getDailyTrend(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          walletId: any(named: 'walletId'),
        ),
      ).called(1);
      controller.dispose();
    });

    test('setPeriod updates state period', () {
      fakeAsync((async) {
        _stubAll(repo);
        final controller = ReportController(repo);

        controller.setPeriod(AppPeriod.yearly);
        expect(controller.state.period, AppPeriod.yearly);

        async.elapse(const Duration(milliseconds: 400));
        async.flushMicrotasks();

        expect(controller.state.status, ReportStatus.loaded);
        controller.dispose();
      });
    });

    test('setPeriod is no-op when same period is set again', () {
      fakeAsync((async) {
        _stubAll(repo);
        final controller = ReportController(repo);

        // Default period is monthly — setting it again should be no-op
        controller.setPeriod(AppPeriod.monthly);

        async.elapse(const Duration(milliseconds: 400));
        async.flushMicrotasks();

        // No repo calls
        verifyNever(
          () => repo.getDailyTrend(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            walletId: any(named: 'walletId'),
          ),
        );
        controller.dispose();
      });
    });
  });
}
