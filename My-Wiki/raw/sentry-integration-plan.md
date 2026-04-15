# Plan: Sentry Integration — SakuRapi

**Tanggal**: 2026-04-15  
**Status**: Planning

---

## Latar Belakang

SakuRapi belum punya error monitoring di production. `sentry_flutter: ^9.17.0` sudah ada di `pubspec.yaml` tapi belum diintegrasikan. Firebase Crashlytics juga ada di `AppLogger` tapi di-comment. Tujuan integrasi Sentry:

1. Tahu kalau ada error di production sebelum user lapor
2. Tau konteks lengkap: siapa usernya, lagi ngapain, di halaman apa, payload dan response-nya apa
3. Tidak banjir noise — hanya capture yang penting dan actionable

---

## Keputusan Desain

| Keputusan | Pilihan | Alasan |
|---|---|---|
| DSN | 1 project, beda `environment` tag | Lebih simpel, filter di Sentry dashboard |
| Dev flavor | `sampleRate: 0.0` (tidak kirim error) | Tidak polusi data prod, breadcrumb tetap di-add lokal untuk debug flow |
| Prod flavor | `sampleRate: 1.0` error, `tracesSampleRate: 0.2` | Tangkap semua error prod, performance sampling rendah |

---

## Apa yang DITANGKAP (Penting & Actionable)

| Kategori | Kondisi | Level |
|---|---|---|
| `PostgrestException` dari Supabase | Selalu (kecuali `PGRST116`) | `error` |
| `FunctionException` dari Edge Function | Status ≥ 500 saja | `error` |
| `AuthException` | Hanya yang bukan 401/403 user flow | `warning` |
| Flutter uncaught error | `FlutterError.onError` | `fatal` |
| Dart uncaught error | `PlatformDispatcher.onError` | `fatal` |
| Business logic critical | Transaction save/update gagal, wallet sync gagal | `error` |

## Apa yang TIDAK DITANGKAP (Noise / Expected)

| Kondisi | Alasan |
|---|---|
| `FunctionException` status 401/403 | User belum login atau token expired — expected |
| `FunctionException` status 422 | Validation error — business logic expected |
| `SocketException` / `ClientException` | User offline — expected |
| `PGRST116` (no rows) | Query mengembalikan 0 row — bukan error |
| AI quota exceeded | Business logic, bukan bug |
| `AppLogger.call()` biasa | Info log, bukan error |
| Dev flavor | `sampleRate: 0.0` |

---

## Arsitektur

### File Baru

```
lib/core/services/
├── sentry_service.dart         ← Wrapper utama Sentry
lib/core/models/
├── sentry_context.dart         ← Model konteks per event
```

### File yang Dimodifikasi

```
lib/main.dart                   ← Wrap bootstrap() dengan SentryFlutter.init()
lib/core/logger/app_logger.dart ← logError() → juga capture ke Sentry
lib/core/network/supabase_handler.dart ← Inject SentryContext per call
lib/core/config/app_flavor.dart ← Tambah sentryDsn getter (via env var)
```

---

## SentryContext Model

```dart
class SentryContext {
  final String action;     // "create_transaction", "fetch_wallets", dll
  final String? page;      // "TransactionFormPage", "WalletListPage", dll  
  final Map<String, dynamic>? payload;    // Request body / parameter
  final Map<String, dynamic>? response;  // Response/error body
  final Map<String, String>? tags;       // Extra tags untuk filter Sentry

  const SentryContext({
    required this.action,
    this.page,
    this.payload,
    this.response,
    this.tags,
  });
}
```

---

## SentryService

```dart
class SentryService {
  /// Init dipanggil di bootstrap(), sebelum runApp()
  static Future<void> init() async { ... }

  /// Set user context saat login berhasil
  static void setUser(String userId, String? email) { ... }

  /// Clear user context saat logout
  static void clearUser() { ... }

  /// Capture exception dengan konteks
  static void captureException(
    dynamic exception,
    StackTrace? stackTrace, {
    SentryContext? context,
    SentryLevel level = SentryLevel.error,
  }) { ... }

  /// Add breadcrumb (tetap berjalan di dev, tidak terkirim karena sampleRate=0)
  static void addBreadcrumb(String message, {
    String category = 'app',
    Map<String, dynamic>? data,
    SentryLevel level = SentryLevel.info,
  }) { ... }

  /// Cek apakah Sentry harus mengirim event (hanya prod)
  static bool get _shouldCapture => AppFlavorConfig.isProd;
  
  /// Cek apakah exception ini layak dikirim ke Sentry
  static bool _isCapturableException(dynamic exception) {
    // Filter noise
    if (exception is SocketException) return false;
    if (exception is ClientException) return false;
    if (exception is PostgrestException && exception.code == 'PGRST116') return false;
    if (exception is FunctionException && (exception.status == 401 || exception.status == 403 || exception.status == 422)) return false;
    return true;
  }
}
```

---

## Integrasi di bootstrap()

