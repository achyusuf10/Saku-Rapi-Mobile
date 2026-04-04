import 'package:app_saku_rapi/features/investment/controllers/investment_controller.dart';
import 'package:app_saku_rapi/features/investment/models/investment_asset_model.dart';
import 'package:app_saku_rapi/features/investment/models/investment_transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper factory for [InvestmentAssetModel].
InvestmentAssetModel _asset({
  String id = 'asset-1',
  InvestmentType type = InvestmentType.gold,
  String name = 'Emas Antam',
  double totalUnits = 8,
  double totalInvested = 12000000,
  double currentPrice = 1500000,
  bool isActive = true,
  int transactionsCount = 5,
}) {
  return InvestmentAssetModel(
    id: id,
    userId: 'u1',
    type: type,
    name: name,
    unitLabel: type == InvestmentType.gold
        ? 'Gram'
        : type == InvestmentType.bitcoin
        ? 'BTC'
        : 'Unit',
    priceSource: 'manual',
    currentPrice: currentPrice,
    isActive: isActive,
    totalUnits: totalUnits,
    totalInvested: totalInvested,
    transactionsCount: transactionsCount,
  );
}

/// Helper factory for [InvestmentTransactionModel].
InvestmentTransactionModel _tx({
  String id = 'tx-1',
  String assetId = 'asset-1',
  String direction = 'buy',
  double units = 5,
  double pricePerUnit = 1500000,
  double fee = 0,
}) {
  return InvestmentTransactionModel(
    id: id,
    assetId: assetId,
    userId: 'u1',
    direction: direction,
    units: units,
    pricePerUnit: pricePerUnit,
    fee: fee,
    deductWallet: false,
    date: DateTime(2025, 7, 1),
  );
}

