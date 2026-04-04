import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:math_expressions/math_expressions.dart';

/// Controller untuk currency input dengan dukungan kalkulasi matematika.
///
/// Mendukung operasi: +, -, ×, ÷
/// Format output: Indonesia (ribuan = titik, desimal = koma)
///
/// **Auto-format:** Ketika `text` di-set langsung, akan otomatis diformat.
/// - `controller.text = '1000'` → tampil `1.000`
/// - `controller.text = '1000 + 500'` → evaluate → tampil `1.500`
///
/// **Active Controller:** Gunakan [activeController] untuk mengakses
/// controller yang sedang aktif (fokus) dari keyboard.
///
/// Contoh penggunaan:
/// ```dart
/// final controller = SakuCurrencyController(initialValue: 1500000);
/// print(controller.numericValue); // 1500000.0
///
/// controller.text = '1000 + 500';
/// // Otomatis evaluate dan format → text jadi '1.500'
/// ```
class SakuCurrencyController extends TextEditingController {
  /// Membuat controller dengan nilai awal opsional.
  ///
  /// Jika [initialValue] tidak null dan bukan 0, akan diformat
  /// dengan thousand separator.
  SakuCurrencyController({double? initialValue}) {
    if (initialValue != null && initialValue != 0) {
      // Gunakan super.text untuk set tanpa auto-format ulang
      super.text = formatNumber(initialValue);
    }
  }

  /// Flag untuk mengecek apakah controller sudah di-dispose.
  bool _isDisposed = false;

  /// Apakah controller sudah di-dispose.
  bool get isDisposed => _isDisposed;

