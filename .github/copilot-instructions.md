# SakuRapi — Copilot Instructions

SakuRapi is a Flutter personal finance app (Indonesian market, IDR only for MVP).
Backend is Supabase (Postgres + Edge Functions). Full PRD is split across 27 files in `docs/prd/`.

## Source-of-Truth Documents

### 🗂️ Wiki (Prioritas Utama)

**`My-Wiki/`** adalah knowledge base yang sudah dikompilasi dari semua dokumen di bawah. Baca wiki **sebelum** membaca raw docs — lebih cepat dan sudah ter-sintesis.

**Cara pakai wiki:**
1. Baca `My-Wiki/index.md` untuk melihat semua halaman yang tersedia
2. Buka halaman yang relevan di `My-Wiki/wiki/` sesuai fitur yang dikerjakan
3. Halaman wiki paling penting:
   - `My-Wiki/wiki/entities/database-schema.md` — skema DB lengkap (15 tabel, triggers, RPC)
   - `My-Wiki/wiki/concepts/aturan-keuangan.md` — financial guardrails non-negotiable
   - `My-Wiki/wiki/concepts/arsitektur-app.md` — tech stack, 3-file pattern, conventions
   - `My-Wiki/wiki/concepts/coding-rules.md` — aturan coding, forbidden actions
   - `My-Wiki/wiki/concepts/design-system.md` — "Financial Trust" design system (colors, typography)
   - `My-Wiki/wiki/entities/{feature}.md` — detail per fitur (wallet, transaksi, budgeting, dll)
   - `My-Wiki/wiki/concepts/coding-rules.md` — coding rules, forbidden actions, best practices

## Build & Run

```bash
# All Flutter commands MUST go through FVM (pinned to Flutter 3.41.6 in .fvmrc)
fvm flutter run                          # Run app
fvm flutter run --flavor dev -t lib/main_dev.dart   # Dev flavor
fvm flutter run --flavor prod -t lib/main_prod.dart # Prod flavor

fvm flutter analyze                      # Lint (uses flutter_lints)
fvm flutter test                         # All tests
fvm flutter test test/features/wallet/   # Tests for a feature
fvm flutter test test/path/to_test.dart  # Single test file

fvm flutter gen-l10n                     # Regenerate localization from .arb files
```

## Architecture

### Tech Stack

| Area | Choice |
|------|--------|
| State management | Riverpod **without** generator (no `@riverpod` annotations) |
| Routing | GoRouter (`lib/core/router/app_router.dart`) |
| Local storage | Hive |
| Backend | Supabase (Postgres + Edge Functions) |
| Icons | `font_awesome_flutter` (not Material Icons) |

### 3-File Data Pattern

Every feature's data layer follows exactly three files:

```
lib/features/{feature}/
├── datasource/
│   ├── {feature}_local_data_source.dart   # Hive/cache operations
│   └── {feature}_remote_data_source.dart  # Supabase calls, returns DataState<T>
├── repositories/
│   └── {feature}_repository.dart          # Orchestrator, pattern-matches DataState
├── controllers/                           # StateNotifier for UI state
├── models/                                # Plain Dart classes (see Model Rules)
└── view/
    ├── ui/          # Screen files
    └── widgets/     # Feature-specific widget extractions
```

### RemoteDataSource → SupabaseHandler

All Supabase calls must be wrapped:

```dart
Future<DataState<List<WalletModel>>> getWallets() async {
  return SupabaseHandler.call<List<WalletModel>>(
    function: () async {
      final res = await supabase.from('wallets').select();
      return res.map((e) => WalletModel.fromMap(e)).toList();
    },
  );
}
```

### Repository → Pattern Match DataState

```dart
final response = await remoteDataSource.getWallets();
return response.map(
  success: (data) => data.data,
  error: (err) {
    AppLogger.call('[Online] [Wallet] Error: ${err.message}');
    throw Exception(err.message);
  },
);
```

### Provider Rules

- Use `StateNotifierProvider`, `FutureProvider`, or `Provider`
- Use `.autoDispose` for screen-scoped providers
- Handle `AsyncValue<T>` with `.when(data:, loading:, error:)`

## Model Rules

- Class and file names end with `Model` (e.g., `WalletModel` in `wallet_model.dart`)
- Plain Dart classes only — **no Freezed, no code generation**
- Must include `copyWith()`, `toMap()`, and `fromMap()` methods

## UI Conventions

### Mandatory Extensions (Never Hardcode)

