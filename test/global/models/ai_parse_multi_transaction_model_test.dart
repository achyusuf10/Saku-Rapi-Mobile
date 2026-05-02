import 'package:app_saku_rapi/features/ocr/models/ocr_parse_result_model.dart';
import 'package:app_saku_rapi/features/voice/models/voice_parse_result_model.dart';
import 'package:app_saku_rapi/global/models/ai_parse_line_item.dart';
import 'package:app_saku_rapi/global/models/ai_parse_transaction_slice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceParseResultModel multi-transaction', () {
    test('fromEdgeFunctionMap parses transactions when length > 1', () {
      final m = VoiceParseResultModel.fromEdgeFunctionMap({
        'data': {
          'isTransaction': true,
          'type': 'expense',
          'amount': 45000,
          'items': <dynamic>[],
          'transactions': [
            {
              'amount': 15000,
              'items': <dynamic>[],
              'categoryId': 'cat-a',
              'categoryKeyword': 'makan',
              'suggestedWalletId': 'wallet-a',
            },
            {
              'amount': 30000,
              'items': <dynamic>[],
              'categoryId': 'cat-b',
              'categoryKeyword': 'transport',
              'suggestedWalletId': 'wallet-b',
            },
          ],
        },
      });
      expect(m.isAiMultiTransaction, isTrue);
      expect(m.aiTransactions, hasLength(2));
      expect(m.aiTransactions![0].effectiveTotal, 15000);
      expect(m.aiTransactions![1].effectiveTotal, 30000);
      expect(m.aiTransactions![0].suggestedWalletId, 'wallet-a');
      expect(m.aiTransactions![1].suggestedWalletId, 'wallet-b');
      expect(m.hasUsableData, isTrue);
    });

    test('ignores transactions when only one element', () {
      final m = VoiceParseResultModel.fromEdgeFunctionMap({
        'data': {
          'isTransaction': true,
          'type': 'expense',
          'amount': 10000,
          'transactions': [
            {'amount': 10000, 'items': <dynamic>[]},
          ],
        },
      });
      expect(m.isAiMultiTransaction, isFalse);
      expect(m.aiTransactions, isNull);
    });
  });

  group('Discount line items (negative amounts)', () {
    test('VoiceItemModel preserves negative subtotal from JSON', () {
      final item = VoiceItemModel.fromMap({
        'name': 'Diskon',
        'qty': 1,
        'unitPrice': -5000,
        'subtotal': -5000,
      });
      expect(item.subtotal, -5000);
      expect(item.unitPrice, -5000);
    });

    test('OcrItemModel preserves negative subtotal when only amount field set', () {
      final item = OcrItemModel.fromMap({
        'name': 'Diskon member',
        'qty': 1,
        'amount': -5000,
      });
      expect(item.subtotal, -5000);
    });

    test('AiParseTransactionSlice.effectiveTotal sums discounts', () {
      final slice = AiParseTransactionSlice.fromMap({
        'amount': 99999,
        'items': [
          {'name': 'Latte', 'qty': 1, 'unitPrice': 35000, 'subtotal': 35000},
          {'name': 'Diskon', 'qty': 1, 'unitPrice': -5000, 'subtotal': -5000},
        ],
      });
      expect(slice.effectiveTotal, 30000);
    });

    test('AiParseLineItem.fromMap supports negative subtotal', () {
      final line = AiParseLineItem.fromMap({
        'name': 'Potongan',
        'qty': 1,
        'subtotal': -12000,
      });
      expect(line.subtotal, -12000);
    });

    test('VoiceParseResultModel includes discount in itemsTotal', () {
      final m = VoiceParseResultModel.fromEdgeFunctionMap({
        'data': {
          'isTransaction': true,
          'type': 'expense',
          'amount': 450000,
          'items': [
            {
              'name': 'Sepatu',
              'qty': 1,
              'unitPrice': 500000,
              'subtotal': 500000,
            },
            {
              'name': 'Diskon',
              'qty': 1,
              'unitPrice': -50000,
              'subtotal': -50000,
            },
          ],
          'categoryKeyword': 'belanja',
        },
      });
      expect(m.itemsTotal, 450000);
      expect(m.hasUsableData, isTrue);
    });
  });

  group('OcrParseResultModel multi-transaction', () {
    test('fromEdgeFunctionMap parses transactions when length > 1', () {
      final m = OcrParseResultModel.fromEdgeFunctionMap({
        'data': {
          'isTransaction': true,
          'type': 'expense',
          'grandTotal': 45000,
          'items': <dynamic>[],
          'transactions': [
            {'amount': 20000, 'items': <dynamic>[], 'categoryKeyword': 'a'},
            {'amount': 25000, 'items': <dynamic>[], 'categoryKeyword': 'b'},
          ],
        },
      });
      expect(m.isAiMultiTransaction, isTrue);
      expect(m.aiTransactions, hasLength(2));
      expect(m.hasUsableData, isTrue);
    });
  });
}
