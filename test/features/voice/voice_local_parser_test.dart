import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/features/voice/models/parsing_dictionary_model.dart';
import 'package:app_saku_rapi/features/voice/models/voice_parse_result_model.dart';
import 'package:app_saku_rapi/features/voice/services/voice_local_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ══════════════════════════════════════════════════
  // Amount extraction
  // ══════════════════════════════════════════════════

  group('VoiceLocalParser — Amount extraction', () {
    test('parses "25rb" → 25000', () {
      final result = VoiceLocalParser.parse('beli kopi 25rb');
      expect(result.amount, 25000.0);
    });

    test('parses "25 ribu" → 25000', () {
      final result = VoiceLocalParser.parse('makan 25 ribu');
      expect(result.amount, 25000.0);
    });

    test('parses "1.5jt" → 1500000', () {
      final result = VoiceLocalParser.parse('bayar cicilan 1.5jt');
      expect(result.amount, 1500000.0);
    });

    test('parses "2jt" → 2000000', () {
      final result = VoiceLocalParser.parse('gaji masuk 2jt');
      expect(result.amount, 2000000.0);
    });

    test('parses "1,5 juta" → 1500000', () {
      final result = VoiceLocalParser.parse('transfer 1,5 juta');
      expect(result.amount, 1500000.0);
    });

    test('parses "150000" plain number → 150000', () {
      final result = VoiceLocalParser.parse('belanja 150000');
      expect(result.amount, 150000.0);
    });

    test('parses "150.000" dot-separated → 150000', () {
      final result = VoiceLocalParser.parse('belanja 150.000');
      expect(result.amount, 150000.0);
    });

    test('returns null when no amount found', () {
      final result = VoiceLocalParser.parse('beli kopi');
      expect(result.amount, isNull);
    });
  });

  // ══════════════════════════════════════════════════
  // Type detection
  // ══════════════════════════════════════════════════

  group('VoiceLocalParser — Type detection', () {
    test('detects expense by default', () {
      final result = VoiceLocalParser.parse('beli makan 25rb');
      expect(result.type, TransactionTypeEnum.expense);
    });

    test('detects income from "gaji"', () {
      final result = VoiceLocalParser.parse('gaji masuk 5jt');
      expect(result.type, TransactionTypeEnum.income);
    });

    test('detects income from "bonus"', () {
      final result = VoiceLocalParser.parse('bonus akhir tahun 2jt');
      expect(result.type, TransactionTypeEnum.income);
    });

    test('detects income from "terima"', () {
      final result = VoiceLocalParser.parse('terima uang 500rb');
      expect(result.type, TransactionTypeEnum.income);
    });

    test('detects income from "dapat"', () {
      final result = VoiceLocalParser.parse('dapat dividen 100rb');
      expect(result.type, TransactionTypeEnum.income);
    });
  });

  // ══════════════════════════════════════════════════
  // Dictionary matching
  // ══════════════════════════════════════════════════

  group('VoiceLocalParser — Dictionary matching', () {
    final dictionaries = [
      const ParsingDictionaryModel(
        id: '1',
        keyword: 'makan',
        categoryId: 'cat-food',
      ),
      const ParsingDictionaryModel(
        id: '2',
        keyword: 'ojol',
        categoryId: 'cat-transport',
      ),
      const ParsingDictionaryModel(
        id: '3',
        keyword: 'gaji',
        categoryId: 'cat-salary',
      ),
    ];

    test('matches keyword "makan" → cat-food', () {
      final result = VoiceLocalParser.parse(
        'makan siang 25rb',
        dictionaries: dictionaries,
      );
      expect(result.categoryKeyword, 'makan');
    });

    test('matches keyword "ojol" → cat-transport', () {
      final result = VoiceLocalParser.parse(
        'ojol ke kantor 15rb',
        dictionaries: dictionaries,
      );
      expect(result.categoryKeyword, 'ojol');
    });

    test('returns null when no keyword matches', () {
      final result = VoiceLocalParser.parse(
        'beli buku 50rb',
        dictionaries: dictionaries,
      );
      expect(result.categoryKeyword, isNull);
    });

    test('returns null with empty dictionaries', () {
      final result = VoiceLocalParser.parse('makan siang 25rb');
      expect(result.categoryKeyword, isNull);
    });
  });

  // ══════════════════════════════════════════════════
  // Provider info
  // ══════════════════════════════════════════════════

  group('VoiceLocalParser — Provider', () {
    test('provider is "local"', () {
      final result = VoiceLocalParser.parse('test');
      expect(result.provider, 'local');
    });

    test('rawTranscript preserves original text', () {
      final result = VoiceLocalParser.parse('Beli kopi 25RB');
      expect(result.rawTranscript, 'Beli kopi 25RB');
    });
  });

  // ══════════════════════════════════════════════════
  // VoiceParseResultModel
  // ══════════════════════════════════════════════════

  group('VoiceParseResultModel', () {
    test('fromEdgeFunctionMap parses voice response', () {
      final json = {
        'success': true,
        'mode': 'voice',
        'provider': 'gemini',
        'data': {
          'amount': 25000,
          'categoryKeyword': 'makan',
          'note': 'kopi kenangan',
          'type': 'expense',
        },
      };

      final result = VoiceParseResultModel.fromEdgeFunctionMap(json);
      expect(result.amount, 25000.0);
      expect(result.categoryKeyword, 'makan');
      expect(result.note, 'kopi kenangan');
      expect(result.type, TransactionTypeEnum.expense);
      expect(result.provider, 'gemini');
    });

    test('fromEdgeFunctionMap handles income type', () {
      final json = {
        'data': {
          'amount': 5000000,
          'categoryKeyword': 'gaji',
          'note': 'gaji bulanan',
          'type': 'income',
        },
        'provider': 'groq',
      };

      final result = VoiceParseResultModel.fromEdgeFunctionMap(json);
      expect(result.type, TransactionTypeEnum.income);
      expect(result.provider, 'groq');
    });

    test('fromEdgeFunctionMap handles null amount', () {
      final json = {
        'data': {
          'amount': null,
          'categoryKeyword': 'makan',
          'note': 'beli kopi',
          'type': 'expense',
        },
      };

      final result = VoiceParseResultModel.fromEdgeFunctionMap(json);
      expect(result.amount, isNull);
    });

    test('fromLocal creates model with local provider', () {
      final result = VoiceParseResultModel.fromLocal(
        amount: 25000,
        categoryKeyword: 'makan',
        note: 'kopi',
        rawTranscript: 'beli kopi 25rb',
      );

      expect(result.provider, 'local');
      expect(result.rawTranscript, 'beli kopi 25rb');
    });

    test('copyWith overrides fields', () {
      const original = VoiceParseResultModel(
        amount: 25000,
        categoryKeyword: 'makan',
      );

      final copy = original.copyWith(amount: 50000);
      expect(copy.amount, 50000.0);
      expect(copy.categoryKeyword, 'makan');
    });

    test('toMap and toString output correctly', () {
      const model = VoiceParseResultModel(
        amount: 25000,
        categoryKeyword: 'makan',
        note: 'kopi',
        provider: 'gemini',
      );

      final map = model.toMap();
      expect(map['amount'], 25000.0);
      expect(map['categoryKeyword'], 'makan');
      expect(map['type'], 'expense');
      expect(model.toString(), contains('VoiceParseResultModel'));
    });
  });
}
