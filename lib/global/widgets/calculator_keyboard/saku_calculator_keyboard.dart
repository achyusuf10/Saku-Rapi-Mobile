import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/int_ext.dart';
import 'package:app_saku_rapi/global/widgets/calculator_keyboard/saku_currency_controller.dart';
import 'package:app_saku_rapi/global/widgets/calculator_keyboard/saku_math_formatter.dart';
import 'package:customized_keyboard/customized_keyboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Custom calculator keyboard untuk input currency.
///
/// Layout:
/// ```
/// ┌─────┬─────┬─────┬─────┐
/// │  C  │  ÷  │  ×  │  ⌫  │
/// ├─────┼─────┼─────┼─────┤
/// │  7  │  8  │  9  │  -  │
/// ├─────┼─────┼─────┼─────┤
/// │  4  │  5  │  6  │  +  │
/// ├─────┼─────┼─────┼─────┤
/// │  1  │  2  │  3  │     │
/// ├─────┼─────┤─────┤ =/> │  ← Dynamic button
/// │  0  │ 000 │  ,  │     │
/// └─────┴─────┴─────┴─────┘
/// ```
///
/// **Dynamic Button Behavior:**
/// - Jika ada operator di text → tampilkan `=` (evaluate only)
/// - Jika tidak ada operator → tampilkan `>` (submit + close)
///
/// **Active Controller:**
/// Keyboard menggunakan [SakuCurrencyController.activeController] untuk
/// mendapatkan controller yang sedang fokus. Tidak perlu passing controller
/// secara eksplisit.
class SakuCalculatorKeyboard extends CustomKeyboard {
  SakuCalculatorKeyboard({this.onEvaluate, this.onSubmit});

  /// Callback saat tombol `=` ditekan (evaluate).
  final VoidCallback? onEvaluate;

  /// Callback saat tombol `>` ditekan (submit).
  final ValueChanged<double>? onSubmit;

  /// Tinggi keyboard: 320.h tapi maksimal 1/2 layar.
  @override
  double get height {
    final preferred = 380.h;
    final maxHeight = 1.sh / 2;
    return preferred > maxHeight ? maxHeight : preferred;
  }

  @override
  String get name => 'saku_calculator';

