import 'package:app_saku_rapi/core/constants/app_constants.dart';
import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

/// Text field untuk input mata uang dengan thousand separator otomatis.
///
/// Widget ini reusable untuk seluruh fitur yang membutuhkan input nominal:
/// - Wallet (initial_balance)
/// - Transaction (amount)
/// - Budget (amount)
/// - dll.
///
/// Gunakan [numericValue] untuk mendapatkan nilai numerik tanpa formatting.
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
  });

  /// Controller untuk text field. Jika null, dibuat internal.
  final TextEditingController? controller;

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

  final Widget? suffixIcon;

  @override
  State<SakuCurrencyField> createState() => _SakuCurrencyFieldState();
}

class _SakuCurrencyFieldState extends State<SakuCurrencyField> {
  late final TextEditingController _controller;
  bool _isInternalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _isInternalController = true;
      _controller = TextEditingController();
    }

    // Set initial value (formatted)
    if (widget.initialValue != null && widget.initialValue! > 0) {
      _controller.text = ThousandInputFormatter.formatNumber(
        widget.initialValue!,
      );
    }
  }

  @override
  void dispose() {
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyleConstants.label1.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
        ],
        TextFormField(
          controller: _controller,
          focusNode: widget.focusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            const ThousandInputFormatter(),
          ],
          readOnly: widget.readOnly,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          validator: widget.validator,
          onChanged: (value) {
            final numericValue = ThousandInputFormatter.parseNumber(value);
            widget.onChanged?.call(numericValue);
          },
          style: TextStyleConstants.b2.copyWith(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint ?? '0',
            hintStyle: TextStyleConstants.b2.copyWith(
              color: colors.textSecondary,
            ),
            errorText: widget.errorText,
            errorStyle: TextStyleConstants.label3.copyWith(color: colors.error),
            suffixIcon: widget.suffixIcon == null
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [widget.suffixIcon!],
                  ),
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
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.w,
            ),
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
              borderSide: BorderSide(
                color: colors.border.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
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
