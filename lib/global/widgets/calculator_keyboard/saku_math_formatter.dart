import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// TextInputFormatter yang auto-format setiap segmen angka
/// dengan thousand separator, sambil mempertahankan operator matematika.
///
/// Contoh:
/// - Input: `1000+500` → Output: `1.000 + 500`
/// - Input: `1500000` → Output: `1.500.000`
/// - Input: `-500` → Output: `-500` (negative number)
/// - Input: `1000+-500` → Output: `1.000 + -500` (adding negative)
class SakuMathFormatter extends TextInputFormatter {
  const SakuMathFormatter();

  static final _formatter = NumberFormat('#,###', 'id_ID');
  static final _operatorChars = {'+', '-', '×', '÷'};

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final formatted = _formatWithOperators(newValue.text);
    final cursorOffset = _calculateCursorOffset(
      oldText: oldValue.text,
      newText: newValue.text,
      formattedText: formatted,
      newCursor: newValue.selection.baseOffset,
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: cursorOffset.clamp(0, formatted.length),
      ),
    );
  }

  /// Format text dengan mempertahankan operator dan memformat setiap segmen angka.
  String _formatWithOperators(String text) {
    final buffer = StringBuffer();
    final segments = _splitIntoSegments(text);

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];

      if (seg.isOperator) {
        // Operator: cek apakah ini negative sign atau operator biasa
        if (seg.value == '-' && _isNegativeSign(segments, i)) {
          // Negative sign: tidak pakai spasi
          buffer.write(seg.value);
        } else {
          // Operator biasa: tambah spasi di sekitarnya
          if (buffer.isNotEmpty && !buffer.toString().endsWith(' ')) {
            buffer.write(' ');
          }
          buffer.write(seg.value);
          buffer.write(' ');
        }
      } else {
        // Angka: format dengan thousand separator
        buffer.write(_formatNumberSegment(seg.value));
      }
    }

    // Clean up multiple spaces dan trim
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Split text menjadi segments (angka dan operator).
  List<_Segment> _splitIntoSegments(String text) {
    final result = <_Segment>[];
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      if (_operatorChars.contains(char)) {
        // Simpan buffer sebelumnya sebagai number segment
        if (buffer.isNotEmpty) {
          result.add(_Segment(buffer.toString(), isOperator: false));
          buffer.clear();
        }
        // Tambahkan operator
        result.add(_Segment(char, isOperator: true));
      } else if (char != ' ') {
        // Tambahkan ke buffer (skip spaces)
        buffer.write(char);
      }
    }

    // Jangan lupa sisa buffer
    if (buffer.isNotEmpty) {
      result.add(_Segment(buffer.toString(), isOperator: false));
    }

    return result;
  }

  /// Cek apakah minus di posisi ini adalah negative sign (bukan operator).
  bool _isNegativeSign(List<_Segment> segments, int index) {
    if (index == 0) return true; // Di awal = negative sign

    // Cek segment sebelumnya
    final prev = segments[index - 1];
    if (prev.isOperator) return true; // Setelah operator lain = negative sign

    return false;
  }

  /// Format segment angka dengan thousand separator.
  String _formatNumberSegment(String segment) {
    // Handle angka dengan koma desimal (ID format)
    final parts = segment.split(',');
    final intPart = parts[0].replaceAll('.', ''); // Hapus existing separators

    if (intPart.isEmpty) return segment;

    final number = int.tryParse(intPart);
    if (number == null) return segment;

    final formatted = _formatter.format(number);
    if (parts.length > 1) {
      // Ada bagian desimal
      return '$formatted,${parts[1]}';
    }
    return formatted;
  }

  /// Hitung posisi cursor yang tepat setelah formatting.
  int _calculateCursorOffset({
    required String oldText,
    required String newText,
    required String formattedText,
    required int newCursor,
  }) {
    // Hitung jumlah digit + operator sebelum cursor di input baru
    final beforeCursor = newText.substring(
      0,
      newCursor.clamp(0, newText.length),
    );
    final significantChars = beforeCursor.replaceAll(RegExp(r'[\s.]'), '');
    final charCount = significantChars.length;

    // Temukan posisi di formatted text setelah char ke-N
    int count = 0;
    for (int i = 0; i < formattedText.length; i++) {
      final char = formattedText[i];
      if (char != ' ' && char != '.') {
        count++;
        if (count == charCount) {
          return i + 1;
        }
      }
    }

    return formattedText.length;
  }
}

