import 'package:app_saku_rapi/features/ocr/models/ocr_parse_result_model.dart';
import 'package:app_saku_rapi/features/voice/models/voice_parse_result_model.dart';
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
