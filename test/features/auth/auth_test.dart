import 'package:app_saku_rapi/features/auth/models/account_login_resolve_model.dart';
import 'package:app_saku_rapi/features/auth/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ─────────────────────────────────────────────────────────────
  // UserModel — fromMap
  // ─────────────────────────────────────────────────────────────
  group('UserModel — fromMap', () {
    test('parses all fields correctly', () {
      final map = {
        'id': 'user-123',
        'email': 'test@example.com',
        'full_name': 'John Doe',
        'avatar_url': 'https://example.com/avatar.png',
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-06-15T12:00:00.000Z',
      };

      final user = UserModel.fromMap(map);

      expect(user.id, 'user-123');
      expect(user.email, 'test@example.com');
      expect(user.fullName, 'John Doe');
      expect(user.avatarUrl, 'https://example.com/avatar.png');
      expect(user.createdAt, isNotNull);
      expect(user.updatedAt, isNotNull);
    });

    test('handles nullable fields', () {
      final map = {
        'id': 'user-1',
        'email': 'anon@test.com',
        'full_name': null,
        'avatar_url': null,
        'created_at': null,
        'updated_at': null,
        'account_deleted': false,
      };

      final user = UserModel.fromMap(map);

      expect(user.fullName, isNull);
      expect(user.avatarUrl, isNull);
      expect(user.createdAt, isNull);
      expect(user.updatedAt, isNull);
      expect(user.accountDeleted, false);
      expect(user.accountDeletedAt, isNull);
    });

    test('parses account_deleted flagged user', () {
      final map = {
        'id': 'user-1',
        'email': 'dormant@test.com',
        'full_name': null,
        'avatar_url': null,
        'account_deleted': true,
        'account_deleted_at': '2026-05-01T00:00:00.000Z',
        'created_at': null,
        'updated_at': null,
      };

      final user = UserModel.fromMap(map);

      expect(user.accountDeleted, true);
      expect(user.accountDeletedAt, isNotNull);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // UserModel — toMap
  // ─────────────────────────────────────────────────────────────
  group('UserModel — toMap', () {
    test('serializes all fields', () {
      final user = UserModel(
        id: 'u1',
        email: 'a@b.com',
        fullName: 'Test User',
        avatarUrl: 'https://img.test/a.png',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 6, 1),
      );

      final map = user.toMap();

      expect(map['id'], 'u1');
      expect(map['email'], 'a@b.com');
      expect(map['full_name'], 'Test User');
      expect(map['avatar_url'], 'https://img.test/a.png');
      expect(map['created_at'], isNotNull);
      expect(map['updated_at'], isNotNull);
    });

    test('nullable fields serialize as null', () {
      const user = UserModel(id: 'u1', email: 'a@b.com');
      final map = user.toMap();

      expect(map['full_name'], isNull);
      expect(map['avatar_url'], isNull);
      expect(map['created_at'], isNull);
      expect(map['updated_at'], isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // UserModel — copyWith
  // ─────────────────────────────────────────────────────────────
  group('UserModel — copyWith', () {
    test('overrides specified fields', () {
      const original = UserModel(
        id: 'u1',
        email: 'old@test.com',
        fullName: 'Old Name',
      );
      final updated = original.copyWith(
        email: 'new@test.com',
        fullName: 'New Name',
      );

      expect(updated.email, 'new@test.com');
      expect(updated.fullName, 'New Name');
      expect(updated.id, 'u1');
    });

    test('preserves original values when not overridden', () {
      const original = UserModel(
        id: 'u1',
        email: 'a@b.com',
        fullName: 'Keep This',
        avatarUrl: 'https://keep.me',
      );
      final updated = original.copyWith(id: 'u2');

      expect(updated.fullName, 'Keep This');
      expect(updated.avatarUrl, 'https://keep.me');
      expect(updated.email, 'a@b.com');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // UserModel — equality
  // ─────────────────────────────────────────────────────────────
  group('UserModel — equality', () {
    test('equal when same id', () {
      const a = UserModel(id: 'x', email: 'a@a.com', fullName: 'Alice');
      const b = UserModel(id: 'x', email: 'b@b.com', fullName: 'Bob');
      expect(a, equals(b));
    });

    test('not equal when different id', () {
      const a = UserModel(id: 'x', email: 'same@test.com');
      const b = UserModel(id: 'y', email: 'same@test.com');
      expect(a, isNot(equals(b)));
    });

    test('hashCode is based on id', () {
      const a = UserModel(id: 'abc', email: 'a@a.com');
      const b = UserModel(id: 'abc', email: 'b@b.com');
      expect(a.hashCode, b.hashCode);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // UserModel — fromMap → toMap roundtrip
  // ─────────────────────────────────────────────────────────────
  group('UserModel — roundtrip', () {
    test('fromMap → toMap → fromMap preserves fields', () {
      final original = UserModel(
        id: 'rt1',
        email: 'roundtrip@test.com',
        fullName: 'Round Trip',
        avatarUrl: 'https://example.com/rt.png',
        createdAt: DateTime(2025, 3, 1),
        updatedAt: DateTime(2025, 3, 15),
      );
      final map = original.toMap();
      final restored = UserModel.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.email, original.email);
      expect(restored.fullName, original.fullName);
      expect(restored.avatarUrl, original.avatarUrl);
    });
  });

  group('AccountLoginResolveModel — fromRpcJson', () {
    test('parses cooldown payload', () {
      final m = AccountLoginResolveModel.fromRpcJson({
        'allowed': false,
        'reason': 'account_cooldown',
        'days_remaining': 7,
      });
      expect(m.allowed, isFalse);
      expect(m.reason, 'account_cooldown');
      expect(m.daysRemaining, 7);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // UserModel — toString
  // ─────────────────────────────────────────────────────────────
  group('UserModel — toString', () {
    test('includes id, email, and fullName', () {
      const user = UserModel(
        id: 'u1',
        email: 'test@mail.com',
        fullName: 'Test',
      );
      final str = user.toString();

      expect(str, contains('u1'));
      expect(str, contains('test@mail.com'));
      expect(str, contains('Test'));
    });
  });
}
