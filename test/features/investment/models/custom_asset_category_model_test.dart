import 'package:app_saku_rapi/features/investment/models/custom_asset_category_model.dart';
import 'package:flutter_test/flutter_test.dart';

CustomAssetCategoryModel _category({
  String id = 'cat-1',
  String userId = 'u1',
  String name = 'Saham',
  String unitLabel = 'Lot',
}) {
  return CustomAssetCategoryModel(
    id: id,
    userId: userId,
    name: name,
    unitLabel: unitLabel,
  );
}

void main() {
  group('CustomAssetCategoryModel.fromMap', () {
    test('parses complete map', () {
      final map = {
        'id': 'cat-abc',
        'user_id': 'user-1',
        'name': 'Reksadana',
        'unit_label': 'Unit',
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-02T00:00:00.000Z',
      };

      final model = CustomAssetCategoryModel.fromMap(map);
      expect(model.id, 'cat-abc');
      expect(model.userId, 'user-1');
      expect(model.name, 'Reksadana');
      expect(model.unitLabel, 'Unit');
      expect(model.createdAt, DateTime.utc(2025));
    });

    test('defaults unit_label to Unit when missing', () {
      final map = {'id': 'cat-1', 'user_id': 'u1', 'name': 'Test'};
      final model = CustomAssetCategoryModel.fromMap(map);
      expect(model.unitLabel, 'Unit');
    });

    test('handles missing timestamps', () {
      final map = {'id': 'cat-1', 'user_id': 'u1', 'name': 'Test'};
      final model = CustomAssetCategoryModel.fromMap(map);
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
    });
  });

  group('CustomAssetCategoryModel.toInsertMap', () {
    test('contains user_id, name, and unit_label', () {
      final map = _category().toInsertMap();
      expect(map, {'user_id': 'u1', 'name': 'Saham', 'unit_label': 'Lot'});
      expect(map.containsKey('id'), false);
    });
  });

  group('CustomAssetCategoryModel.toUpdateMap', () {
    test('contains name and unit_label only', () {
      final map = _category().toUpdateMap();
      expect(map, {'name': 'Saham', 'unit_label': 'Lot'});
    });
  });

  group('CustomAssetCategoryModel.toFullMap', () {
    test('contains all fields', () {
      final model = _category();
      final map = model.toFullMap();
      expect(map['id'], 'cat-1');
      expect(map['user_id'], 'u1');
      expect(map['name'], 'Saham');
      expect(map['unit_label'], 'Lot');
    });
  });

  group('CustomAssetCategoryModel.copyWith', () {
    test('returns identical when no args', () {
      final model = _category();
      final copy = model.copyWith();
      expect(copy.id, model.id);
      expect(copy.name, model.name);
      expect(copy.unitLabel, model.unitLabel);
    });

    test('updates name and unitLabel', () {
      final model = _category(name: 'Old', unitLabel: 'Lot');
      final updated = model.copyWith(name: 'New', unitLabel: 'Lembar');
      expect(updated.name, 'New');
      expect(updated.unitLabel, 'Lembar');
      expect(updated.id, model.id);
    });
  });

  group('CustomAssetCategoryModel roundtrip', () {
    test('toFullMap → fromMap produces equivalent model', () {
      final original = _category(
        id: 'rt-1',
        name: 'Obligasi',
        unitLabel: 'Unit',
      );
      final restored = CustomAssetCategoryModel.fromMap(original.toFullMap());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.unitLabel, original.unitLabel);
    });
  });
}
