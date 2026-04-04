import 'package:app_saku_rapi/features/investment/models/custom_gold_type_model.dart';
import 'package:flutter_test/flutter_test.dart';

CustomGoldTypeModel _goldType({
  String id = 'gt-1',
  String userId = 'u1',
  String name = 'Emas UBS',
}) {
  return CustomGoldTypeModel(id: id, userId: userId, name: name);
}

void main() {
  group('CustomGoldTypeModel.fromMap', () {
    test('parses complete map', () {
      final map = {
        'id': 'gt-abc',
        'user_id': 'user-1',
        'name': 'Emas UBS',
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-02T00:00:00.000Z',
      };

      final model = CustomGoldTypeModel.fromMap(map);
      expect(model.id, 'gt-abc');
      expect(model.userId, 'user-1');
      expect(model.name, 'Emas UBS');
      expect(model.createdAt, DateTime.utc(2025));
      expect(model.updatedAt, DateTime.utc(2025, 1, 2));
    });

    test('handles missing timestamps', () {
      final map = {'id': 'gt-1', 'user_id': 'u1', 'name': 'Test'};
      final model = CustomGoldTypeModel.fromMap(map);
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
    });
  });

  group('CustomGoldTypeModel.toInsertMap', () {
    test('contains user_id and name only', () {
      final map = _goldType().toInsertMap();
      expect(map, {'user_id': 'u1', 'name': 'Emas UBS'});
      expect(map.containsKey('id'), false);
    });
  });

  group('CustomGoldTypeModel.toUpdateMap', () {
    test('contains name only', () {
      final map = _goldType().toUpdateMap();
      expect(map, {'name': 'Emas UBS'});
    });
  });

  group('CustomGoldTypeModel.toFullMap', () {
    test('contains all fields', () {
      final model = _goldType();
      final map = model.toFullMap();
      expect(map['id'], 'gt-1');
      expect(map['user_id'], 'u1');
      expect(map['name'], 'Emas UBS');
    });
  });

  group('CustomGoldTypeModel.copyWith', () {
    test('returns identical when no args', () {
      final model = _goldType();
      final copy = model.copyWith();
      expect(copy.id, model.id);
      expect(copy.name, model.name);
    });

    test('updates name only', () {
      final model = _goldType(name: 'Old Name');
      final updated = model.copyWith(name: 'New Name');
      expect(updated.name, 'New Name');
      expect(updated.id, model.id);
    });
  });

  group('CustomGoldTypeModel roundtrip', () {
    test('toFullMap → fromMap produces equivalent model', () {
      final original = _goldType(id: 'rt-1', name: 'Emas Galangan');
      final restored = CustomGoldTypeModel.fromMap(original.toFullMap());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.userId, original.userId);
    });
  });
}
