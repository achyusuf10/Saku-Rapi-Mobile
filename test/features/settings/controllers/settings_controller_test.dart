import 'package:app_saku_rapi/features/settings/controllers/settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ─── TransactionEntryPoint enum tests ───

  group('TransactionEntryPoint', () {
    group('fromString', () {
      test('returns manual for "manual"', () {
        expect(
          TransactionEntryPoint.fromString('manual'),
          TransactionEntryPoint.manual,
        );
      });

      test('returns voice for "voice"', () {
        expect(
          TransactionEntryPoint.fromString('voice'),
          TransactionEntryPoint.voice,
        );
      });

      test('returns scan for "scan"', () {
        expect(
          TransactionEntryPoint.fromString('scan'),
          TransactionEntryPoint.scan,
        );
      });

      test('returns manual for null (default fallback)', () {
        expect(
          TransactionEntryPoint.fromString(null),
          TransactionEntryPoint.manual,
        );
      });

      test('returns manual for unknown string', () {
        expect(
          TransactionEntryPoint.fromString('unknown'),
          TransactionEntryPoint.manual,
        );
      });

      test('returns manual for empty string', () {
        expect(
          TransactionEntryPoint.fromString(''),
          TransactionEntryPoint.manual,
        );
      });
    });

    group('dbValue', () {
      test('manual returns "manual"', () {
        expect(TransactionEntryPoint.manual.dbValue, 'manual');
      });

      test('voice returns "voice"', () {
        expect(TransactionEntryPoint.voice.dbValue, 'voice');
      });

      test('scan returns "scan"', () {
        expect(TransactionEntryPoint.scan.dbValue, 'scan');
      });
    });

    group('roundtrip fromString ↔ dbValue', () {
      test('all values survive roundtrip', () {
        for (final entry in TransactionEntryPoint.values) {
          final roundtripped = TransactionEntryPoint.fromString(entry.dbValue);
          expect(roundtripped, entry, reason: '${entry.name} roundtrip failed');
        }
      });
    });
  });
}
