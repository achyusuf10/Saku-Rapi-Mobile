import 'dart:async';

import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/history/controllers/history_controller.dart';
import 'package:app_saku_rapi/features/history/datasource/history_local_data_source.dart';
import 'package:app_saku_rapi/features/history/models/history_models.dart';
import 'package:app_saku_rapi/features/history/repositories/history_repository.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

class _MockHistoryRepository extends Mock implements HistoryRepository {}

class _MockHistoryLocalDataSource extends Mock
    implements HistoryLocalDataSource {}

// ─── Data helpers ─────────────────────────────────────────────────────────────

final _successEmpty = DataState<HistoryResult>.success(
  data: const HistoryResult(transactions: [], hasMore: false),
);

final _successHasMore = DataState<HistoryResult>.success(
  data: const HistoryResult(transactions: [], hasMore: true),
);

final _errorResult =
    DataState<HistoryResult>.error(message: 'Network error');

TransactionModel _makeTxn(String id) => TransactionModel(
  id: id,
  userId: 'u1',
  walletId: 'w1',
  type: TransactionTypeEnum.expense,
  totalAmount: 50000.0,
  date: DateTime(2025, 3, 15),
  isMultiItem: false,
  items: const [],
);

// ─── Setup helpers ─────────────────────────────────────────────────────────────

/// Stubs repository so every call immediately returns [result].
void _stubRepo(_MockHistoryRepository repo, DataState<HistoryResult> result) {
  when(
    () => repo.getTransactions(
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
      walletId: any(named: 'walletId'),
      search: any(named: 'search'),
      groupMode: any(named: 'groupMode'),
      limit: any(named: 'limit'),
      offset: any(named: 'offset'),
    ),
  ).thenAnswer((_) async => result);
}