/// Representasi segment dalam ekspresi matematika.
class _Segment {
  final String value;
  final bool isOperator;

  _Segment(this.value, {required this.isOperator});
}

/// Validator untuk input calculator keyboard.
///
/// Digunakan untuk memvalidasi input sebelum dimasukkan ke text field.
class CalculatorInputValidator {
  const CalculatorInputValidator();

  static final _operators = {'+', '-', '×', '÷'};

  /// Cek apakah karakter bisa dimasukkan di posisi saat ini.
  ///
  /// Return true jika valid, false jika harus diblokir.
  bool canInsert(String char, String currentText) {
    final trimmed = currentText.trim();
    final charTrimmed = char.trim();

    // Empty field
    if (trimmed.isEmpty) {
      // Hanya digit dan minus yang boleh di awal
      if (charTrimmed == '000') return false;
      if (charTrimmed == ',') return false;
      if (_operators.contains(charTrimmed) && charTrimmed != '-') return false;
      return true;
    }

    final lastChar = trimmed.isNotEmpty ? trimmed[trimmed.length - 1] : '';

    // 000 handling
    if (charTrimmed == '000') {
      // Block setelah operator, koma, atau di awal
      if (_operators.contains(lastChar)) return false;
      if (lastChar == ',') return false;
      return true;
    }

    // Decimal (koma) handling
    if (charTrimmed == ',') {
      // Block decimal ganda dalam satu segmen
      final lastSegment = _getLastNumberSegment(trimmed);
      if (lastSegment.contains(',')) return false;
      // Block setelah operator
      if (_operators.contains(lastChar)) return false;
      return true;
    }

    // Operator handling
    if (_operators.contains(charTrimmed)) {
      // Minus setelah operator lain → negative number (allow)
      if (charTrimmed == '-' && _operators.contains(lastChar)) {
        return lastChar != '-'; // Block double minus
      }
      // Block operator setelah operator (kecuali minus untuk negative)
      if (_operators.contains(lastChar)) return false;
      // Block operator setelah koma
      if (lastChar == ',') return false;
      return true;
    }

    return true;
  }

  /// Dapatkan segment angka terakhir (setelah operator terakhir).
  String _getLastNumberSegment(String text) {
    // Split by operators (tapi hati-hati dengan negative)
    final segments = text.split(RegExp(r'(?<=\d)\s*[+×÷]\s*|(?<=\d)\s*-\s*'));
    return segments.isEmpty ? text : segments.last;
  }

  /// Handle consecutive operator: replace operator terakhir dengan yang baru.
  ///
  /// Return modified text jika perlu replace, null jika tidak perlu.
  String? handleConsecutiveOperator(String char, String currentText) {
    final trimmed = currentText.trimRight();
    final charTrimmed = char.trim();

    if (!_operators.contains(charTrimmed)) return null;
    if (trimmed.isEmpty) return null;

    // Cek apakah berakhir dengan " operator " atau "operator"
    final match = RegExp(r'\s*[+\-×÷]\s*$').firstMatch(trimmed);
    if (match != null) {
      // Minus setelah operator lain untuk negative → append, don't replace
      if (charTrimmed == '-') {
        final prevOp = match.group(0)!.trim();
        if (prevOp != '-') {
          // Tambahkan minus untuk negative number
          return '${trimmed.substring(0, match.start)} $prevOp -';
        }
      }
      // Replace operator
      return '${trimmed.substring(0, match.start)} $charTrimmed ';
    }

    return null;
  }
}
