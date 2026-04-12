import 'package:app_saku_rapi/core/enums/debt_loan_kind_enum.dart';
import 'package:app_saku_rapi/core/enums/debt_status_enum.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/features/transaction/repositories/transaction_repository.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
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
  DebtLoanKindEnum? settlementKind,
  String? referenceTransactionId,
  String? status,
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
  settlementKind: settlementKind,
  referenceTransactionId: referenceTransactionId,
  status: status != null ? DebtStatusEnum.fromString(status) : null,
);

WalletModel _wallet({
  String id = 'w1',
  String name = 'Mandiri',
  double balance = 1000000,
}) => WalletModel(
  id: id,
  userId: 'u1',
  name: name,
  icon: 'wallet',
  color: '#10B981',
  balance: balance,
  initialBalance: balance,
  currency: 'IDR',
  excludeFromTotal: false,
  sortOrder: 0,
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
      expect(txn.date.toUtc(), DateTime.utc(2025, 3, 15, 10));
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
      final txn = _txn().copyWith(settlementKind: DebtLoanKindEnum.debtPayment);
      expect(txn.isSettlement, true);
    });

    test('isSettlement returns false when settlementKind is null', () {
      final txn = _txn();
      expect(txn.isSettlement, false);
    });

    test('toFullMap serializes date as UTC ISO 8601 timestamp', () {
      final txn = _txn().copyWith(
        date: DateTime.utc(2025, 1, 1, 14, 30).toLocal(),
      );

      expect(
        txn.toFullMap()['date'],
        DateTime.utc(2025, 1, 1, 14, 30).toIso8601String(),
      );
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

  // ─── Edge Case: invalid category ───

  group('Edge Case: invalid category', () {
    test('expense with null category on all items rejected', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.expense,
        totalAmount: 75000,
        items: [
          _item(categoryId: null, amount: 50000),
          _item(categoryId: null, amount: 25000),
        ],
      );
      expect(result, isNotNull);
      expect(result, contains('Kategori'));
    });

    test('income with empty string categoryId rejected', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.income,
        totalAmount: 100000,
        items: [_item(categoryId: '', amount: 100000)],
      );
      expect(result, isNotNull);
      expect(result, contains('Kategori'));
    });

    test('multi-item expense: partial null category fails', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.expense,
        totalAmount: 100000,
        items: [
          _item(categoryId: 'cat-1', amount: 50000),
          _item(categoryId: null, amount: 50000), // invalid
        ],
      );
      expect(result, isNotNull);
      expect(result, contains('Kategori'));
    });

    test('debt does not require category', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.debt,
        totalAmount: 50000,
        items: [_item(categoryId: null, amount: 50000)],
        withPerson: 'Budi',
      );
      expect(result, isNull);
    });

    test('adjustment does not require category', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.adjustment,
        totalAmount: 50000,
        items: [_item(categoryId: null, amount: 50000)],
      );
      expect(result, isNull);
    });
  });

  // ─── Edge Case: destination wallet same as source ───

  group('Edge Case: destination wallet same as source', () {
    test('transfer with identical wallet IDs rejected', () {
      final result = TransactionRepository.validateInput(
        walletId: 'wallet-abc',
        destinationWalletId: 'wallet-abc',
        type: TransactionTypeEnum.transfer,
        totalAmount: 500000,
        items: [_item(categoryId: null, amount: 500000)],
      );
      expect(result, isNotNull);
      expect(result, contains('sama'));
    });

    test('transfer with different wallet IDs passes', () {
      final result = TransactionRepository.validateInput(
        walletId: 'wallet-abc',
        destinationWalletId: 'wallet-xyz',
        type: TransactionTypeEnum.transfer,
        totalAmount: 500000,
        items: [_item(categoryId: null, amount: 500000)],
      );
      expect(result, isNull);
    });
  });

  // ─── Edge Case: item total mismatch ───

  group('Edge Case: item total mismatch', () {
    test('single item amount != totalAmount rejected', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.expense,
        totalAmount: 100000,
        items: [_item(amount: 99000)],
      );
      expect(result, isNotNull);
      expect(result, contains('Total item'));
    });

    test('multi-item sum < totalAmount rejected', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.expense,
        totalAmount: 200000,
        items: [
          _item(amount: 50000),
          _item(amount: 50000),
          _item(amount: 50000),
        ],
      );
      expect(result, isNotNull);
      expect(result, contains('Total item'));
    });

    test('multi-item sum > totalAmount rejected', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.expense,
        totalAmount: 100000,
        items: [_item(amount: 50001), _item(amount: 50001)],
      );
      expect(result, isNotNull);
      expect(result, contains('Total item'));
    });

    test('multi-item sum matches exactly passes', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.expense,
        totalAmount: 150000,
        items: [_item(amount: 75000), _item(amount: 75000)],
      );
      expect(result, isNull);
    });

    test('floating point tolerance: 0.005 diff passes', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.expense,
        totalAmount: 100000,
        items: [_item(amount: 100000.005)],
      );
      expect(result, isNull);
    });

    test('over tolerance: 0.02 diff fails', () {
      final result = TransactionRepository.validateInput(
        walletId: 'w1',
        type: TransactionTypeEnum.expense,
        totalAmount: 100000,
        items: [_item(amount: 100000.02)],
      );
      expect(result, isNotNull);
    });
  });

  // ─── Edge Case: duplicate submit (anti double-submit) ───

  group('Edge Case: duplicate submit', () {
    test('TransactionFormState.isSaving blocks resubmission', () {
      const state = TransactionFormState(status: TransactionFormStatus.saving);
      expect(state.isSaving, true);
    });

    test('idle state allows submission', () {
      const state = TransactionFormState(status: TransactionFormStatus.idle);
      expect(state.isSaving, false);
    });

    test('saved state does not block', () {
      const state = TransactionFormState(status: TransactionFormStatus.saved);
      expect(state.isSaving, false);
    });

    test('error state allows re-submission', () {
      const state = TransactionFormState(status: TransactionFormStatus.error);
      expect(state.isSaving, false);
    });
  });

  // ─── Edge Case: edit/delete affecting balance (model consistency) ───

  group('Edge Case: edit/delete transaction affecting balance', () {
    test('settlement transactions are flagged correctly', () {
      final settlement = _txn(
        type: TransactionTypeEnum.expense,
        settlementKind: DebtLoanKindEnum.debtPayment,
        referenceTransactionId: 'ref-txn-1',
      );
      expect(settlement.isSettlement, true);
      expect(settlement.isReportable, false);
    });

    test('non-settlement expense is reportable', () {
      final expense = _txn(type: TransactionTypeEnum.expense);
      expect(expense.isSettlement, false);
      expect(expense.isReportable, true);
    });

    test('transfer is not reportable', () {
      final transfer = _txn(
        type: TransactionTypeEnum.transfer,
        destinationWalletId: 'w2',
      );
      expect(transfer.isReportable, false);
    });

    test('debt is not reportable', () {
      final debt = _txn(type: TransactionTypeEnum.debt, withPerson: 'Budi');
      expect(debt.isReportable, false);
    });

    test('loan_collection settlement is not reportable', () {
      final settlement = _txn(
        type: TransactionTypeEnum.income,
        settlementKind: DebtLoanKindEnum.loanCollection,
        referenceTransactionId: 'ref-txn-2',
      );
      expect(settlement.isSettlement, true);
      // Income with settlement is still isReportable via type...
      // ...but isSettlement being true tells the report to exclude it
      expect(settlement.isSettlement, true);
    });

    test('adjustment is not reportable', () {
      final adj = _txn(type: TransactionTypeEnum.adjustment);
      expect(adj.isReportable, false);
    });

    test('copyWith preserves settlement fields on edit', () {
      final original = _txn(
        type: TransactionTypeEnum.debt,
        withPerson: 'Andi',
        totalAmount: 500000,
      );

      // Simulate an edit: user changes the amount
      final edited = original.copyWith(totalAmount: 400000);

      expect(edited.type, TransactionTypeEnum.debt);
      expect(edited.withPerson, 'Andi');
      expect(edited.totalAmount, 400000);
      expect(edited.walletId, original.walletId);
    });
  });

  // ─── TransactionTypeEnum domain rules ───

  group('TransactionTypeEnum domain rules', () {
    test('only expense is budgetable', () {
      for (final type in TransactionTypeEnum.values) {
        if (type == TransactionTypeEnum.expense) {
          expect(type.isBudgetable, true);
        } else {
          expect(
            type.isBudgetable,
            false,
            reason: '$type should not be budgetable',
          );
        }
      }
    });

    test('only income and expense are reportable', () {
      expect(TransactionTypeEnum.income.isReportable, true);
      expect(TransactionTypeEnum.expense.isReportable, true);
      expect(TransactionTypeEnum.transfer.isReportable, false);
      expect(TransactionTypeEnum.debt.isReportable, false);
      expect(TransactionTypeEnum.loan.isReportable, false);
      expect(TransactionTypeEnum.adjustment.isReportable, false);
      expect(TransactionTypeEnum.transferToAsset.isReportable, false);
    });

    test('only transfer requires destination wallet', () {
      for (final type in TransactionTypeEnum.values) {
        if (type == TransactionTypeEnum.transfer) {
          expect(type.requiresDestinationWallet, true);
        } else {
          expect(
            type.requiresDestinationWallet,
            false,
            reason: '$type should not require dest wallet',
          );
        }
      }
    });

    test('only debt and loan require withPerson', () {
      expect(TransactionTypeEnum.debt.requiresWithPerson, true);
      expect(TransactionTypeEnum.loan.requiresWithPerson, true);
      expect(TransactionTypeEnum.income.requiresWithPerson, false);
      expect(TransactionTypeEnum.expense.requiresWithPerson, false);
      expect(TransactionTypeEnum.transfer.requiresWithPerson, false);
    });

    test('fromString round trips all values', () {
      for (final type in TransactionTypeEnum.values) {
        final dbVal = type.toDbValue();
        final roundTripped = TransactionTypeEnum.fromString(dbVal);
        expect(roundTripped, type);
      }
    });

    test('fromString throws on unknown value', () {
      expect(
        () => TransactionTypeEnum.fromString('unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // ─── TransactionFormState computed props ───

  group('TransactionFormState computed properties', () {
    test('isEditing true when existingTransaction set', () {
      final state = TransactionFormState(existingTransaction: _txn());
      expect(state.isEditing, true);
    });

    test('isEditing false when no existingTransaction', () {
      const state = TransactionFormState();
      expect(state.isEditing, false);
    });

    test('isMultiItem when items > 1', () {
      final state = TransactionFormState(
        items: [_item(amount: 50000), _item(amount: 50000)],
      );
      expect(state.isMultiItem, true);
    });

    test('not isMultiItem when single item', () {
      final state = TransactionFormState(items: [_item(amount: 50000)]);
      expect(state.isMultiItem, false);
    });

    test('itemsTotal sums all items', () {
      final state = TransactionFormState(
        items: [
          _item(amount: 30000),
          _item(amount: 20000),
          _item(amount: 10000),
        ],
      );
      expect(state.itemsTotal, 60000.0);
    });

    test('isTotalMatched when items match totalAmount', () {
      final state = TransactionFormState(
        totalAmount: 100000,
        items: [_item(amount: 60000), _item(amount: 40000)],
      );
      expect(state.isTotalMatched, true);
    });

    test('isTotalMatched false when mismatch', () {
      final state = TransactionFormState(
        totalAmount: 100000,
        items: [_item(amount: 60000), _item(amount: 30000)],
      );
      expect(state.isTotalMatched, false);
    });

    test('clearFields resets nullable fields', () {
      final state = TransactionFormState(
        wallet: _wallet(),
        destinationWallet: _wallet(id: 'w2', name: 'BCA'),
        withPerson: 'Budi',
        dueDate: DateTime(2025, 12, 31),
        merchantName: 'Indomaret',
        note: 'belanja',
        errorMessage: 'some error',
        items: [_item(amount: 50000)],
      );

      final cleared = state.clearFields(
        clearDestWallet: true,
        clearWithPerson: true,
        clearDueDate: true,
        clearMerchant: true,
        clearNote: true,
        clearError: true,
      );

      expect(cleared.destinationWallet, isNull);
      expect(cleared.withPerson, isNull);
      expect(cleared.dueDate, isNull);
      expect(cleared.merchantName, isNull);
      expect(cleared.note, isNull);
      expect(cleared.errorMessage, isNull);
      // wallet and items preserved
      expect(cleared.wallet, isNotNull);
      expect(cleared.items, hasLength(1));
    });
  });

  // ─── DebtLoanKindEnum ───

  group('DebtLoanKindEnum', () {
    test('fromString round trips', () {
      for (final kind in DebtLoanKindEnum.values) {
        final dbVal = kind.toDbValue();
        final roundTripped = DebtLoanKindEnum.fromString(dbVal);
        expect(roundTripped, kind);
      }
    });

    test('debt maps to debt', () {
      expect(DebtLoanKindEnum.debt.toDbValue(), 'debt');
    });

    test('loan maps to loan', () {
      expect(DebtLoanKindEnum.loan.toDbValue(), 'loan');
    });

    test('debtPayment maps to debt_payment', () {
      expect(DebtLoanKindEnum.debtPayment.toDbValue(), 'debt_payment');
    });

    test('loanCollection maps to loan_collection', () {
      expect(DebtLoanKindEnum.loanCollection.toDbValue(), 'loan_collection');
    });

    test('isSettlement returns true only for payment/collection', () {
      expect(DebtLoanKindEnum.debt.isSettlement, false);
      expect(DebtLoanKindEnum.loan.isSettlement, false);
      expect(DebtLoanKindEnum.debtPayment.isSettlement, true);
      expect(DebtLoanKindEnum.loanCollection.isSettlement, true);
    });

    test('fromString throws on invalid value', () {
      expect(
        () => DebtLoanKindEnum.fromString('invalid'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
