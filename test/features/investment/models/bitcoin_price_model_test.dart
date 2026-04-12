import 'package:app_saku_rapi/features/investment/models/bitcoin_price_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BitcoinPriceModel.fromMap', () {
    test('parses complete map', () {
      final map = {
        'id': 'bp-1',
        'source': 'indodax',
        'price_idr': 1500000000.0,
        'fetched_at': '2025-07-01T12:00:00.000Z',
      };

      final model = BitcoinPriceModel.fromMap(map);
      expect(model.id, 'bp-1');
      expect(model.source, 'indodax');
      expect(model.priceIdr, 1500000000.0);
      expect(model.fetchedAt.toUtc(), DateTime.utc(2025, 7, 1, 12));
    });

    test('handles integer price', () {
      final map = {
        'id': 'bp-2',
        'source': 'coingecko',
        'price_idr': 1500000000,
        'fetched_at': '2025-07-01T12:00:00.000Z',
      };

      final model = BitcoinPriceModel.fromMap(map);
      expect(model.priceIdr, 1500000000.0);
    });

    test('handles string price', () {
      final map = {
        'id': 'bp-3',
        'source': 'indodax',
        'price_idr': '1500000000.50',
        'fetched_at': '2025-07-01T12:00:00.000Z',
      };

      final model = BitcoinPriceModel.fromMap(map);
      expect(model.priceIdr, 1500000000.50);
    });

    test('defaults to 0 for null price', () {
      final map = {
        'id': 'bp-4',
        'source': 'indodax',
        'price_idr': null,
        'fetched_at': '2025-07-01T12:00:00.000Z',
      };

      final model = BitcoinPriceModel.fromMap(map);
      expect(model.priceIdr, 0);
    });
  });

  group('BitcoinPriceModel.toFullMap', () {
    test('contains all fields', () {
      final now = DateTime.utc(2025, 7, 1);
      final model = BitcoinPriceModel(
        id: 'bp-1',
        source: 'indodax',
        priceIdr: 1500000000,
        fetchedAt: now,
      );
      final map = model.toFullMap();

      expect(map['id'], 'bp-1');
      expect(map['source'], 'indodax');
      expect(map['price_idr'], 1500000000);
      expect(map['fetched_at'], now.toIso8601String());
    });
  });

  group('BitcoinPriceModel.copyWith', () {
    test('returns identical when no args', () {
      final model = BitcoinPriceModel(
        id: 'bp-1',
        source: 'indodax',
        priceIdr: 1500000000,
        fetchedAt: DateTime.utc(2025),
      );
      final copy = model.copyWith();
      expect(copy.id, model.id);
      expect(copy.priceIdr, model.priceIdr);
    });

    test('updates specified fields', () {
      final model = BitcoinPriceModel(
        id: 'bp-1',
        source: 'indodax',
        priceIdr: 1500000000,
        fetchedAt: DateTime.utc(2025),
      );
      final updated = model.copyWith(priceIdr: 1600000000, source: 'coingecko');
      expect(updated.priceIdr, 1600000000);
      expect(updated.source, 'coingecko');
      expect(updated.id, 'bp-1');
    });
  });

  group('BitcoinPriceModel roundtrip', () {
    test('toFullMap → fromMap produces equivalent model', () {
      final original = BitcoinPriceModel(
        id: 'rt-1',
        source: 'coingecko',
        priceIdr: 1450000000,
        fetchedAt: DateTime.utc(2025, 6, 15, 10, 30),
      );
      final restored = BitcoinPriceModel.fromMap(original.toFullMap());
      expect(restored.id, original.id);
      expect(restored.source, original.source);
      expect(restored.priceIdr, original.priceIdr);
      expect(restored.fetchedAt.toUtc(), original.fetchedAt.toUtc());
    });
  });
}
