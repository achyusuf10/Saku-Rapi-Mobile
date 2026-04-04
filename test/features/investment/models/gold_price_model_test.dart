import 'package:app_saku_rapi/features/investment/models/gold_price_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoldPriceModel.fromMap', () {
    test('parses complete map', () {
      final map = {
        'id': 'gp-1',
        'source': 'antaremas',
        'buy_price': 1500000.0,
        'sell_price': 1480000.0,
        'fetched_at': '2025-07-01T12:00:00.000Z',
      };

      final model = GoldPriceModel.fromMap(map);
      expect(model.id, 'gp-1');
      expect(model.source, 'antaremas');
      expect(model.buyPrice, 1500000.0);
      expect(model.sellPrice, 1480000.0);
      expect(model.fetchedAt, DateTime.utc(2025, 7, 1, 12));
    });

    test('handles integer prices', () {
      final map = {
        'id': 'gp-2',
        'source': 'logammulia',
        'buy_price': 1600000,
        'sell_price': 1580000,
        'fetched_at': '2025-07-01T12:00:00.000Z',
      };

      final model = GoldPriceModel.fromMap(map);
      expect(model.buyPrice, 1600000.0);
      expect(model.sellPrice, 1580000.0);
    });

    test('handles string prices', () {
      final map = {
        'id': 'gp-3',
        'source': 'antaremas',
        'buy_price': '1500000.50',
        'sell_price': '1480000.75',
        'fetched_at': '2025-07-01T12:00:00.000Z',
      };

      final model = GoldPriceModel.fromMap(map);
      expect(model.buyPrice, 1500000.50);
      expect(model.sellPrice, 1480000.75);
    });

    test('defaults to 0 for null prices', () {
      final map = {
        'id': 'gp-4',
        'source': 'antaremas',
        'buy_price': null,
        'sell_price': null,
        'fetched_at': '2025-07-01T12:00:00.000Z',
      };

      final model = GoldPriceModel.fromMap(map);
      expect(model.buyPrice, 0);
      expect(model.sellPrice, 0);
    });
  });

  group('GoldPriceModel.toFullMap', () {
    test('contains all fields', () {
      final now = DateTime.utc(2025, 7, 1);
      final model = GoldPriceModel(
        id: 'gp-1',
        source: 'antaremas',
        buyPrice: 1500000,
        sellPrice: 1480000,
        fetchedAt: now,
      );
      final map = model.toFullMap();

      expect(map['id'], 'gp-1');
      expect(map['source'], 'antaremas');
      expect(map['buy_price'], 1500000);
      expect(map['sell_price'], 1480000);
      expect(map['fetched_at'], now.toIso8601String());
    });
  });

  group('GoldPriceModel.copyWith', () {
    test('returns identical when no args', () {
      final model = GoldPriceModel(
        id: 'gp-1',
        source: 'antaremas',
        buyPrice: 1500000,
        sellPrice: 1480000,
        fetchedAt: DateTime.utc(2025),
      );
      final copy = model.copyWith();
      expect(copy.id, model.id);
      expect(copy.buyPrice, model.buyPrice);
    });

    test('updates specified fields', () {
      final model = GoldPriceModel(
        id: 'gp-1',
        source: 'antaremas',
        buyPrice: 1500000,
        sellPrice: 1480000,
        fetchedAt: DateTime.utc(2025),
      );
      final updated = model.copyWith(buyPrice: 1600000, sellPrice: 1580000);
      expect(updated.buyPrice, 1600000);
      expect(updated.sellPrice, 1580000);
      expect(updated.source, 'antaremas');
    });
  });

  group('GoldPriceModel roundtrip', () {
    test('toFullMap → fromMap produces equivalent model', () {
      final original = GoldPriceModel(
        id: 'rt-1',
        source: 'logammulia',
        buyPrice: 1550000,
        sellPrice: 1530000,
        fetchedAt: DateTime.utc(2025, 6, 15, 10, 30),
      );
      final restored = GoldPriceModel.fromMap(original.toFullMap());
      expect(restored.id, original.id);
      expect(restored.source, original.source);
      expect(restored.buyPrice, original.buyPrice);
      expect(restored.sellPrice, original.sellPrice);
      expect(restored.fetchedAt, original.fetchedAt);
    });
  });
}
