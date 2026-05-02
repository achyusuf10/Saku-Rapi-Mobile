import 'package:app_saku_rapi/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Konstanta layout PDF (presentasi: margin ketat, konsisten).
abstract final class ExportPdfLayout {
  ExportPdfLayout._();

  /// Margin halaman PDF (Syncfusion).
  static const double pageMarginPt = 12;

  /// Jarak kiri/kanan untuk tabel & blok angka — sama di semua halaman.
  static const double tableSideInset = 8;

  /// Padding teks judul bab / KPI (dari tepi area konten).
  static const double textInsetPt = 12;

  /// Padding halaman landscape untuk judul + chart.
  static const double landscapePad = 18;

  /// Ukuran capture chart (logical px) — bounds eksplisit untuk [RepaintBoundary].
  static const double chartCaptureWidth = 1000;
  static const double chartCaptureHeightBar = 480;
  static const double chartCaptureHeightPie = 620;
}

/// Map [AppColorScheme] + [ThemeData] ke warna/font dasar PDF.
final class ExportPdfTheme {
  ExportPdfTheme._({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.primary,
    required this.income,
    required this.expense,
    required this.transfer,
    required this.warning,
    required this.headerFill,
  });

  final PdfColor background;
  final PdfColor surface;
  final PdfColor textPrimary;
  final PdfColor textSecondary;
  final PdfColor border;
  final PdfColor primary;
  final PdfColor income;
  final PdfColor expense;
  final PdfColor transfer;
  final PdfColor warning;
  final PdfColor headerFill;

  static ExportPdfTheme fromContext({
    required AppColorScheme colors,
  }) {
    return ExportPdfTheme._(
      background: _c(colors.background),
      surface: _c(colors.surface),
      textPrimary: _c(colors.textPrimary),
      textSecondary: _c(colors.textSecondary),
      border: _c(colors.border),
      primary: _c(colors.primary),
      income: _c(colors.income),
      expense: _c(colors.expense),
      transfer: _c(colors.transfer),
      warning: _c(colors.warning),
      headerFill: _c(colors.surfaceVariant),
    );
  }

  static PdfColor _c(Color c) => PdfColor(
        (c.r * 255).round().clamp(0, 255),
        (c.g * 255).round().clamp(0, 255),
        (c.b * 255).round().clamp(0, 255),
      );

  PdfSolidBrush brush(PdfColor c) => PdfSolidBrush(c);

  PdfPen pen(PdfColor c, [double width = 0.5]) => PdfPen(c, width: width);

  PdfFont bodyFont([double size = 9]) =>
      PdfStandardFont(PdfFontFamily.helvetica, size);

  PdfFont boldFont([double size = 9]) => PdfStandardFont(
        PdfFontFamily.helvetica,
        size,
        style: PdfFontStyle.bold,
      );

  /// Teks putih di atas header tabel bergaya “brand”.
  PdfSolidBrush get onPrimaryBrush => PdfSolidBrush(PdfColor(255, 255, 255));
}
