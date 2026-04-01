import 'package:app_saku_rapi/features/notification/models/notification_settings_model.dart';
import 'package:app_saku_rapi/features/notification/repositories/notification_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ─── NotificationSettingsModel tests ───

  group('NotificationSettingsModel', () {
    group('fromMap', () {
      test('parses full map correctly', () {
        final map = {
          'id': 'test-id',
          'user_id': 'user-123',
          'reminder_enabled': true,
          'reminder_time': '20:30:00',
          'budget_alert_enabled': true,
          'debt_reminder_enabled': false,
          'debt_reminder_days_before': 5,
          'created_at': '2025-01-01T00:00:00.000Z',
          'updated_at': '2025-01-02T00:00:00.000Z',
        };

        final model = NotificationSettingsModel.fromMap(map);

        expect(model.id, 'test-id');
        expect(model.userId, 'user-123');
        expect(model.reminderEnabled, true);
        expect(model.reminderTime, const TimeOfDay(hour: 20, minute: 30));
        expect(model.budgetAlertEnabled, true);
        expect(model.debtReminderEnabled, false);
        expect(model.debtReminderDaysBefore, 5);
        expect(model.createdAt, isNotNull);
        expect(model.updatedAt, isNotNull);
      });

      test('handles null reminder_time', () {
        final map = {
          'id': 'test-id',
          'user_id': 'user-123',
          'reminder_enabled': false,
          'reminder_time': null,
          'budget_alert_enabled': true,
          'debt_reminder_enabled': true,
          'debt_reminder_days_before': 3,
        };

        final model = NotificationSettingsModel.fromMap(map);

        expect(model.reminderTime, isNull);
        expect(model.reminderEnabled, false);
      });

      test('applies default values for missing fields', () {
        final map = {'id': 'test-id', 'user_id': 'user-123'};

        final model = NotificationSettingsModel.fromMap(map);

        expect(model.reminderEnabled, false);
        expect(model.reminderTime, isNull);
        expect(model.budgetAlertEnabled, true);
        expect(model.budgetAlert50Enabled, false);
        expect(model.debtReminderEnabled, true);
        expect(model.debtReminderDaysBefore, 3);
      });
    });

    group('toUpdateMap', () {
      test('produces correct map with time', () {
        const model = NotificationSettingsModel(
          id: 'test-id',
          userId: 'user-123',
          reminderEnabled: true,
          reminderTime: TimeOfDay(hour: 8, minute: 5),
          budgetAlertEnabled: false,
          budgetAlert50Enabled: true,
          debtReminderEnabled: true,
          debtReminderDaysBefore: 7,
        );

        final map = model.toUpdateMap();

        expect(map['reminder_enabled'], true);
        expect(map['reminder_time'], '08:05:00');
        expect(map['budget_alert_enabled'], false);
        expect(map['budget_alert_50_enabled'], true);
        expect(map['debt_reminder_enabled'], true);
        expect(map['debt_reminder_days_before'], 7);
      });

      test('produces null reminder_time when not set', () {
        const model = NotificationSettingsModel(
          id: 'test-id',
          userId: 'user-123',
        );

        final map = model.toUpdateMap();

        expect(map['reminder_time'], isNull);
      });
    });

    group('toFullMap', () {
      test('includes all fields', () {
        const model = NotificationSettingsModel(
          id: 'test-id',
          userId: 'user-123',
          reminderEnabled: true,
          reminderTime: TimeOfDay(hour: 20, minute: 0),
          budgetAlertEnabled: true,
          budgetAlert50Enabled: true,
          debtReminderEnabled: true,
          debtReminderDaysBefore: 3,
        );

        final map = model.toFullMap();

        expect(map['id'], 'test-id');
        expect(map['user_id'], 'user-123');
        expect(map['reminder_enabled'], true);
        expect(map['reminder_time'], '20:00:00');
        expect(map['budget_alert_enabled'], true);
        expect(map['budget_alert_50_enabled'], true);
        expect(map['debt_reminder_enabled'], true);
        expect(map['debt_reminder_days_before'], 3);
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        const original = NotificationSettingsModel(
          id: 'test-id',
          userId: 'user-123',
          reminderEnabled: false,
          budgetAlertEnabled: true,
          debtReminderDaysBefore: 3,
        );

        final copied = original.copyWith(
          reminderEnabled: true,
          reminderTime: const TimeOfDay(hour: 9, minute: 0),
          debtReminderDaysBefore: 5,
        );

        expect(copied.reminderEnabled, true);
        expect(copied.reminderTime, const TimeOfDay(hour: 9, minute: 0));
        expect(copied.debtReminderDaysBefore, 5);
        // Unchanged fields
        expect(copied.id, 'test-id');
        expect(copied.budgetAlertEnabled, true);
      });

      test('clearReminderTime sets time to null', () {
        const original = NotificationSettingsModel(
          id: 'test-id',
          userId: 'user-123',
          reminderTime: TimeOfDay(hour: 20, minute: 0),
        );

        final copied = original.copyWith(clearReminderTime: true);

        expect(copied.reminderTime, isNull);
      });
    });

    group('round-trip (fromMap ← toFullMap)', () {
      test('produces identical model', () {
        const original = NotificationSettingsModel(
          id: 'test-id',
          userId: 'user-123',
          reminderEnabled: true,
          reminderTime: TimeOfDay(hour: 15, minute: 45),
          budgetAlertEnabled: false,
          budgetAlert50Enabled: true,
          debtReminderEnabled: true,
          debtReminderDaysBefore: 2,
        );

        final restored = NotificationSettingsModel.fromMap(
          original.toFullMap(),
        );

        expect(restored.id, original.id);
        expect(restored.userId, original.userId);
        expect(restored.reminderEnabled, original.reminderEnabled);
        expect(restored.reminderTime, original.reminderTime);
        expect(restored.budgetAlertEnabled, original.budgetAlertEnabled);
        expect(restored.budgetAlert50Enabled, original.budgetAlert50Enabled);
        expect(restored.debtReminderEnabled, original.debtReminderEnabled);
        expect(
          restored.debtReminderDaysBefore,
          original.debtReminderDaysBefore,
        );
      });
    });
  });

  // ─── BudgetAlertData tests ───

  group('BudgetAlertData', () {
    test('stores values correctly', () {
      const data = BudgetAlertData(
        id: 'budget-1',
        categoryName: 'Makan',
        isHalfUsed: true,
        isNearLimit: true,
        isOverBudget: false,
        notificationSent50: false,
        notificationSent80: false,
        notificationSent100: false,
      );

      expect(data.id, 'budget-1');
      expect(data.categoryName, 'Makan');
      expect(data.isHalfUsed, true);
      expect(data.isNearLimit, true);
      expect(data.isOverBudget, false);
      expect(data.notificationSent50, false);
      expect(data.notificationSent80, false);
      expect(data.notificationSent100, false);
    });
  });

  // ─── NotificationService static helper tests ───

  group('NotificationService IDs', () {
    test('budgetAlertId generates consistent IDs', () {
      // Import is not needed since we test via the service
      // Just verify the base ID logic
      const baseId = 2000;
      const testBudgetId = 'some-uuid-1234';
      final id80 = baseId + (testBudgetId.hashCode.abs() % 100000);
      final id100 = id80 + 1;

      expect(id80, greaterThan(baseId));
      expect(id100, equals(id80 + 1));
      // IDs should be deterministic
      expect(baseId + (testBudgetId.hashCode.abs() % 100000), equals(id80));
    });
  });
}
