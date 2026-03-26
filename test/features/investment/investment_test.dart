import 'package:app_saku_rapi/features/investment/controllers/investment_controller.dart';
import 'package:app_saku_rapi/features/investment/models/investment_model.dart';
import 'package:app_saku_rapi/features/investment/repositories/investment_repository.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Helpers ───

InvestmentModel _inv({
  String id = 'inv-1',
  String type = 'gold',
  String name = 'Emas Antam',
  double amount = 10,
  double avgBuyPrice = 1000000,
  double? customCurrentPrice,
  double? livePricePerUnit,
  String? symbol,
  String? linkedWalletId,
  String? notes,
}) => InvestmentModel(
  id: id,
  userId: 'u1',
  type: type,
  name: name,
  symbol: symbol,
  amount: amount,
  avgBuyPrice: avgBuyPrice,
  customCurrentPrice: customCurrentPrice,
  linkedWalletId: linkedWalletId,
  notes: notes,
  livePricePerUnit: livePricePerUnit,
);

WalletModel _wallet({String id = 'w1', double balance = 50000000}) =>
    WalletModel(
      id: id,
      userId: 'u1',
      name: 'Mandiri',
      icon: 'wallet',
      color: '#10B981',
      balance: balance,
      initialBalance: balance,
      currency: 'IDR',
      excludeFromTotal: false,
      sortOrder: 0,
    );

