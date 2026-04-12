import 'package:app_saku_rapi/features/investment/models/investment_asset_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper factory untuk membuat [InvestmentAssetModel] minimal.
InvestmentAssetModel _asset({
  String id = 'asset-1',
  String userId = 'u1',
  InvestmentType type = InvestmentType.gold,
  String name = 'Emas Antam',
  String? goldType = 'antam',
  String? customGoldTypeId,
  String? customCategoryId,
  String unitLabel = 'Gram',
  String priceSource = 'antaremas',
  double currentPrice = 1500000,
  bool isActive = true,
  double totalBuyUnits = 10,
  double totalSellUnits = 2,
  double totalUnits = 8,
  double totalInvested = 12000000,
  double totalFee = 50000,
  double avgBuyPrice = 1200000,
  int transactionsCount = 5,
}) {
  return InvestmentAssetModel(
    id: id,
    userId: userId,
    type: type,
    name: name,
    goldType: goldType,
    customGoldTypeId: customGoldTypeId,
    customCategoryId: customCategoryId,
    unitLabel: unitLabel,
    priceSource: priceSource,
    currentPrice: currentPrice,
    isActive: isActive,
    totalBuyUnits: totalBuyUnits,
    totalSellUnits: totalSellUnits,
    totalUnits: totalUnits,
    totalInvested: totalInvested,
    totalFee: totalFee,
    avgBuyPrice: avgBuyPrice,
    transactionsCount: transactionsCount,
  );
}

