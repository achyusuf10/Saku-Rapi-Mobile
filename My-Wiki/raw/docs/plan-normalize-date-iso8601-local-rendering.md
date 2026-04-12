# Plan: Normalisasi Date ISO 8601 + Local Rendering

## Status implementasi (2026-04-12)

- ✅ Flutter sekarang memakai helper terpusat `SakuDateUtils` untuk memisahkan timestamp UTC vs field kalender `YYYY-MM-DD`.
- ✅ `transactions.date`, `transactions.due_date`, dan `investment_transactions.date` sudah dimigrasikan ke `date` di Supabase Dev.
- ✅ `ai-parse` sudah menerima `localDate` dari Flutter untuk relative-date prompt dan kuota harian.
- ✅ AI quota sekarang dihitung dari `ai_usage_logs.usage_date` (tanggal lokal user dari client), bukan hardcoded `Asia/Jakarta`.
- ✅ Budget recurring sekarang bisa disinkronkan on-demand via `auto_renew_budgets(p_today)` saat Flutter fetch budget aktif/upcoming/completed.
- ✅ Data lama di Dev DB sudah dibackfill ke kontrak baru.
- ⚠️ Sisa issue repo yang masih ada setelah implementasi ini bukan berasal dari refactor tanggal: 3 test `transaction_repository_test` dan 4 test `saku_currency_controller_test`, plus 5 issue analyzer existing.

## Tujuan

Merapikan seluruh flow tanggal/waktu supaya:

1. Field **timestamp** disimpan dan dikirim ke Supabase sebagai **ISO 8601 UTC penuh**.
2. Field **kalender** tetap **date-only ISO 8601** (`YYYY-MM-DD`), tidak dipaksa jadi timestamp.
3. Data yang diterima Flutter untuk UI selalu dikonversi ke **local user** saat dipakai/display.
4. Logic Flutter dan Supabase tidak lagi campur UTC, local device, dan hardcoded `Asia/Jakarta` tanpa sengaja.

## Keputusan yang sudah dikunci

- **Date-only tetap date-only**; tidak semua field dipaksa jadi timestamp.
- **Timestamp tetap timestamp UTC**.
- **UI user-facing mengikuti local device user** (`toLocal()`).
- Audit dilakukan dari **kode repo** dan **live schema Supabase Dev**.

## Ringkasan temuan audit

### Flutter

- Banyak write path masih memakai raw `.toIso8601String()` dari `DateTime` lokal tanpa `.toUtc()`. Ini berisiko mengirim timestamp ambigu.
- Banyak read path model memakai `DateTime.parse()` mentah; konversi local baru terjadi di formatter UI. Akibatnya controller, grouping, dan filter masih bisa membaca komponen hari dalam basis UTC.
- `report_remote_data_source.dart` dan `dashboard_remote_data_source.dart` masih grouping harian memakai `substring(0, 10)` dari string Supabase.
- `string_ext.dart` masih punya helper hardcoded `+0700`.
- Form transaksi/investasi/due date saat ini memperlakukan tanggal sebagai **tanggal kalender**, bukan jam spesifik.

### Supabase

- Live schema saat ini:
  - `budgets.start_date`, `budgets.end_date` = `date`
  - `transactions.date`, `transactions.due_date` = `timestamptz`
  - `investment_transactions.date` = `timestamptz`
  - `created_at`, `updated_at`, `fetched_at`, `tier_expires_at` = `timestamptz`
- Live trigger `update_budget_usage()` masih compare `transactions.date` dengan `budgets.start_date::timestamptz`.
- Live RPC create/update/settlement/investment masih menerima `p_date timestamptz default now()`.
- Edge function `ai-parse` masih membangun `today` dari `new Date().toISOString().split('T')[0]`.
- Edge function `gold-price` masih memakai `getTodayDateWIB()` dengan offset `+7` hardcoded.
- AI quota RPC masih memakai batas hari `Asia/Jakarta`.

## Rekomendasi arsitektur target

### 1. Bedakan dua jenis field

| Jenis | Contoh | Target format |
| --- | --- | --- |
| Kalender (tanpa jam) | `transactions.date`, `transactions.due_date`, `investment_transactions.date`, `budgets.start_date`, `budgets.end_date`, hasil AI parse/OCR | ISO 8601 date-only `YYYY-MM-DD` |
| Timestamp (point-in-time) | `created_at`, `updated_at`, `fetched_at`, `tier_expires_at`, `ai_usage_logs.created_at` | ISO 8601 UTC penuh `YYYY-MM-DDTHH:mm:ss.sssZ` |

### 2. Rekomendasi penting

`transactions.date`, `transactions.due_date`, dan `investment_transactions.date` **lebih tepat dimigrasikan dari `timestamptz` menjadi `date`**.

Alasannya:

- UI dan form saat ini memperlakukan field tersebut sebagai **tanggal kalender**, bukan jam spesifik.
- History/report/budget juga bekerja per hari, bukan per jam.
- Memaksa field kalender tetap `timestamptz` akan terus memunculkan edge case timezone, terutama di filter harian dan trigger budget.

Jika field-field itu dipaksa tetap `timestamptz`, maka kita perlu metadata timezone per user dan query/trigger yang jauh lebih kompleks.

## Workstreams

### 1. Shared date contract + helper tunggal

