import 'package:app_saku_rapi/global/widgets/calculator_keyboard/saku_currency_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SakuCurrencyController', () {
    group('Constructor & Initial Value', () {
      test('should create empty controller when no initial value', () {
        final controller = SakuCurrencyController();
        expect(controller.text, isEmpty);
        expect(controller.numericValue, 0.0);
      });

      test('should format initial value with thousand separator', () {
        final controller = SakuCurrencyController(initialValue: 1500000);
        expect(controller.text, '1.500.000');
      });

      test('should not format zero initial value', () {
        final controller = SakuCurrencyController(initialValue: 0);
        expect(controller.text, isEmpty);
      });

      test('should format negative initial value', () {
        final controller = SakuCurrencyController(initialValue: -500000);
        expect(controller.text, '-500.000');
      });

      test('should format decimal initial value', () {
        final controller = SakuCurrencyController(initialValue: 1500.50);
        expect(controller.text, '1.500,50');
      });
    });

    group('formatNumber', () {
      test('should format integer with thousand separator', () {
        expect(SakuCurrencyController.formatNumber(1000), '1.000');
        expect(SakuCurrencyController.formatNumber(1500000), '1.500.000');
        expect(SakuCurrencyController.formatNumber(100), '100');
      });

      test('should return empty string for zero', () {
        expect(SakuCurrencyController.formatNumber(0), '');
      });

      test('should format negative numbers', () {
        expect(SakuCurrencyController.formatNumber(-1500), '-1.500');
        expect(SakuCurrencyController.formatNumber(-12345678), '-12.345.678');
      });

      test('should format decimal numbers with comma', () {
        expect(SakuCurrencyController.formatNumber(1500.50), '1.500,50');
        expect(SakuCurrencyController.formatNumber(100.99), '100,99');
      });
    });

    group('parseNumber', () {
      test('should parse formatted number', () {
        expect(SakuCurrencyController.parseNumber('1.500.000'), 1500000);
        expect(SakuCurrencyController.parseNumber('100'), 100);
      });

      test('should return 0 for empty string', () {
        expect(SakuCurrencyController.parseNumber(''), 0);
      });

      test('should parse decimal with comma', () {
        expect(SakuCurrencyController.parseNumber('1.500,50'), 1500.50);
      });
    });

    group('hasOperator', () {
      test('should return false for empty text', () {
        final controller = SakuCurrencyController();
        expect(controller.hasOperator, false);
      });

      test('should return false for plain number', () {
        final controller = SakuCurrencyController();
        controller.text = '1.500.000';
        expect(controller.hasOperator, false);
      });

      test('should return true with + operator', () {
        final controller = SakuCurrencyController();
        controller.setRawText('1.000 + 500');
        expect(controller.hasOperator, true);
      });

      test('should return true with - operator (subtraction)', () {
        final controller = SakuCurrencyController();
        controller.setRawText('1.000 - 500');
        expect(controller.hasOperator, true);
      });

      test('should return true with × operator', () {
        final controller = SakuCurrencyController();
        controller.setRawText('1.000 × 2');
        expect(controller.hasOperator, true);
      });

      test('should return true with ÷ operator', () {
        final controller = SakuCurrencyController();
        controller.setRawText('1.000 ÷ 2');
        expect(controller.hasOperator, true);
      });

      test('should return false for leading minus (negative number)', () {
        final controller = SakuCurrencyController();
        controller.text = '-500';
        expect(controller.hasOperator, false);
      });
    });

    group('numericValue - Basic', () {
      test('should return 0 for empty text', () {
        final controller = SakuCurrencyController();
        expect(controller.numericValue, 0.0);
      });

      test('should parse plain number', () {
        final controller = SakuCurrencyController();
        controller.text = '1.500.000';
        expect(controller.numericValue, 1500000.0);
      });

      test('should parse negative number', () {
        final controller = SakuCurrencyController();
        controller.text = '-500';
        expect(controller.numericValue, -500.0);
      });
    });

    group('numericValue - Addition', () {
      test('should evaluate simple addition', () {
        final controller = SakuCurrencyController();
        controller.text = '1.000 + 500';
        expect(controller.numericValue, 1500.0);
      });

      test('should evaluate addition with formatted numbers', () {
        final controller = SakuCurrencyController();
        controller.text = '1.500.000 + 500.000';
        expect(controller.numericValue, 2000000.0);
      });

      test('should evaluate multiple additions', () {
        final controller = SakuCurrencyController();
        controller.text = '100 + 200 + 300';
        expect(controller.numericValue, 600.0);
      });
    });

    group('numericValue - Subtraction', () {
      test('should evaluate simple subtraction', () {
        final controller = SakuCurrencyController();
        controller.text = '1.000 - 500';
        expect(controller.numericValue, 500.0);
      });

      test('should evaluate subtraction resulting in negative', () {
        final controller = SakuCurrencyController();
        controller.text = '500 - 1.000';
        expect(controller.numericValue, -500.0);
      });
    });

    group('numericValue - Multiplication', () {
      test('should evaluate simple multiplication', () {
        final controller = SakuCurrencyController();
        controller.text = '1.000 × 2';
        expect(controller.numericValue, 2000.0);
      });

      test('should evaluate multiplication with larger numbers', () {
        final controller = SakuCurrencyController();
        controller.text = '500 × 100';
        expect(controller.numericValue, 50000.0);
      });
    });

    group('numericValue - Division', () {
      test('should evaluate simple division', () {
        final controller = SakuCurrencyController();
        controller.text = '1.000 ÷ 2';
        expect(controller.numericValue, 500.0);
      });

      test('should handle division with decimal result', () {
        final controller = SakuCurrencyController();
        controller.text = '100 ÷ 3';
        expect(controller.numericValue, closeTo(33.33, 0.01));
      });

      test('should handle division by zero gracefully', () {
        final controller = SakuCurrencyController();
        controller.setRawText('100 ÷ 0');
        // Division by zero returns 0 (handled gracefully)
        expect(controller.numericValue, 0);
      });
    });

    group('numericValue - Mixed Operations', () {
      test('should evaluate mixed addition and subtraction', () {
        final controller = SakuCurrencyController();
        controller.text = '1.000 + 500 - 200';
        expect(controller.numericValue, 1300.0);
      });

      test('should respect operator precedence (× before +)', () {
        final controller = SakuCurrencyController();
        controller.text = '100 + 50 × 2';
        expect(controller.numericValue, 200.0); // 100 + (50*2) = 200
      });

      test('should evaluate complex expression', () {
        final controller = SakuCurrencyController();
        controller.text = '1.000 × 2 + 500';
        expect(controller.numericValue, 2500.0);
      });
    });

    group('numericValue - Negative Numbers in Expression', () {
      test('should handle adding negative number', () {
        final controller = SakuCurrencyController();
        controller.text = '1.000 + -500';
        expect(controller.numericValue, 500.0);
      });

      test('should handle multiplying by negative', () {
        final controller = SakuCurrencyController();
        controller.text = '100 × -2';
        expect(controller.numericValue, -200.0);
      });
    });

    group('numericValue - Decimal Operations', () {
      test('should evaluate decimal addition', () {
        final controller = SakuCurrencyController();
        controller.text = '1,5 + 2,3';
        expect(controller.numericValue, 3.8);
      });

      test('should evaluate decimal multiplication', () {
        final controller = SakuCurrencyController();
        controller.text = '10,5 × 2';
        expect(controller.numericValue, 21.0);
      });
    });

    group('setDoubleValue', () {
      test('should format and set value', () {
        final controller = SakuCurrencyController();
        controller.setDoubleValue(1500000);
        expect(controller.text, '1.500.000');
      });

      test('should set cursor at end', () {
        final controller = SakuCurrencyController();
        controller.setDoubleValue(1500);
        expect(controller.selection.baseOffset, controller.text.length);
      });

      test('should clear text for zero value', () {
        final controller = SakuCurrencyController();
        controller.text = '1.000';
        controller.setDoubleValue(0);
        expect(controller.text, isEmpty);
      });
    });

    group('evaluate', () {
      test('should evaluate expression and update text', () {
        final controller = SakuCurrencyController();
        controller.setRawText('1.000 + 500');
        final result = controller.evaluate();
        expect(result, true);
        expect(controller.text, '1.500');
        expect(controller.hasOperator, false);
      });

      test('should return false for plain number', () {
        final controller = SakuCurrencyController();
        controller.text = '1.500';
        final result = controller.evaluate();
        expect(result, false);
        expect(controller.text, '1.500'); // unchanged
      });

      test('should handle complex evaluation', () {
        final controller = SakuCurrencyController();
        controller.text = '10.000 + 5.000 × 2';
        controller.evaluate();
        expect(controller.text, '20.000');
      });
    });

    group('Edge Cases', () {
      test('should handle incomplete expression', () {
        final controller = SakuCurrencyController();
        controller.text = '1.000 + ';
        // Should fallback to parsing digits only
        expect(controller.numericValue, 1000.0);
      });

      test('should handle operator only input', () {
        final controller = SakuCurrencyController();
        controller.text = '+';
        expect(controller.numericValue, 0.0);
      });

      test('should handle spaces in expression', () {
        final controller = SakuCurrencyController();
        controller.text = '1.000  +  500';
        expect(controller.numericValue, 1500.0);
      });

      test('should handle very large numbers', () {
        final controller = SakuCurrencyController();
        controller.text = '999.999.999.999';
        expect(controller.numericValue, 999999999999.0);
      });
    });

    group('text setter - Auto Format', () {
      test('should auto-format plain number', () {
        final controller = SakuCurrencyController();
        controller.text = '1000000';
        expect(controller.text, '1.000.000');
      });

      test('should auto-evaluate expression with operators', () {
        final controller = SakuCurrencyController();
        controller.text = '1000+500';
        expect(controller.text, '1.500');
      });

      test('should auto-evaluate expression with visual operators', () {
        final controller = SakuCurrencyController();
        controller.text = '1.000 × 2';
        expect(controller.text, '2.000');
      });

      test('should keep already formatted number as-is', () {
        final controller = SakuCurrencyController();
        controller.text = '1.500.000';
        expect(controller.text, '1.500.000');
      });

      test('should handle empty string', () {
        final controller = SakuCurrencyController();
        controller.text = '';
        expect(controller.text, '');
      });

      test('setRawText should not auto-format', () {
        final controller = SakuCurrencyController();
        controller.setRawText('1.000 + 500');
        expect(controller.text, '1.000 + 500');
        expect(controller.hasOperator, true);
      });
    });
  });
}
