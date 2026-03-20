import 'dart:convert';
import 'dart:io';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// HTTP client dengan SSL Certificate Pinning menggunakan SHA-256 fingerprint.
///
/// Fingerprint di-supply via `--dart-define=SSL_FINGERPRINTS=hash1,hash2`.
/// Mendukung beberapa fingerprint sekaligus untuk rotasi sertifikat.
///
/// Jika fingerprint kosong (dev mode), fallback ke trust store default.
///
/// Contoh penggunaan:
/// ```dart
/// final client = SslPinningClient();
/// final response = await client.post(
///   Uri.parse('https://example.com/api'),
///   headers: {'Authorization': 'Bearer $token'},
///   body: {'key': 'value'},
/// );
/// client.close();
/// ```
class SslPinningClient {
  static const _tag = 'SslPinning';

  /// Fingerprint SHA-256 dari sertifikat yang di-pin.
  /// Format: comma-separated lowercase hex hashes.
  static const _rawFingerprints = String.fromEnvironment(
    'SSL_FINGERPRINTS',
    defaultValue: '',
  );

  late final HttpClient _client;
  late final List<String> _pins;

  SslPinningClient() {
    _pins = _parseFingerprints();

    if (_pins.isEmpty) {
      // Dev mode — gunakan trust store default OS.
      _client = HttpClient();
      if (kDebugMode) {
        AppLogger.call(
          '[$_tag] No pins configured — using default trust store',
          colorLog: ColorLog.yellow,
        );
      }
    } else {
      // Production — tolak semua sertifikat kecuali yang cocok pin.
      final context = SecurityContext(withTrustedRoots: false);
      _client = HttpClient(context: context)
        ..badCertificateCallback = _validateCertificate;

      AppLogger.call(
        '[$_tag] Initialized with ${_pins.length} pinned fingerprint(s)',
        colorLog: ColorLog.green,
      );
    }
  }

  /// Parse comma-separated fingerprints menjadi list lowercase.
  List<String> _parseFingerprints() {
    if (_rawFingerprints.isEmpty) return [];
    return _rawFingerprints
        .split(',')
        .map((fp) => fp.trim().toLowerCase())
        .where((fp) => fp.isNotEmpty)
        .toList();
  }

  /// Callback verifikasi sertifikat terhadap pinned fingerprint.
  bool _validateCertificate(X509Certificate cert, String host, int port) {
    final certHash = sha256.convert(cert.der).toString().toLowerCase();
    final isValid = _pins.contains(certHash);

    if (!isValid) {
      AppLogger.logError(
        '[$_tag] Certificate pin mismatch for $host:$port\n'
        'Expected one of: $_pins\n'
        'Got: $certHash',
        runtimeType: SslPinningClient,
      );
    }

    return isValid;
  }

  /// HTTP POST request dengan SSL pinning.
  ///
  /// [body] akan di-encode ke JSON secara otomatis.
  /// Return: response body sebagai `Map<String, dynamic>`.
  Future<Map<String, dynamic>> post(
    Uri uri, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    final request = await _client.postUrl(uri);

    // Set headers
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    headers?.forEach((key, value) => request.headers.set(key, value));

    // Write body
    if (body != null) {
      request.write(jsonEncode(body));
    }

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'HTTP ${response.statusCode}: $responseBody',
        uri: uri,
      );
    }

    return jsonDecode(responseBody) as Map<String, dynamic>;
  }

  /// Tutup koneksi HTTP client.
  void close() {
    _client.close();
  }
}
