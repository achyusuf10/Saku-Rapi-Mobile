/// Calculator Keyboard Module untuk SakuRapi.
///
/// Menyediakan custom keyboard bergaya kalkulator untuk input currency
/// dengan dukungan operasi matematika sederhana (+, -, ×, ÷).
///
/// ## Komponen Utama
/// - [SakuCurrencyController]: Controller dengan evaluasi matematika
/// - [SakuMathFormatter]: Formatter untuk auto-format dengan thousand separator
/// - [SakuCalculatorKeyboard]: Widget custom keyboard
///
/// ## Penggunaan
/// ```dart
/// // Di main.dart atau screen wrapper
/// KeyboardWrapper(
///   keyboards: [SakuCalculatorKeyboard(controller: _controller)],
///   child: MaterialApp(...),
/// )
///
/// // Di form field
/// SakuCurrencyField(
///   controller: _controller,
///   enableCalculator: true,
/// )
/// ```
library;

export 'saku_calculator_keyboard.dart';
export 'saku_currency_controller.dart';
export 'saku_math_formatter.dart';
