import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/category/repositories/category_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper factory untuk membuat [CategoryModel] minimal.
CategoryModel _cat({
  String id = 'c1',
  String name = 'Makan',
  CategoryType type = CategoryType.expense,
  String? parentId,
  bool isHidden = false,
  int sortOrder = 0,
}) {
  return CategoryModel(
    id: id,
    userId: 'u1',
    name: name,
    icon: 'utensils',
    color: '#F59E0B',
    type: type,
    parentId: parentId,
    sortOrder: sortOrder,
    isHidden: isHidden,
  );
}

void main() {
  // ─────────────────────────────────────────────────────────────
  // CategoryType
  // ─────────────────────────────────────────────────────────────
  group('CategoryType', () {
    test('fromString parses all known values', () {
      expect(CategoryType.fromString('income'), CategoryType.income);
      expect(CategoryType.fromString('expense'), CategoryType.expense);
      expect(CategoryType.fromString('system'), CategoryType.system);
    });

    test('fromString defaults to expense for unknown value', () {
      expect(CategoryType.fromString('invalid'), CategoryType.expense);
      expect(CategoryType.fromString(''), CategoryType.expense);
    });

    test('value returns correct string', () {
      expect(CategoryType.income.value, 'income');
      expect(CategoryType.expense.value, 'expense');
      expect(CategoryType.system.value, 'system');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // CategoryModel — computed getters
  // ─────────────────────────────────────────────────────────────
  group('CategoryModel — computed getters', () {
    test('isParent is true when parentId is null', () {
      expect(_cat(parentId: null).isParent, isTrue);
    });

    test('isParent is false when parentId is set', () {
      expect(_cat(parentId: 'p1').isParent, isFalse);
    });

    test('isChild is true when parentId is set', () {
      expect(_cat(parentId: 'p1').isChild, isTrue);
    });

    test('isChild is false when parentId is null', () {
      expect(_cat(parentId: null).isChild, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // CategoryModel — equality
  // ─────────────────────────────────────────────────────────────
  group('CategoryModel — equality', () {
    test('equal when same id, even with different names', () {
      final a = _cat(id: 'x', name: 'Makan');
      final b = _cat(id: 'x', name: 'Transport');
      expect(a, equals(b));
    });

    test('not equal when different id', () {
      final a = _cat(id: 'x');
      final b = _cat(id: 'y');
      expect(a, isNot(equals(b)));
    });

    test('hashCode is based on id', () {
      final a = _cat(id: 'x');
      final b = _cat(id: 'x', name: 'Different');
      expect(a.hashCode, b.hashCode);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // CategoryModel — fromMap
  // ─────────────────────────────────────────────────────────────
  group('CategoryModel — fromMap', () {
    test('allows null user_id (kategori global, RPC get/toggle)', () {
      final map = {
        'id': 'g1',
        'user_id': null,
        'name': 'Transport',
        'icon': 'car',
        'color': '#3B82F6',
        'type': 'expense',
        'parent_id': null,
        'is_default': true,
        'is_hidden': true,
        'sort_order': 1,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-01T00:00:00.000Z',
      };
      final c = CategoryModel.fromMap(map);
      expect(c.userId, isNull);
      expect(c.isDefault, isTrue);
      expect(c.isHidden, isTrue);
    });

    test('parses all fields correctly', () {
      final map = {
        'id': 'cat-1',
        'user_id': 'user-1',
        'name': 'Makanan',
        'icon': 'utensils',
        'color': '#F59E0B',
        'type': 'expense',
        'parent_id': null,
        'is_default': true,
        'is_hidden': false,
        'sort_order': 5,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-15T12:00:00.000Z',
      };

      final cat = CategoryModel.fromMap(map);

      expect(cat.id, 'cat-1');
      expect(cat.userId, 'user-1');
      expect(cat.name, 'Makanan');
      expect(cat.icon, 'utensils');
      expect(cat.color, '#F59E0B');
      expect(cat.type, CategoryType.expense);
      expect(cat.parentId, isNull);
      expect(cat.isDefault, isTrue);
      expect(cat.isHidden, isFalse);
      expect(cat.sortOrder, 5);
      expect(cat.createdAt, isNotNull);
      expect(cat.updatedAt, isNotNull);
    });

    test('handles nullable fields', () {
      final map = {
        'id': 'c1',
        'user_id': null,
        'name': 'System',
        'icon': 'gear',
        'color': '#999',
        'type': 'system',
      };

      final cat = CategoryModel.fromMap(map);
      expect(cat.userId, isNull);
      expect(cat.parentId, isNull);
      expect(cat.isDefault, isFalse);
      expect(cat.sortOrder, 0);
      expect(cat.createdAt, isNull);
    });

    test('parses child category with parentId', () {
      final map = {
        'id': 'c2',
        'user_id': 'u1',
        'name': 'Snack',
        'icon': 'cookie',
        'color': '#FFA',
        'type': 'expense',
        'parent_id': 'c1',
      };

      final cat = CategoryModel.fromMap(map);
      expect(cat.parentId, 'c1');
      expect(cat.isChild, isTrue);
      expect(cat.isParent, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // CategoryModel — toMap / toFullMap
  // ─────────────────────────────────────────────────────────────
  group('CategoryModel — toMap', () {
    test('excludes id and created_at', () {
      final cat = _cat();
      final map = cat.toMap();

      expect(map.containsKey('id'), isFalse);
      expect(map.containsKey('created_at'), isFalse);
      expect(map['user_id'], 'u1');
      expect(map['name'], 'Makan');
      expect(map['type'], 'expense');
    });
  });

  group('CategoryModel — toFullMap', () {
    test('includes id and timestamps', () {
      final cat = _cat(id: 'cat-x');
      final map = cat.toFullMap();

      expect(map['id'], 'cat-x');
      expect(map.containsKey('created_at'), isTrue);
      expect(map.containsKey('updated_at'), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // CategoryModel — copyWith
  // ─────────────────────────────────────────────────────────────
  group('CategoryModel — copyWith', () {
    test('overrides specified fields', () {
      final original = _cat(name: 'Makan', sortOrder: 0);
      final updated = original.copyWith(name: 'Transport', sortOrder: 5);

      expect(updated.name, 'Transport');
      expect(updated.sortOrder, 5);
      expect(updated.id, original.id);
      expect(updated.type, original.type);
    });

    test('preserves original values when not overridden', () {
      final original = _cat(name: 'Makan', type: CategoryType.income);
      final updated = original.copyWith(sortOrder: 10);

      expect(updated.name, 'Makan');
      expect(updated.type, CategoryType.income);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // CategoryModel — fromMap → toFullMap roundtrip
  // ─────────────────────────────────────────────────────────────
  group('CategoryModel — roundtrip', () {
    test('fromMap → toFullMap → fromMap preserves core fields', () {
      final original = _cat(
        id: 'rt1',
        name: 'Transport',
        type: CategoryType.income,
        parentId: null,
      );
      final map = original.toFullMap();
      final restored = CategoryModel.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.parentId, original.parentId);
      expect(restored.isHidden, original.isHidden);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // CategoryRepository.groupParentChild
  // ─────────────────────────────────────────────────────────────
  group('CategoryRepository.groupParentChild', () {
    test('returns empty list for empty input', () {
      expect(CategoryRepository.groupParentChild([]), isEmpty);
    });

    test('groups children under their parents', () {
      final flat = [
        _cat(id: 'p1', name: 'Makan'),
        _cat(id: 'p2', name: 'Transport'),
        _cat(id: 'c1', name: 'Snack', parentId: 'p1'),
        _cat(id: 'c2', name: 'Minum', parentId: 'p1'),
        _cat(id: 'c3', name: 'Bensin', parentId: 'p2'),
      ];

      final grouped = CategoryRepository.groupParentChild(flat);

      expect(grouped, hasLength(2));

      final makan = grouped.firstWhere((c) => c.id == 'p1');
      expect(makan.children, hasLength(2));
      expect(makan.children.map((c) => c.id), containsAll(['c1', 'c2']));

      final transport = grouped.firstWhere((c) => c.id == 'p2');
      expect(transport.children, hasLength(1));
      expect(transport.children.first.id, 'c3');
    });

    test('parent without children has empty children list', () {
      final flat = [_cat(id: 'p1', name: 'Solo Parent')];

      final grouped = CategoryRepository.groupParentChild(flat);
      expect(grouped, hasLength(1));
      expect(grouped.first.children, isEmpty);
    });

    test('sorts children by sortOrder', () {
      final flat = [
        _cat(id: 'p1', name: 'Parent'),
        _cat(id: 'c1', name: 'Third', parentId: 'p1', sortOrder: 3),
        _cat(id: 'c2', name: 'First', parentId: 'p1', sortOrder: 1),
        _cat(id: 'c3', name: 'Second', parentId: 'p1', sortOrder: 2),
      ];

      final grouped = CategoryRepository.groupParentChild(flat);
      final children = grouped.first.children;

      expect(children[0].id, 'c2');
      expect(children[1].id, 'c3');
      expect(children[2].id, 'c1');
    });

    test('excludes hidden categories when includeHidden=false', () {
      final flat = [
        _cat(id: 'p1', name: 'Visible'),
        _cat(id: 'p2', name: 'Hidden', isHidden: true),
        _cat(id: 'c1', name: 'Visible Child', parentId: 'p1'),
        _cat(id: 'c2', name: 'Hidden Child', parentId: 'p1', isHidden: true),
      ];

      final grouped = CategoryRepository.groupParentChild(
        flat,
        includeHidden: false,
      );

      expect(grouped, hasLength(1));
      expect(grouped.first.id, 'p1');
      expect(grouped.first.children, hasLength(1));
      expect(grouped.first.children.first.id, 'c1');
    });

    test('includes hidden categories when includeHidden=true (default)', () {
      final flat = [
        _cat(id: 'p1', name: 'Parent'),
        _cat(id: 'p2', name: 'Hidden Parent', isHidden: true),
        _cat(id: 'c1', name: 'Hidden Child', parentId: 'p1', isHidden: true),
      ];

      final grouped = CategoryRepository.groupParentChild(flat);

      expect(grouped, hasLength(2));
      final p1 = grouped.firstWhere((c) => c.id == 'p1');
      expect(p1.children, hasLength(1));
    });
  });
}
