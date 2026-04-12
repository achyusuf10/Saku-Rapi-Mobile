import 'dart:convert';

class GoogleIdTokenUtils {
  const GoogleIdTokenUtils._();

  static const Duration _defaultExpiryBuffer = Duration(minutes: 1);

  static bool isExpiredOrNearExpiry(
    String idToken, {
    DateTime? nowUtc,
    Duration expiryBuffer = _defaultExpiryBuffer,
  }) {
    final payload = parsePayload(idToken);
    final exp = payload['exp'];

    if (exp is! num) {
      throw const FormatException(
        'Google ID token tidak memiliki claim exp yang valid.',
      );
    }

    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      exp.toInt() * 1000,
      isUtc: true,
    );
    final currentTime = (nowUtc ?? DateTime.now().toUtc()).toUtc();

    return !expiresAt.isAfter(currentTime.add(expiryBuffer));
  }

  static Map<String, dynamic> parsePayload(String idToken) {
    final parts = idToken.split('.');

    if (parts.length != 3) {
      throw const FormatException('Format Google ID token tidak valid.');
    }

    final normalizedPayload = base64Url.normalize(parts[1]);
    final decodedPayload = utf8.decode(base64Url.decode(normalizedPayload));
    final payload = jsonDecode(decodedPayload);

    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Payload Google ID token tidak valid.');
    }

    return payload;
  }
}