/// Creates a [HistoryController] with mocked dependencies.
HistoryController _makeController(
  _MockHistoryRepository repo,
  _MockHistoryLocalDataSource local,
) {
  when(() => local.loadFilterPrefs()).thenReturn(null);
  when(
    () => local.saveFilterPrefs(
      period: any(named: 'period'),
      groupMode: any(named: 'groupMode'),
      walletId: any(named: 'walletId'),
      typeFilter: any(named: 'typeFilter'),
      searchKeyword: any(named: 'searchKeyword'),
      subPeriodIndex: any(named: 'subPeriodIndex'),
      customStart: any(named: 'customStart'),
      customEnd: any(named: 'customEnd'),
    ),
  ).thenReturn(null);
  return HistoryController(repo, local);
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late _MockHistoryRepository repo;
  late _MockHistoryLocalDataSource local;

  setUpAll(() async {
    // Required by mocktail for any(named: ...) on custom types
    registerFallbackValue(HistoryPeriod.monthly);
    registerFallbackValue(HistoryGroupMode.byDate);
    registerFallbackValue(TransactionTypeEnum.expense);
    registerFallbackValue(DateTime.now());
    // Initialize 'id' locale data — needed by DateFormat in subPeriodTabs getter
    await initializeDateFormatting('id', null);
  });

  setUp(() {
    repo = _MockHistoryRepository();
    local = _MockHistoryLocalDataSource();
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Basic load paths
  // ═══════════════════════════════════════════════════════════════════════════

  group('loadTransactions — basic paths', () {
    test('initial state is HistoryStatus.initial', () {
      _stubRepo(repo, _successEmpty);
      final controller = _makeController(repo, local);
      expect(controller.state.status, HistoryStatus.initial);
      controller.dispose();
    });

    test('sets status to loaded on success', () async {
      _stubRepo(repo, _successEmpty);
      final controller = _makeController(repo, local);

      await controller.loadTransactions();

      expect(controller.state.status, HistoryStatus.loaded);
      expect(controller.state.transactions, isEmpty);
      expect(controller.state.hasMore, isFalse);
      controller.dispose();
    });

    test('sets status to error on failure', () async {
      _stubRepo(repo, _errorResult);
      final controller = _makeController(repo, local);

      await controller.loadTransactions();

      expect(controller.state.status, HistoryStatus.error);
      expect(controller.state.errorMessage, 'Network error');
      controller.dispose();
    });

    test('resets offset to pageSize on each call', () async {
      _stubRepo(repo, _successEmpty);
      final controller = _makeController(repo, local);

      await controller.loadTransactions();
      expect(controller.state.offset, 30);

      await controller.loadTransactions();
      expect(controller.state.offset, 30); // still 30, not doubled
      controller.dispose();
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Generation counter — stale responses are discarded
  // ═══════════════════════════════════════════════════════════════════════════

  group('generation counter — stale responses discarded', () {
    test(
        'stale first load (slow) is discarded when second load fires and '
        'completes first', () async {
      final completer1 = Completer<DataState<HistoryResult>>();
      final completer2 = Completer<DataState<HistoryResult>>();

      var callCount = 0;
      when(
        () => repo.getTransactions(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          walletId: any(named: 'walletId'),
          search: any(named: 'search'),
          groupMode: any(named: 'groupMode'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) {
        callCount++;
        return callCount == 1 ? completer1.future : completer2.future;
      });

      final controller = _makeController(repo, local);

      // First load (gen=1) — stays in flight
      final future1 = controller.loadTransactions();
      expect(controller.state.status, HistoryStatus.loading);

      // Second load (gen=2) — supersedes first
      final future2 = controller.loadTransactions();

      // Complete stale request first (gen=1 < current gen=2)
      completer1.complete(_errorResult);
      await future1;

      // Error from stale load must NOT be applied — still loading
      expect(controller.state.status, HistoryStatus.loading);

      // Complete fresh request (gen=2 == current gen=2)
      completer2.complete(_successEmpty);
      await future2;

      expect(controller.state.status, HistoryStatus.loaded);
      controller.dispose();
    });

    test('in-flight load is discarded when loadTransactions fires again',
        () async {
      final slowCompleter = Completer<DataState<HistoryResult>>();
      var callCount = 0;

      when(
        () => repo.getTransactions(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          walletId: any(named: 'walletId'),
          search: any(named: 'search'),
          groupMode: any(named: 'groupMode'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) {
        callCount++;
        if (callCount == 1) return slowCompleter.future; // first: slow
        return Future.value(_successEmpty); // second: fast
      });

      final controller = _makeController(repo, local);

      // Start slow first load (gen=1)
      final slowFuture = controller.loadTransactions();

      // Fire a second fast load (gen=2) and let it complete
      await controller.loadTransactions();
      expect(controller.state.status, HistoryStatus.loaded);

      // Complete slow first load with an error (stale gen=1)
      slowCompleter.complete(_errorResult);
      await slowFuture;

      // Error from stale load must not overwrite the loaded state
      expect(controller.state.status, HistoryStatus.loaded);
      controller.dispose();
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Debounce — rapid switches coalesce into one request
  // ═══════════════════════════════════════════════════════════════════════════

  group('debounce — rapid switching coalesces', () {
    test('rapid setSubPeriod calls result in exactly one repo call', () {
      fakeAsync((async) {
        var callCount = 0;
        when(
          () => repo.getTransactions(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            walletId: any(named: 'walletId'),
            search: any(named: 'search'),
            groupMode: any(named: 'groupMode'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          return _successEmpty;
        });

        final controller = _makeController(repo, local);

        // Fire rapid sub-period switches
        controller.setSubPeriod(0);
        controller.setSubPeriod(1);
        controller.setSubPeriod(2);
        controller.setSubPeriod(3);

        // UI should show loading immediately (before debounce fires)
        expect(controller.state.status, HistoryStatus.loading);
        // Repo must NOT have been called yet
        expect(callCount, 0);

        // Advance past debounce window and drain async operations
        async.elapse(const Duration(milliseconds: 400));
        async.flushMicrotasks();

        // Only ONE repo call — all rapid switches were coalesced
        expect(callCount, 1);
        expect(controller.state.status, HistoryStatus.loaded);
        controller.dispose();
      });
    });

    test('rapid setPeriod changes result in exactly one repo call', () {
      fakeAsync((async) {
        var callCount = 0;
        when(
          () => repo.getTransactions(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            walletId: any(named: 'walletId'),
            search: any(named: 'search'),
            groupMode: any(named: 'groupMode'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          return _successEmpty;
        });

        final controller = _makeController(repo, local);

        // Each setPeriod cancels the previous debounce and starts a new one
        controller.setPeriod(HistoryPeriod.yearly);
        controller.setPeriod(HistoryPeriod.weekly);
        controller.setPeriod(HistoryPeriod.daily);
        controller.setPeriod(HistoryPeriod.monthly);

        expect(controller.state.status, HistoryStatus.loading);
        expect(callCount, 0);

        async.elapse(const Duration(milliseconds: 400));
        async.flushMicrotasks();

        expect(callCount, 1);
        controller.dispose();
      });
    });

    test('loadTransactions() cancels a pending debounce timer', () {
      fakeAsync((async) {
        var callCount = 0;
        when(
          () => repo.getTransactions(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            walletId: any(named: 'walletId'),
            search: any(named: 'search'),
            groupMode: any(named: 'groupMode'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          return _successEmpty;
        });

        final controller = _makeController(repo, local);

        // Start debounce via setSubPeriod
        controller.setSubPeriod(0);
        expect(callCount, 0); // debounce pending, no call yet

        // Immediate loadTransactions should cancel debounce
        controller.loadTransactions();
        async.flushMicrotasks(); // let immediate load's future resolve

        // Advance well past debounce window
        async.elapse(const Duration(milliseconds: 500));
        async.flushMicrotasks();

        // Only 1 call: from loadTransactions, debounce was cancelled
        expect(callCount, 1);
        controller.dispose();
      });
    });

    test('debounce does not fire after dispose — no exceptions', () {
      fakeAsync((async) {
        _stubRepo(repo, _successEmpty);
        final controller = _makeController(repo, local);

        controller.setSubPeriod(0);
        controller.dispose(); // dispose before debounce timer fires

        // Should not throw or make any repo calls
        async.elapse(const Duration(milliseconds: 400));
        async.flushMicrotasks();

        verifyNever(
          () => repo.getTransactions(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            walletId: any(named: 'walletId'),
            search: any(named: 'search'),
            groupMode: any(named: 'groupMode'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        );
      });
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // loadMore — staleness guard
  // ═══════════════════════════════════════════════════════════════════════════

  group('loadMore — staleness guard', () {
    test('stale loadMore result is discarded when period changes mid-flight',
        () async {
      // Initial load with hasMore=true
      _stubRepo(repo, _successHasMore);
      final controller = _makeController(repo, local);
      await controller.loadTransactions();

      expect(controller.state.hasMore, isTrue);

      // Prepare: loadMore returns slow future, subsequent calls return fast
      final loadMoreCompleter = Completer<DataState<HistoryResult>>();
      var callCount = 0;
      when(
        () => repo.getTransactions(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          walletId: any(named: 'walletId'),
          search: any(named: 'search'),
          groupMode: any(named: 'groupMode'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) {
        callCount++;
        if (callCount == 1) return loadMoreCompleter.future; // slow loadMore
        return Future.value(_successEmpty); // fast loadTransactions
      });

      // Start loadMore in flight
      final loadMoreFuture = controller.loadMore();
      expect(controller.state.isLoadingMore, isTrue);

      // Period changes while loadMore is in flight — increments generation
      await controller.loadTransactions();
      // Note: isLoadingMore is NOT cleared by loadTransactions (only by loadMore completing)
      // The key invariant: hasMore reflects the new load's result
      expect(controller.state.hasMore, isFalse); // new result has hasMore=false

      // Complete stale loadMore with hasMore=true — should be ignored
      loadMoreCompleter.complete(_successHasMore);
      await loadMoreFuture;

      // stale result must NOT override the new state's hasMore=false
      expect(controller.state.hasMore, isFalse);
      expect(controller.state.isLoadingMore, isFalse);
      controller.dispose();
    });

    test('loadMore is no-op when hasMore is false', () async {
      _stubRepo(repo, _successEmpty); // hasMore=false
      final controller = _makeController(repo, local);
      await controller.loadTransactions();

      expect(controller.state.hasMore, isFalse);

      // Clear interaction counts from initial load
      clearInteractions(repo);

      // loadMore should be a no-op — no repo call
      await controller.loadMore();

      verifyNever(
        () => repo.getTransactions(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          walletId: any(named: 'walletId'),
          search: any(named: 'search'),
          groupMode: any(named: 'groupMode'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      );
      controller.dispose();
    });

    test('loadMore is no-op when isLoadingMore is already true', () async {
      _stubRepo(repo, _successHasMore);
      final controller = _makeController(repo, local);
      await controller.loadTransactions();

      final loadMoreCompleter = Completer<DataState<HistoryResult>>();
      var loadMoreCallCount = 0;
      when(
        () => repo.getTransactions(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          walletId: any(named: 'walletId'),
          search: any(named: 'search'),
          groupMode: any(named: 'groupMode'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) {
        loadMoreCallCount++;
        return loadMoreCompleter.future;
      });

      // First loadMore starts — save future to await later
      final firstLoadMoreFuture = controller.loadMore();
      expect(controller.state.isLoadingMore, isTrue);

      // Second loadMore while first is in-flight — should be a no-op
      await controller.loadMore();
      expect(loadMoreCallCount, 1); // only one repo call

      // Complete first loadMore cleanly so its state update runs before dispose
      loadMoreCompleter.complete(_successEmpty);
      await firstLoadMoreFuture;
      controller.dispose();
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Immediate-load actions (no debounce)
  // ═══════════════════════════════════════════════════════════════════════════

  group('immediate-load actions — no debounce', () {
    test('setWalletFilter fires loadTransactions without debounce delay',
        () async {
      _stubRepo(repo, _successEmpty);
      final controller = _makeController(repo, local);

      await controller.setWalletFilter('wallet-1');
      expect(controller.state.status, HistoryStatus.loaded);
      expect(controller.state.walletId, 'wallet-1');

      verify(
        () => repo.getTransactions(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          walletId: any(named: 'walletId'),
          search: any(named: 'search'),
          groupMode: any(named: 'groupMode'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).called(1);
      controller.dispose();
    });

    test('setCustomRange fires loadTransactions without debounce delay',
        () async {
      _stubRepo(repo, _successEmpty);
      final controller = _makeController(repo, local);

      await controller.setCustomRange(
        DateTime(2025, 1, 1),
        DateTime(2025, 1, 31),
      );

      expect(controller.state.status, HistoryStatus.loaded);
      expect(controller.state.period, HistoryPeriod.custom);

      verify(
        () => repo.getTransactions(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          walletId: any(named: 'walletId'),
          search: any(named: 'search'),
          groupMode: any(named: 'groupMode'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).called(1);
      controller.dispose();
    });

    test('refresh fires loadTransactions without debounce delay', () async {
      _stubRepo(repo, _successEmpty);
      final controller = _makeController(repo, local);

      await controller.refresh();

      verify(
        () => repo.getTransactions(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          walletId: any(named: 'walletId'),
          search: any(named: 'search'),
          groupMode: any(named: 'groupMode'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).called(1);
      controller.dispose();
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // removeTransaction — local mutation without refetch
  // ═══════════════════════════════════════════════════════════════════════════

  group('removeTransaction', () {
    test('removes transaction from list without making a repo call', () async {
      _stubRepo(
        repo,
        DataState.success(
          data: HistoryResult(
            transactions: [
              _makeTxn('txn-1'),
              _makeTxn('txn-2'),
              _makeTxn('txn-3'),
            ],
            hasMore: false,
          ),
        ),
      );

      final controller = _makeController(repo, local);
      await controller.loadTransactions();
      expect(controller.state.transactions, hasLength(3));

      clearInteractions(repo); // reset call counter

      controller.removeTransaction('txn-2');

      expect(controller.state.transactions, hasLength(2));
      expect(
        controller.state.transactions.map((t) => t.id).toList(),
        containsAll(['txn-1', 'txn-3']),
      );

      // No additional repo calls for a local removal
      verifyNever(
        () => repo.getTransactions(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          walletId: any(named: 'walletId'),
          search: any(named: 'search'),
          groupMode: any(named: 'groupMode'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      );
      controller.dispose();
    });

    test('removeTransaction is a no-op for unknown id', () async {
      _stubRepo(
        repo,
        DataState.success(
          data: HistoryResult(
            transactions: [_makeTxn('txn-1')],
            hasMore: false,
          ),
        ),
      );

      final controller = _makeController(repo, local);
      await controller.loadTransactions();

      controller.removeTransaction('does-not-exist');

      expect(controller.state.transactions, hasLength(1));
      controller.dispose();
    });
  });
}
