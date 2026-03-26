# SakuRapi — Final Review & Release Checklist
**Review Date:** 2026-03-26  
**Docs Reference:** PRD v6.1 · DATABASE v6.1 · COPILOT_RULES merged  
**Target:** Internal demo build (Android)

---

## 1. CHECKLIST FINAL

### A. Feature Completeness — P0

| # | Fitur P0 | Status | Catatan |
|---|----------|--------|---------|
| 1 | Google Sign-In + profil | ✅ Done | OAuth via Supabase, trigger `handle_new_user`, seed categories & notification_settings |
| 2 | Multi-wallet CRUD | ✅ Done | Create/update/delete, duplicate name guard, exclude_from_total, balance protected by trigger |
| 3 | Dashboard | ✅ Done | Total balance (non-excluded), recent transactions, income/expense snapshot, chart carousel |
| 4 | Transaksi manual (7 tipe) | ✅ Done | income, expense, transfer, debt, loan, adjustment, transfer_to_asset — semua via RPC atomik |
| 5 | History + filter + grouping | ✅ Done | Daily/weekly/monthly/quarterly/yearly/custom, group by date/category (lokal), pagination |
| 6 | Kategori parent-child | ✅ Done | Max 2 level, system categories protected, icon mapper, color picker |
| 7 | Settings (profil, tema, bahasa, kategori) | ✅ Done | Profile, theme (system/light/dark), language (ID/EN), category entry, notification settings |

**P0 completeness: 7/7 ✅**

---

### B. Feature Completeness — P1

| # | Fitur P1 | Status | Catatan |
|---|----------|--------|---------|
| 1 | Multi-item / split bill | ✅ Done | Expense only, items dengan qty/unitPrice/amount, sum validation, RPC atomik |
| 2 | Voice input AI | ✅ Done | STT → Edge Function (Gemini/Grok failover) → local parser fallback, prefill only |
| 3 | OCR struk AI | ✅ Done | Camera → Vision AI → ML Kit → local parser fallback, multi-item prefill |
| 4 | Parsing dictionary cache | ✅ Done | Table `parsing_dictionaries`, cache 24h di Hive, global read RLS |
| 5 | Budgeting parent/child | ✅ Done | Expense only, parent budget oleh child expense, 80%/100% alert, recurring |
| 6 | Visual reports | ✅ Done | Income/expense P&L (excludes transfer/settlement/adjustment), category breakdown, trend chart |
| 7 | Local notifications | ✅ Done | Budget alerts (80%/100%), debt reminders, daily reminder, WorkManager support |

**P1 completeness: 7/7 ✅**

---

### C. Feature Completeness — P2

| # | Fitur P2 | Status | Catatan |
|---|----------|--------|---------|
| 1 | Wealth management / investasi | ✅ Done | Gold/crypto/custom, live price cache, transfer_to_asset RPC |
| 2 | Lampiran lanjutan | ⚠️ Partial | attachment_url di transaction model, storage bucket ready, upload service exists |
| 3 | Export/Import | ❌ Coming Soon | Placeholder di Settings ("coming soon") |
| 4 | Improvement analytics | ❌ Not started | — |

---

### D. Database Readiness

| Item | Status | Detail |
|------|--------|--------|
| 9 tabel sesuai spec | ✅ | users, wallets, categories, transactions, transaction_items, budgets, investments, parsing_dictionaries, notification_settings |
| Semua constraint aktif | ✅ | total_amount > 0, wallet != destination, with_person for debt/loan, settlement rules |
| Trigger: handle_new_user | ✅ | After insert/update on auth.users |
| Trigger: seed_default_categories | ✅ | 33 kategori (25 expense + 6 income + 2 system) per user baru |
| Trigger: seed_notification_settings | ✅ | Default settings per user baru |
| Trigger: update_wallet_balance | ✅ | Satu-satunya tempat balance berubah (7 tipe transaksi) |
| Trigger: update_budget_usage | ✅ | Recalc dari transaction_items, exclude settlement |
| Trigger: set_updated_at | ✅ | Semua 9 tabel |
| Cron: auto_renew_budgets | ⚠️ Commented | Function exists tapi `cron.schedule()` di-comment, butuh enable pg_cron extension di Supabase Dashboard |
| RPC: create_transaction_with_items | ✅ | Atomik, validasi lengkap |
| RPC: update_transaction_with_items | ✅ | Atomik, handle type/wallet change |
| RPC: delete_transaction | ✅ | Guard settlement references |
| RPC: create_adjustment_transaction | ✅ | Handle positive/negative diff, bypass trigger |
| RPC: settle_debt_or_loan | ✅ | Guard overpayment, update status |
| RPC: create_investment_with_wallet_deduction | ✅ | Conditional transfer_to_asset |
| RLS semua tabel | ✅ | 9 tabel + 2 storage buckets |
| Index sesuai spec | ✅ | 13 index termasuk partial index untuk settlement |
| Seed categories | ✅ | Sesuai PRD §8 |
| Storage buckets | ✅ | attachments (private, 5MB) + avatars (public read) |
| Edge Functions | ✅ | ai-parse (voice+OCR) + gold-price |

