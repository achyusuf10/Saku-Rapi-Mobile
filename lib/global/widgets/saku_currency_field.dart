import 'package:app_saku_rapi/core/constants/app_constants.dart';
import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/global/widgets/calculator_keyboard/calculator_keyboard.dart';
import 'package:customized_keyboard/customized_keyboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

/// Text field untuk input mata uang dengan calculator keyboard.
///
/// Widget ini otomatis menggunakan [SakuCalculatorKeyboard] untuk input
/// dengan dukungan operasi matematika (+, -, ×, ÷).
///
/// Widget ini reusable untuk seluruh fitur yang membutuhkan input nominal:
/// - Wallet (initial_balance)
/// - Transaction (amount)
/// - Budget (amount)
/// - Investment (price, fee)
/// - dll.
///
/// **Auto-format:** Ketika controller.text di-set langsung, akan otomatis diformat.
/// - `controller.text = '1000'` → tampil `1.000`
/// - `controller.text = '1000 + 500'` → evaluate → tampil `1.500`
///
/// Contoh penggunaan:
/// ```dart
/// final controller = SakuCurrencyController(initialValue: 1000);
///
/// SakuCurrencyField(
///   controller: controller,
///   label: 'Amount',
///   onChanged: (value) => print('Value: $value'),
/// )
/// ```
class SakuCurrencyField extends StatefulWidget {
  const SakuCurrencyField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.onChanged,
    this.initialValue,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.validator,
    this.showPrefix = true,
    this.suffixIcon,
    this.onSubmit,
  });

  /// Controller untuk text field.
  ///
  /// Jika null, dibuat internal [SakuCurrencyController].
  /// Jika disediakan, HARUS berupa [SakuCurrencyController].
  final SakuCurrencyController? controller;

  /// Label di atas field.
  final String? label;

  /// Hint di dalam field.
  final String? hint;

  /// Teks error validasi.
  final String? errorText;

  /// Callback saat value berubah (mengembalikan nilai numerik).
  final ValueChanged<double>? onChanged;

  /// Nilai awal (numerik, bukan formatted string).
  final double? initialValue;

  /// Apakah field hanya baca.
  final bool readOnly;

  /// Apakah field aktif.
  final bool enabled;

  /// Apakah field otomatis fokus.
  final bool autofocus;

  /// Focus node.
  final FocusNode? focusNode;

  /// Validator untuk Form widget.
  final String? Function(String?)? validator;

  /// Tampilkan prefix simbol mata uang.
  final bool showPrefix;

  /// Widget suffix (misal: tombol MAX).
  final Widget? suffixIcon;

  /// Callback saat tombol submit (>) ditekan.
  final ValueChanged<double>? onSubmit;

  @override
  State<SakuCurrencyField> createState() => _SakuCurrencyFieldState();
}

class _SakuCurrencyFieldState extends State<SakuCurrencyField> {
  late final SakuCurrencyController _controller;
  late final FocusNode _focusNode;
  bool _isInternalController = false;
  bool _isInternalFocusNode = false;

  @override
  void initState() {
    super.initState();
    // Setup controller
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _isInternalController = true;
      _controller = SakuCurrencyController(initialValue: widget.initialValue);
    }

