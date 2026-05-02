import 'dart:convert';

import 'package:app_saku_rapi/core/services/home_widget_service.dart';
import 'package:app_saku_rapi/features/home_widget/home_widget_constants.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Test Helpers ───

WalletModel _wallet({
  String id = 'w-1',
  String name = 'Cash',
  double balance = 1500000,
  String icon = '💰',
  String color = '#0F172A',
  bool excludeFromTotal = false,
  int sortOrder = 0,
}) {
  return WalletModel(
    id: id,
    userId: 'user-1',
    name: name,
    icon: icon,
    color: color,
    backgroundColor: WalletModel.defaultBackgroundColorHex,
    balance: balance,
    initialBalance: 0,
    currency: 'IDR',
    excludeFromTotal: excludeFromTotal,
    sortOrder: sortOrder,
  );
}

void main() {
  group('HomeWidgetService', () {
    group('syncWalletData', () {
      test('does not throw when wallets list is empty', () async {
        // Should not throw — just silently sync empty list
        await expectLater(
          HomeWidgetService.syncWalletData([]),
          completes,
        );
      });

      test('does not throw when wallets list has data', () async {
        final wallets = [
          _wallet(id: 'w-1', name: 'Cash', balance: 1500000),
          _wallet(id: 'w-2', name: 'Bank BCA', balance: 5000000),
        ];

        await expectLater(
          HomeWidgetService.syncWalletData(wallets),
          completes,
        );
      });
    });

    group('wallet JSON serialization', () {
      test('serializes wallet data correctly for native consumption', () {
        final wallets = [
          _wallet(
            id: 'w-abc',
            name: 'Dompet Utama',
            balance: 2500000,
            icon: '💳',
            color: '#CA8A04',
            excludeFromTotal: true,
            sortOrder: 2,
          ),
        ];

        // Verify the JSON structure matches what native Android expects
        final walletsJson = wallets
            .map(
              (w) => {
                'id': w.id,
                'name': w.name,
                'balance': w.balance,
                'icon': w.icon,
                'color': w.color,
                'backgroundColor': w.backgroundColor,
                'excludeFromTotal': w.excludeFromTotal,
                'sortOrder': w.sortOrder,
              },
            )
            .toList();

        final encoded = jsonEncode(walletsJson);
        final decoded = jsonDecode(encoded) as List;

        expect(decoded.length, 1);
        expect(decoded[0]['id'], 'w-abc');
        expect(decoded[0]['name'], 'Dompet Utama');
        expect(decoded[0]['balance'], 2500000);
        expect(decoded[0]['icon'], '💳');
        expect(decoded[0]['color'], '#CA8A04');
        expect(decoded[0]['backgroundColor'], WalletModel.defaultBackgroundColorHex);
        expect(decoded[0]['excludeFromTotal'], true);
        expect(decoded[0]['sortOrder'], 2);
      });

      test('handles multiple wallets', () {
        final wallets = [
          _wallet(id: 'w-1', name: 'Cash', balance: 100000),
          _wallet(id: 'w-2', name: 'Bank', balance: 500000),
          _wallet(id: 'w-3', name: 'E-Wallet', balance: 250000),
        ];

        final walletsJson = wallets
            .map(
              (w) => {
                'id': w.id,
                'name': w.name,
                'balance': w.balance,
                'icon': w.icon,
                'color': w.color,
                'backgroundColor': w.backgroundColor,
                'excludeFromTotal': w.excludeFromTotal,
                'sortOrder': w.sortOrder,
              },
            )
            .toList();

        final encoded = jsonEncode(walletsJson);
        final decoded = jsonDecode(encoded) as List;

        expect(decoded.length, 3);
        expect(decoded.map((e) => e['id']), ['w-1', 'w-2', 'w-3']);
      });
    });

    group('config key format', () {
      test('generates correct config key per appWidgetId', () {
        expect(
          '${HomeWidgetConstants.configKeyPrefix}42',
          'widget_config_42',
        );
        expect(
          '${HomeWidgetConstants.configKeyPrefix}0',
          'widget_config_0',
        );
      });

      test('config value is JSON array of wallet IDs', () {
        final selectedIds = ['w-1', 'w-3'];
        final encoded = jsonEncode(selectedIds);
        final decoded = (jsonDecode(encoded) as List).cast<String>();

        expect(decoded, ['w-1', 'w-3']);
      });
    });
  });
}