| What | Use | Not |
|------|-----|-----|
| Colors | `context.colors.primary`, `.background`, etc. | `Colors.blue`, `Color(0xFF...)` |
| Typography | `TextStyleConstants.h2`, `.b1`, etc. | `TextStyle(fontSize: 14)` |
| Sizing | ScreenUtil: `.h`, `.w`, `.r`, `.sp` | Raw pixel values |
| Currency | `amount.extToRupiah()`, `balance.toCurrency()` | `NumberFormat`, `'Rp $val'` |
| Dates | `date.extToDateStringDDMMMMYYYY()`, `.extTimeAgo()` | `DateFormat(...)`, manual string interpolation |
| Strings | `.arb` localization keys | Hardcoded Indonesian/English text |

Currency extensions: `lib/core/extensions/int_ext.dart`, `double_ext.dart`
Date extensions: `lib/core/extensions/date_time_ext.dart`, `string_ext.dart`

### Domain Date Contract (Use `SakuDateUtils`)

- Use `lib/core/utils/saku_date_utils.dart` for all domain date parsing, serialization, and local-day query boundaries.
- `formatTimestamp()` / `parseRequiredTimestamp()` for UTC timestamp fields such as `transactions.date`, `investment_transactions.date`, `created_at`, `updated_at`, and `fetched_at`.
- `formatDate()` / `parseRequiredDate()` for true calendar-only fields such as `transactions.due_date`, `budgets.start_date`, and `budgets.end_date`.
- `parseOptionalFlexibleLocalDateTime()` only for AI-prefill fields that may contain either `yyyy-MM-dd` or `yyyy-MM-ddTHH:mm:ss`.
- `localDayRangeUtc()` when filtering `timestamptz` columns by a user-local date range.
- Do not introduce new raw `DateTime.parse()`, raw `.toIso8601String()`, manual timezone offsets, or `substring(0, 10)` date grouping in models/datasources. Date extensions are for display formatting, not backend contract logic.

### Currency Input

Use `SakuCurrencyField` widget for money input fields (handles thousand formatting).

### Global Widgets (Check Before Creating New Ones)

`lib/global/widgets/` contains reusable components: `SakuButton`, `SakuTextField`, `SakuCard`, `SakuDropdown`, `SakuDialog`, `SakuEmptyState`, `SakuErrorState`, `ShimmerWidget`, and more.

### UI State Handling

- **Loading**: Use `ShimmerWidget` — never bare `CircularProgressIndicator`
- **Empty**: Use `SakuEmptyState`
- **Error**: Use `SakuErrorState` with retry button
- **Blocking overlay**: `context.showLoadingOverlay()` / `context.closeOverlay()` (in `finally`)
- **Alerts/Dialogs**: `context.showAppAlert()`, `context.showConfirmDialog()`

### Long Lists

Use `ListView.builder` / `SliverList` / `GridView.builder` — never plain `ListView` or `Column` for dynamic data. Implement pagination with `visibility_detector` for large datasets.

## Logging

```dart
AppLogger.call('[Online] [Wallet] Fetched ${wallets.length} wallets');
AppLogger.logError('Failed to sync', runtimeType: WalletRepository);
```

Format: `[Sync|Offline|Online] [{FeatureName}] {message}`

## Financial Guardrails (Non-Negotiable)

1. **Never** update `wallets.balance` directly from Flutter — balance changes only via database triggers on `transactions`
2. Every transaction must have ≥1 `transaction_item`; `sum(items.amount) == transactions.total_amount`
3. Transfers are **not** expenses/income in reports
4. Debt/loan settlements are **not** income/expense in reports or budgets
5. Complex writes (create/update transaction, settle debt, investment buy) must use Supabase **RPC** for atomicity
6. AI voice/OCR output is only a suggestion — never auto-save
7. Use `int` (minor units) or consistent `Decimal` for money calculations — not `double`
8. Point-in-time timestamps are stored as UTC ISO 8601 and rendered in each user's local timezone; true calendar fields stay date-only

## Supabase Edge Functions

Edge Functions run on **Deno + TypeScript** (not Node.js):

```typescript
Deno.env.get('GEMINI_API_KEY')  // ✅ Correct
process.env.GEMINI_API_KEY      // ❌ Wrong
```

Located in `supabase/functions/`.

## Localization

- Template: `lib/l10n/app_id.arb` (Indonesian)
- Config: `l10n.yaml` with `flutter: generate: true`
- Always check existing keys before adding new ones
- Run `fvm flutter gen-l10n` after `.arb` changes
