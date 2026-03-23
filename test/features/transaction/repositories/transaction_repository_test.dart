import 'package:app_saku_rapi/core/enums/settlement_kind_enum.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/features/transaction/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Helpers ───

TransactionItemModel _item({
  String? categoryId = 'cat-1',
  double amount = 50000,
  String? itemName = 'Makan Siang',
}) => TransactionItemModel(
  amount: amount,
  categoryId: categoryId,
  itemName: itemName,
  qty: 1,
  sortOrder: 0,
);

TransactionModel _txn({
  TransactionTypeEnum type = TransactionTypeEnum.expense,
  double totalAmount = 50000,
  String walletId = 'w1',
  String? destinationWalletId,
  String? withPerson,
  List<TransactionItemModel>? items,
}) => TransactionModel(
  id: 'txn-1',
  userId: 'u1',
  walletId: walletId,
  destinationWalletId: destinationWalletId,
  type: type,
  totalAmount: totalAmount,
  date: DateTime(2025, 1, 1),
  isMultiItem: (items?.length ?? 1) > 1,
  withPerson: withPerson,
  items: items ?? [_item(amount: totalAmount)],
);

// ─── validateInput tests ───

void main() {
  group('TransactionRepository.validateInput', () {
    test('returns null for valid expense', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.expense,
        totalAmount: 50000,
        items: [_item()],
      );
      expect(result, isNull);
    });

    test('rejects totalAmount <= 0', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.expense,
        totalAmount: 0,
        items: [_item(amount: 0)],
      );
      expect(result, isNotNull);
      expect(result, contains('Nominal'));
    });

    test('rejects negative totalAmount', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.expense,
        totalAmount: -100,
        items: [_item(amount: -100)],
      );
      expect(result, isNotNull);
      expect(result, contains('Nominal'));
    });

    test('transfer: rejects missing destination wallet', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.transfer,
        totalAmount: 100000,
        items: [_item(amount: 100000)],
      );
      expect(result, isNotNull);
      expect(result, contains('dompet tujuan'));
    });

    test('transfer: rejects empty destinationWalletId', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.transfer,
        totalAmount: 100000,
        items: [_item(amount: 100000)],
        destinationWalletId: '',
      );
      expect(result, isNotNull);
      expect(result, contains('dompet tujuan'));
    });

    test('transfer: rejects same source and destination wallet', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        destinationWalletId: 'w1',
        type: TransactionTypeEnum.transfer,
        totalAmount: 100000,
        items: [_item(amount: 100000)],
      );
      expect(result, isNotNull);
      expect(result, contains('sama'));
    });

    test('transfer: passes with different wallets', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        destinationWalletId: 'w2',
        type: TransactionTypeEnum.transfer,
        totalAmount: 100000,
        items: [_item(amount: 100000)],
      );
      expect(result, isNull);
    });

    test('debt: rejects empty withPerson', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.debt,
        totalAmount: 50000,
        items: [_item(amount: 50000)],
        withPerson: '',
      );
      expect(result, isNotNull);
      expect(result, contains('kontak'));
    });

    test('debt: rejects whitespace-only withPerson', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.debt,
        totalAmount: 50000,
        items: [_item(amount: 50000)],
        withPerson: '   ',
      );
      expect(result, isNotNull);
      expect(result, contains('kontak'));
    });

    test('loan: rejects null withPerson', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.loan,
        totalAmount: 50000,
        items: [_item(amount: 50000)],
      );
      expect(result, isNotNull);
      expect(result, contains('kontak'));
    });

    test('loan: passes with valid withPerson', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.loan,
        totalAmount: 50000,
        items: [_item(amount: 50000)],
        withPerson: 'Budi',
      );
      expect(result, isNull);
    });

    test('rejects empty items list', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.expense,
        totalAmount: 50000,
        items: [],
      );
      expect(result, isNotNull);
      expect(result, contains('item'));
    });

    test('rejects items sum != totalAmount', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.expense,
        totalAmount: 100000,
        items: [
          _item(amount: 40000),
          _item(amount: 40000), // sum = 80000, not 100000
        ],
      );
      expect(result, isNotNull);
      expect(result, contains('Total item'));
    });

    test('passes when items sum matches within tolerance', () {
      // 0.005 tolerance — should pass
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.expense,
        totalAmount: 100000,
        items: [_item(amount: 100000.005)],
      );
      expect(result, isNull);
    });

    test('rejects income item without category', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.income,
        totalAmount: 50000,
        items: [_item(categoryId: null, amount: 50000)],
      );
      expect(result, isNotNull);
      expect(result, contains('Kategori'));
    });

    test('rejects expense item with empty category', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.expense,
        totalAmount: 50000,
        items: [_item(categoryId: '', amount: 50000)],
      );
      expect(result, isNotNull);
      expect(result, contains('Kategori'));
    });

    test('transfer does not require category', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        destinationWalletId: 'w2',
        type: TransactionTypeEnum.transfer,
        totalAmount: 50000,
        items: [_item(categoryId: null, amount: 50000)],
      );
      expect(result, isNull);
    });
  });

  // ─── TransactionModel ───

  group('TransactionModel', () {
    test('fromMap parses basic fields', () {
      final map = {
        'id': 'txn-abc',
        'user_id': 'u1',
        'wallet_id': 'w1',
        'destination_wallet_id': null,
        'type': 'expense',
        'total_amount': 75000,
        'date': '2025-03-15T10:00:00.000Z',
        'merchant_name': 'Indomaret',
        'note': 'snack',
        'attachment_url': null,
        'with_person': null,
        'status': null,
        'due_date': null,
        'is_multi_item': false,
        'reference_transaction_id': null,
        'settlement_kind': null,
        'created_at': '2025-03-15T10:00:00.000Z',
        'updated_at': '2025-03-15T10:00:00.000Z',
        'transaction_items': [],
      };

      final txn = TransactionModel.fromMap(map);

      expect(txn.id, 'txn-abc');
      expect(txn.type, TransactionTypeEnum.expense);
      expect(txn.totalAmount, 75000.0);
      expect(txn.merchantName, 'Indomaret');
      expect(txn.isMultiItem, false);
      expect(txn.items, isEmpty);
    });

    test('fromMap parses nested transaction_items', () {
      final map = {
        'id': 'txn-1',
        'user_id': 'u1',
        'wallet_id': 'w1',
        'destination_wallet_id': null,
        'type': 'expense',
        'total_amount': 80000,
        'date': '2025-01-01T00:00:00.000Z',
        'merchant_name': null,
        'note': null,
        'attachment_url': null,
        'with_person': null,
        'status': null,
        'due_date': null,
        'is_multi_item': true,
        'reference_transaction_id': null,
        'settlement_kind': null,
        'created_at': null,
        'updated_at': null,
        'transaction_items': [
          {
            'id': 'item-1',
            'transaction_id': 'txn-1',
            'category_id': 'cat-1',
            'item_name': 'Nasi Goreng',
            'qty': 1,
            'unit_price': 50000,
            'amount': 50000,
            'note': null,
            'sort_order': 0,
            'categories': {
              'name': 'Makanan',
              'icon': 'food',
              'color': '#FF5722',
            },
          },
          {
            'id': 'item-2',
            'transaction_id': 'txn-1',
            'category_id': 'cat-1',
            'item_name': 'Es Teh',
            'qty': 2,
            'unit_price': 15000,
            'amount': 30000,
            'note': null,
            'sort_order': 1,
            'categories': {
              'name': 'Makanan',
              'icon': 'food',
              'color': '#FF5722',
            },
          },
        ],
      };

      final txn = TransactionModel.fromMap(map);

      expect(txn.items.length, 2);
      expect(txn.items[0].itemName, 'Nasi Goreng');
      expect(txn.items[0].amount, 50000.0);
      expect(txn.items[0].categoryName, 'Makanan');
      expect(txn.items[1].itemName, 'Es Teh');
      expect(txn.items[1].qty, 2);
    });

    test('isSettlement returns true when settlementKind is set', () {
      final txn = _txn().copyWith(
        settlementKind: SettlementKindEnum.debtPayment,
      );
      expect(txn.isSettlement, true);
    });

    test('isSettlement returns false when settlementKind is null', () {
      final txn = _txn();
      expect(txn.isSettlement, false);
    });

    test('isReportable for income', () {
      final txn = _txn(type: TransactionTypeEnum.income);
      expect(txn.isReportable, true);
    });

    test('isReportable for expense', () {
      final txn = _txn(type: TransactionTypeEnum.expense);
      expect(txn.isReportable, true);
    });

    test('isReportable false for transfer', () {
      final txn = _txn(
        type: TransactionTypeEnum.transfer,
        destinationWalletId: 'w2',
      );
      expect(txn.isReportable, false);
    });
  });

  // ─── TransactionItemModel ───

  group('TransactionItemModel', () {
    test('toRpcMap excludes id and transaction_id', () {
      final item = TransactionItemModel(
        id: 'item-1',
        transactionId: 'txn-1',
        categoryId: 'cat-1',
        itemName: 'Bakso',
        qty: 2,
        unitPrice: 25000,
        amount: 50000,
        note: 'pedas',
        sortOrder: 0,
      );

      final map = item.toRpcMap();

      expect(map.containsKey('id'), false);
      expect(map.containsKey('transaction_id'), false);
      expect(map['category_id'], 'cat-1');
      expect(map['item_name'], 'Bakso');
      expect(map['qty'], 2);
      expect(map['unit_price'], 25000.0);
      expect(map['amount'], 50000.0);
      expect(map['note'], 'pedas');
      expect(map['sort_order'], 0);
    });

    test('fromMap parses nested categories join', () {
      final map = {
        'id': 'item-1',
        'transaction_id': 'txn-1',
        'category_id': 'cat-1',
        'item_name': 'Kopi',
        'qty': 1,
        'unit_price': 20000,
        'amount': 20000,
        'note': null,
        'sort_order': 0,
        'categories': {'name': 'Minuman', 'icon': 'coffee', 'color': '#8B4513'},
      };

      final item = TransactionItemModel.fromMap(map);

      expect(item.itemName, 'Kopi');
      expect(item.amount, 20000.0);
      expect(item.categoryName, 'Minuman');
      expect(item.categoryIcon, 'coffee');
      expect(item.categoryColor, '#8B4513');
    });
  });
}
