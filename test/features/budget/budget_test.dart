import 'package:app_saku_rapi/features/budget/controllers/budget_controller.dart';
import 'package:app_saku_rapi/features/budget/models/budget_model.dart';
import 'package:app_saku_rapi/features/budget/repositories/budget_repository.dart';
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
  bool notificationSent80 = false,
  bool notificationSent100 = false,
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
    notificationSent80: notificationSent80,
    notificationSent100: notificationSent100,
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
        'notification_sent_80': false,
        'notification_sent_100': false,
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
      expect(budget.notificationSent80, isFalse);
      expect(budget.notificationSent100, isFalse);
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
    test('excludes id, used_amount, notification flags, timestamps', () {
      final budget = _budget();
      final map = budget.toInsertMap();

      expect(map.containsKey('id'), isFalse);
      expect(map.containsKey('used_amount'), isFalse);
      expect(map.containsKey('notification_sent_80'), isFalse);
      expect(map.containsKey('notification_sent_100'), isFalse);
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
      expect(map['notification_sent_80'], isFalse);
      expect(map['notification_sent_100'], isFalse);
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
      expect(BudgetRepository.calculateSpendable(budgets), 0.0);
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

    test('copyWith preserves selectedPeriodType by default', () {
      const state = BudgetState(selectedPeriodType: BudgetPeriodType.quarterly);
      final next = state.copyWith(status: BudgetStatus.loaded);
      expect(next.selectedPeriodType, BudgetPeriodType.quarterly);
    });

    test('copyWith clearPeriodType sets to null', () {
      const state = BudgetState(selectedPeriodType: BudgetPeriodType.quarterly);
      final next = state.copyWith(clearPeriodType: true);
      expect(next.selectedPeriodType, isNull);
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
}
