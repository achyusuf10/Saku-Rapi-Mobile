import 'package:app_saku_rapi/global/widgets/calculator_keyboard/saku_math_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SakuMathFormatter', () {
    const formatter = SakuMathFormatter();

    TextEditingValue format(String oldText, String newText, {int? cursor}) {
      final oldValue = TextEditingValue(
        text: oldText,
        selection: TextSelection.collapsed(offset: oldText.length),
      );
      final newValue = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursor ?? newText.length),
      );
      return formatter.formatEditUpdate(oldValue, newValue);
    }

    group('Basic Number Formatting', () {
      test('should format single digit', () {
        final result = format('', '1');
        expect(result.text, '1');
      });

      test('should add thousand separator', () {
        final result = format('', '1000');
        expect(result.text, '1.000');
      });

      test('should format larger numbers', () {
        final result = format('', '1500000');
        expect(result.text, '1.500.000');
      });

      test('should handle empty input', () {
        final result = format('1.000', '');
        expect(result.text, '');
      });
    });

    group('Operator Formatting', () {
      test('should add space before + operator', () {
        final result = format('1.000', '1.000+');
        // Formatter trims trailing space, so we expect space before operator
        expect(result.text, '1.000 +');
      });

      test('should add space before - operator (subtraction)', () {
        final result = format('1.000', '1.000-');
        expect(result.text, '1.000 -');
      });

      test('should add space before × operator', () {
        final result = format('1.000', '1.000×');
        expect(result.text, '1.000 ×');
      });

      test('should add space before ÷ operator', () {
        final result = format('1.000', '1.000÷');
        expect(result.text, '1.000 ÷');
      });
    });

    group('Negative Numbers', () {
      test('should handle leading minus (negative number)', () {
        final result = format('', '-');
        expect(result.text, '-');
      });

      test('should format negative number', () {
        final result = format('-', '-500');
        expect(result.text, '-500');
      });

      test('should handle negative number after operator', () {
        final result = format('1.000 + ', '1.000 + -');
        expect(result.text, '1.000 + -');
      });

      test('should handle complete expression with negative', () {
        final result = format('1.000 + -', '1.000 + -500');
        expect(result.text, '1.000 + -500');
      });
    });

    group('Expression Formatting', () {
      test('should format both operands', () {
        final result = format('1.000 + ', '1.000 + 500');
        expect(result.text, '1.000 + 500');
      });

      test('should format larger second operand', () {
        final result = format('1.000 + ', '1.000 + 5000');
        expect(result.text, '1.000 + 5.000');
      });

      test('should handle multiple operators', () {
        final result = format('1.000 + 500', '1.000 + 500 - ');
        // Depending on implementation
        expect(result.text.contains('+'), true);
        expect(result.text.contains('-'), true);
      });
    });

    group('Decimal Handling', () {
      test('should keep decimal comma', () {
        final result = format('1.000', '1.000,');
        expect(result.text.contains(','), true);
      });

      test('should format number with decimal', () {
        final result = format('1.000,', '1.000,5');
        expect(result.text, '1.000,5');
      });

      test('should format complete decimal number', () {
        final result = format('1.000,5', '1.000,50');
        expect(result.text, '1.000,50');
      });
    });

    group('Cursor Position', () {
      test('should place cursor at end after formatting', () {
        final result = format('', '1000');
        expect(result.selection.baseOffset, result.text.length);
      });

      test('should adjust cursor after adding separator', () {
        final result = format('100', '1000', cursor: 4);
        // Cursor should be at proper position in formatted text
        expect(
          result.selection.baseOffset,
          lessThanOrEqualTo(result.text.length),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle multiple consecutive spaces', () {
        final result = format('1.000  +  ', '1.000  +  500');
        // Should normalize spaces
        expect(result.text.contains('  '), false);
      });

      test('should handle 000 input', () {
        final result = format('1', '1000');
        expect(result.text, '1.000');
      });
    });
  });

  group('CalculatorInputValidator', () {
    const validator = CalculatorInputValidator();

    group('canInsert - Empty Field', () {
      test('should allow digit at start', () {
        expect(validator.canInsert('1', ''), true);
        expect(validator.canInsert('5', ''), true);
        expect(validator.canInsert('0', ''), true);
      });

      test('should allow minus at start (negative number)', () {
        expect(validator.canInsert('-', ''), true);
      });

      test('should block + at start', () {
        expect(validator.canInsert('+', ''), false);
      });

      test('should block × at start', () {
        expect(validator.canInsert('×', ''), false);
      });

      test('should block ÷ at start', () {
        expect(validator.canInsert('÷', ''), false);
      });

      test('should block 000 at start', () {
        expect(validator.canInsert('000', ''), false);
      });

      test('should block decimal at start', () {
        expect(validator.canInsert(',', ''), false);
      });
    });

    group('canInsert - After Digit', () {
      test('should allow digit after digit', () {
        expect(validator.canInsert('5', '100'), true);
      });

      test('should allow operator after digit', () {
        expect(validator.canInsert('+', '100'), true);
        expect(validator.canInsert('-', '100'), true);
        expect(validator.canInsert('×', '100'), true);
        expect(validator.canInsert('÷', '100'), true);
      });

      test('should allow 000 after digit', () {
        expect(validator.canInsert('000', '1'), true);
      });

      test('should allow decimal after digit', () {
        expect(validator.canInsert(',', '100'), true);
      });
    });

    group('canInsert - After Operator', () {
      test('should allow digit after operator', () {
        expect(validator.canInsert('5', '100 + '), true);
      });

      test('should allow minus after operator (negative)', () {
        expect(validator.canInsert('-', '100 + '), true);
      });

      test('should block + after +', () {
        expect(validator.canInsert('+', '100 + '), false);
      });

      test('should block × after +', () {
        expect(validator.canInsert('×', '100 + '), false);
      });

      test('should block double minus', () {
        expect(validator.canInsert('-', '100 - '), false);
      });

      test('should block 000 after operator', () {
        expect(validator.canInsert('000', '100 + '), false);
      });

      test('should block decimal after operator', () {
        expect(validator.canInsert(',', '100 + '), false);
      });
    });

    group('canInsert - Double Decimal', () {
      test('should block second decimal in same segment', () {
        expect(validator.canInsert(',', '100,5'), false);
      });

      test('should allow decimal in new segment after operator', () {
        expect(validator.canInsert(',', '100,5 + 50'), true);
      });
    });

    group('handleConsecutiveOperator', () {
      test('should replace + with ×', () {
        final result = validator.handleConsecutiveOperator(' × ', '100 + ');
        expect(result, isNotNull);
        expect(result!.contains('×'), true);
        expect(result.contains('+'), false);
      });

      test('should replace - with +', () {
        final result = validator.handleConsecutiveOperator(' + ', '100 - ');
        expect(result, isNotNull);
        expect(result!.contains('+'), true);
      });

      test('should allow minus after + (negative number)', () {
        final result = validator.handleConsecutiveOperator(' - ', '100 + ');
        // Should append minus for negative, not replace
        expect(result!.endsWith('-'), true);
      });

      test('should return null for non-operator', () {
        final result = validator.handleConsecutiveOperator('5', '100 + ');
        expect(result, isNull);
      });

      test('should return null for digit at end', () {
        final result = validator.handleConsecutiveOperator(' + ', '100');
        expect(result, isNull);
      });
    });
  });
}
