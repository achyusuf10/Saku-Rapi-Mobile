import 'dart:convert';

import 'package:app_saku_rapi/features/auth/utils/google_id_token_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoogleIdTokenUtils', () {
    test('parsePayload reads JWT payload correctly', () {
      final token = _buildToken({
        'exp': 1_800_000_000,
        'email': 'test@test.com',
      });

      final payload = GoogleIdTokenUtils.parsePayload(token);

      expect(payload['exp'], 1_800_000_000);
      expect(payload['email'], 'test@test.com');
    });

    test(
      'isExpiredOrNearExpiry returns false for token that is still valid',
      () {
        final now = DateTime.utc(2026, 4, 12, 14, 0);
        final token = _buildToken({
          'exp':
              now.add(const Duration(minutes: 5)).millisecondsSinceEpoch ~/
              1000,
        });

        final isExpired = GoogleIdTokenUtils.isExpiredOrNearExpiry(
          token,
          nowUtc: now,
        );

        expect(isExpired, isFalse);
      },
    );

    test('isExpiredOrNearExpiry returns true for expired token', () {
      final now = DateTime.utc(2026, 4, 12, 14, 0);
      final token = _buildToken({
        'exp':
            now.subtract(const Duration(minutes: 1)).millisecondsSinceEpoch ~/
            1000,
      });

      final isExpired = GoogleIdTokenUtils.isExpiredOrNearExpiry(
        token,
        nowUtc: now,
      );

      expect(isExpired, isTrue);
    });

    test('isExpiredOrNearExpiry treats near-expiry token as expired', () {
      final now = DateTime.utc(2026, 4, 12, 14, 0);
      final token = _buildToken({
        'exp':
            now.add(const Duration(seconds: 30)).millisecondsSinceEpoch ~/ 1000,
      });

      final isExpired = GoogleIdTokenUtils.isExpiredOrNearExpiry(
        token,
        nowUtc: now,
      );

      expect(isExpired, isTrue);
    });

    test('parsePayload throws for malformed token', () {
      expect(
        () => GoogleIdTokenUtils.parsePayload('invalid-token'),
        throwsFormatException,
      );
    });
  });
}

String _buildToken(Map<String, dynamic> payload) {
  final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'RS256'})));
  final encodedPayload = base64Url.encode(utf8.encode(jsonEncode(payload)));

  return '$header.$encodedPayload.signature';
}
