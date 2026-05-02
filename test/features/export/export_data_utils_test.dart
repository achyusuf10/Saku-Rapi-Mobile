import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/features/export/utils/export_data_utils.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExportDataUtils', () {
    test('expenseTotalsByCategory sums item amounts', () {
      final t = TransactionModel(
        id: '1',
        userId: 'u',
        walletId: 'w',
        type: TransactionTypeEnum.expense,
        totalAmount: 150,
        date: DateTime(2026, 4, 1),
        isMultiItem: true,
        items: const [
          TransactionItemModel(
            amount: 100,
            sortOrder: 0,
            categoryName: 'Makan',
          ),
          TransactionItemModel(
            amount: 50,
            sortOrder: 1,
            categoryName: 'Transport',
          ),
        ],
      );

      final map = ExportDataUtils.expenseTotalsByCategory([t]);
      expect(map['Makan'], 100);
      expect(map['Transport'], 50);
    });

    test('dailyIncomeExpense splits by day', () {
      final income = TransactionModel(
        id: '1',
        userId: 'u',
        walletId: 'w',
        type: TransactionTypeEnum.income,
        totalAmount: 1000,
        date: DateTime(2026, 4, 2, 10),
        isMultiItem: false,
        items: const [
          TransactionItemModel(amount: 1000, sortOrder: 0),
        ],
      );
      final expense = TransactionModel(
        id: '2',
        userId: 'u',
        walletId: 'w',
        type: TransactionTypeEnum.expense,
        totalAmount: 300,
        date: DateTime(2026, 4, 2, 15),
        isMultiItem: false,
        items: const [
          TransactionItemModel(amount: 300, sortOrder: 0),
        ],
      );

      final daily = ExportDataUtils.dailyIncomeExpense([income, expense]);
      final day = DateTime(2026, 4, 2);
      expect(daily[day]?.income, 1000);
      expect(daily[day]?.expense, 300);
    });

    test('combinedCategoryNames preserves item order and uniqueness', () {
      final t = TransactionModel(
        id: '1',
        userId: 'u',
        walletId: 'w',
        type: TransactionTypeEnum.expense,
        totalAmount: 30,
        date: DateTime(2026, 4, 1),
        isMultiItem: true,
        items: const [
          TransactionItemModel(
            amount: 10,
            sortOrder: 1,
            categoryName: 'B',
          ),
          TransactionItemModel(
            amount: 10,
            sortOrder: 0,
            categoryName: 'A',
          ),
          TransactionItemModel(
            amount: 10,
            sortOrder: 2,
            categoryName: 'A',
          ),
        ],
      );

      expect(ExportDataUtils.combinedCategoryNames(t), 'A; B');
    });
  });
}