- Tambah helper tunggal di Flutter untuk:
  - serialize timestamp -> UTC ISO 8601
  - parse timestamp Supabase -> local `DateTime`
  - serialize date-only -> `YYYY-MM-DD`
  - parse date-only -> `DateTime` lokal tanpa drift timezone
- Hapus raw `DateTime.parse()` dan raw `.toIso8601String()` dari flow penting.

### 2. Flutter refactor

- Models:
  - `transaction_model.dart`
  - `budget_model.dart`
  - model debt/loan
  - model investment
  - model auth/wallet/category
  - `voice_parse_result_model.dart`
  - `ocr_parse_result_model.dart`
- Data sources:
  - transaction
  - investment
  - history
  - reports
  - dashboard
  - budget
- Grouping/filtering:
  - stop `substring(0, 10)` dari raw string Supabase
  - group berdasarkan parsed domain date
  - rapikan range builder harian/mingguan/bulanan
- Hapus helper hardcoded `+0700`.

### 3. Supabase schema + RPC alignment

- Buat migration untuk mengubah business-calendar columns ke `date` (**recommended path**):
  - `transactions.date`
  - `transactions.due_date`
  - `investment_transactions.date`
- Update RPC signatures/params/casts yang masih `timestamptz` untuk field kalender.
- Update trigger `update_budget_usage()` supaya compare **date-to-date**, bukan `date::timestamptz`.
- Review default `now()` pada RPC date params agar tidak jadi fallback diam-diam.

### 4. Edge Functions + server calendar logic

- `ai-parse`:
  - tetap output date-only `YYYY-MM-DD`
  - jangan derive tanggal kalender dari timezone server secara diam-diam
- `gold-price`:
  - pisahkan `fetched_at` (UTC timestamp) vs market-day logic
- Review server logic yang masih hardcoded `Asia/Jakarta`:
  - AI quota RPC
  - `auto_renew_budgets()`
  - `gold-price`
  - `ai-parse`

### 5. Docs + tests

- Update wiki/source-of-truth yang masih bilang “render Asia/Jakarta”.
- Tambah test plan Flutter + Supabase.
- Dokumentasikan jelas mana field **calendar date** dan mana field **timestamp**.

## File/area yang wajib disentuh

### Flutter

- `lib/core/extensions/date_time_ext.dart`
- `lib/core/extensions/string_ext.dart`
- `lib/features/transaction/models/transaction_model.dart`
- `lib/features/transaction/datasource/transaction_remote_data_source.dart`
- `lib/features/history/datasource/history_remote_data_source.dart`
- `lib/features/history/controllers/history_controller.dart`
- `lib/features/history/view/ui/history_page.dart`
- `lib/features/reports/datasource/report_remote_data_source.dart`
- `lib/features/dashboard/datasource/dashboard_remote_data_source.dart`
- `lib/features/dashboard/view/widgets/dashboard_recent_transactions.dart`
- `lib/features/budget/models/budget_model.dart`
- `lib/features/budget/datasource/budget_remote_data_source.dart`
- `lib/features/debt_loan/models/*.dart`
- `lib/features/investment/models/*.dart`
- `lib/features/investment/datasource/investment_remote_data_source.dart`
- `lib/features/voice/models/voice_parse_result_model.dart`
- `lib/features/ocr/models/ocr_parse_result_model.dart`

### Supabase

- Live tables:
  - `transactions`
  - `budgets`
  - `investment_transactions`
  - `gold_prices`
  - `bitcoin_prices`
  - `users`
  - `ai_usage_logs`
- Triggers/functions:
  - `update_budget_usage()`
  - `auto_renew_budgets()`
- RPCs:
  - create/update transaction
  - adjustment
  - settlement
  - investment RPCs
  - `replace_budget()`
  - AI quota RPCs
- Edge functions:
  - `ai-parse`
  - `gold-price`
  - `bitcoin-price`

## Testing plan

### Supabase side

- Verify migrated column types dan RPC signatures.
- Test create/edit transaction, settlement, dan investment transaction dengan tanggal hari ini/kemarin/besok.
- Pastikan `budget_usage` tetap benar di boundary pergantian hari.
- Pastikan `created_at`, `updated_at`, `fetched_at`, `tier_expires_at` tetap UTC.
- Recheck AI quota/day-boundary setelah policy business-day disepakati.

### Flutter side

- Unit test helper serialize/parse untuk timestamp vs date-only.
- Unit test `fromMap()/toMap()` model-model utama.
- Integration test history/report/dashboard filter & grouping di boundary hari.
- Manual test create transaction lalu bandingkan:
  - nilai yang tersimpan di Supabase
  - nilai yang tampil di UI
- Manual test label `fetched_at` untuk gold/bitcoin.

## Open review points

1. **Approve atau tidak** migrasi `transactions.date`, `transactions.due_date`, dan `investment_transactions.date` menjadi `date`?
Boleh migrasi aja
2. Untuk **AI quota / recurring budget / gold market day**, mau tetap pakai **business day Asia/Jakarta** atau ikut **timezone local user**?
Ikut timezone Local User
3. Setelah plan disetujui, implementasi paling aman adalah:
   1. migration Supabase lebih dulu
   2. helper + refactor Flutter
   3. edge function/server calendar cleanup
   4. docs + tests
