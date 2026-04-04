import 'package:app_saku_rapi/features/investment/models/investment_transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper factory untuk membuat [InvestmentTransactionModel] minimal.
InvestmentTransactionModel _tx({
  String id = 'tx-1',
  String assetId = 'asset-1',
  String userId = 'u1',
  String direction = 'buy',
  double units = 5,
  double pricePerUnit = 1500000,
  double fee = 10000,
  String? walletId,
  bool deductWallet = false,
  String? linkedWalletTransactionId,
  DateTime? date,
  String? note,
}) {
  return InvestmentTransactionModel(
    id: id,
    assetId: assetId,
    userId: userId,
    direction: direction,
    units: units,
    pricePerUnit: pricePerUnit,
    fee: fee,
    walletId: walletId,
    deductWallet: deductWallet,
    linkedWalletTransactionId: linkedWalletTransactionId,
    date: date ?? DateTime(2025, 7, 1),
    note: note,
  );
}

void main() {
  // ─── Computed properties ───

  group('InvestmentTransactionModel computed', () {
    test('totalValue = units * pricePerUnit', () {
      final tx = _tx(units: 5, pricePerUnit: 1500000);
      expect(tx.totalValue, 7500000);
    });

    test('totalCost = totalValue + fee', () {
      final tx = _tx(units: 5, pricePerUnit: 1500000, fee: 50000);
      expect(tx.totalCost, 7550000);
    });

    test('totalCost equals totalValue when fee is 0', () {
      final tx = _tx(units: 3, pricePerUnit: 1000000, fee: 0);
      expect(tx.totalCost, tx.totalValue);
    });

    test('isBuy returns true for buy direction', () {
      expect(_tx(direction: 'buy').isBuy, true);
      expect(_tx(direction: 'buy').isSell, false);
    });

    test('isSell returns true for sell direction', () {
      expect(_tx(direction: 'sell').isSell, true);
      expect(_tx(direction: 'sell').isBuy, false);
    });

    test('handles fractional units (BTC)', () {
      final tx = _tx(units: 0.00150000, pricePerUnit: 1500000000);
      expect(tx.totalValue, closeTo(2250000, 0.01));
    });
  });

  // ─── fromMap ───

  group('InvestmentTransactionModel.fromMap', () {
    test('parses complete map correctly', () {
      final map = {
        'id': 'tx-abc',
        'asset_id': 'asset-123',
        'user_id': 'user-1',
        'direction': 'buy',
        'units': 5.0,
        'price_per_unit': 1500000.0,
        'fee': 10000.0,
        'wallet_id': 'w-1',
        'deduct_wallet': true,
        'linked_wallet_transaction_id': 'wt-1',
        'date': '2025-07-01T00:00:00.000Z',
        'note': 'First purchase',
        'created_at': '2025-07-01T00:00:00.000Z',
      };

      final tx = InvestmentTransactionModel.fromMap(map);

      expect(tx.id, 'tx-abc');
      expect(tx.assetId, 'asset-123');
      expect(tx.userId, 'user-1');
      expect(tx.direction, 'buy');
      expect(tx.units, 5.0);
      expect(tx.pricePerUnit, 1500000.0);
      expect(tx.fee, 10000.0);
      expect(tx.walletId, 'w-1');
      expect(tx.deductWallet, true);
      expect(tx.linkedWalletTransactionId, 'wt-1');
      expect(tx.note, 'First purchase');
      expect(tx.createdAt, DateTime.utc(2025, 7, 1));
    });

    test('handles integer numeric values', () {
      final map = {
        'id': 'tx-1',
        'asset_id': 'a1',
        'direction': 'sell',
        'units': 3, // int
        'price_per_unit': 2000000, // int
        'fee': 5000, // int
        'date': '2025-07-01T00:00:00.000Z',
      };

      final tx = InvestmentTransactionModel.fromMap(map);
      expect(tx.units, 3.0);
      expect(tx.pricePerUnit, 2000000.0);
      expect(tx.fee, 5000.0);
    });

    test('handles string numeric values', () {
      final map = {
        'id': 'tx-1',
        'asset_id': 'a1',
        'direction': 'buy',
        'units': '0.5',
        'price_per_unit': '1500000.50',
        'fee': '0',
        'date': '2025-07-01T00:00:00.000Z',
      };

      final tx = InvestmentTransactionModel.fromMap(map);
      expect(tx.units, 0.5);
      expect(tx.pricePerUnit, 1500000.50);
      expect(tx.fee, 0.0);
    });

    test('defaults for missing nullable fields', () {
      final map = {
        'id': 'tx-1',
        'asset_id': 'a1',
        'direction': 'buy',
        'units': 1.0,
        'price_per_unit': 1500000.0,
      };

      final tx = InvestmentTransactionModel.fromMap(map);
      expect(tx.userId, '');
      expect(tx.fee, 0.0);
      expect(tx.walletId, isNull);
      expect(tx.deductWallet, false);
      expect(tx.linkedWalletTransactionId, isNull);
      expect(tx.note, isNull);
      expect(tx.createdAt, isNull);
    });
  });

  // ─── toFullMap ───

  group('InvestmentTransactionModel.toFullMap', () {
    test('contains all fields', () {
      final tx = _tx(walletId: 'w-1', deductWallet: true, note: 'Test note');
      final map = tx.toFullMap();

      expect(map['id'], 'tx-1');
      expect(map['asset_id'], 'asset-1');
      expect(map['user_id'], 'u1');
      expect(map['direction'], 'buy');
      expect(map['units'], 5.0);
      expect(map['price_per_unit'], 1500000.0);
      expect(map['fee'], 10000.0);
      expect(map['wallet_id'], 'w-1');
      expect(map['deduct_wallet'], true);
      expect(map['note'], 'Test note');
    });
  });

  // ─── copyWith ───

  group('InvestmentTransactionModel.copyWith', () {
    test('returns identical model when no args', () {
      final tx = _tx();
      final copy = tx.copyWith();

      expect(copy.id, tx.id);
      expect(copy.direction, tx.direction);
      expect(copy.units, tx.units);
      expect(copy.pricePerUnit, tx.pricePerUnit);
    });

    test('updates specified fields only', () {
      final tx = _tx(units: 5, pricePerUnit: 1500000);
      final updated = tx.copyWith(units: 10, pricePerUnit: 1600000);

      expect(updated.units, 10);
      expect(updated.pricePerUnit, 1600000);
      expect(updated.id, tx.id); // unchanged
      expect(updated.direction, tx.direction); // unchanged
    });

    test('can change direction', () {
      final tx = _tx(direction: 'buy');
      final updated = tx.copyWith(direction: 'sell');
      expect(updated.isSell, true);
    });

    test('can set wallet fields', () {
      final tx = _tx(walletId: null, deductWallet: false);
      final updated = tx.copyWith(walletId: 'w-1', deductWallet: true);

      expect(updated.walletId, 'w-1');
      expect(updated.deductWallet, true);
    });
  });

  // ─── Roundtrip ───

  group('InvestmentTransactionModel roundtrip', () {
    test('toFullMap → fromMap produces equivalent model', () {
      final original = _tx(
        id: 'rt-1',
        direction: 'sell',
        units: 0.001,
        pricePerUnit: 1500000000,
        fee: 0,
        walletId: 'w-1',
        deductWallet: true,
        note: 'Sell BTC',
      );

      final map = original.toFullMap();
      final restored = InvestmentTransactionModel.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.direction, original.direction);
      expect(restored.units, original.units);
      expect(restored.pricePerUnit, original.pricePerUnit);
      expect(restored.fee, original.fee);
      expect(restored.walletId, original.walletId);
      expect(restored.deductWallet, original.deductWallet);
      expect(restored.note, original.note);
    });
  });
}
