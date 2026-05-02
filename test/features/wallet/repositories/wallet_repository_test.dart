import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/features/wallet/repositories/wallet_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper factory untuk membuat [WalletModel] minimal.
WalletModel _wallet({
  String id = 'w1',
  String name = 'Mandiri',
  double balance = 100000,
  bool excludeFromTotal = false,
}) {
  return WalletModel(
    id: id,
    userId: 'u1',
    name: name,
    icon: 'wallet',
    color: '#10B981',
    backgroundColor: WalletModel.defaultBackgroundColorHex,
    balance: balance,
    initialBalance: balance,
    currency: 'IDR',
    excludeFromTotal: excludeFromTotal,
    sortOrder: 0,
  );
}

void main() {
  group('WalletRepository.calculateTotalBalance', () {
    test('returns 0 for empty list', () {
      expect(WalletRepository.calculateTotalBalance([]), 0.0);
    });

    test('sums only non-excluded wallets', () {
      final wallets = [
        _wallet(id: 'w1', balance: 100000),
        _wallet(id: 'w2', balance: 200000, excludeFromTotal: true),
        _wallet(id: 'w3', balance: 50000),
      ];

      final total = WalletRepository.calculateTotalBalance(wallets);
      expect(total, 150000.0);
    });

    test('returns 0 when all wallets are excluded', () {
      final wallets = [
        _wallet(id: 'w1', balance: 100000, excludeFromTotal: true),
        _wallet(id: 'w2', balance: 200000, excludeFromTotal: true),
      ];

      final total = WalletRepository.calculateTotalBalance(wallets);
      expect(total, 0.0);
    });

    test('handles single wallet', () {
      final wallets = [_wallet(id: 'w1', balance: 500000)];

      expect(WalletRepository.calculateTotalBalance(wallets), 500000.0);
    });

    test('handles negative balances correctly', () {
      final wallets = [
        _wallet(id: 'w1', balance: 100000),
        _wallet(id: 'w2', balance: -30000),
      ];

      expect(WalletRepository.calculateTotalBalance(wallets), 70000.0);
    });
  });

  group('WalletModel', () {
    test('fromMap parses correctly', () {
      final map = {
        'id': 'abc-123',
        'user_id': 'user-1',
        'name': 'BCA',
        'icon': 'wallet',
        'color': '#10B981',
        'balance': 500000,
        'initial_balance': 500000,
        'currency': 'IDR',
        'exclude_from_total': false,
        'sort_order': 1,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-01T00:00:00.000Z',
      };

      final wallet = WalletModel.fromMap(map);

      expect(wallet.id, 'abc-123');
      expect(wallet.userId, 'user-1');
      expect(wallet.name, 'BCA');
      expect(wallet.balance, 500000.0);
      expect(wallet.initialBalance, 500000.0);
      expect(wallet.excludeFromTotal, false);
      expect(wallet.sortOrder, 1);
      expect(wallet.backgroundColor, WalletModel.defaultBackgroundColorHex);
    });

    test('fromMap uses explicit background_color', () {
      final map = {
        'id': 'abc-123',
        'user_id': 'user-1',
        'name': 'BCA',
        'icon': 'wallet',
        'color': '#10B981',
        'background_color': '#FF0000',
        'balance': 0,
        'initial_balance': 0,
        'currency': 'IDR',
        'exclude_from_total': false,
        'sort_order': 0,
      };
      final wallet = WalletModel.fromMap(map);
      expect(wallet.backgroundColor, '#FF0000');
    });

    test('toInsertMap sets balance = initialBalance', () {
      final wallet = _wallet(balance: 250000);
      final map = wallet.toInsertMap();

      expect(map['balance'], 250000.0);
      expect(map['initial_balance'], 250000.0);
      expect(map['background_color'], WalletModel.defaultBackgroundColorHex);
      expect(map.containsKey('id'), false);
    });

    test('toUpdateMap does not include balance fields', () {
      final wallet = _wallet();
      final map = wallet.toUpdateMap();

      expect(map.containsKey('balance'), false);
      expect(map.containsKey('initial_balance'), false);
      expect(map.containsKey('name'), true);
      expect(map['background_color'], WalletModel.defaultBackgroundColorHex);
    });

    test('copyWith creates modified copy', () {
      final wallet = _wallet(name: 'Old Name');
      final updated = wallet.copyWith(name: 'New Name');

      expect(updated.name, 'New Name');
      expect(updated.id, wallet.id);
      expect(updated.balance, wallet.balance);
    });

    test('fromMap handles numeric types from Supabase', () {
      final map = {
        'id': 'w1',
        'user_id': 'u1',
        'name': 'Cash',
        'icon': 'wallet',
        'color': '#000',
        'balance': '250000.50', // String from DB numeric type
        'initial_balance': 250000, // int from DB
        'currency': 'IDR',
        'exclude_from_total': false,
        'sort_order': 0,
        'created_at': null,
        'updated_at': null,
      };

      final wallet = WalletModel.fromMap(map);
      expect(wallet.balance, 250000.50);
      expect(wallet.initialBalance, 250000.0);
    });
  });
}