  @override
  void dispose() {
    _isDisposed = true;
    // Clear active SEBELUM dispose untuk mencegah race condition
    clearActive();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  //  Static Active Controller Management
  // ═══════════════════════════════════════════════════════════

  /// Notifier untuk controller yang sedang aktif (fokus).
  ///
  /// Digunakan oleh keyboard untuk mendapatkan controller saat ini.
  static final activeController = ValueNotifier<SakuCurrencyController?>(null);

  /// Set controller ini sebagai active controller.
  void setActive() => activeController.value = this;

  /// Clear active controller jika ini yang aktif.
  void clearActive() {
    if (activeController.value == this) {
      activeController.value = null;
    }
  }

  static final _formatter = NumberFormat('#,###', 'id_ID');
  static final _parser = GrammarParser();

  /// Flag internal untuk mencegah recursive formatting.
  bool _isSettingText = false;

  /// Override text setter untuk auto-format.
  ///
  /// - Input angka biasa (`'1000'`) → format ke `'1.000'`
  /// - Input dengan operator (`'1000 + 500'`) → evaluate → `'1.500'`
  /// - Input sudah diformat (`'1.000'`) → tetap `'1.000'`
  @override
  set text(String newText) {
    if (_isSettingText) {
      super.text = newText;
      return;
    }

    _isSettingText = true;
    try {
      if (newText.isEmpty) {
        super.text = '';
        return;
      }

      // Cek apakah sudah diformat (ada titik sebagai thousand separator)
      // atau mengandung operator visual (×, ÷)
      final isAlreadyFormatted =
          newText.contains('.') ||
          newText.contains('×') ||
          newText.contains('÷');

      if (isAlreadyFormatted) {
        // Cek apakah ada operator → evaluate
        if (_hasOperatorIn(newText)) {
          final result = _evaluateExpression(newText);
          super.text = formatNumber(result);
        } else {
          super.text = newText;
        }
        return;
      }

      // Input belum diformat, coba parse
      // Cek apakah ada operator standar (+, -, *, /)
      if (RegExp(r'[\d]\s*[+\-*/]\s*[\d]').hasMatch(newText)) {
        // Evaluate expression
        final result = _evaluateExpression(newText);
        super.text = formatNumber(result);
      } else {
        // Plain number - coba parse dan format
        final parsed = double.tryParse(newText.replaceAll(',', '.'));
        if (parsed != null) {
          super.text = formatNumber(parsed);
        } else {
          super.text = newText;
        }
      }
    } finally {
      _isSettingText = false;
    }
  }

  /// Cek apakah string mengandung operator matematika (setelah digit).
  bool _hasOperatorIn(String input) {
    return RegExp(r'\d\s*[+\-×÷*/]\s*').hasMatch(input);
  }

  /// Evaluate expression dan return hasil.
  double _evaluateExpression(String input) {
    final cleaned = input
        .replaceAll('.', '') // hapus thousand separator
        .replaceAll(',', '.') // ubah desimal ID ke titik
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll(' ', '');

    if (cleaned.isEmpty) return 0.0;

    try {
      final expression = _parser.parse(cleaned);
      final evaluator = RealEvaluator();
      final result = evaluator.evaluate(expression);
      final doubleResult = result.toDouble();
      // Handle infinity/NaN (e.g., division by zero)
      if (doubleResult.isInfinite || doubleResult.isNaN) {
        return 0.0;
      }
      return _roundTo(doubleResult, 2);
    } catch (_) {
      final digitsOnly = input.replaceAll(RegExp(r'[^\d]'), '');
      return double.tryParse(digitsOnly) ?? 0.0;
    }
  }

  /// Cek apakah text mengandung operator matematika.
  ///
  /// Return true jika ada operator (+, -, ×, ÷) yang bukan leading minus.
  /// Return false jika controller sudah di-dispose.
  bool get hasOperator {
    if (_isDisposed) return false;
    if (text.isEmpty) return false;
    // Match operator yang ada setelah digit (bukan leading minus)
    return RegExp(r'\d\s*[+\-×÷]\s*').hasMatch(text);
  }

  /// Nilai numerik hasil evaluasi ekspresi.
  ///
  /// Return 0.0 jika ekspresi invalid, kosong, atau controller sudah di-dispose.
  /// Jika ada operator, akan dievaluasi. Jika tidak, parse langsung.
  double get numericValue {
    if (_isDisposed) return 0.0;
    final cleaned = _cleanForEvaluation(text);
    if (cleaned.isEmpty) return 0.0;

    try {
      final expression = _parser.parse(cleaned);
      final evaluator = RealEvaluator();
      final result = evaluator.evaluate(expression);
      final doubleResult = result.toDouble();
      // Handle infinity/NaN (e.g., division by zero)
      if (doubleResult.isInfinite || doubleResult.isNaN) {
        return 0.0;
      }
      return _roundTo(doubleResult, 2);
    } catch (_) {
      // Fallback: coba parse sebagai angka biasa
      final digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');
      return double.tryParse(digitsOnly) ?? 0.0;
    }
  }

  /// Set nilai dan format ulang dengan thousand separator.
  ///
  /// Cursor akan dipindahkan ke akhir text.
  void setDoubleValue(double value) {
    _isSettingText = true;
    try {
      super.text = formatNumber(value);
      selection = TextSelection.collapsed(offset: text.length);
    } finally {
      _isSettingText = false;
    }
  }

  /// Set text tanpa auto-format (untuk input manual dari keyboard).
  void setRawText(String value) {
    _isSettingText = true;
    try {
      super.text = value;
    } finally {
      _isSettingText = false;
    }
  }

  /// Evaluate ekspresi matematika dan replace text dengan hasilnya.
  ///
  /// Return true jika berhasil evaluate, false jika tidak ada operator.
  bool evaluate() {
    if (!hasOperator) return false;

    final result = numericValue;
    setDoubleValue(result);
    return true;
  }

  /// Format angka dengan thousand separator Indonesia.
  ///
  /// - Angka negatif akan diawali dengan `-`
  /// - Desimal menggunakan koma (`,`)
  /// - Return empty string jika value = 0
  static String formatNumber(double value) {
    if (value == 0) return '';
    final isNegative = value < 0;
    final absValue = value.abs();

    // Handle decimal
    final hasDecimal = absValue != absValue.truncateToDouble();
    String formatted;
    if (hasDecimal) {
      final intPart = _formatter.format(absValue.truncate());
      // Ambil 2 digit desimal
      final decPart = (absValue - absValue.truncate())
          .toStringAsFixed(2)
          .substring(2);
      formatted = '$intPart,$decPart';
    } else {
      formatted = _formatter.format(absValue.toInt());
    }

    return isNegative ? '-$formatted' : formatted;
  }

  /// Parse string berpemisah ribuan kembali ke nilai numerik.
  static double parseNumber(String text) {
    if (text.isEmpty) return 0;
    final clean = text
        .replaceAll('.', '') // hapus thousand separator
        .replaceAll(',', '.'); // ubah desimal koma ke titik
    return double.tryParse(clean) ?? 0;
  }

  /// Bersihkan string untuk evaluasi math_expressions.
  String _cleanForEvaluation(String input) {
    return input
        .replaceAll('.', '') // hapus thousand separator
        .replaceAll(',', '.') // ubah desimal ID ke titik
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll(' ', '');
  }

  /// Round ke N decimal places.
  double _roundTo(double value, int decimals) {
    final mod = pow(10.0, decimals).toDouble();
    return (value * mod).roundToDouble() / mod;
  }
}