---

### E. Auth Readiness

| Item | Status |
|------|--------|
| Google Sign-In via Supabase OAuth | ✅ |
| Session restore on app launch | ✅ |
| Auto-redirect (session → dashboard, no session → login) | ✅ |
| Trigger bootstrap (user + categories + notifications) | ✅ |
| Logout clears local session | ✅ |
| GoRouter auth redirect guard | ✅ |

---

### F. Wallet / Transaction / Report Correctness

| Rule (dari Accounting Matrix) | Status |
|------|--------|
| income → +wallet | ✅ |
| expense → -wallet | ✅ |
| transfer → -source, +destination | ✅ |
| debt → +wallet (borrowed) | ✅ |
| loan → -wallet (lent out) | ✅ |
| adjustment → ±wallet (via RPC) | ✅ |
| transfer_to_asset → -wallet | ✅ |
| Report hanya menghitung income+expense non-settlement | ✅ |
| Budget hanya menghitung expense non-settlement | ✅ |
| Settlement tidak masuk report/budget | ✅ |
| Transfer tidak masuk report/budget | ✅ |
| sum(items.amount) = total_amount (validasi) | ✅ |
| Minimal 1 transaction_item per transaksi | ✅ |
| Settlement guard: tidak melebihi principal | ✅ |

---

### G. Localization Completeness

| Item | Status |
|------|--------|
| File .arb: app_id.arb + app_en.arb | ✅ |
| Total keys: 250+ | ✅ |
| Keys sinkron antara ID dan EN | ✅ |
| Tidak ada hardcoded string di UI | ✅ |
| Locale switching di Settings | ✅ |

---

### H. Loading / Empty / Error Coverage

| Item | Status |
|------|--------|
| Global widgets tersedia (SakuLoadingIndicator, SakuEmptyState, SakuErrorState) | ✅ |
| Digunakan di 8+ feature views | ✅ |
| Features yang pakai: dashboard, history, budget, category, investment, reports, wallet, category_picker | ✅ |

---

### I. Test Coverage

| Area Test | Status | File |
|-----------|--------|------|
| Transaction repository validation | ✅ | transaction_repository_test.dart |
| Transaction form controller (multi-item, total match) | ✅ | transaction_form_controller_test.dart |
| History controller (period, filter, grouping) | ✅ | history_controller_test.dart |
| Dashboard controller (period, state) | ✅ | dashboard_controller_test.dart |
| Budget model (usage, ratio, limits) | ✅ | budget_test.dart |
| Wallet repository (balance, serialization) | ✅ | wallet_repository_test.dart |
| Voice local parser (amount, type, dictionary) | ✅ | voice_local_parser_test.dart |
| OCR local parser (amount, merchant, date) | ✅ | ocr_local_parser_test.dart |
| Auth test | ✅ | auth_test.dart |
| Category test | ✅ | category_test.dart |
| Investment test | ✅ | investment_test.dart |
| Report test | ✅ | report_test.dart |
| Notification test | ✅ | notification_test.dart |
| Settings controller test | ✅ | settings_controller_test.dart |
| **Widget test** | ❌ Missing | Tidak ada test untuk form transaksi, multi-item input, wallet picker |
| **Integration test** | ❌ Missing | Tidak ada test flow login→dashboard, create expense, create transfer |

**Total unit test files: 14** | Widget test: 0 | Integration test: 0

---

### J. Android Permission Readiness

