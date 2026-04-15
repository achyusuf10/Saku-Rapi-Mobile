import 'dart:io';

import 'package:app_saku_rapi/core/models/sentry_context.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wrapper terpusat untuk Sentry error monitoring.
///
/// ### Cara pakai
/// ```dart
/// SentryService.captureException(
///   e, stackTrace,
///   context: SentryContext(
///     action: 'create_transaction',
///     page: 'TransactionFormPage',
///     payload: {'amount': 50000},
///   ),
/// );
/// ```
///
/// Di prod, sampleRate = 1.0 → semua error dikirim.
/// Di dev, sampleRate = 0.0 → tidak ada yang dikirim ke server Sentry.
class SentryService {
  SentryService._();

  // ─────────────────────────────────────────────────────────
  // User identity
  // ─────────────────────────────────────────────────────────

  /// Set identitas user setelah login berhasil.
  static void setUser(String userId, String? email) {
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(id: userId, email: email));
    });
  }

  /// Hapus identitas user setelah logout.
  static void clearUser() {
    Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }

  // ─────────────────────────────────────────────────────────
  // Capture exception
  // ─────────────────────────────────────────────────────────

  /// Kirim exception ke Sentry dengan konteks tambahan.
  ///
  /// Exception yang di-filter (tidak dikirim):
  /// - [SocketException] → offline, expected
  /// - [FunctionException] status < 500 → client/auth error, expected
  /// - [PostgrestException] code `PGRST116` → no rows found, bukan error
  /// - [AuthException] statusCode 400/401/403 → auth flow normal
  static void captureException(
    dynamic exception,
    StackTrace? stackTrace, {
    SentryContext? context,
    SentryLevel level = SentryLevel.error,
  }) {
    if (!_isCapturableException(exception)) return;

    // Fire-and-forget — SDK buffer menangani pengiriman
    Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.level = level;

        if (context != null) {
          scope.setTag('action', context.action);
          if (context.page != null) scope.setTag('page', context.page!);
          context.tags?.forEach((k, v) => scope.setTag(k, v));
          // ignore: deprecated_member_use
          if (context.payload != null) scope.setExtra('payload', context.payload!);
          // ignore: deprecated_member_use
          if (context.response != null) scope.setExtra('response', context.response!);
        }

        // Tambahkan detail spesifik per exception type
        if (exception is PostgrestException) {
          scope.setTag('supabase.error_code', exception.code ?? 'unknown');
          // ignore: deprecated_member_use
          scope.setExtra('supabase', {
            if (exception.hint != null) 'hint': exception.hint,
            if (exception.details != null) 'details': exception.details,
          });
        } else if (exception is FunctionException) {
          scope.setTag(
            'function.http_status',
            exception.status.toString(),
          );
          if (exception.details != null) {
            // ignore: deprecated_member_use
            scope.setExtra('function', {'details': exception.details!});
          }
        } else if (exception is AuthException) {
          scope.setTag(
            'auth.status_code',
            exception.statusCode?.toString() ?? 'unknown',
          );
        }
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // Breadcrumbs
  // ─────────────────────────────────────────────────────────

  /// Tambah breadcrumb untuk audit trail sebelum error terjadi.
  static void addBreadcrumb(
    String message, {
    String category = 'app',
    Map<String, dynamic>? data,
    SentryLevel level = SentryLevel.info,
  }) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        data: data,
        level: level,
        timestamp: DateTime.now().toUtc(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Internal: noise filter
  // ─────────────────────────────────────────────────────────

  static bool _isCapturableException(dynamic exception) {
    // Offline errors — bukan bug
    if (exception is SocketException) return false;

    // FunctionException: hanya capture server errors (>= 500)
    if (exception is FunctionException) {
      return exception.status >= 500;
    }

    // PostgrestException: skip "no rows found" (PGRST116)
    if (exception is PostgrestException) {
      return exception.code != 'PGRST116';
    }

    // AuthException: skip expected auth flows
    if (exception is AuthException) {
      final code = exception.statusCode;
      if (code == '400' || code == '401' || code == '403') return false;
    }

    return true;
  }
}
