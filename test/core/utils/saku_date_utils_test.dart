import 'package:app_saku_rapi/core/utils/saku_date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SakuDateUtils', () {
    test('formatTimestamp serializes timestamps as UTC ISO 8601', () {
      final localTimestamp = DateTime.utc(2026, 4, 12, 15, 30, 45).toLocal();

      expect(
        SakuDateUtils.formatTimestamp(localTimestamp),
        DateTime.utc(2026, 4, 12, 15, 30, 45).toIso8601String(),
      );
    });

    test('parseOptionalTimestamp preserves the same instant', () {
      final utcTimestamp = DateTime.utc(2026, 4, 12, 15, 30, 45);

      final parsed = SakuDateUtils.parseOptionalTimestamp(
        utcTimestamp.toIso8601String(),
      );

      expect(parsed?.toUtc(), utcTimestamp);
    });

    test('formatDate keeps local calendar semantics', () {
      final value = DateTime.utc(2026, 4, 12, 23, 30);
      final local = value.toLocal();

      expect(
        SakuDateUtils.formatDate(value),
        '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}',
      );
    });

    test('parseRequiredDate parses date-only strings without UTC drift', () {
      final parsed = SakuDateUtils.parseRequiredDate('2026-04-12');

      expect(parsed.year, 2026);
      expect(parsed.month, 4);
      expect(parsed.day, 12);
      expect(parsed.hour, 0);
      expect(parsed.minute, 0);
      expect(parsed.isUtc, isFalse);
    });

    test(
      'parseOptionalFlexibleLocalDateTime keeps explicit local time details',
      () {
        final parsed = SakuDateUtils.parseOptionalFlexibleLocalDateTime(
          '2026-04-12T08:45:00',
        );

        expect(parsed, isNotNull);
        expect(parsed!.year, 2026);
        expect(parsed.month, 4);
        expect(parsed.day, 12);
        expect(parsed.hour, 8);
        expect(parsed.minute, 45);
        expect(parsed.isUtc, isFalse);
      },
    );

    test(
      'localDayRangeUtc converts local day boundaries to UTC ISO strings',
      () {
        final range = SakuDateUtils.localDayRangeUtc(
          startDate: DateTime(2026, 4, 12, 18, 30),
          endDate: DateTime(2026, 4, 12, 23, 59),
        );

        expect(DateTime.parse(range.startUtc).toLocal(), DateTime(2026, 4, 12));
        expect(
          DateTime.parse(range.endUtcExclusive).toLocal(),
          DateTime(2026, 4, 13),
        );
      },
    );
  });
}