void main() {
  // ═══════════════════════════════════════════════
  // InvestmentModel
  // ═══════════════════════════════════════════════

  group('InvestmentModel', () {
    group('fromMap', () {
      test('parses full map correctly', () {
        final map = {
          'id': 'inv-1',
          'user_id': 'u1',
          'type': 'gold',
          'name': 'Emas Antam',
          'symbol': 'XAU',
          'amount': 10.0,
          'avg_buy_price': 1000000,
          'custom_current_price': 1200000.0,
          'linked_wallet_id': 'w1',
          'notes': 'test notes',
          'created_at': '2025-01-01T00:00:00.000Z',
          'updated_at': '2025-01-02T00:00:00.000Z',
        };

        final model = InvestmentModel.fromMap(map);

        expect(model.id, 'inv-1');
        expect(model.userId, 'u1');
        expect(model.type, 'gold');
        expect(model.name, 'Emas Antam');
        expect(model.symbol, 'XAU');
        expect(model.amount, 10.0);
        expect(model.avgBuyPrice, 1000000);
        expect(model.customCurrentPrice, 1200000.0);
        expect(model.linkedWalletId, 'w1');
        expect(model.notes, 'test notes');
        expect(model.createdAt, isNotNull);
        expect(model.updatedAt, isNotNull);
      });

      test('handles null optional fields', () {
        final map = {
          'id': 'inv-1',
          'user_id': 'u1',
          'type': 'crypto',
          'name': 'Bitcoin',
          'amount': 0.5,
          'avg_buy_price': 500000000,
        };

        final model = InvestmentModel.fromMap(map);

        expect(model.symbol, isNull);
        expect(model.customCurrentPrice, isNull);
        expect(model.linkedWalletId, isNull);
        expect(model.notes, isNull);
      });

      test('parses integer amount as double', () {
        final map = {
          'id': 'inv-1',
          'user_id': 'u1',
          'type': 'gold',
          'name': 'Gold',
          'amount': 5,
          'avg_buy_price': 1000000,
        };

        final model = InvestmentModel.fromMap(map);
        expect(model.amount, 5.0);
        expect(model.avgBuyPrice, 1000000.0);
      });

      test('parses string amount as double', () {
        final map = {
          'id': 'inv-1',
          'user_id': 'u1',
          'type': 'gold',
          'name': 'Gold',
          'amount': '3.5',
          'avg_buy_price': '900000',
        };

        final model = InvestmentModel.fromMap(map);
        expect(model.amount, 3.5);
        expect(model.avgBuyPrice, 900000.0);
      });

      test('extracts wallet name from joined data', () {
        final map = {
          'id': 'inv-1',
          'user_id': 'u1',
          'type': 'gold',
          'name': 'Gold',
          'amount': 1,
          'avg_buy_price': 1000000,
          'wallets': {'name': 'Mandiri'},
        };

        final model = InvestmentModel.fromMap(map);
        expect(model.walletName, 'Mandiri');
      });
    });

    group('computed properties', () {
      test('currentPrice uses customCurrentPrice when available', () {
        final inv = _inv(avgBuyPrice: 1000000, customCurrentPrice: 1200000);
        expect(inv.currentPrice, 1200000);
      });

      test('currentPrice falls back to avgBuyPrice', () {
        final inv = _inv(avgBuyPrice: 1000000);
        expect(inv.currentPrice, 1000000);
      });

      test('currentPrice prioritizes livePricePerUnit over custom', () {
        final inv = _inv(
          avgBuyPrice: 1000000,
          customCurrentPrice: 1200000,
          livePricePerUnit: 1500000,
        );
        expect(inv.currentPrice, 1500000);
        expect(inv.hasLivePrice, true);
      });

      test('currentPrice uses livePricePerUnit over avgBuyPrice', () {
        final inv = _inv(avgBuyPrice: 1000000, livePricePerUnit: 1300000);
        expect(inv.currentPrice, 1300000);
      });

      test('hasLivePrice false when no live price', () {
        final inv = _inv(avgBuyPrice: 1000000);
        expect(inv.hasLivePrice, false);
      });

      test('currentValue calculates correctly', () {
        final inv = _inv(amount: 5, customCurrentPrice: 1500000);
        expect(inv.currentValue, 7500000);
      });

      test('investedValue calculates correctly', () {
        final inv = _inv(amount: 5, avgBuyPrice: 1000000);
        expect(inv.investedValue, 5000000);
      });

      test('unrealizedPL is positive for profit', () {
        final inv = _inv(
          amount: 10,
          avgBuyPrice: 1000000,
          customCurrentPrice: 1200000,
        );
        expect(inv.unrealizedPL, 2000000);
        expect(inv.isProfit, true);
        expect(inv.isLoss, false);
      });

      test('unrealizedPL is negative for loss', () {
        final inv = _inv(
          amount: 10,
          avgBuyPrice: 1000000,
          customCurrentPrice: 800000,
        );
        expect(inv.unrealizedPL, -2000000);
        expect(inv.isProfit, false);
        expect(inv.isLoss, true);
      });

      test('unrealizedPL is zero when no price change', () {
        final inv = _inv(amount: 10, avgBuyPrice: 1000000);
        expect(inv.unrealizedPL, 0);
        expect(inv.isProfit, false);
        expect(inv.isLoss, false);
      });

      test('unrealizedPLPercent correct', () {
        final inv = _inv(
          amount: 10,
          avgBuyPrice: 1000000,
          customCurrentPrice: 1100000,
        );
        // P/L = 1M, invested = 10M -> 10%
        expect(inv.unrealizedPLPercent, closeTo(0.1, 0.0001));
      });

      test('unrealizedPLPercent is 0 when investedValue is 0', () {
        final inv = _inv(amount: 0, avgBuyPrice: 1000000);
        expect(inv.unrealizedPLPercent, 0);
      });
    });

    group('serialization', () {
      test('toInsertMap excludes id and timestamps', () {
        final inv = _inv(
          type: 'crypto',
          name: 'BTC',
          symbol: 'BTC',
          amount: 0.5,
          avgBuyPrice: 500000000,
        );
        final map = inv.toInsertMap();

        expect(map.containsKey('id'), false);
        expect(map.containsKey('created_at'), false);
        expect(map['user_id'], 'u1');
        expect(map['type'], 'crypto');
        expect(map['name'], 'BTC');
        expect(map['symbol'], 'BTC');
        expect(map['amount'], 0.5);
        expect(map['avg_buy_price'], 500000000);
      });

      test('toUpdateMap excludes id and user_id', () {
        final inv = _inv();
        final map = inv.toUpdateMap();

        expect(map.containsKey('id'), false);
        expect(map.containsKey('user_id'), false);
        expect(map.containsKey('type'), false);
        expect(map['name'], 'Emas Antam');
      });

      test('toFullMap includes all fields', () {
        final inv = _inv(
          symbol: 'XAU',
          customCurrentPrice: 1200000,
          notes: 'test',
        );
        final map = inv.toFullMap();

        expect(map['id'], 'inv-1');
        expect(map['user_id'], 'u1');
        expect(map['type'], 'gold');
        expect(map['name'], 'Emas Antam');
        expect(map['symbol'], 'XAU');
        expect(map['custom_current_price'], 1200000);
        expect(map['notes'], 'test');
      });

      test('round-trip fromMap → toFullMap → fromMap', () {
        final original = _inv(
          symbol: 'XAU',
          customCurrentPrice: 1200000,
          notes: 'round-trip test',
        );
        final reconstructed = InvestmentModel.fromMap(original.toFullMap());

        expect(reconstructed.id, original.id);
        expect(reconstructed.type, original.type);
        expect(reconstructed.name, original.name);
        expect(reconstructed.symbol, original.symbol);
        expect(reconstructed.amount, original.amount);
        expect(reconstructed.avgBuyPrice, original.avgBuyPrice);
        expect(reconstructed.customCurrentPrice, original.customCurrentPrice);
        expect(reconstructed.notes, original.notes);
      });
    });

    group('copyWith', () {
      test('updates specified fields', () {
        final inv = _inv();
        final updated = inv.copyWith(name: 'Gold Bar', amount: 20);

        expect(updated.name, 'Gold Bar');
        expect(updated.amount, 20);
        expect(updated.id, inv.id);
        expect(updated.type, inv.type);
      });

      test('clears nullable fields with clear flags', () {
        final inv = _inv(
          customCurrentPrice: 1200000,
          linkedWalletId: 'w1',
          notes: 'test',
          livePricePerUnit: 1400000,
        );
        final cleared = inv.copyWith(
          clearCustomCurrentPrice: true,
          clearLinkedWalletId: true,
          clearNotes: true,
          clearLivePricePerUnit: true,
        );

        expect(cleared.customCurrentPrice, isNull);
        expect(cleared.linkedWalletId, isNull);
        expect(cleared.notes, isNull);
        expect(cleared.livePricePerUnit, isNull);
      });

      test('copyWith sets livePricePerUnit', () {
        final inv = _inv();
        final updated = inv.copyWith(livePricePerUnit: 1500000);
        expect(updated.livePricePerUnit, 1500000);
        expect(updated.currentPrice, 1500000);
      });
    });
  });

  // ═══════════════════════════════════════════════
  // InvestmentRepository.validateInput
  // ═══════════════════════════════════════════════

  group('InvestmentRepository.validateInput', () {
    test('returns null for valid input without wallet', () {
      final result = InvestmentRepository.validateInput(
        name: 'Emas Antam',
        amount: 10,
        avgBuyPrice: 1000000,
        deductFromWallet: false,
      );
      expect(result, isNull);
    });

    test('returns null for valid input with wallet', () {
      final result = InvestmentRepository.validateInput(
        name: 'Emas Antam',
        amount: 10,
        avgBuyPrice: 1000000,
        deductFromWallet: true,
        walletId: 'w1',
        walletBalance: 50000000,
      );
      expect(result, isNull);
    });

    test('rejects empty name', () {
      final result = InvestmentRepository.validateInput(
        name: '',
        amount: 10,
        avgBuyPrice: 1000000,
        deductFromWallet: false,
      );
      expect(result, isNotNull);
      expect(result, contains('Nama'));
    });

    test('rejects zero amount', () {
      final result = InvestmentRepository.validateInput(
        name: 'Gold',
        amount: 0,
        avgBuyPrice: 1000000,
        deductFromWallet: false,
      );
      expect(result, isNotNull);
    });

    test('rejects negative avgBuyPrice', () {
      final result = InvestmentRepository.validateInput(
        name: 'Gold',
        amount: 10,
        avgBuyPrice: -100,
        deductFromWallet: false,
      );
      expect(result, isNotNull);
    });

    test('rejects deduct without wallet ID', () {
      final result = InvestmentRepository.validateInput(
        name: 'Gold',
        amount: 10,
        avgBuyPrice: 1000000,
        deductFromWallet: true,
        walletId: null,
      );
      expect(result, isNotNull);
      expect(result, contains('dompet'));
    });

    test('rejects insufficient wallet balance', () {
      final result = InvestmentRepository.validateInput(
        name: 'Gold',
        amount: 10,
        avgBuyPrice: 1000000,
        deductFromWallet: true,
        walletId: 'w1',
        walletBalance: 5000000, // costs 10M, only has 5M
      );
      expect(result, isNotNull);
      expect(result, contains('tidak mencukupi'));
    });
  });

  // ═══════════════════════════════════════════════
  // InvestmentRepository.calculatePortfolio
  // ═══════════════════════════════════════════════

  group('InvestmentRepository portfolio calculations', () {
    final investments = [
      _inv(
        id: 'inv-1',
        amount: 10,
        avgBuyPrice: 1000000,
        customCurrentPrice: 1200000,
      ),
      _inv(
        id: 'inv-2',
        type: 'crypto',
        name: 'Bitcoin',
        amount: 0.5,
        avgBuyPrice: 500000000,
        customCurrentPrice: 600000000,
      ),
    ];

    test('calculateTotalValue sums current values', () {
      // 10 * 1.2M = 12M, 0.5 * 600M = 300M => 312M
      final total = InvestmentRepository.calculateTotalValue(investments);
      expect(total, closeTo(312000000, 0.01));
    });

    test('calculateTotalInvested sums invested values', () {
      // 10 * 1M = 10M, 0.5 * 500M = 250M => 260M
      final total = InvestmentRepository.calculateTotalInvested(investments);
      expect(total, closeTo(260000000, 0.01));
    });

    test('calculateTotalPL is positive for profitable portfolio', () {
      final pl = InvestmentRepository.calculateTotalPL(investments);
      expect(pl, closeTo(52000000, 0.01));
    });

    test('calculateTotalPLPercent is correct', () {
      final plPct = InvestmentRepository.calculateTotalPLPercent(investments);
      // 52M / 260M = 0.2 (20%)
      expect(plPct, closeTo(0.2, 0.001));
    });

    test('empty portfolio returns 0 for all', () {
      expect(InvestmentRepository.calculateTotalValue([]), 0);
      expect(InvestmentRepository.calculateTotalInvested([]), 0);
      expect(InvestmentRepository.calculateTotalPL([]), 0);
      expect(InvestmentRepository.calculateTotalPLPercent([]), 0);
    });
  });

  // ═══════════════════════════════════════════════
  // InvestmentFormState
  // ═══════════════════════════════════════════════

  group('InvestmentFormState', () {
    test('estimatedCost calculates correctly', () {
      const state = InvestmentFormState(amount: 10, avgBuyPrice: 1000000);
      expect(state.estimatedCost, 10000000);
    });

    test('isWalletSufficient returns true when not deducting', () {
      const state = InvestmentFormState(
        deductFromWallet: false,
        amount: 100,
        avgBuyPrice: 1000000,
      );
      expect(state.isWalletSufficient, true);
    });

    test('isWalletSufficient returns true when balance sufficient', () {
      final state = InvestmentFormState(
        deductFromWallet: true,
        amount: 10,
        avgBuyPrice: 1000000,
        linkedWallet: _wallet(balance: 50000000),
      );
      expect(state.isWalletSufficient, true);
    });

    test('isWalletSufficient returns false when balance insufficient', () {
      final state = InvestmentFormState(
        deductFromWallet: true,
        amount: 10,
        avgBuyPrice: 1000000,
        linkedWallet: _wallet(balance: 5000000),
      );
      expect(state.isWalletSufficient, false);
    });

    test('isEditing false for new investment', () {
      const state = InvestmentFormState();
      expect(state.isEditing, false);
    });

    test('isEditing true when existingInvestment set', () {
      final state = InvestmentFormState(existingInvestment: _inv());
      expect(state.isEditing, true);
    });

    test('copyWith preserves unmodified fields', () {
      const state = InvestmentFormState(type: 'gold', name: 'Emas', amount: 10);
      final updated = state.copyWith(name: 'Gold Bar');

      expect(updated.name, 'Gold Bar');
      expect(updated.type, 'gold');
      expect(updated.amount, 10);
    });

    test('copyWith clears nullable fields', () {
      final state = InvestmentFormState(
        linkedWallet: _wallet(),
        notes: 'test',
        customCurrentPrice: 1200000,
        errorMessage: 'error',
      );
      final cleared = state.copyWith(
        clearLinkedWallet: true,
        clearNotes: true,
        clearCustomCurrentPrice: true,
        clearError: true,
      );

      expect(cleared.linkedWallet, isNull);
      expect(cleared.notes, isNull);
      expect(cleared.customCurrentPrice, isNull);
      expect(cleared.errorMessage, isNull);
    });
  });

  // ═══════════════════════════════════════════════
  // InvestmentState
  // ═══════════════════════════════════════════════

  group('InvestmentState', () {
    test('isEmpty true when loaded with no investments', () {
      const state = InvestmentState(status: InvestmentStatus.loaded);
      expect(state.isEmpty, true);
    });

    test('isEmpty false when has investments', () {
      final state = InvestmentState(
        status: InvestmentStatus.loaded,
        investments: [_inv()],
      );
      expect(state.isEmpty, false);
    });

    test('isEmpty false when still loading', () {
      const state = InvestmentState(status: InvestmentStatus.loading);
      expect(state.isEmpty, false);
    });

    test('isLoading reflects status', () {
      const loading = InvestmentState(status: InvestmentStatus.loading);
      const loaded = InvestmentState(status: InvestmentStatus.loaded);

      expect(loading.isLoading, true);
      expect(loaded.isLoading, false);
    });

    test('isPriceLoading defaults to false', () {
      const state = InvestmentState();
      expect(state.isPriceLoading, false);
    });

    test('copyWith sets isPriceLoading', () {
      const state = InvestmentState();
      final updated = state.copyWith(isPriceLoading: true);
      expect(updated.isPriceLoading, true);
    });
  });

  // ═══════════════════════════════════════════════
  // Live Price Integration
  // ═══════════════════════════════════════════════

  group('Live price integration', () {
    test('portfolio calculations use live price when available', () {
      final investments = [
        _inv(
          id: 'inv-1',
          amount: 10,
          avgBuyPrice: 1000000,
          livePricePerUnit: 1500000,
        ),
      ];

      // 10 * 1.5M = 15M
      expect(
        InvestmentRepository.calculateTotalValue(investments),
        closeTo(15000000, 0.01),
      );
      // PL = 15M - 10M = 5M
      expect(
        InvestmentRepository.calculateTotalPL(investments),
        closeTo(5000000, 0.01),
      );
    });

    test('live price overrides custom price in calculations', () {
      final inv = _inv(
        amount: 1,
        avgBuyPrice: 1000000,
        customCurrentPrice: 1200000,
        livePricePerUnit: 1800000,
      );

      expect(inv.currentValue, 1800000);
      expect(inv.unrealizedPL, 800000);
    });
  });
}
