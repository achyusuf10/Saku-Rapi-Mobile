---
title: "Plan: Sentry Integration"
type: source
tags: [sentry, error-monitoring, flutter, logging, observability, prod]
source_file: raw/sentry-integration-plan.md
created: 2026-04-15
updated: 2026-04-15
---

# Plan: Sentry Integration — Ringkasan

> Sumber: `raw/sentry-integration-plan.md`  
> Status: **Selesai diimplementasi** (April 2026)

---

## Apa yang Dibangun

Integrasi Sentry untuk error monitoring di production. `sentry_flutter: ^9.17.0` sudah ada di `pubspec.yaml` sebelumnya (belum dipakai). Firebase Crashlytics sudah di-comment di `AppLogger`. Tujuan:

1. Tahu error di production sebelum user lapor
2. Konteks lengkap per event: user, halaman, action, payload, response
3. Tidak banjir noise — hanya tangkap yang penting dan actionable

---

## Keputusan Desain

| Keputusan | Pilihan | Alasan |
|---|---|---|
| Sentry project | 1 project, beda `environment` tag | Lebih simpel, filter di Sentry dashboard |
| Dev flavor | `sampleRate: 0.0` | Tidak polusi data prod; breadcrumb tetap di-track lokal |
| Prod flavor | `sampleRate: 1.0`, `tracesSampleRate: 0.2` | Tangkap semua error prod, performance sampling rendah |
| PII | `sendDefaultPii = false` | Privacy — tidak kirim email/IP secara otomatis |
| Screenshot | `attachScreenshot = false` | Privacy |

---

## Apa yang DITANGKAP vs TIDAK DITANGKAP

### ✅ Ditangkap (Penting & Actionable)

| Kategori | Kondisi |
|---|---|
| `PostgrestException` | Semua kecuali `PGRST116` (no rows) |
| `FunctionException` | Status ≥ 500 saja (server error) |
| `AuthException` | Yang bukan 400/401/403 (auth flow normal) |
| Flutter uncaught error | Via `SentryFlutter.init()` `appRunner` zone |
| Business logic critical | Bisa pass `sendToSentry: true` di `AppLogger.logError()` |

### ❌ Tidak Ditangkap (Noise / Expected)

| Kondisi | Alasan |
|---|---|
| `SocketException` | User offline — expected |
| `FunctionException` status < 500 | Client/auth error — expected |
| `PGRST116` (no rows) | Bukan error, query normal |
| `AuthException` 400/401/403 | Auth flow normal |
| Dev flavor | `sampleRate: 0.0` |

---

## Files Dibuat/Diubah

**Baru (Flutter):**
- `lib/core/models/sentry_context.dart` — model konteks per event
- `lib/core/services/sentry_service.dart` — wrapper Sentry terpusat

**Diubah (Flutter):**
- `lib/main.dart` — `bootstrap()` dibungkus `SentryFlutter.init()`, config per flavor
- `lib/core/logger/app_logger.dart` — `logError()` + param `sendToSentry` + `sentryContext`
- `lib/core/network/supabase_handler.dart` — `call()` + param `sentryContext`, auto-capture exception
- `lib/features/auth/controllers/auth_controller.dart` — `setUser` saat login, `clearUser` saat logout

**Env:**
- `.env.dev` + `.env.prod` — ditambahkan `SENTRY_DSN=` (kosong, perlu diisi manual)

---

## Arsitektur

### SentryContext Model

```dart
class SentryContext {
  final String action;                    // "create_transaction", "fetch_wallets"
  final String? page;                     // "TransactionFormPage", "WalletListPage"
  final Map<String, dynamic>? payload;   // Data yang dikirim ke backend
  final Map<String, dynamic>? response;  // Response/error body dari backend
  final Map<String, String>? tags;       // Extra Sentry tags untuk filter
}
```

### SentryService API

```dart
SentryService.setUser(userId, email);     // Setelah login
SentryService.clearUser();                // Setelah logout
SentryService.captureException(e, st, context: ctx);  // Manual capture
SentryService.addBreadcrumb('message', category: 'wallet', data: {...});
```

### Config per Flavor di main.dart

```dart
await SentryFlutter.init(
  (options) {
    options.dsn = const String.fromEnvironment('SENTRY_DSN');
    options.environment = AppFlavorConfig.name.toLowerCase(); // 'dev'/'prod'
    options.sampleRate = AppFlavorConfig.isProd ? 1.0 : 0.0;
    options.tracesSampleRate = AppFlavorConfig.isProd ? 0.2 : 0.0;
    options.sendDefaultPii = false;
  },
  appRunner: () => runApp(ProviderScope(...)),
);
```

### Auto-Capture di SupabaseHandler

Semua `SupabaseHandler.call()` otomatis kirim exception ke Sentry kecuali `AuthException`. Pass `sentryContext` untuk konteks tambahan:

```dart
return SupabaseHandler.call<List<WalletModel>>(
  sentryContext: SentryContext(
    action: 'fetch_wallets',
    page: 'WalletListPage',
  ),
  function: () async { ... },
);
```

### Manual Capture via AppLogger

Untuk error di luar `SupabaseHandler`:

```dart
AppLogger.logError(
  'Failed to process receipt',
  runtimeType: OcrRepository,
  sendToSentry: true,
  sentryContext: SentryContext(
    action: 'ocr_parse',
    page: 'OcrReceiptPage',
    payload: {'fileName': 'receipt.jpg'},
  ),
  stackTrace: stackTrace,
);
```

---

## Sentry Dashboard — Context per Event

| Field | Contoh |
|---|---|
| `user.id` | `b0b306e5-...` (UUID user Supabase) |
| `user.email` | dari `SentryService.setUser()` |
| `environment` | `prod` / `dev` |
| `tag: action` | `create_transaction` |
| `tag: page` | `TransactionFormPage` |
| `tag: supabase.error_code` | `23503` (FK violation) |
| `tag: function.http_status` | `500` |
| `extra: payload` | `{"type": "expense", "amount": 50000}` |
| `extra: response` | `{"code": "23503", "message": "..."}` |

---

## Setup DSN (Perlu Dilakukan Manual)

1. Buat project di [sentry.io](https://sentry.io) → pilih **Flutter**
2. Salin DSN (format: `https://xxx@oXXX.ingest.sentry.io/xxx`)
3. Isi di kedua env file:
   ```
   SENTRY_DSN=https://xxx@oXXX.ingest.sentry.io/xxx
   ```
4. DSN sama untuk dev & prod — dibedakan via `environment` tag di Sentry

> **Note:** Selama `SENTRY_DSN` kosong, Sentry SDK tidak akan crash tetapi tidak akan mengirim apapun.

---

## Lihat Juga

- [[wiki/concepts/keamanan|Keamanan & Security Posture]] — postur keamanan keseluruhan
- [[wiki/concepts/arsitektur-app|Arsitektur App]] — 3-file pattern, SupabaseHandler
- [[wiki/entities/edge-functions|Edge Functions]] — error dari edge function ditangkap via `FunctionException`
- `raw/sentry-integration-plan.md` — plan lengkap dengan semua code sample
