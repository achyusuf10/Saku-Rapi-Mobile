import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_multi_manual_coordinator.dart';
import 'package:app_saku_rapi/features/transaction/models/manual_transaction_entry_model.dart';
import 'package:app_saku_rapi/features/transaction/utils/manual_multi_batch_limits.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/features/transaction/datasource/transaction_remote_data_source.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/transaction/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

// ─── Helpers ───

TransactionItemModel _item({
  double amount = 0,
  double qty = 1,
  double? unitPrice,
  String? categoryId,
  String? itemName,
  int sortOrder = 0,
}) => TransactionItemModel(
  amount: amount,
  qty: qty,
  unitPrice: unitPrice,
  categoryId: categoryId,
  itemName: itemName,
  sortOrder: sortOrder,
);

void main() {
  // ══════════════════════════════════════════════════
  // TransactionFormState computed properties
  // ══════════════════════════════════════════════════

  group('TransactionFormState', () {
    test('isMultiItem is true when items > 1', () {
      final state = TransactionFormState(
        items: [_item(amount: 100), _item(amount: 200)],
      );
      expect(state.isMultiItem, isTrue);
    });

    test('isMultiItem is false with single item', () {
      final state = TransactionFormState(items: [_item(amount: 100)]);
      expect(state.isMultiItem, isFalse);
    });

    test('isMultiItem is false with empty items', () {
      const state = TransactionFormState();
      expect(state.isMultiItem, isFalse);
    });

    test('itemsTotal sums all items', () {
      final state = TransactionFormState(
        items: [
          _item(amount: 25000),
          _item(amount: 35000),
          _item(amount: 15000),
        ],
      );
      expect(state.itemsTotal, 75000.0);
    });

    test('itemsTotal is 0 for empty items', () {
      const state = TransactionFormState();
      expect(state.itemsTotal, 0.0);
    });

    test('isTotalMatched returns true within tolerance', () {
      final state = TransactionFormState(
        totalAmount: 50000,
        items: [_item(amount: 50000.005)],
      );
      expect(state.isTotalMatched, isTrue);
    });

    test('isTotalMatched returns false when mismatch > tolerance', () {
      final state = TransactionFormState(
        totalAmount: 50000,
        items: [_item(amount: 49000)],
      );
      expect(state.isTotalMatched, isFalse);
    });

    test('isTotalMatched exact match', () {
      final state = TransactionFormState(
        totalAmount: 100000,
        items: [_item(amount: 60000), _item(amount: 40000)],
      );
      expect(state.isTotalMatched, isTrue);
    });
  });

  // ══════════════════════════════════════════════════
  // _resolveItemAmount (static helper)
  // ══════════════════════════════════════════════════

  group('TransactionFormController._resolveItemAmount', () {
    test('computes amount from qty * unitPrice', () {
      final item = _item(qty: 3, unitPrice: 15000, amount: 0);
      final resolved = TransactionFormController.resolveItemAmountForTest(item);
      expect(resolved.amount, 45000.0);
    });

    test('keeps original amount when unitPrice is null', () {
      final item = _item(qty: 2, unitPrice: null, amount: 30000);
      final resolved = TransactionFormController.resolveItemAmountForTest(item);
      expect(resolved.amount, 30000.0);
    });

    test('keeps original amount when qty is 0', () {
      final item = _item(qty: 0, unitPrice: 5000, amount: 10000);
      final resolved = TransactionFormController.resolveItemAmountForTest(item);
      expect(resolved.amount, 10000.0);
    });

    test('handles fractional qty', () {
      final item = _item(qty: 1.5, unitPrice: 10000, amount: 0);
      final resolved = TransactionFormController.resolveItemAmountForTest(item);
      expect(resolved.amount, 15000.0);
    });

    test('handles zero unitPrice', () {
      final item = _item(qty: 5, unitPrice: 0, amount: 0);
      final resolved = TransactionFormController.resolveItemAmountForTest(item);
      expect(resolved.amount, 0.0);
    });
  });

  // ══════════════════════════════════════════════════
  // sumItems (static helper)
  // ══════════════════════════════════════════════════

  group('TransactionFormController.sumItems', () {
    test('sums multiple items', () {
      final items = [
        _item(amount: 10000),
        _item(amount: 20000),
        _item(amount: 5000),
      ];
      expect(TransactionFormController.sumItemsForTest(items), 35000.0);
    });

    test('returns 0 for empty list', () {
      expect(TransactionFormController.sumItemsForTest([]), 0.0);
    });

    test('single item returns its amount', () {
      expect(
        TransactionFormController.sumItemsForTest([_item(amount: 99000)]),
        99000.0,
      );
    });
  });

  // ══════════════════════════════════════════════════
  // TransactionFormState.clearFields
  // ══════════════════════════════════════════════════

  group('TransactionFormState.clearFields', () {
    test('clearCategory clears all items categories', () {
      final state = TransactionFormState(
        items: [
          _item(categoryId: 'cat-1', amount: 100),
          _item(categoryId: 'cat-2', amount: 200),
        ],
      );
      final cleared = state.clearFields(clearCategory: true);
      for (final item in cleared.items) {
        expect(item.categoryId, isNull);
      }
    });

    test('clearCategory preserves item amounts', () {
      final state = TransactionFormState(
        items: [_item(categoryId: 'cat-1', amount: 50000)],
      );
      final cleared = state.clearFields(clearCategory: true);
      expect(cleared.items.first.amount, 50000);
    });
  });

  // ══════════════════════════════════════════════════
  // Edge cases
  // ══════════════════════════════════════════════════

  group('Edge cases', () {
    test('empty items list has itemsTotal = 0', () {
      const state = TransactionFormState(items: []);
      expect(state.itemsTotal, 0.0);
    });

    test('single zero-amount item', () {
      final state = TransactionFormState(items: [_item(amount: 0)]);
      expect(state.itemsTotal, 0.0);
      expect(state.isMultiItem, isFalse);
    });

    test('qty * unitPrice with large values', () {
      final item = _item(qty: 100, unitPrice: 999999, amount: 0);
      final resolved = TransactionFormController.resolveItemAmountForTest(item);
      expect(resolved.amount, 99999900.0);
    });

    test('qty decimal precision', () {
      // 2.5 * 10000 = 25000
      final item = _item(qty: 2.5, unitPrice: 10000, amount: 0);
      final resolved = TransactionFormController.resolveItemAmountForTest(item);
      expect(resolved.amount, 25000.0);
    });

    test('total mismatch with multiple items', () {
      final state = TransactionFormState(
        totalAmount: 100000,
        items: [
          _item(amount: 40000),
          _item(amount: 30000),
          // sum = 70000, not 100000
        ],
      );
      expect(state.isTotalMatched, isFalse);
      expect(state.itemsTotal, 70000.0);
    });

    test('items with mixed qty/unitPrice and manual amounts', () {
      // Item 1: has qty + unitPrice → amount computed
      final item1 = _item(qty: 2, unitPrice: 25000, amount: 0);
      final resolved1 = TransactionFormController.resolveItemAmountForTest(
        item1,
      );
      expect(resolved1.amount, 50000.0);

      // Item 2: manual amount, no unitPrice
      final item2 = _item(amount: 30000);
      final resolved2 = TransactionFormController.resolveItemAmountForTest(
        item2,
      );
      expect(resolved2.amount, 30000.0);

      // Total should be 80000
      final total = TransactionFormController.sumItemsForTest([
        resolved1,
        resolved2,
      ]);
      expect(total, 80000.0);
    });
  });

  // ══════════════════════════════════════════════════
  // Reorder logic
  // ══════════════════════════════════════════════════

  group('Reorder logic', () {
    test('reorder items reflects correct new order', () {
      final items = [
        _item(itemName: 'A', amount: 10000),
        _item(itemName: 'B', amount: 20000),
        _item(itemName: 'C', amount: 30000),
      ];

      // Simulate reorder: move index 0 to after index 2
      // ReorderableListView convention: newIndex > oldIndex means newIndex - 1
      final newItems = [...items];
      final item = newItems.removeAt(0);
      final adjustedIndex = 2 > 0 ? 2 - 1 : 2;
      newItems.insert(adjustedIndex, item);

      expect(newItems[0].itemName, 'B');
      expect(newItems[1].itemName, 'A');
      expect(newItems[2].itemName, 'C');
    });

    test('reorder preserves all items', () {
      final items = [
        _item(itemName: 'X', amount: 100),
        _item(itemName: 'Y', amount: 200),
        _item(itemName: 'Z', amount: 300),
      ];

      // Move last to first
      final newItems = [...items];
      final item = newItems.removeAt(2);
      newItems.insert(0, item);

      expect(newItems.length, 3);
      expect(newItems[0].itemName, 'Z');
      expect(newItems[1].itemName, 'X');
      expect(newItems[2].itemName, 'Y');
    });
  });

  // ══════════════════════════════════════════════════
  // TransactionItemModel edge cases
  // ══════════════════════════════════════════════════

  group('TransactionFormController parent category (expense multi-item)', () {
    late TransactionFormController ctrl;

    CategoryModel expenseCat(String id) => CategoryModel(
          id: id,
          userId: 'u1',
          name: 'Makan',
          icon: 'utensils',
          color: '#111111',
          type: CategoryType.expense,
        );

    setUp(() {
      final repo = TransactionRepository(
        remoteDataSource: TransactionRemoteDataSource(
          client: _MockSupabaseClient(),
        ),
      );
      ctrl = TransactionFormController(repository: repo);
      ctrl.setType(TransactionTypeEnum.expense);
      ctrl.addItem();
    });

    test('setCategory applies same category to all items', () {
      final cat = expenseCat('cat-a');
      ctrl.setCategory(cat);
      expect(ctrl.state.category?.id, 'cat-a');
      for (final it in ctrl.state.items) {
        expect(it.categoryId, 'cat-a');
      }
    });

    test('updateItem overwrites per-line category drift with parent', () {
      final cat = expenseCat('cat-parent');
      ctrl.setCategory(cat);
      ctrl.updateItem(
        0,
        ctrl.state.items.first.copyWith(
          categoryId: 'other',
          categoryName: 'X',
        ),
      );
      expect(ctrl.state.items.first.categoryId, 'cat-parent');
    });

    test('addItem seeds new row with parent category when set', () {
      ctrl.setCategory(expenseCat('cat-b'));
      ctrl.addItem();
      expect(ctrl.state.items.length, 2);
      expect(ctrl.state.items.last.categoryId, 'cat-b');
    });
  });

  group('TransactionItemModel', () {
    test('default qty is 1', () {
      const item = TransactionItemModel(amount: 5000);
      expect(item.qty, 1);
    });

    test('default unitPrice is null', () {
      const item = TransactionItemModel(amount: 5000);
      expect(item.unitPrice, isNull);
    });

    test('copyWith preserves unset fields', () {
      final item = _item(
        amount: 10000,
        qty: 3,
        unitPrice: 5000,
        itemName: 'Kopi',
        categoryId: 'cat-1',
      );
      final updated = item.copyWith(amount: 20000);
      expect(updated.qty, 3);
      expect(updated.unitPrice, 5000);
      expect(updated.itemName, 'Kopi');
      expect(updated.categoryId, 'cat-1');
      expect(updated.amount, 20000);
    });

    test('clearCategory preserves amount and qty', () {
      final item = _item(
        amount: 15000,
        qty: 2,
        unitPrice: 7500,
        categoryId: 'cat-1',
      );
      final cleared = item.clearCategory();
      expect(cleared.categoryId, isNull);
      expect(cleared.categoryName, isNull);
      expect(cleared.amount, 15000);
      expect(cleared.qty, 2);
      expect(cleared.unitPrice, 7500);
    });

    test('toRpcMap includes qty and unit_price', () {
      final item = _item(
        amount: 30000,
        qty: 2,
        unitPrice: 15000,
        itemName: 'Nasi Goreng',
        categoryId: 'cat-1',
      );
      final map = item.toRpcMap();
      expect(map['qty'], 2);
      expect(map['unit_price'], 15000);
      expect(map['amount'], 30000);
      expect(map['item_name'], 'Nasi Goreng');
      expect(map['category_id'], 'cat-1');
    });

    test('fromMap parses qty and unit_price', () {
      final map = {
        'id': 'item-1',
        'transaction_id': 'txn-1',
        'category_id': 'cat-1',
        'item_name': 'Es Teh',
        'qty': 3,
        'unit_price': 5000,
        'amount': 15000,
        'note': null,
        'sort_order': 0,
      };
      final item = TransactionItemModel.fromMap(map);
      expect(item.qty, 3);
      expect(item.unitPrice, 5000);
      expect(item.amount, 15000);
      expect(item.itemName, 'Es Teh');
    });
  });

  group('Multi manual setManualMultiEntryTotalAmount', () {
    late TransactionFormController ctrl;

    setUp(() {
      final repo = TransactionRepository(
        remoteDataSource: TransactionRemoteDataSource(
          client: _MockSupabaseClient(),
        ),
      );
      ctrl = TransactionFormController(repository: repo);
      ctrl.setType(TransactionTypeEnum.expense);
      ctrl.initSingleItem();
      ctrl.setMultiManualMode(true);
    });

    test('updates first item amount and total for single-item entry', () {
      expect(ctrl.state.manualMultiEntries, hasLength(1));
      ctrl.setManualMultiEntryTotalAmount(0, 75000);
      final e = ctrl.state.manualMultiEntries.first;
      expect(e.totalAmount, 75000);
      expect(e.items, hasLength(1));
      expect(e.items.single.amount, 75000);
    });

    test('no-op when entry has more than one item', () {
      ctrl.addManualMultiItem(0);
      expect(ctrl.state.manualMultiEntries.first.items, hasLength(2));
      ctrl.setManualMultiEntryTotalAmount(0, 99999);
      final e = ctrl.state.manualMultiEntries.first;
      expect(e.items, hasLength(2));
      expect(e.totalAmount, isNot(99999));
    });

    test('addManualMultiItem marks entry as multi-item (two rows)', () {
      ctrl.setManualMultiEntryTotalAmount(0, 5000);
      expect(ctrl.state.manualMultiEntries.first.isMultiItem, isFalse);
      ctrl.addManualMultiItem(0);
      final e = ctrl.state.manualMultiEntries.first;
      expect(e.isMultiItem, isTrue);
      expect(e.items, hasLength(2));
    });
  });

  group('prefillMultiManualEntries', () {
    late TransactionFormController ctrl;

    setUp(() {
      final repo = TransactionRepository(
        remoteDataSource: TransactionRemoteDataSource(
          client: _MockSupabaseClient(),
        ),
      );
      ctrl = TransactionFormController(repository: repo);
      ctrl.setType(TransactionTypeEnum.expense);
      ctrl.initSingleItem();
    });

    test('enables multi manual and allocates fresh entry and item keys', () {
      final w = const WalletModel(
        id: 'w1',
        userId: 'u1',
        name: 'Dompet',
        icon: 'wallet',
        color: '#111',
        balance: 0,
        initialBalance: 0,
        currency: 'IDR',
        excludeFromTotal: false,
        sortOrder: 0,
      );
      final c = const CategoryModel(
        id: 'c1',
        userId: 'u1',
        name: 'Makan',
        icon: 'utensils',
        color: '#222',
        type: CategoryType.expense,
      );
      ctrl.prefillMultiManualEntries([
        ManualTransactionEntryModel(
          entryKey: 999,
          wallet: w,
          category: c,
          items: [
            _item(amount: 10000, categoryId: 'c1'),
          ],
          itemKeys: const [111],
          totalAmount: 10000,
        ),
        ManualTransactionEntryModel(
          entryKey: 888,
          wallet: w,
          category: c,
          items: [
            _item(amount: 5000, categoryId: 'c1'),
          ],
          itemKeys: const [222],
          totalAmount: 5000,
        ),
      ]);
      expect(ctrl.state.isMultiManualMode, isTrue);
      expect(ctrl.state.manualMultiEntries, hasLength(2));
      expect(ctrl.state.manualMultiEntries.first.entryKey, isNot(999));
      expect(ctrl.state.manualMultiEntries.first.itemKeys, isNot(contains(111)));
      expect(ctrl.state.manualMultiEntries.first.itemKeys, hasLength(1));
      expect(ctrl.state.manualMultiEntries.first.totalAmount, 10000);
      expect(ctrl.state.manualMultiEntries.last.totalAmount, 5000);
    });
  });

  group('TransactionFormMultiManualCoordinator.validateBatch', () {
    WalletModel _wallet() => const WalletModel(
          id: 'w1',
          userId: 'u1',
          name: 'Dompet',
          icon: 'wallet',
          color: '#111',
          balance: 0,
          initialBalance: 0,
          currency: 'IDR',
          excludeFromTotal: false,
          sortOrder: 0,
        );

    CategoryModel _category() => const CategoryModel(
          id: 'c1',
          userId: 'u1',
          name: 'Makan',
          icon: 'utensils',
          color: '#222',
          type: CategoryType.expense,
        );

    test('returns null for one valid expense entry', () {
      final entry = ManualTransactionEntryModel(
        entryKey: 0,
        wallet: _wallet(),
        category: _category(),
        items: [
          _item(amount: 10000, categoryId: 'c1'),
        ],
        itemKeys: const [0],
        totalAmount: 10000,
      );
      final state = TransactionFormState(
        type: TransactionTypeEnum.expense,
        isMultiManualMode: true,
        manualMultiEntries: [entry],
      );
      expect(
        TransactionFormMultiManualCoordinator.validateBatch(
          state,
          TransactionTypeEnum.expense,
        ),
        isNull,
      );
    });

    test('rejects more than max entries', () {
      final many = List.generate(
        kManualMultiBatchMaxTransactions + 1,
        (i) => ManualTransactionEntryModel(
          entryKey: i,
          wallet: _wallet(),
          category: _category(),
          items: [_item(amount: 1, categoryId: 'c1')],
          itemKeys: [i],
          totalAmount: 1,
        ),
      );
      final state = TransactionFormState(
        type: TransactionTypeEnum.expense,
        isMultiManualMode: true,
        manualMultiEntries: many,
      );
      final msg = TransactionFormMultiManualCoordinator.validateBatch(
        state,
        TransactionTypeEnum.expense,
      );
      expect(msg, isNotNull);
      expect(msg, contains('$kManualMultiBatchMaxTransactions'));
    });

    test('returns message when wallet missing', () {
      final entry = ManualTransactionEntryModel(
        entryKey: 0,
        category: _category(),
        items: [_item(amount: 100, categoryId: 'c1')],
        itemKeys: const [0],
        totalAmount: 100,
      );
      final state = TransactionFormState(
        type: TransactionTypeEnum.expense,
        isMultiManualMode: true,
        manualMultiEntries: [entry],
      );
      final msg = TransactionFormMultiManualCoordinator.validateBatch(
        state,
        TransactionTypeEnum.expense,
      );
      expect(msg, isNotNull);
      expect(msg, contains('dompet'));
    });
  });
}