    // Setup focus node with listener
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _isInternalFocusNode = true;
      _focusNode = FocusNode();
    }
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    // Safety check: jangan akses controller yang sudah di-dispose
    if (_controller.isDisposed) return;

    if (_focusNode.hasFocus) {
      _controller.setActive();
    } else {
      // Auto-evaluate jika masih ada operator (math expression)
      if (_controller.hasOperator) {
        _controller.evaluate();
      }
      _controller.clearActive();
    }
  }

  @override
  void didUpdateWidget(covariant SakuCurrencyField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Jika initialValue berubah dari null/0 ke nilai baru (prefill dari OCR/Voice)
    // dan user belum mengetik manual → update controller setelah build selesai.
    final oldVal = oldWidget.initialValue ?? 0;
    final newVal = widget.initialValue ?? 0;
    if (newVal > 0 && oldVal != newVal && _controller.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.text.isEmpty) {
          _controller.setDoubleValue(newVal);
        }
      });
    }
  }

  @override
  void dispose() {
    // PENTING: Clear active dan evaluate SEBELUM dispose
    // untuk mencegah keyboard widget akses disposed controller.
    // Gunakan addPostFrameCallback agar ValueNotifier tidak fire
    // saat widget tree sedang unmount (menyebabkan assertion error).
    if (!_controller.isDisposed) {
      // Auto-evaluate expression sebelum dispose
      if (_controller.hasOperator) {
        _controller.evaluate();
      }
      // Defer clearActive agar tidak trigger rebuild saat unmount
      final controllerRef = _controller;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!controllerRef.isDisposed) {
          controllerRef.clearActive();
        }
      });
    }
    _focusNode.removeListener(_onFocusChanged);
    if (_isInternalFocusNode) {
      _focusNode.dispose();
    }
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Wrap dengan PopScope untuk intercept back button ketika keyboard aktif
    return ListenableBuilder(
      listenable: _focusNode,
      builder: (context, child) {
        return PopScope(
          // Block back jika field ini fokus (keyboard aktif)
          canPop: !_focusNode.hasFocus,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && _focusNode.hasFocus) {
              // Close keyboard dengan unfocus, jangan close dialog
              _focusNode.unfocus();
            }
          },
          child: child!,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: TextStyleConstants.label1.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: 6.h),
          ],
          _buildCalculatorField(context, colors),
        ],
      ),
    );
  }

  /// Build calculator field dengan custom keyboard.
  Widget _buildCalculatorField(BuildContext context, dynamic colors) {
    return CustomTextFormField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: const CustomTextInputType(name: 'saku_calculator'),
      inputFormatters: [const SakuMathFormatter()],
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      validator: widget.validator,
      onChanged: (value) {
        final numericValue = _controller.numericValue;
        widget.onChanged?.call(numericValue);
      },
      style: TextStyleConstants.b2.copyWith(color: colors.textPrimary),
      decoration: _buildInputDecoration(colors),
    );
  }

  /// Build InputDecoration yang sama untuk kedua mode.
  InputDecoration _buildInputDecoration(dynamic colors) {
    return InputDecoration(
      hintText: widget.hint ?? '0',
      hintStyle: TextStyleConstants.b2.copyWith(color: colors.textSecondary),
      errorText: widget.errorText,
      errorStyle: TextStyleConstants.label3.copyWith(color: colors.error),
      suffixIcon: widget.suffixIcon == null
          ? null
          : Row(mainAxisSize: MainAxisSize.min, children: [widget.suffixIcon!]),
      suffixIconConstraints: BoxConstraints.tight(Size(42.w, 40.h)),
      prefixIcon: widget.showPrefix
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                10.horizontalSpace,
                Center(
                  child: Text(
                    AppConstants.currencySymbol,
                    style: TextStyleConstants.b1.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          : null,
      prefixIconConstraints: BoxConstraints.tight(Size(42.w, 40.h)),
      filled: true,
      fillColor: colors.surfaceVariant,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: colors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: colors.error, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: colors.border.withValues(alpha: 0.5)),
      ),
    );
  }
}

// ───────────────── ThousandInputFormatter ─────────────────

/// [TextInputFormatter] yang otomatis menambahkan pemisah ribuan (titik).
///
/// Contoh: input '1500000' → ditampilkan '1.500.000'.
///
/// Gunakan [formatNumber] untuk konversi double → string formatted.
/// Gunakan [parseNumber] untuk konversi string formatted → double.
class ThousandInputFormatter extends TextInputFormatter {
  const ThousandInputFormatter();

  static final _formatter = NumberFormat('#,###', 'id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Hapus semua non-digit
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final number = int.tryParse(digits) ?? 0;
    final formatted = _formatter.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Format angka menjadi string dengan pemisah ribuan.
  static String formatNumber(double value) {
    if (value == 0) return '';
    return _formatter.format(value.toInt());
  }

  /// Parse string berpemisah ribuan kembali ke nilai numerik.
  static double parseNumber(String text) {
    if (text.isEmpty) return 0;
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(clean) ?? 0;
  }
}