```dart
// Di main.dart
Future<void> bootstrap() async {
  // ... init lainnya ...
  
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.environment = AppFlavorConfig.name.toLowerCase(); // 'dev' atau 'prod'
      options.release = 'sakurapi@${const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0')}';
      
      // Dev: breadcrumb saja, tidak kirim error ke server
      // Prod: tangkap semua error
      options.sampleRate = AppFlavorConfig.isProd ? 1.0 : 0.0;
      options.tracesSampleRate = AppFlavorConfig.isProd ? 0.2 : 0.0;
      
      // Tidak kirim PII (email, IP) secara otomatis
      options.sendDefaultPii = false;
      
      // Flutter-specific
      options.attachScreenshot = false; // Privacy, tidak kirim screenshot
      options.attachViewHierarchy = false;
    },
    appRunner: () => runApp(
      ProviderScope(
        observers: [...],
        child: SakuRapiApp(),
      ),
    ),
  );
}
```

> **Note**: DSN harus di-inject via `--dart-define=SENTRY_DSN=...` di run command, sama seperti `SUPABASE_URL`.

---

## Integrasi di AppLogger.logError()

```dart
static void logError(
  dynamic message, {
  Type? runtimeType,
  String? nameLog,
  bool sendToSentry = false,   // BARU: default false untuk tidak banjir
  SentryContext? sentryContext, // BARU: konteks tambahan
  StackTrace? stackTrace,
}) {
  // ... existing console log ...
  
  if (sendToSentry) {
    SentryService.captureException(
      message,
      stackTrace,
      context: sentryContext,
    );
  }
}
```

---

## Integrasi di SupabaseHandler

```dart
static Future<DataState<T>> call<T>({
  required Future<T> Function() function,
  SentryContext? sentryContext, // BARU
}) async {
  try {
    // ...
  } on PostgrestException catch (e, stackTrace) {
    AppLogger.logError(...);
    SentryService.captureException(e, stackTrace, context: sentryContext);
    // ...
  } catch (e, stackTrace) {
    AppLogger.logError(...);
    SentryService.captureException(e, stackTrace, context: sentryContext);
    // ...
  }
}
```

---

## Cara Pakai di Repository

```dart
// Di wallet_repository.dart
final response = await remoteDataSource.getWallets(
  sentryContext: SentryContext(
    action: 'fetch_wallets',
    page: 'WalletListPage',
  ),
);

// Di transaction_repository.dart saat create transaction
final response = await remoteDataSource.createTransaction(
  params,
  sentryContext: SentryContext(
    action: 'create_transaction',
    page: 'TransactionFormPage',
    payload: {'type': params.type, 'amount': params.totalAmount},
  ),
);
```

---

## User Context (Auth)

Saat user berhasil login, panggil:
```dart
SentryService.setUser(user.id, user.email);
```

Saat logout:
```dart
SentryService.clearUser();
```

Lokasi: auth controller/repository, setelah login berhasil / sebelum logout.

---

## Sentry Dashboard — Yang Akan Kamu Lihat per Event

| Field | Contoh |
|---|---|
| `user.id` | `b0b306e5-...` |
| `user.email` | `achyusufbagus@gmail.com` |
| `environment` | `prod` / `dev` |
| `tag: action` | `create_transaction` |
| `tag: page` | `TransactionFormPage` |
| `extra: payload` | `{"type": "expense", "amount": 50000}` |
| `extra: response` | `{"code": "23503", "message": "violates FK constraint"}` |
| `extra: supabase_error_code` | `23503` |
| `breadcrumb` | Riwayat aksi sebelum error terjadi |

---

## Setup yang Dibutuhkan

### 1. Buat Sentry Project
- Buka sentry.io → Create project → Flutter
- Salin DSN

### 2. Tambah ke run config
```
--dart-define=SENTRY_DSN=https://xxx@xxx.ingest.sentry.io/xxx
```

Tambahkan ke:
- `launch.json` (VS Code)
- Fastlane / CI scripts

### 3. Tidak perlu package tambahan
`sentry_flutter: ^9.17.0` sudah ada.

---

## Langkah Implementasi

1. Buat `SentryContext` model
2. Buat `SentryService` wrapper
3. Modifikasi `main.dart` → wrap dengan `SentryFlutter.init()`
4. Modifikasi `AppLogger.logError()` → tambah `sendToSentry` + `sentryContext`
5. Modifikasi `SupabaseHandler.call()` → tambah `sentryContext`, auto-capture exception
6. Tambah `setUser` / `clearUser` di auth flow
7. Pasang `--dart-define=SENTRY_DSN=...` di launch config

---

## Yang Tidak Dilakukan (Scope Out)

- Performance tracing per transaction (terlalu verbose, bisa tambah nanti)
- Session replay / screenshot (privacy concern)
- Custom Sentry dashboard (pakai built-in)
- Integrasi GitHub/Slack notif (bisa setup sendiri di Sentry dashboard)
