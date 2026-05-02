import 'package:app_saku_rapi/features/export/utils/export_period_ranges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExportPeriodRanges', () {
    test('thisMonth starts at first of month and ends today', () {
      final now = DateTime(2026, 4, 15);
      final r = ExportPeriodRanges.fromPreset(
        ExportPeriodPreset.thisMonth,
        now: now,
      );
      expect(r.start, DateTime(2026, 4, 1));
      expect(r.end, DateTime(2026, 4, 15));
    });

    test('lastMonth covers full previous calendar month', () {
      final now = DateTime(2026, 4, 15);
      final r = ExportPeriodRanges.fromPreset(
        ExportPeriodPreset.lastMonth,
        now: now,
      );
      expect(r.start, DateTime(2026, 3, 1));
      expect(r.end, DateTime(2026, 3, 31));
    });

    test('thisQuarter starts at first month of quarter', () {
      final now = DateTime(2026, 5, 10);
      final r = ExportPeriodRanges.fromPreset(
        ExportPeriodPreset.thisQuarter,
        now: now,
      );
      expect(r.start, DateTime(2026, 4, 1));
      expect(r.end, DateTime(2026, 5, 10));
    });

    test('thisYear starts January 1', () {
      final now = DateTime(2026, 7, 1);
      final r = ExportPeriodRanges.fromPreset(
        ExportPeriodPreset.thisYear,
        now: now,
      );
      expect(r.start, DateTime(2026, 1, 1));
      expect(r.end, DateTime(2026, 7, 1));
    });
  });
}