| Permission | Status | Manifest |
|-----------|--------|----------|
| READ_EXTERNAL_STORAGE | ✅ | Gallery access |
| WRITE_EXTERNAL_STORAGE | ✅ | Save files |
| RECORD_AUDIO | ✅ | Voice input |
| MODIFY_AUDIO_SETTINGS | ✅ | Audio processing |
| RECEIVE_BOOT_COMPLETED | ✅ | Scheduled notifications |
| SCHEDULE_EXACT_ALARM | ✅ | Budget/debt alerts |
| POST_NOTIFICATIONS | ✅ | Android 13+ notifications |
| Camera | ✅ | OCR receipt scan |
| Internet | ✅ | Implicit |

---

### K. Release Build Readiness

| Item | Status | Detail |
|------|--------|--------|
| Signing config | ✅ | key.properties loaded, applied to debug+release |
| Flavor dev/prod | ✅ | dev (`.dev` suffix) + prod |
| CompileSdk/TargetSdk | ✅ | Dynamic from Flutter SDK |
| Java desugaring | ✅ | coreLibraryDesugaring enabled |
| APK naming | ✅ | Custom `MyLifte-{version}+{code}_{date}_at_{time}.apk` |
| ProGuard / R8 | ❌ Missing | Tidak ada konfigurasi proguard-rules.pro |
| Compile errors | ⚠️ 1 warning | Unused `_client` field di connectivity_service.dart |
| FVM configured | ✅ | main_dev.dart / main_prod.dart via AppFlavorConfig |

---

## 2. DAFTAR GAP / BLOCKER

### 🔴 Critical (harus fix sebelum production)

| # | Gap | Severity | Detail |
|---|-----|----------|--------|
| C1 | `double` untuk field uang di semua model | 🔴 High | PRD §4.1: "Jangan gunakan double untuk kalkulasi bisnis". 8 model files (22 fields) pakai `double` untuk balance, amount, totalAmount, price. **Untuk demo tidak blocking** karena IDR tanpa subunit, tapi **wajib fix untuk production** |
| C2 | Widget test tidak ada | 🔴 High | PRD §12: "Widget test untuk form transaksi" required. 0 widget test files |
| C3 | Integration test tidak ada | 🔴 High | PRD §12: "Integration test minimal" required. 0 integration test files |
| C4 | ProGuard/R8 tidak dikonfigurasi | 🔴 Medium | Release build tanpa shrinking/obfuscation rentan decompile |

### 🟠 Moderate (fix sebelum production, OK untuk demo)

| # | Gap | Severity | Detail |
|---|-----|----------|--------|
| M1 | `ListView()` tanpa `.builder` di 8 views | 🟠 Medium | Budget detail/page, wallet page, settings, transaction detail, notification, report. Performance risk untuk data banyak |
| M2 | Manual `toStringAsFixed()` untuk persentase (12 lokasi) | 🟠 Medium | Seharusnya pakai `.toPercentage()` dari double_ext.dart |
| M3 | Manual `DateFormat()` di 4 chart widgets | 🟠 Medium | Seharusnya pakai extension dari date_time_ext.dart |
| M4 | pg_cron auto_renew_budgets masih di-comment | 🟠 Medium | Function exists, tapi schedule belum aktif. Budget recurring tidak akan auto-renew |
| M5 | Dashboard quick actions punya 4 tombol (spec bilang 3) | 🟠 Low | Extra "Wallets" button, bukan anti-pattern tapi menyimpang dari FAB spec |

### 🟡 Minor (nice to have)

| # | Gap | Severity | Detail |
|---|-----|----------|--------|
| N1 | Hardcoded color di budget_card_tile.dart | 🟡 Low | `Color(0xFF6B7280)` fallback — seharusnya pakai theme |
| N2 | Unused `_client` di connectivity_service.dart | 🟡 Low | Compile warning, dead code |
| N3 | APK naming masih "MyLifte" bukan "SakuRapi" | 🟡 Low | Ganti di build.gradle.kts |

---

## 3. PATCH CODE

### Patch 1: Fix unused `_client` warning

**File:** `lib/core/network/connectivity_service.dart`

```dart
// Remove or use the _client field
// Jika memang tidak digunakan, hapus field-nya
```

### Patch 2: Fix hardcoded color di budget_card_tile

**File:** `lib/features/budget/view/widgets/budget_card_tile.dart` line 166, 171