void main() {
  // ─── InvestmentType tests ───

  group('InvestmentType', () {
    test('fromString parses gold', () {
      expect(InvestmentType.fromString('gold'), InvestmentType.gold);
    });

    test('fromString parses bitcoin', () {
      expect(InvestmentType.fromString('bitcoin'), InvestmentType.bitcoin);
    });

    test('fromString parses custom', () {
      expect(InvestmentType.fromString('custom'), InvestmentType.custom);
    });

    test('fromString defaults to custom for unknown', () {
      expect(InvestmentType.fromString('stocks'), InvestmentType.custom);
      expect(InvestmentType.fromString(''), InvestmentType.custom);
    });
  });

  // ─── Computed properties ───

  group('InvestmentAssetModel computed properties', () {
    test('currentValue = totalUnits * currentPrice', () {
      final asset = _asset(totalUnits: 5, currentPrice: 1500000);
      expect(asset.currentValue, 7500000);
    });

    test('profitLoss = currentValue - totalInvested', () {
      final asset = _asset(
        totalUnits: 5,
        currentPrice: 1500000,
        totalInvested: 6000000,
      );
      // currentValue = 7500000, profitLoss = 1500000
      expect(asset.profitLoss, 1500000);
    });

    test('profitLoss is negative when losing', () {
      final asset = _asset(
        totalUnits: 5,
        currentPrice: 1000000,
        totalInvested: 6000000,
      );
      // currentValue = 5000000, profitLoss = -1000000
      expect(asset.profitLoss, -1000000);
    });

    test('profitLossPercent = profitLoss / totalInvested', () {
      final asset = _asset(
        totalUnits: 5,
        currentPrice: 1500000,
        totalInvested: 6000000,
      );
      // profitLoss = 1500000, percent = 0.25
      expect(asset.profitLossPercent, 0.25);
    });

    test('profitLossPercent returns 0 when totalInvested is 0', () {
      final asset = _asset(
        totalUnits: 5,
        currentPrice: 1500000,
        totalInvested: 0,
      );
      expect(asset.profitLossPercent, 0);
    });

    test('currentValue is 0 when totalUnits is 0', () {
      final asset = _asset(totalUnits: 0, currentPrice: 1500000);
      expect(asset.currentValue, 0);
    });
  });

  // ─── fromMap ───

  group('InvestmentAssetModel.fromMap', () {
    test('parses complete map correctly', () {
      final map = {
        'id': 'asset-abc',
        'user_id': 'user-123',
        'type': 'gold',
        'name': 'Emas Antam 1gr',
        'gold_type': 'antam',
        'custom_gold_type_id': null,
        'custom_category_id': null,
        'unit_label': 'Gram',
        'price_source': 'antaremas',
        'current_price': 1500000,
        'is_active': true,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-01T00:00:00.000Z',
        'total_buy_units': 10.5,
        'total_sell_units': 2.0,
        'total_units': 8.5,
        'total_invested': 12000000,
        'total_fee': 50000,
        'avg_buy_price': 1200000,
        'transactions_count': 5,
      };

      final asset = InvestmentAssetModel.fromMap(map);

      expect(asset.id, 'asset-abc');
      expect(asset.userId, 'user-123');
      expect(asset.type, InvestmentType.gold);
      expect(asset.name, 'Emas Antam 1gr');
      expect(asset.goldType, 'antam');
      expect(asset.customGoldTypeId, isNull);
      expect(asset.customCategoryId, isNull);
      expect(asset.unitLabel, 'Gram');
      expect(asset.priceSource, 'antaremas');
      expect(asset.currentPrice, 1500000);
      expect(asset.isActive, true);
      expect(asset.createdAt?.toUtc(), DateTime.utc(2025));
      expect(asset.totalBuyUnits, 10.5);
      expect(asset.totalSellUnits, 2.0);
      expect(asset.totalUnits, 8.5);
      expect(asset.totalInvested, 12000000);
      expect(asset.totalFee, 50000);
      expect(asset.avgBuyPrice, 1200000);
      expect(asset.transactionsCount, 5);
    });

    test('handles integer numeric values', () {
      final map = {
        'id': 'a1',
        'user_id': 'u1',
        'type': 'bitcoin',
        'name': 'BTC',
        'current_price': 1500000000, // int
        'total_units': 1, // int
        'total_invested': 1000000000, // int
      };

      final asset = InvestmentAssetModel.fromMap(map);
      expect(asset.currentPrice, 1500000000.0);
      expect(asset.totalUnits, 1.0);
      expect(asset.totalInvested, 1000000000.0);
    });

    test('handles string numeric values', () {
      final map = {
        'id': 'a1',
        'user_id': 'u1',
        'type': 'gold',
        'name': 'Gold',
        'current_price': '1500000.50',
        'total_units': '8.5',
      };

      final asset = InvestmentAssetModel.fromMap(map);
      expect(asset.currentPrice, 1500000.50);
      expect(asset.totalUnits, 8.5);
    });

    test('defaults for missing nullable/optional fields', () {
      final map = {'id': 'a1', 'type': 'custom', 'name': 'Saham'};

      final asset = InvestmentAssetModel.fromMap(map);
      expect(asset.userId, '');
      expect(asset.goldType, isNull);
      expect(asset.unitLabel, 'unit');
      expect(asset.priceSource, 'manual');
      expect(asset.currentPrice, 0);
      expect(asset.isActive, true);
      expect(asset.totalBuyUnits, 0);
      expect(asset.totalSellUnits, 0);
      expect(asset.totalUnits, 0);
      expect(asset.totalInvested, 0);
      expect(asset.totalFee, 0);
      expect(asset.avgBuyPrice, 0);
      expect(asset.transactionsCount, 0);
    });

    test('parses bitcoin type correctly', () {
      final map = {
        'id': 'btc-1',
        'user_id': 'u1',
        'type': 'bitcoin',
        'name': 'BTC',
        'price_source': 'indodax',
        'current_price': 1500000000.0,
      };

      final asset = InvestmentAssetModel.fromMap(map);
      expect(asset.type, InvestmentType.bitcoin);
      expect(asset.priceSource, 'indodax');
    });

    test('parses custom type with category', () {
      final map = {
        'id': 'custom-1',
        'user_id': 'u1',
        'type': 'custom',
        'name': 'Saham BBCA',
        'custom_category_id': 'cat-1',
        'unit_label': 'Lot',
        'price_source': 'manual',
        'current_price': 10000,
      };

      final asset = InvestmentAssetModel.fromMap(map);
      expect(asset.type, InvestmentType.custom);
      expect(asset.customCategoryId, 'cat-1');
      expect(asset.unitLabel, 'Lot');
    });
  });

  // ─── toInsertMap ───

  group('InvestmentAssetModel.toInsertMap', () {
    test('contains required insert fields', () {
      final asset = _asset();
      final map = asset.toInsertMap();

      expect(map['user_id'], 'u1');
      expect(map['type'], 'gold');
      expect(map['name'], 'Emas Antam');
      expect(map['gold_type'], 'antam');
      expect(map['unit_label'], 'Gram');
      expect(map['price_source'], 'antaremas');
      expect(map['current_price'], 1500000);
    });

    test('does not contain id or aggregated fields', () {
      final map = _asset().toInsertMap();

      expect(map.containsKey('id'), false);
      expect(map.containsKey('is_active'), false);
      expect(map.containsKey('total_units'), false);
      expect(map.containsKey('total_invested'), false);
    });
  });

  // ─── toUpdateMap ───

  group('InvestmentAssetModel.toUpdateMap', () {
    test('contains updatable fields', () {
      final map = _asset().toUpdateMap();

      expect(map['name'], 'Emas Antam');
      expect(map['gold_type'], 'antam');
      expect(map['unit_label'], 'Gram');
      expect(map['price_source'], 'antaremas');
      expect(map['current_price'], 1500000);
    });

    test('does not contain id, user_id, or type', () {
      final map = _asset().toUpdateMap();

      expect(map.containsKey('id'), false);
      expect(map.containsKey('user_id'), false);
      expect(map.containsKey('type'), false);
    });
  });

  // ─── toFullMap ───

  group('InvestmentAssetModel.toFullMap', () {
    test('contains all fields including aggregated', () {
      final asset = _asset();
      final map = asset.toFullMap();

      expect(map['id'], 'asset-1');
      expect(map['user_id'], 'u1');
      expect(map['type'], 'gold');
      expect(map['total_units'], 8);
      expect(map['total_invested'], 12000000);
      expect(map['transactions_count'], 5);
      expect(map['is_active'], true);
    });
  });

  // ─── copyWith ───

  group('InvestmentAssetModel.copyWith', () {
    test('returns identical model when no args', () {
      final asset = _asset();
      final copy = asset.copyWith();

      expect(copy.id, asset.id);
      expect(copy.name, asset.name);
      expect(copy.type, asset.type);
      expect(copy.currentPrice, asset.currentPrice);
    });

    test('updates specified fields only', () {
      final asset = _asset();
      final updated = asset.copyWith(name: 'Emas Baru', currentPrice: 2000000);

      expect(updated.name, 'Emas Baru');
      expect(updated.currentPrice, 2000000);
      expect(updated.id, asset.id); // unchanged
      expect(updated.type, asset.type); // unchanged
    });

    test('can change type', () {
      final asset = _asset(type: InvestmentType.gold);
      final updated = asset.copyWith(type: InvestmentType.bitcoin);
      expect(updated.type, InvestmentType.bitcoin);
    });

    test('can update aggregated fields', () {
      final asset = _asset();
      final updated = asset.copyWith(
        totalUnits: 100,
        totalInvested: 50000000,
        transactionsCount: 20,
      );

      expect(updated.totalUnits, 100);
      expect(updated.totalInvested, 50000000);
      expect(updated.transactionsCount, 20);
    });
  });

  // ─── Roundtrip ───

  group('InvestmentAssetModel roundtrip', () {
    test('toFullMap → fromMap produces equivalent model', () {
      final original = _asset(
        id: 'rt-1',
        name: 'BTC',
        type: InvestmentType.bitcoin,
        currentPrice: 1500000000,
        totalUnits: 0.5,
        totalInvested: 500000000,
      );

      final map = original.toFullMap();
      final restored = InvestmentAssetModel.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.currentPrice, original.currentPrice);
      expect(restored.totalUnits, original.totalUnits);
      expect(restored.totalInvested, original.totalInvested);
    });
  });
}