  List<int> get recomendedExpressions => [
    1000,
    2000,
    5000,
    10000,
    20000,
    50000,
    100000,
  ];
  static const _validator = CalculatorInputValidator();
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ValueListenableBuilder<SakuCurrencyController?>(
      valueListenable: SakuCurrencyController.activeController,
      builder: (context, controller, _) {
        // Jika tidak ada controller aktif atau sudah di-dispose, tampilkan placeholder
        if (controller == null || controller.isDisposed) {
          return SizedBox(height: height);
        }

        return Material(
          color: colors.surface,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 2.w,
                  decoration: BoxDecoration(
                    color: colors.textPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2.r),
                    boxShadow: [
                      BoxShadow(
                        color: colors.textPrimary.withValues(alpha: 0.06),
                        blurRadius: 2,
                        spreadRadius: 2,
                        offset: Offset(0, -1.w),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 60.w,
                  width: double.infinity,

                  child: ListView.separated(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    itemBuilder: (_, index) {
                      final expr = recomendedExpressions[index];
                      return GestureDetector(
                        onTap: () {
                          // Validasi sebelum insert
                          if (!_validator.canInsert(
                            expr.toString(),
                            controller.text,
                          )) {
                            return;
                          }

                          // Insert karakter
                          final wrapper = KeyboardWrapper.of(context);
                          wrapper?.onKey(
                            CustomKeyboardEvent.character(expr.toString()),
                          );
                        },
                        child: Container(
                          width:
                              (1.sw / 4) -
                              (12.w * 2 / 4) -
                              6.w, // 4 item per row, dengan padding 12.w antar item
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            expr.extToRibuan(),
                            style: TextStyleConstants.b2.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, _) => SizedBox(width: 12.w),
                    itemCount: recomendedExpressions.length,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
                    child: Row(
                      children: [
                        // Kolom kiri (3 kolom angka & operator)
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              // Row 1: C, ÷, ×
                              _buildRow([
                                _ActionKey(
                                  label: 'C',
                                  labelColor: colors.primary,
                                  backgroundColor: colors.surfaceVariant,
                                  event: const CustomKeyboardEvent.clear(),
                                ),
                                _OperatorKey(
                                  label: '÷',
                                  controller: controller,
                                ),
                                _OperatorKey(
                                  label: '×',
                                  controller: controller,
                                ),
                              ]),
                              SizedBox(height: 8.h),
                              // Row 2: 7, 8, 9
                              _buildRow([
                                _NumericKey(label: '7', controller: controller),
                                _NumericKey(label: '8', controller: controller),
                                _NumericKey(label: '9', controller: controller),
                              ]),
                              SizedBox(height: 8.h),
                              // Row 3: 4, 5, 6
                              _buildRow([
                                _NumericKey(label: '4', controller: controller),
                                _NumericKey(label: '5', controller: controller),
                                _NumericKey(label: '6', controller: controller),
                              ]),
                              SizedBox(height: 8.h),
                              // Row 4: 1, 2, 3
                              _buildRow([
                                _NumericKey(label: '1', controller: controller),
                                _NumericKey(label: '2', controller: controller),
                                _NumericKey(label: '3', controller: controller),
                              ]),
                              SizedBox(height: 8.h),
                              // Row 5: 0, 000, ,
                              _buildRow([
                                _NumericKey(label: '0', controller: controller),
                                _NumericKey(
                                  label: '000',
                                  controller: controller,
                                ),
                                _NumericKey(label: ',', controller: controller),
                              ]),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // Kolom kanan (operator & submit)
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              // Row 1: ⌫
                              Expanded(
                                child: _ActionKey(
                                  icon: FontAwesomeIcons.deleteLeft,
                                  iconColor: colors.primary,
                                  backgroundColor: colors.surfaceVariant,
                                  event: const CustomKeyboardEvent.deleteOne(),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              // Row 2: -
                              Expanded(
                                child: _OperatorKey(
                                  label: '-',
                                  controller: controller,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              // Row 3: +
                              Expanded(
                                child: _OperatorKey(
                                  label: '+',
                                  controller: controller,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              // Row 4-5: Submit (spans 2 rows)
                              Expanded(
                                flex: 2,
                                child: _DynamicSubmitButton(
                                  controller: controller,
                                  onEvaluate: onEvaluate,
                                  onSubmit: onSubmit,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(List<Widget> children) {
    return Expanded(
      child: Row(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            Expanded(child: children[i]),
            if (i < children.length - 1) SizedBox(width: 8.w),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Key Widgets
// ─────────────────────────────────────────────────────────────

/// Tombol angka (0-9, 000, koma).
class _NumericKey extends StatelessWidget {
  const _NumericKey({required this.label, required this.controller});

  final String label;
  final SakuCurrencyController controller;

  static const _validator = CalculatorInputValidator();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: () {
        // Validasi sebelum insert
        if (!_validator.canInsert(label, controller.text)) return;

        // Insert karakter
        final wrapper = KeyboardWrapper.of(context);
        wrapper?.onKey(CustomKeyboardEvent.character(label));
      },
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol operator (+, -, ×, ÷).
class _OperatorKey extends StatelessWidget {
  const _OperatorKey({required this.label, required this.controller});

  final String label;
  final SakuCurrencyController controller;

  static const _validator = CalculatorInputValidator();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: () {
        final currentText = controller.text;

        // Cek apakah perlu replace operator
        final replaced = _validator.handleConsecutiveOperator(
          ' $label ',
          currentText,
        );
        if (replaced != null) {
          controller.text = replaced;
          controller.selection = TextSelection.collapsed(
            offset: controller.text.length,
          );
          return;
        }

        // Validasi sebelum insert
        if (!_validator.canInsert(label, currentText)) return;

        // Insert operator dengan spasi
        final wrapper = KeyboardWrapper.of(context);
        wrapper?.onKey(CustomKeyboardEvent.character(' $label '));
      },
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w600,
              color: colors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol aksi (C, backspace).
class _ActionKey extends StatelessWidget {
  const _ActionKey({
    this.label,
    this.icon,
    this.labelColor,
    this.iconColor,
    required this.backgroundColor,
    required this.event,
  });

  final String? label;
  final IconData? icon;
  final Color? labelColor;
  final Color? iconColor;
  final Color backgroundColor;
  final CustomKeyboardEvent event;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return CustomKeyboardKey(
      keyEvent: event,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: icon != null
              ? FaIcon(
                  icon,
                  size: 20.sp,
                  color: iconColor ?? colors.textPrimary,
                )
              : Text(
                  label ?? '',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: labelColor ?? colors.textPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Tombol dinamis yang berubah antara `=` dan `>`.
///
/// - `=` (evaluate): Jika ada operator di text
/// - `>` (submit): Jika tidak ada operator
class _DynamicSubmitButton extends StatelessWidget {
  const _DynamicSubmitButton({
    required this.controller,
    this.onEvaluate,
    this.onSubmit,
  });

  final SakuCurrencyController controller;
  final VoidCallback? onEvaluate;
  final ValueChanged<double>? onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accentTextColor =
        ThemeData.estimateBrightnessForColor(colors.accent) == Brightness.dark
        ? Colors.white
        : const Color(0xFF0F172A);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final showEquals = controller.hasOperator;

        if (showEquals) {
          // Mode: Evaluate (=)
          return GestureDetector(
            onTap: () {
              // Evaluate ekspresi
              controller.evaluate();
              onEvaluate?.call();
            },
            child: Container(
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Text(
                  '=',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: accentTextColor,
                  ),
                ),
              ),
            ),
          );
        } else {
          // Mode: Submit (>)
          return GestureDetector(
            onTap: () {
              final value = controller.numericValue;
              onSubmit?.call(value);
              // Close keyboard dengan unfocus
              FocusScope.of(context).unfocus();
            },
            child: Container(
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.chevronRight,
                  size: 24.sp,
                  color: colors.onPrimary,
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