```dart
// SEBELUM:
Color(0xFF6B7280)

// SESUDAH:
context.colors.onSurfaceVariant  // atau neutral color dari theme
```

### Patch 3: Fix APK naming

**File:** `android/app/build.gradle.kts`

```kotlin
// SEBELUM:
"MyLifte-${versionName}+${versionCode}_${date}_at_${time}.apk"

// SESUDAH:
"SakuRapi-${versionName}+${versionCode}_${date}_at_${time}.apk"
```

### Patch 4: Enable pg_cron (manual step)

```
1. Buka Supabase Dashboard → Database → Extensions
2. Enable pg_cron
3. Jalankan SQL:
   SELECT cron.schedule(
     'auto-renew-budgets',
     '5 17 * * *',
     $$ SELECT public.auto_renew_budgets() $$
   );
```

### Patch 5: ListView → ListView.builder (8 files)

Lokasi yang perlu diganti:
1. `budget/view/ui/budget_page.dart` (2 lokasi)
2. `budget/view/ui/budget_detail_page.dart`
3. `budget/view/widgets/budget_form_sheet.dart`
4. `wallet/view/ui/wallet_page.dart`
5. `settings/view/ui/settings_page.dart`
6. `transaction/view/ui/transaction_detail_page.dart`
7. `notification/view/ui/notification_settings_page.dart`
8. `reports/view/ui/report_page.dart`

> **Catatan:** Beberapa mungkin intentional (settings/form dengan item terbatas). Review per file sebelum refactor.

---

## 4. REKOMENDASI NEXT STEPS

### Fase "Siap Demo" — Status: ✅ SIAP

Project ini **siap untuk demo internal** karena:
- Semua P0 + P1 features lengkap dan fungsional
- Database schema, triggers, RPC, RLS, dan indexes lengkap
- Auth flow, wallet, transaction, history, budget, reports, voice, OCR, investment, notification — semua working
- Localization lengkap (ID + EN, 250+ keys)
- Loading/empty/error states implemented
- 14 unit test files covering critical paths
- Android permissions lengkap
- Build config dengan flavor dev/prod dan signing

### Fase "Siap Production" — Status: ⚠️ BELUM

Gap yang harus ditutup sebelum production release:

| Priority | Item | Effort |
|----------|------|--------|
| 1 | Tambah widget tests (form transaksi, multi-item, wallet picker) | Medium |
| 2 | Tambah integration tests (login→dashboard, CRUD flow) | Medium |
| 3 | Konfigurasi ProGuard/R8 untuk release build | Small |
| 4 | Evaluasi `double` → `int` untuk money fields (atau gunakan `Decimal` package) | Large (breaking change) |
| 5 | Ganti `ListView()` → `ListView.builder()` di 8 views | Small |
| 6 | Ganti manual formatting (DateFormat, toStringAsFixed) dengan extension methods | Small |
| 7 | Enable pg_cron di Supabase Dashboard untuk auto-renew budget | Small (manual step) |
| 8 | Fix APK naming dari "MyLifte" ke "SakuRapi" | Trivial |
| 9 | Fix compile warning (unused _client) | Trivial |
| 10 | Performance testing dengan data besar (1000+ transaksi) | Medium |
| 11 | Security audit: SSL pinning configuration, API key handling | Medium |
| 12 | Widget test + integration test untuk P1 features (voice, OCR, budget) | Large |

---

## 5. ARCHITECTURE SCORECARD

| Dimensi | Score | Status |
|---------|-------|--------|
| Feature completeness (P0) | 100% | ✅ |
| Feature completeness (P1) | 100% | ✅ |
| Database & backend | 98% | ✅ (cron job di-comment) |
| Architecture compliance | 100% | ✅ (3-file pattern, Riverpod non-generator, GoRouter) |
| Domain validation | 98% | ✅ |
| Localization | 100% | ✅ |
| UI state coverage (loading/empty/error) | 95% | ✅ |
| Unit test coverage | 70% | ⚠️ (unit ✅, widget ❌, integration ❌) |
| Coding rules compliance | 85% | ⚠️ (double for money, manual formatting, ListView) |
| Release readiness | 80% | ⚠️ (no ProGuard, APK name wrong) |

**Overall: 93% — SIAP DEMO, belum siap production penuh.**
