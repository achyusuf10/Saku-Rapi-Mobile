import 'package:flutter/material.dart';

/// Preset periode laporan untuk layar Export.
enum ExportPeriodPreset {
  thisMonth,
  lastMonth,
  thisQuarter,
  thisYear,
  custom,
}

/// Menghitung [DateTimeRange] lokal (tanggal saja) untuk tiap preset non-custom.
final class ExportPeriodRanges {
  ExportPeriodRanges._();

  /// [now] boleh memuat jam; ujung rentang preset selalu **hari ini** (normalize).
  static DateTimeRange fromPreset(
    ExportPeriodPreset preset, {
    DateTime? now,
  }) {
    assert(
      preset != ExportPeriodPreset.custom,
      'Gunakan customPeriod untuk preset custom.',
    );
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);

    switch (preset) {
      case ExportPeriodPreset.thisMonth:
        return DateTimeRange(
          start: DateTime(today.year, today.month, 1),
          end: today,
        );
      case ExportPeriodPreset.lastMonth:
        final firstThis = DateTime(today.year, today.month, 1);
        final endPrev = firstThis.subtract(const Duration(days: 1));
        return DateTimeRange(
          start: DateTime(endPrev.year, endPrev.month, 1),
          end: endPrev,
        );
      case ExportPeriodPreset.thisQuarter:
        final qStartMonth = ((today.month - 1) ~/ 3) * 3 + 1;
        return DateTimeRange(
          start: DateTime(today.year, qStartMonth, 1),
          end: today,
        );
      case ExportPeriodPreset.thisYear:
        return DateTimeRange(
          start: DateTime(today.year, 1, 1),
          end: today,
        );
      case ExportPeriodPreset.custom:
        throw ArgumentError.value(preset, 'preset');
    }
  }
}