void main() {
  // ═══════════════════════════════════════════════════════════════
  // InvestmentState tests
  // ═══════════════════════════════════════════════════════════════

  group('InvestmentState', () {
    test('default state has expected initial values', () {
      const state = InvestmentState();
      expect(state.status, InvestmentStatus.initial);
      expect(state.assets, isEmpty);
      expect(state.errorMessage, isNull);
    });

    test('copyWith returns new state with updated fields', () {
      const state = InvestmentState();
      final updated = state.copyWith(
        status: InvestmentStatus.loaded,
        assets: [_asset()],
      );

      expect(updated.status, InvestmentStatus.loaded);
      expect(updated.assets, hasLength(1));
    });

    test('copyWith without args returns identical state', () {
      const state = InvestmentState(status: InvestmentStatus.loaded);
      final copy = state.copyWith();
      expect(copy.status, InvestmentStatus.loaded);
    });

    test('copyWith clears errorMessage when not provided', () {
      final state = const InvestmentState().copyWith(
        errorMessage: 'Network error',
      );
      expect(state.errorMessage, 'Network error');

      final cleared = state.copyWith(status: InvestmentStatus.loaded);
      expect(cleared.errorMessage, isNull);
    });
  });

  // ─── activeAssets / inactiveAssets ───

  group('InvestmentState.activeAssets / inactiveAssets', () {
    test('activeAssets returns only active assets', () {
      final assets = [
        _asset(id: 'a1', isActive: true),
        _asset(id: 'a2', isActive: false),
        _asset(id: 'a3', isActive: true),
      ];

      final state = InvestmentState(
        status: InvestmentStatus.loaded,
        assets: assets,
      );

      expect(state.activeAssets, hasLength(2));
      expect(state.activeAssets.map((a) => a.id), ['a1', 'a3']);
    });

    test('inactiveAssets returns only inactive assets', () {
      final assets = [
        _asset(id: 'a1', isActive: true),
        _asset(id: 'a2', isActive: false),
      ];

      final state = InvestmentState(
        status: InvestmentStatus.loaded,
        assets: assets,
      );

      expect(state.inactiveAssets, hasLength(1));
      expect(state.inactiveAssets.first.id, 'a2');
    });

    test('returns empty lists when no assets', () {
      const state = InvestmentState(status: InvestmentStatus.loaded);
      expect(state.activeAssets, isEmpty);
      expect(state.inactiveAssets, isEmpty);
    });
  });

  // ─── groupedActiveAssets ───

  group('InvestmentState.groupedActiveAssets', () {
    test('groups active assets by type', () {
      final assets = [
        _asset(id: 'a1', type: InvestmentType.gold),
        _asset(id: 'a2', type: InvestmentType.gold),
        _asset(id: 'a3', type: InvestmentType.bitcoin),
        _asset(id: 'a4', type: InvestmentType.custom),
        _asset(id: 'a5', type: InvestmentType.gold, isActive: false),
      ];

      final state = InvestmentState(
        status: InvestmentStatus.loaded,
        assets: assets,
      );

      final grouped = state.groupedActiveAssets;
      expect(grouped[InvestmentType.gold], hasLength(2));
      expect(grouped[InvestmentType.bitcoin], hasLength(1));
      expect(grouped[InvestmentType.custom], hasLength(1));
    });

    test('does not include types with zero active assets', () {
      final assets = [_asset(id: 'a1', type: InvestmentType.gold)];

      final state = InvestmentState(
        status: InvestmentStatus.loaded,
        assets: assets,
      );

      final grouped = state.groupedActiveAssets;
      expect(grouped.containsKey(InvestmentType.gold), true);
      expect(grouped.containsKey(InvestmentType.bitcoin), false);
      expect(grouped.containsKey(InvestmentType.custom), false);
    });

    test('returns empty map when no active assets', () {
      final state = InvestmentState(
        status: InvestmentStatus.loaded,
        assets: [_asset(isActive: false)],
      );
      expect(state.groupedActiveAssets, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // InvestmentTransactionsState tests
  // ═══════════════════════════════════════════════════════════════

  group('InvestmentTransactionsState', () {
    test('default state has expected initial values', () {
      const state = InvestmentTransactionsState();
      expect(state.status, InvestmentStatus.initial);
      expect(state.buyTransactions, isEmpty);
      expect(state.sellTransactions, isEmpty);
      expect(state.errorMessage, isNull);
    });

    test('copyWith updates buyTransactions', () {
      final buys = [
        _tx(id: 'tx-1', direction: 'buy'),
        _tx(id: 'tx-2', direction: 'buy'),
      ];

      final state = const InvestmentTransactionsState().copyWith(
        status: InvestmentStatus.loaded,
        buyTransactions: buys,
      );

      expect(state.buyTransactions, hasLength(2));
      expect(state.sellTransactions, isEmpty);
    });

    test('copyWith updates sellTransactions', () {
      final sells = [_tx(id: 'tx-1', direction: 'sell')];

      final state = const InvestmentTransactionsState().copyWith(
        status: InvestmentStatus.loaded,
        sellTransactions: sells,
      );

      expect(state.sellTransactions, hasLength(1));
      expect(state.buyTransactions, isEmpty);
    });

    test('copyWith preserves existing values when partial update', () {
      final buys = [_tx(id: 'b1', direction: 'buy')];
      final sells = [_tx(id: 's1', direction: 'sell')];

      final state = InvestmentTransactionsState(
        status: InvestmentStatus.loaded,
        buyTransactions: buys,
        sellTransactions: sells,
      );

      final updated = state.copyWith(status: InvestmentStatus.loading);
      expect(updated.status, InvestmentStatus.loading);
      expect(updated.buyTransactions, hasLength(1));
      expect(updated.sellTransactions, hasLength(1));
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Portfolio aggregate tests (business logic)
  // ═══════════════════════════════════════════════════════════════

  group('Portfolio aggregate calculations', () {
    test('total portfolio value sums all active assets', () {
      final assets = [
        _asset(id: 'a1', totalUnits: 10, currentPrice: 1500000, isActive: true),
        _asset(
          id: 'a2',
          totalUnits: 0.5,
          currentPrice: 1500000000,
          isActive: true,
        ),
        _asset(id: 'a3', totalUnits: 5, currentPrice: 1000000, isActive: false),
      ];

      final state = InvestmentState(
        status: InvestmentStatus.loaded,
        assets: assets,
      );

      final totalValue = state.activeAssets.fold(
        0.0,
        (sum, a) => sum + a.currentValue,
      );

      // a1: 15000000 + a2: 750000000 = 765000000
      expect(totalValue, 765000000);
    });

    test('total invested sums all active assets', () {
      final assets = [
        _asset(id: 'a1', totalInvested: 12000000, isActive: true),
        _asset(id: 'a2', totalInvested: 500000000, isActive: true),
      ];

      final state = InvestmentState(
        status: InvestmentStatus.loaded,
        assets: assets,
      );

      final totalInvested = state.activeAssets.fold(
        0.0,
        (sum, a) => sum + a.totalInvested,
      );

      expect(totalInvested, 512000000);
    });

    test('portfolio P&L is total value minus total invested', () {
      final assets = [
        _asset(
          id: 'a1',
          totalUnits: 10,
          currentPrice: 1600000,
          totalInvested: 15000000,
          isActive: true,
        ),
      ];

      final state = InvestmentState(
        status: InvestmentStatus.loaded,
        assets: assets,
      );

      final totalValue = state.activeAssets.fold(
        0.0,
        (sum, a) => sum + a.currentValue,
      );
      final totalInvested = state.activeAssets.fold(
        0.0,
        (sum, a) => sum + a.totalInvested,
      );

      // value: 16000000, invested: 15000000, P&L: 1000000
      expect(totalValue - totalInvested, 1000000);
    });
  });
}
