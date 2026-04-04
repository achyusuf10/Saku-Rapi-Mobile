import 'package:app_saku_rapi/features/ocr/models/ocr_parse_result_model.dart';
import 'package:app_saku_rapi/features/ocr/repositories/ocr_repository.dart';
import 'package:app_saku_rapi/features/ocr/services/ocr_local_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ══════════════════════════════════════════════════
  // OcrLocalParser — Amount parsing
  // ══════════════════════════════════════════════════

  group('OcrLocalParser — Amount parsing', () {
    test('parses "15.000" → 15000 (Indonesian thousands)', () {
      final result = OcrLocalParser.parse('Kopi Susu 15.000');
      expect(result.items, isNotEmpty);
      expect(result.items.first.subtotal, 15000.0);
    });

    test('parses "150.000" → 150000 (Indonesian thousands)', () {
      final result = OcrLocalParser.parse('Beras 5kg 150.000');
      expect(result.items, isNotEmpty);
      expect(result.items.first.subtotal, 150000.0);
    });

    test('parses "1.500.000" → 1500000 (millions)', () {
      final result = OcrLocalParser.parse('TV LED 1.500.000');
      expect(result.items, isNotEmpty);
      expect(result.items.first.subtotal, 1500000.0);
    });

    test('parses "15.000,00" → 15000 (Indonesian with decimal)', () {
      final result = OcrLocalParser.parse('Kopi Susu 15.000,00');
      expect(result.items, isNotEmpty);
      expect(result.items.first.subtotal, 15000.0);
    });

    test('returns no items for empty text', () {
      final result = OcrLocalParser.parse('');
      expect(result.items, isEmpty);
    });
  });

  // ══════════════════════════════════════════════════
  // OcrLocalParser — Merchant extraction
  // ══════════════════════════════════════════════════

  group('OcrLocalParser — Merchant extraction', () {
    test('extracts first meaningful line as merchant', () {
      final result = OcrLocalParser.parse(
        'INDOMARET\n'
        '23/03/2025 14:30\n'
        'Kopi Susu 15.000\n'
        'TOTAL 15.000',
      );
      expect(result.merchantName, 'INDOMARET');
    });

    test('skips generic headers like STRUK', () {
      final result = OcrLocalParser.parse(
        'STRUK\n'
        'ALFAMART\n'
        'Kopi 15.000\n'
        'TOTAL 15.000',
      );
      expect(result.merchantName, 'ALFAMART');
    });

    test('skips lines starting with date', () {
      final result = OcrLocalParser.parse(
        '23/03/2025\n'
        'TOKO ABC\n'
        'Kopi 15.000\n'
        'TOTAL 15.000',
      );
      expect(result.merchantName, 'TOKO ABC');
    });

    test('returns null when no merchant found', () {
      final result = OcrLocalParser.parse('15.000');
      expect(result.merchantName, isNull);
    });
  });

  // ══════════════════════════════════════════════════
  // OcrLocalParser — Date extraction
  // ══════════════════════════════════════════════════

  group('OcrLocalParser — Date extraction', () {
    test('extracts dd/MM/yyyy format', () {
      final result = OcrLocalParser.parse('TOKO ABC\n23/03/2025\nKopi 15.000');
      expect(result.date, DateTime(2025, 3, 23));
    });

    test('extracts dd-MM-yyyy format', () {
      final result = OcrLocalParser.parse('TOKO ABC\n23-03-2025\nKopi 15.000');
      expect(result.date, DateTime(2025, 3, 23));
    });

    test('extracts dd.MM.yy format with 2-digit year', () {
      final result = OcrLocalParser.parse('TOKO ABC\n23.03.25\nKopi 15.000');
      expect(result.date, DateTime(2025, 3, 23));
    });

    test('returns null for invalid date', () {
      final result = OcrLocalParser.parse('TOKO ABC\n32/13/2025\nKopi 15.000');
      expect(result.date, isNull);
    });

    test('returns null when no date found', () {
      final result = OcrLocalParser.parse('TOKO ABC\nKopi 15.000');
      expect(result.date, isNull);
    });
  });

  // ══════════════════════════════════════════════════
  // OcrLocalParser — Grand total extraction
  // ══════════════════════════════════════════════════

  group('OcrLocalParser — Grand total extraction', () {
    test('extracts TOTAL line amount', () {
      final result = OcrLocalParser.parse(
        'TOKO ABC\n'
        'Kopi 15.000\n'
        'Roti 10.000\n'
        'TOTAL 25.000',
      );
      expect(result.grandTotal, 25000.0);
    });

    test('prefers GRAND TOTAL over TOTAL', () {
      final result = OcrLocalParser.parse(
        'TOKO ABC\n'
        'Kopi 15.000\n'
        'SUBTOTAL 15.000\n'
        'GRAND TOTAL 15.000',
      );
      expect(result.grandTotal, 15000.0);
    });

    test('skips SUBTOTAL lines', () {
      final result = OcrLocalParser.parse(
        'TOKO ABC\n'
        'Kopi 15.000\n'
        'SUBTOTAL 15.000\n',
      );
      // No TOTAL (only SUBTOTAL), should return null
      expect(result.grandTotal, isNull);
    });

    test('returns null when no total found', () {
      final result = OcrLocalParser.parse('TOKO ABC\nKopi 15.000');
      expect(result.grandTotal, isNull);
    });
  });

  // ══════════════════════════════════════════════════
  // OcrLocalParser — Item extraction
  // ══════════════════════════════════════════════════

  group('OcrLocalParser — Item extraction', () {
    test('parses simple item line "Kopi Susu 15.000"', () {
      final result = OcrLocalParser.parse(
        'TOKO ABC\nKopi Susu 15.000\nTOTAL 15.000',
      );
      expect(result.items.length, 1);
      expect(result.items.first.name, 'Kopi Susu');
      expect(result.items.first.subtotal, 15000.0);
    });

    test('parses item with qty "2x @15.000 30.000"', () {
      final result = OcrLocalParser.parse(
        'TOKO ABC\nKopi 2x @15.000 30.000\nTOTAL 30.000',
      );
      expect(result.items, isNotEmpty);
      final item = result.items.first;
      expect(item.qty, 2.0);
      expect(item.subtotal, 30000.0);
    });

    test('skips TOTAL/TUNAI/KEMBALIAN lines', () {
      final result = OcrLocalParser.parse(
        'TOKO ABC\n'
        'Kopi 15.000\n'
        'TOTAL 15.000\n'
        'TUNAI 20.000\n'
        'KEMBALIAN 5.000',
      );
      expect(result.items.length, 1);
      expect(result.items.first.name, 'Kopi');
    });

    test('parses multiple items', () {
      final result = OcrLocalParser.parse(
        'TOKO ABC\n'
        'Kopi Susu 15.000\n'
        'Roti Bakar 10.000\n'
        'Nasi Goreng 25.000\n'
        'TOTAL 50.000',
      );
      expect(result.items.length, 3);
      expect(result.items[0].subtotal, 15000.0);
      expect(result.items[1].subtotal, 10000.0);
      expect(result.items[2].subtotal, 25000.0);
    });
  });

  // ══════════════════════════════════════════════════
  // OcrLocalParser — Full receipt parsing
  // ══════════════════════════════════════════════════

  group('OcrLocalParser — Full receipt', () {
    test('parses typical Indonesian receipt', () {
      final result = OcrLocalParser.parse(
        'INDOMARET\n'
        'Jl. Raya No. 123\n'
        '23/03/2025 14:30:00\n'
        'Kopi Susu 15.000\n'
        'Roti Tawar 12.000\n'
        'TOTAL 27.000',
      );
      expect(result.merchantName, 'INDOMARET');
      expect(result.date, DateTime(2025, 3, 23));
      expect(result.grandTotal, 27000.0);
      expect(result.items.length, greaterThanOrEqualTo(1));
      expect(result.provider, 'local');
    });

    test('sets provider to "local"', () {
      final result = OcrLocalParser.parse('TOKO\nKopi 15.000');
      expect(result.provider, 'local');
    });

    test('preserves rawOcrText', () {
      const text = 'Hello World';
      final result = OcrLocalParser.parse(text);
      expect(result.rawOcrText, text);
    });
  });

  // ══════════════════════════════════════════════════
  // OcrParseResultModel — fromEdgeFunctionMap
  // ══════════════════════════════════════════════════

  group('OcrParseResultModel — fromEdgeFunctionMap', () {
    test('parses new format (qty + unitPrice + subtotal)', () {
      final json = {
        'success': true,
        'provider': 'gemini',
        'data': {
          'merchantName': 'Indomaret',
          'date': '2025-03-23',
          'grandTotal': 45000,
          'items': [
            {'name': 'Kopi', 'qty': 2, 'unitPrice': 15000, 'subtotal': 30000},
            {'name': 'Roti', 'qty': 1, 'unitPrice': 15000, 'subtotal': 15000},
          ],
        },
      };

      final result = OcrParseResultModel.fromEdgeFunctionMap(
        json,
        rawOcrText: 'test',
      );
      expect(result.merchantName, 'Indomaret');
      expect(result.date, DateTime(2025, 3, 23));
      expect(result.grandTotal, 45000.0);
      expect(result.items.length, 2);
      expect(result.items[0].qty, 2.0);
      expect(result.items[0].unitPrice, 15000.0);
      expect(result.items[0].subtotal, 30000.0);
      expect(result.provider, 'gemini');
    });

    test('parses old format (name + amount only)', () {
      final json = {
        'data': {
          'merchantName': 'Toko ABC',
          'date': '2025-01-15',
          'grandTotal': 25000,
          'items': [
            {'name': 'Kopi', 'amount': 15000},
            {'name': 'Roti', 'amount': 10000},
          ],
        },
        'provider': 'groq',
      };

      final result = OcrParseResultModel.fromEdgeFunctionMap(json);
      expect(result.items.length, 2);
      expect(result.items[0].subtotal, 15000.0);
      expect(result.items[0].qty, 1.0);
      expect(result.items[1].subtotal, 10000.0);
      expect(result.provider, 'groq');
    });

    test('handles null/missing fields gracefully', () {
      final json = <String, dynamic>{
        'data': <String, dynamic>{
          'merchantName': null,
          'date': null,
          'grandTotal': null,
          'items': <dynamic>[],
        },
      };

      final result = OcrParseResultModel.fromEdgeFunctionMap(json);
      expect(result.merchantName, isNull);
      expect(result.date, isNull);
      expect(result.grandTotal, isNull);
      expect(result.items, isEmpty);
    });

    test('handles int grandTotal', () {
      final json = {
        'data': {'grandTotal': 15000, 'items': <dynamic>[]},
      };

      final result = OcrParseResultModel.fromEdgeFunctionMap(json);
      expect(result.grandTotal, 15000.0);
    });
  });

  // ══════════════════════════════════════════════════
  // OcrParseResultModel — Computed properties
  // ══════════════════════════════════════════════════

  group('OcrParseResultModel — Computed properties', () {
    test('itemsTotal sums all item subtotals', () {
      final result = OcrParseResultModel(
        items: [
          const OcrItemModel(name: 'A', subtotal: 10000),
          const OcrItemModel(name: 'B', subtotal: 15000),
          const OcrItemModel(name: 'C', subtotal: 5000),
        ],
      );
      expect(result.itemsTotal, 30000.0);
    });

    test('isTotalMatched true when items sum == grandTotal', () {
      final result = OcrParseResultModel(
        grandTotal: 25000,
        items: [
          const OcrItemModel(name: 'A', subtotal: 15000),
          const OcrItemModel(name: 'B', subtotal: 10000),
        ],
      );
      expect(result.isTotalMatched, isTrue);
    });

    test('isTotalMatched false when mismatch > 1', () {
      final result = OcrParseResultModel(
        grandTotal: 30000,
        items: [
          const OcrItemModel(name: 'A', subtotal: 15000),
          const OcrItemModel(name: 'B', subtotal: 10000),
        ],
      );
      expect(result.isTotalMatched, isFalse);
    });

    test('hasUsableData true when grandTotal > 0', () {
      const result = OcrParseResultModel(grandTotal: 100);
      expect(result.hasUsableData, isTrue);
    });

    test('hasUsableData true when items not empty', () {
      final result = OcrParseResultModel(
        items: [const OcrItemModel(name: 'A', subtotal: 100)],
      );
      expect(result.hasUsableData, isTrue);
    });

    test('hasUsableData false when no data', () {
      const result = OcrParseResultModel();
      expect(result.hasUsableData, isFalse);
    });
  });

  // ══════════════════════════════════════════════════
  // OcrParseResultModel — toMap / copyWith
  // ══════════════════════════════════════════════════

  group('OcrParseResultModel — toMap / copyWith', () {
    test('toMap serializes all fields', () {
      final result = OcrParseResultModel(
        merchantName: 'Indomaret',
        date: DateTime(2025, 3, 23),
        grandTotal: 15000,
        items: [const OcrItemModel(name: 'Kopi', subtotal: 15000)],
        provider: 'gemini',
        rawOcrText: 'raw',
      );

      final map = result.toMap();
      expect(map['merchantName'], 'Indomaret');
      expect(map['grandTotal'], 15000.0);
      expect(map['provider'], 'gemini');
      expect((map['items'] as List).length, 1);
    });

    test('copyWith replaces specified fields', () {
      const original = OcrParseResultModel(merchantName: 'A', grandTotal: 100);
      final modified = original.copyWith(merchantName: 'B');
      expect(modified.merchantName, 'B');
      expect(modified.grandTotal, 100.0);
    });
  });

  // ══════════════════════════════════════════════════
  // OcrItemModel — fromMap
  // ══════════════════════════════════════════════════

  group('OcrItemModel — fromMap', () {
    test('parses new format with qty + unitPrice + subtotal', () {
      final item = OcrItemModel.fromMap({
        'name': 'Kopi',
        'qty': 2,
        'unitPrice': 15000,
        'subtotal': 30000,
      });
      expect(item.name, 'Kopi');
      expect(item.qty, 2.0);
      expect(item.unitPrice, 15000.0);
      expect(item.subtotal, 30000.0);
    });

    test('parses old format with amount only', () {
      final item = OcrItemModel.fromMap({'name': 'Kopi', 'amount': 15000});
      expect(item.qty, 1.0);
      expect(item.unitPrice, isNull);
      expect(item.subtotal, 15000.0);
    });

    test('calculates subtotal from qty * unitPrice when subtotal is 0', () {
      final item = OcrItemModel.fromMap({
        'name': 'Kopi',
        'qty': 3,
        'unitPrice': 10000,
        'subtotal': 0,
      });
      expect(item.subtotal, 30000.0);
    });

    test('defaults qty to 1 when null', () {
      final item = OcrItemModel.fromMap({'name': 'Kopi', 'subtotal': 15000});
      expect(item.qty, 1.0);
    });
  });

  // ══════════════════════════════════════════════════
  // OcrRepository.balanceResult
  // ══════════════════════════════════════════════════

  group('OcrRepository — balanceResult', () {
    test('returns unchanged when total matches', () {
      final result = OcrParseResultModel(
        grandTotal: 25000,
        items: [
          const OcrItemModel(name: 'A', subtotal: 15000),
          const OcrItemModel(name: 'B', subtotal: 10000),
        ],
      );

      final balanced = OcrRepository.balanceResult(result);
      expect(balanced.items.length, 2);
    });

    test('adds "Item lainnya" when items sum < grandTotal', () {
      final result = OcrParseResultModel(
        grandTotal: 30000,
        items: [
          const OcrItemModel(name: 'A', subtotal: 15000),
          const OcrItemModel(name: 'B', subtotal: 10000),
        ],
      );

      final balanced = OcrRepository.balanceResult(result);
      expect(balanced.items.length, 3);
      expect(balanced.items.last.name, 'Item lainnya');
      expect(balanced.items.last.subtotal, 5000.0);
    });

    test('adds "Diskon/potongan" when items sum > grandTotal', () {
      final result = OcrParseResultModel(
        grandTotal: 20000,
        items: [
          const OcrItemModel(name: 'A', subtotal: 15000),
          const OcrItemModel(name: 'B', subtotal: 10000),
        ],
      );

      final balanced = OcrRepository.balanceResult(result);
      expect(balanced.items.length, 3);
      expect(balanced.items.last.name, 'Diskon/potongan');
      expect(balanced.items.last.subtotal, -5000.0);
    });

    test('returns unchanged when grandTotal is null', () {
      final result = OcrParseResultModel(
        items: [const OcrItemModel(name: 'A', subtotal: 15000)],
      );

      final balanced = OcrRepository.balanceResult(result);
      expect(balanced.items.length, 1);
    });

    test('returns unchanged when items empty', () {
      const result = OcrParseResultModel(grandTotal: 15000);

      final balanced = OcrRepository.balanceResult(result);
      expect(balanced.items, isEmpty);
    });
  });
}
