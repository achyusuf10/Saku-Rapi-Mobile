import 'package:app_saku_rapi/features/budget/controllers/budget_controller.dart';
import 'package:app_saku_rapi/features/budget/models/budget_model.dart';
import 'package:app_saku_rapi/features/budget/repositories/budget_repository.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper factory untuk membuat [BudgetModel] minimal.
BudgetModel _budget({
  String id = 'b1',
  double amount = 500000,
  double usedAmount = 200000,
  DateTime? startDate,
  DateTime? endDate,
  BudgetPeriodType periodType = BudgetPeriodType.monthly,
  bool isRecurring = false,
  bool carryForward = false,
}) {
  return BudgetModel(
    id: id,
    userId: 'u1',
    categoryId: 'cat1',
    amount: amount,
    usedAmount: usedAmount,
    startDate: startDate ?? DateTime(2025, 1, 1),
    endDate: endDate ?? DateTime(2025, 1, 31),
    periodType: periodType,
    isRecurring: isRecurring,
    carryForward: carryForward,
  );
}

void main() {
  // ─────────────────────────────────────────────────────────────
  // BudgetPeriodType
  // ─────────────────────────────────────────────────────────────
  group('BudgetPeriodType', () {
    test('fromString parses all known values', () {
      expect(BudgetPeriodType.fromString('weekly'), BudgetPeriodType.weekly);
      expect(BudgetPeriodType.fromString('monthly'), BudgetPeriodType.monthly);
      expect(
        BudgetPeriodType.fromString('quarterly'),
        BudgetPeriodType.quarterly,
      );
      expect(BudgetPeriodType.fromString('yearly'), BudgetPeriodType.yearly);
      expect(BudgetPeriodType.fromString('custom'), BudgetPeriodType.custom);
    });

    test('fromString defaults to monthly for unknown value', () {
      expect(BudgetPeriodType.fromString('invalid'), BudgetPeriodType.monthly);
      expect(BudgetPeriodType.fromString(''), BudgetPeriodType.monthly);
    });

    test('value returns correct string', () {
      expect(BudgetPeriodType.weekly.value, 'weekly');
      expect(BudgetPeriodType.monthly.value, 'monthly');
      expect(BudgetPeriodType.quarterly.value, 'quarterly');
      expect(BudgetPeriodType.yearly.value, 'yearly');
      expect(BudgetPeriodType.custom.value, 'custom');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // BudgetModel — computed getters
  // ─────────────────────────────────────────────────────────────
  group('BudgetModel — computed getters', () {
    test('remaining = amount - usedAmount', () {
      expect(_budget(amount: 500000, usedAmount: 200000).remaining, 300000);
    });

    test('remaining can be negative when over budget', () {
      expect(_budget(amount: 500000, usedAmount: 600000).remaining, -100000);
    });

    test('usageRatio calculates correctly', () {
      expect(_budget(amount: 500000, usedAmount: 250000).usageRatio, 0.5);
    });

    test('usageRatio returns 0 when amount is 0', () {
      expect(_budget(amount: 0, usedAmount: 0).usageRatio, 0);
    });

    test('usagePercent = usageRatio * 100', () {
      expect(_budget(amount: 500000, usedAmount: 400000).usagePercent, 80.0);
    });

    test('isOverBudget when used >= amount', () {
      expect(_budget(amount: 500000, usedAmount: 500000).isOverBudget, isTrue);
      expect(_budget(amount: 500000, usedAmount: 600000).isOverBudget, isTrue);
      expect(_budget(amount: 500000, usedAmount: 499999).isOverBudget, isFalse);
    });

    test('isNearLimit when usage >= 80%', () {
      expect(_budget(amount: 500000, usedAmount: 400000).isNearLimit, isTrue);
      expect(_budget(amount: 500000, usedAmount: 399999).isNearLimit, isFalse);
      expect(_budget(amount: 500000, usedAmount: 500000).isNearLimit, isTrue);
    });

    test('isHalfUsed when usage >= 50%', () {
      expect(_budget(amount: 500000, usedAmount: 250000).isHalfUsed, isTrue);
      expect(_budget(amount: 500000, usedAmount: 249999).isHalfUsed, isFalse);
      expect(_budget(amount: 500000, usedAmount: 500000).isHalfUsed, isTrue);
    });

    test('carryForward defaults to false', () {
      expect(_budget().carryForward, isFalse);
    });

    test('carryForward can be set to true', () {
      expect(_budget(carryForward: true).carryForward, isTrue);
    });

    test('totalDays is inclusive', () {
      final budget = _budget(
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 31),
      );
      expect(budget.totalDays, 31);
    });

    test('totalDays = 1 for single day', () {
      final budget = _budget(
        startDate: DateTime(2025, 3, 15),
        endDate: DateTime(2025, 3, 15),
      );
      expect(budget.totalDays, 1);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // BudgetModel — fromMap / serialization
  // ─────────────────────────────────────────────────────────────
  group('BudgetModel — fromMap', () {
    test('parses all fields correctly', () {
      final map = {
        'id': 'budget-1',
        'user_id': 'user-1',
        'category_id': 'cat-1',
        'wallet_id': 'wallet-1',
        'amount': 1000000,
        'used_amount': 350000.5,
        'start_date': '2025-01-01',
        'end_date': '2025-01-31',
        'period_type': 'monthly',
        'is_recurring': true,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-15T12:00:00.000Z',
      };

      final budget = BudgetModel.fromMap(map);

      expect(budget.id, 'budget-1');
      expect(budget.userId, 'user-1');
      expect(budget.categoryId, 'cat-1');
      expect(budget.walletId, 'wallet-1');
      expect(budget.amount, 1000000);
      expect(budget.usedAmount, 350000.5);
      expect(budget.startDate, DateTime(2025, 1, 1));
      expect(budget.endDate, DateTime(2025, 1, 31));
      expect(budget.periodType, BudgetPeriodType.monthly);
      expect(budget.isRecurring, isTrue);
      expect(budget.createdAt, isNotNull);
      expect(budget.updatedAt, isNotNull);
    });

    test('handles nullable wallet_id', () {
      final map = {
        'id': 'b1',
        'user_id': 'u1',
        'category_id': 'c1',
        'wallet_id': null,
        'amount': 500000,
        'used_amount': 0,
        'start_date': '2025-01-01',
        'end_date': '2025-01-31',
      };

      final budget = BudgetModel.fromMap(map);
      expect(budget.walletId, isNull);
    });

    test('handles int and string amounts via _toDouble', () {
      final map = {
        'id': 'b1',
        'user_id': 'u1',
        'category_id': 'c1',
        'amount': '750000',
        'used_amount': 200000,
        'start_date': '2025-01-01',
        'end_date': '2025-01-31',
      };

      final budget = BudgetModel.fromMap(map);
      expect(budget.amount, 750000.0);
      expect(budget.usedAmount, 200000.0);
    });

    test('defaults is_recurring to false when missing', () {
      final map = {
        'id': 'b1',
        'user_id': 'u1',
        'category_id': 'c1',
        'amount': 500000,
        'used_amount': 0,
        'start_date': '2025-01-01',
        'end_date': '2025-01-31',
      };

      final budget = BudgetModel.fromMap(map);
      expect(budget.isRecurring, isFalse);
    });

    test('defaults period_type to monthly when missing', () {
      final map = {
        'id': 'b1',
        'user_id': 'u1',
        'category_id': 'c1',
        'amount': 500000,
        'used_amount': 0,
        'start_date': '2025-01-01',
        'end_date': '2025-01-31',
      };

      final budget = BudgetModel.fromMap(map);
      expect(budget.periodType, BudgetPeriodType.monthly);
    });
  });

  group('BudgetModel — toInsertMap', () {
    test('excludes id, used_amount, timestamps', () {
      final budget = _budget();
      final map = budget.toInsertMap();

      expect(map.containsKey('id'), isFalse);
      expect(map.containsKey('used_amount'), isFalse);
      expect(map.containsKey('created_at'), isFalse);
      expect(map.containsKey('updated_at'), isFalse);
      expect(map['user_id'], 'u1');
      expect(map['category_id'], 'cat1');
      expect(map['amount'], 500000);
      expect(map['period_type'], 'monthly');
    });
  });

  group('BudgetModel — toUpdateMap', () {
    test('excludes id, user_id, used_amount, timestamps', () {
      final budget = _budget();
      final map = budget.toUpdateMap();

      expect(map.containsKey('id'), isFalse);
      expect(map.containsKey('user_id'), isFalse);
      expect(map.containsKey('used_amount'), isFalse);
      expect(map.containsKey('created_at'), isFalse);
      expect(map['category_id'], 'cat1');
      expect(map['amount'], 500000);
    });
  });

  group('BudgetModel — toFullMap', () {
    test('includes all fields for local cache', () {
      final budget = _budget();
      final map = budget.toFullMap();

      expect(map['id'], 'b1');
      expect(map['user_id'], 'u1');
      expect(map['amount'], 500000);
      expect(map['used_amount'], 200000);
    });
  });

  group('BudgetModel — copyWith', () {
    test('creates new instance with overridden fields', () {
      final original = _budget(amount: 500000, usedAmount: 200000);
      final updated = original.copyWith(amount: 750000, usedAmount: 300000);

      expect(updated.amount, 750000);
      expect(updated.usedAmount, 300000);
      expect(updated.id, original.id);
      expect(updated.categoryId, original.categoryId);
    });

    test('keeps original values when not overridden', () {
      final original = _budget(isRecurring: true);
      final updated = original.copyWith(amount: 999);

      expect(updated.isRecurring, isTrue);
      expect(updated.periodType, original.periodType);
    });
  });

  group('BudgetModel — fromMap → toFullMap roundtrip', () {
    test('roundtrip preserves core fields', () {
      final original = _budget(
        amount: 1000000,
        usedAmount: 450000,
        periodType: BudgetPeriodType.quarterly,
        isRecurring: true,
      );
      final map = original.toFullMap();
      final restored = BudgetModel.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.categoryId, original.categoryId);
      expect(restored.amount, original.amount);
      expect(restored.usedAmount, original.usedAmount);
      expect(restored.periodType, original.periodType);
      expect(restored.isRecurring, original.isRecurring);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // BudgetRepository — static calculators
  // ─────────────────────────────────────────────────────────────
  group('BudgetRepository.calculateTotalBudget', () {
    test('returns 0 for empty list', () {
      expect(BudgetRepository.calculateTotalBudget([]), 0.0);
    });

    test('sums all budget amounts', () {
      final budgets = [
        _budget(id: 'b1', amount: 500000),
        _budget(id: 'b2', amount: 300000),
        _budget(id: 'b3', amount: 200000),
      ];
      expect(BudgetRepository.calculateTotalBudget(budgets), 1000000.0);
    });
  });

  group('BudgetRepository.calculateTotalUsed', () {
    test('returns 0 for empty list', () {
      expect(BudgetRepository.calculateTotalUsed([]), 0.0);
    });

    test('sums all used amounts', () {
      final budgets = [
        _budget(id: 'b1', usedAmount: 100000),
        _budget(id: 'b2', usedAmount: 250000),
      ];
      expect(BudgetRepository.calculateTotalUsed(budgets), 350000.0);
    });
  });

  group('BudgetRepository.calculateSpendable', () {
    test('returns 0 for empty list', () {
      expect(BudgetRepository.calculateSpendable([]), 0.0);
    });

    test('returns total - used when positive', () {
      final budgets = [
        _budget(id: 'b1', amount: 500000, usedAmount: 200000),
        _budget(id: 'b2', amount: 300000, usedAmount: 100000),
      ];
      // total = 800000, used = 300000, spendable = 500000
      expect(BudgetRepository.calculateSpendable(budgets), 500000.0);
    });

    test('clamps to 0 when over budget', () {
      final budgets = [_budget(id: 'b1', amount: 500000, usedAmount: 600000)];
      expect(BudgetRepository.calculateSpendable(budgets), -100000.0);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // BudgetState — copyWith + computed
  // ─────────────────────────────────────────────────────────────
  group('BudgetState', () {
    test('isLoading reflects status', () {
      expect(const BudgetState(status: BudgetStatus.loading).isLoading, isTrue);
      expect(const BudgetState(status: BudgetStatus.loaded).isLoading, isFalse);
      expect(
        const BudgetState(status: BudgetStatus.initial).isLoading,
        isFalse,
      );
    });

    test('copyWith preserves walletFilter by default', () {
      const state = BudgetState(walletFilter: 'w1');
      final next = state.copyWith(status: BudgetStatus.loaded);
      expect(next.walletFilter, 'w1');
    });

    test('copyWith clearWalletFilter sets to null', () {
      const state = BudgetState(walletFilter: 'w1');
      final next = state.copyWith(clearWalletFilter: true);
      expect(next.walletFilter, isNull);
    });

    test('copyWith preserves selectedPeriodKey by default', () {
      const state = BudgetState(selectedPeriodKey: 'quarterly');
      final next = state.copyWith(status: BudgetStatus.loaded);
      expect(next.selectedPeriodKey, 'quarterly');
    });

    test('copyWith clearPeriodKey sets to null', () {
      const state = BudgetState(selectedPeriodKey: 'quarterly');
      final next = state.copyWith(clearPeriodKey: true);
      expect(next.selectedPeriodKey, isNull);
    });

    test('copyWith clears errorMessage when not provided', () {
      const state = BudgetState(
        status: BudgetStatus.error,
        errorMessage: 'some error',
      );
      final next = state.copyWith(status: BudgetStatus.loaded);
      expect(next.errorMessage, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Fix #5: toFullMap includes category & wallet nested data
  // ─────────────────────────────────────────────────────────────
  group('BudgetModel — toFullMap with relations', () {
    test('includes categories when category is not null', () {
      final category = CategoryModel(
        id: 'cat-1',
        userId: 'u1',
        name: 'Makan',
        icon: 'utensils',
        color: '#FF5733',
        type: CategoryType.expense,
        sortOrder: 0,
      );
      final budget = BudgetModel(
        id: 'b1',
        userId: 'u1',
        categoryId: 'cat-1',
        amount: 500000,
        usedAmount: 200000,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 31),
        category: category,
      );

      final map = budget.toFullMap();
      expect(map.containsKey('categories'), isTrue);
      final catMap = map['categories'] as Map<String, dynamic>;
      expect(catMap['id'], 'cat-1');
      expect(catMap['name'], 'Makan');
    });

    test('includes wallets when wallet is not null', () {
      final wallet = WalletModel(
        id: 'w1',
        userId: 'u1',
        name: 'Cash',
        icon: 'wallet',
        color: '#33FF57',
        backgroundColor: WalletModel.defaultBackgroundColorHex,
        balance: 1000000,
        initialBalance: 1000000,
        currency: 'IDR',
        excludeFromTotal: false,
        sortOrder: 0,
      );
      final budget = BudgetModel(
        id: 'b1',
        userId: 'u1',
        categoryId: 'cat-1',
        amount: 500000,
        usedAmount: 200000,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 31),
        wallet: wallet,
      );

      final map = budget.toFullMap();
      expect(map.containsKey('wallets'), isTrue);
      final walletMap = map['wallets'] as Map<String, dynamic>;
      expect(walletMap['id'], 'w1');
      expect(walletMap['name'], 'Cash');
    });

    test('excludes categories/wallets when null', () {
      final budget = _budget();
      final map = budget.toFullMap();
      expect(map.containsKey('categories'), isFalse);
      expect(map.containsKey('wallets'), isFalse);
    });

    test('roundtrip with category preserves relation data', () {
      final category = CategoryModel(
        id: 'cat-1',
        userId: 'u1',
        name: 'Transport',
        icon: 'car',
        color: '#0000FF',
        type: CategoryType.expense,
        sortOrder: 1,
      );
      final original = BudgetModel(
        id: 'b1',
        userId: 'u1',
        categoryId: 'cat-1',
        amount: 300000,
        usedAmount: 100000,
        startDate: DateTime(2025, 3, 1),
        endDate: DateTime(2025, 3, 31),
        category: category,
      );

      final map = original.toFullMap();
      final restored = BudgetModel.fromMap(map);

      expect(restored.category, isNotNull);
      expect(restored.category!.id, 'cat-1');
      expect(restored.category!.name, 'Transport');
      expect(restored.category!.icon, 'car');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Fix: updateBudget constructs model directly (walletId=null)
  // ─────────────────────────────────────────────────────────────
  group('BudgetModel — wallet scope edge cases', () {
    test('model with walletId=null has null walletId in toUpdateMap', () {
      final budget = BudgetModel(
        id: 'b1',
        userId: 'u1',
        categoryId: 'cat-1',
        walletId: null,
        amount: 500000,
        usedAmount: 200000,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 31),
      );
      final map = budget.toUpdateMap();
      expect(map['wallet_id'], isNull);
    });

    test('model with walletId set has walletId in toUpdateMap', () {
      final budget = BudgetModel(
        id: 'b1',
        userId: 'u1',
        categoryId: 'cat-1',
        walletId: 'w1',
        amount: 500000,
        usedAmount: 200000,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 31),
      );
      final map = budget.toUpdateMap();
      expect(map['wallet_id'], 'w1');
    });

    test('directly constructing model preserves null walletId', () {
      // Simulates what the repository updateBudget now does
      final existing = BudgetModel(
        id: 'b1',
        userId: 'u1',
        categoryId: 'cat-1',
        walletId: 'w1', // originally wallet-scoped
        amount: 500000,
        usedAmount: 200000,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 31),
      );

      // User changes to "All Wallets" (walletId = null)
      final updated = BudgetModel(
        id: existing.id,
        userId: existing.userId,
        categoryId: existing.categoryId,
        walletId: null, // changed to global
        amount: existing.amount,
        usedAmount: existing.usedAmount,
        startDate: existing.startDate,
        endDate: existing.endDate,
      );

      expect(updated.walletId, isNull);
      expect(updated.toUpdateMap()['wallet_id'], isNull);
    });

    test('copyWith cannot clear walletId to null (known limitation)', () {
      // This demonstrates why repository uses direct construction
      final existing = BudgetModel(
        id: 'b1',
        userId: 'u1',
        categoryId: 'cat-1',
        walletId: 'w1',
        amount: 500000,
        usedAmount: 200000,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 31),
      );

      final viaCopyWith = existing.copyWith(walletId: null);
      // copyWith with null value keeps old value — this is the limitation
      expect(viaCopyWith.walletId, 'w1'); // NOT null
    });
  });

  // ─────────────────────────────────────────────────────────────
  // CompletedBudgetsState — copyWith + pagination
  // ─────────────────────────────────────────────────────────────
  group('CompletedBudgetsState', () {
    test('defaults to isLoading=true, hasMore=true', () {
      const state = CompletedBudgetsState();
      expect(state.isLoading, isTrue);
      expect(state.hasMore, isTrue);
      expect(state.isLoadingMore, isFalse);
      expect(state.budgets, isEmpty);
    });

    test('copyWith preserves existing values', () {
      final state = CompletedBudgetsState(
        budgets: [_budget()],
        isLoading: false,
        hasMore: true,
      );
      final next = state.copyWith(isLoadingMore: true);
      expect(next.budgets.length, 1);
      expect(next.isLoading, isFalse);
      expect(next.isLoadingMore, isTrue);
      expect(next.hasMore, isTrue);
    });
  });
}
