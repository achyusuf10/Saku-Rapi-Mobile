import 'package:app_saku_rapi/core/themes/app_colors.dart';
import 'package:flutter/material.dart';

/// Warna hex untuk styling sel Excel, diselaraskan dengan [AppColorScheme.light].
///
/// File Excel umumnya dibaca dalam konteks terang; kita pakai skema light + blend halus.
final class ExportExcelPalette {
  ExportExcelPalette._();

  static const _light = AppColorScheme.light;

  static String _hexRgb(Color c) {
    final r = (c.r * 255.0).round().clamp(0, 255);
    final g = (c.g * 255.0).round().clamp(0, 255);
    final b = (c.b * 255.0).round().clamp(0, 255);
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
  }

  static Color _blend(Color foreground, Color background, double a) {
    return Color.alphaBlend(foreground.withValues(alpha: a), background);
  }

  static String get primary => _hexRgb(_light.primary);
  static String get primaryLight => _hexRgb(_light.primaryLight);
  static String get income => _hexRgb(_light.income);
  static String get expense => _hexRgb(_light.expense);
  static String get transfer => _hexRgb(_light.transfer);
  static String get debtTone => _hexRgb(_light.debt);
  static String get loanTone => _hexRgb(_light.loan);
  static String get info => _hexRgb(_light.info);
  static String get surface => _hexRgb(_light.surface);
  static String get surfaceVariant => _hexRgb(_light.surfaceVariant);
  static String get border => _hexRgb(_light.border);
  static String get textPrimary => _hexRgb(_light.textPrimary);
  static String get textSecondary => _hexRgb(_light.textSecondary);
  static String get warning => _hexRgb(_light.warning);
  static String get accent => _hexRgb(_light.accent);

  static String get summaryIncomeBg => _hexRgb(_light.primaryLight);

  static String get summaryExpenseBg =>
      _hexRgb(_blend(_light.expense, _light.surface, 0.12));

  static String get summaryBalanceBg =>
      _hexRgb(_blend(_light.info, _light.surface, 0.14));

  static String get rowStripeOdd => surface;
  static String get rowStripeEven => _hexRgb(_light.surfaceVariant);

  static String get headerFill => _hexRgb(_light.primaryLight);

  /// Baris hutang/piutang lunas vs belum (selaras semantic success / warning).
  static String get debtPaidRowBg => _hexRgb(_blend(_light.income, _light.surface, 0.22));

  static String get debtUnpaidRowBg =>
      _hexRgb(_blend(_light.warning, _light.surface, 0.22));
}
