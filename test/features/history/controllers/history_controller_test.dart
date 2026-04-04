import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/features/history/controllers/history_controller.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Helpers ───

TransactionModel _txn({
  String id = 'txn-1',
  TransactionTypeEnum type = TransactionTypeEnum.expense,
  double totalAmount = 50000,
  String? categoryName,
  String? categoryIcon,
  DateTime? date,
  String? walletName = 'Mandiri',
}) => TransactionModel(
  id: id,
  userId: 'u1',
  walletId: 'w1',
  type: type,
  totalAmount: totalAmount,
  date: date ?? DateTime(2025, 3, 15),
  isMultiItem: false,
  items: [
    TransactionItemModel(
      amount: totalAmount,
      categoryId: 'cat-1',
      qty: 1,
      sortOrder: 0,
    ),
  ],
  categoryName: categoryName,
  categoryIcon: categoryIcon,
  walletName: walletName,
);

void main() {
  group('HistoryState', () {
    group('dateRange', () {
      test('monthly period returns correct boundaries', () {
        const state = HistoryState(period: HistoryPeriod.monthly);
        final (start, end) = state.dateRange;
        final now = DateTime.now();

        expect(start.year, now.year);
        expect(start.month, now.month);
        expect(start.day, 1);
        expect(end.month == now.month || end.month == now.month + 1, isTrue);
        expect(end.hour, 23);
        expect(end.minute, 59);
        expect(end.second, 59);
      });

      test('daily period returns today boundaries', () {
        const state = HistoryState(period: HistoryPeriod.daily);
        final (start, end) = state.dateRange;
        final now = DateTime.now();

        expect(start.year, now.year);
        expect(start.month, now.month);
        expect(start.day, now.day);
        expect(end.day, now.day);
        expect(end.hour, 23);
      });

      test('custom period uses customStart/customEnd', () {
        final state = HistoryState(
          period: HistoryPeriod.custom,
          customStart: DateTime(2025, 1, 1),
          customEnd: DateTime(2025, 1, 31),
        );
        final (start, end) = state.dateRange;

        expect(start.year, 2025);
        expect(start.month, 1);
        expect(start.day, 1);
        expect(end.year, 2025);
        expect(end.month, 1);
        expect(end.day, 31);
        expect(end.hour, 23);
      });

      test('yearly period returns full year', () {
        const state = HistoryState(period: HistoryPeriod.yearly);
        final (start, end) = state.dateRange;
        final now = DateTime.now();

        expect(start.month, 1);
        expect(start.day, 1);
        expect(end.month, 12);
        expect(end.day, 31);
        expect(start.year, now.year);
      });
    });

    group('filteredTransactions', () {
      test('returns all when typeFilter is null', () {
        final state = HistoryState(
          transactions: [
            _txn(id: '1', type: TransactionTypeEnum.income),
            _txn(id: '2', type: TransactionTypeEnum.expense),
          ],
        );

        expect(state.filteredTransactions.length, 2);
      });

      test('filters by type when typeFilter is set', () {
        final state = HistoryState(
          typeFilter: TransactionTypeEnum.expense,
          transactions: [
            _txn(id: '1', type: TransactionTypeEnum.income),
            _txn(id: '2', type: TransactionTypeEnum.expense),
            _txn(id: '3', type: TransactionTypeEnum.expense),
          ],
        );

        expect(state.filteredTransactions.length, 2);
        expect(
          state.filteredTransactions.every(
            (t) => t.type == TransactionTypeEnum.expense,
          ),
          isTrue,
        );
      });
    });

    group('groupedByDate', () {
      test('groups transactions by date key', () {
        final state = HistoryState(
          transactions: [
            _txn(id: '1', date: DateTime(2025, 3, 15)),
            _txn(id: '2', date: DateTime(2025, 3, 15)),
            _txn(id: '3', date: DateTime(2025, 3, 16)),
          ],
        );

        final groups = state.groupedByDate;
        expect(groups.length, 2);
        expect(groups['2025-03-15']?.length, 2);
        expect(groups['2025-03-16']?.length, 1);
      });
    });

    group('groupedByCategory', () {
      test('groups transactions by category name', () {
        final state = HistoryState(
          transactions: [
            _txn(id: '1', categoryName: 'Makan'),
            _txn(id: '2', categoryName: 'Makan'),
            _txn(id: '3', categoryName: 'Transport'),
          ],
        );

        final groups = state.groupedByCategory;
        expect(groups.length, 2);
        expect(groups['Makan']?.length, 2);
        expect(groups['Transport']?.length, 1);
      });

      test('falls back to type when categoryName is null', () {
        final state = HistoryState(
          transactions: [
            _txn(
              id: '1',
              type: TransactionTypeEnum.transfer,
              categoryName: null,
            ),
          ],
        );

        final groups = state.groupedByCategory;
        expect(groups.containsKey('transfer'), isTrue);
      });
    });

    group('totals', () {
      test('totalIncome sums only income transactions', () {
        final state = HistoryState(
          transactions: [
            _txn(
              id: '1',
              type: TransactionTypeEnum.income,
              totalAmount: 100000,
            ),
            _txn(id: '2', type: TransactionTypeEnum.income, totalAmount: 50000),
            _txn(
              id: '3',
              type: TransactionTypeEnum.expense,
              totalAmount: 30000,
            ),
          ],
        );

        expect(state.totalIncome, 150000);
      });

      test('totalExpense sums only expense transactions', () {
        final state = HistoryState(
          transactions: [
            _txn(
              id: '1',
              type: TransactionTypeEnum.expense,
              totalAmount: 30000,
            ),
            _txn(
              id: '2',
              type: TransactionTypeEnum.expense,
              totalAmount: 20000,
            ),
            _txn(
              id: '3',
              type: TransactionTypeEnum.income,
              totalAmount: 100000,
            ),
          ],
        );

        expect(state.totalExpense, 50000);
      });
    });

    group('copyWith', () {
      test('clears wallet when clearWallet is true', () {
        final state = HistoryState(walletId: 'w1');
        final newState = state.copyWith(clearWallet: true);

        expect(newState.walletId, isNull);
      });

      test('clears typeFilter when clearType is true', () {
        final state = HistoryState(typeFilter: TransactionTypeEnum.expense);
        final newState = state.copyWith(clearType: true);

        expect(newState.typeFilter, isNull);
      });

      test('preserves other values on partial update', () {
        final state = HistoryState(
          status: HistoryStatus.loaded,
          period: HistoryPeriod.weekly,
          walletId: 'w1',
        );
        final newState = state.copyWith(period: HistoryPeriod.monthly);

        expect(newState.status, HistoryStatus.loaded);
        expect(newState.period, HistoryPeriod.monthly);
        expect(newState.walletId, 'w1');
      });
    });
  });
}
