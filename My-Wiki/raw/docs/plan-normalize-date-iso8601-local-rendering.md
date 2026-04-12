# Plan: Normalisasi Date ISO 8601 + Local Rendering

## Status implementasi akhir (2026-04-12)

- ✅ Kontrak akhir sudah dipisah tegas antara **calendar date** dan **point-in-time timestamp**.
- ✅ Flutter sekarang memakai `SakuDateUtils` untuk serialize/parse yang konsisten, termasuk boundary query **local day -> UTC**.
- ✅ Supabase Dev sudah memakai kontrak final hasil migration `021_restore_transaction_timestamps`.
- ✅ `transactions.date` dan `investment_transactions.date` kembali menjadi **`timestamptz`**.
- ✅ `transactions.due_date`, `budgets.start_date`, dan `budgets.end_date` tetap **`date`**.
- ✅ UI transaksi/investasi/debt-settlement yang memang mewakili point-in-time event kembali menampilkan jam lokal user.
- ✅ AI quota harian memakai `ai_usage_logs.usage_date` dari local date client, bukan hardcoded hari server.
- ✅ Source `ai-parse` di repo sudah diubah agar bisa mempertahankan jam eksplisit saat input memang menyebut waktu.

## Kontrak final yang dipakai

| Jenis field | Contoh | Format simpan/kirim |
| --- | --- | --- |
| Calendar date | `transactions.due_date`, `budgets.start_date`, `budgets.end_date` | `YYYY-MM-DD` |
| Event timestamp | `transactions.date`, `investment_transactions.date` | UTC ISO 8601 penuh (`YYYY-MM-DDTHH:mm:ss.sssZ`) |
| Audit/system timestamp | `created_at`, `updated_at`, `fetched_at`, `tier_expires_at` | UTC ISO 8601 penuh |

## Ringkasan implementasi

### Flutter

- Tambah dan pakai helper terpusat `SakuDateUtils`.
- Model transaksi, debt/loan, settlement, investasi, voice, dan OCR sekarang membedakan parse **timestamp** vs **date-only**.
- Read filter harian di transaction/history/dashboard/reports/budget tidak lagi bergantung pada string date mentah; sekarang memakai range UTC yang dibangun dari local-day user.
- Detail/list/form yang memang butuh point-in-time kembali menampilkan `HH:mm`.

### Supabase

- Migration 019 sempat meratakan beberapa event timestamp menjadi `date`.
- Migration 021 memulihkan kontrak yang benar:
  - `transactions.date` -> `timestamptz`
  - `investment_transactions.date` -> `timestamptz`
  - `transactions.due_date` tetap `date`
- RPC transaksi/investasi/settlement kembali menerima dan mengembalikan timestamp untuk field event time.
- Trigger `update_budget_usage()` dihitung dari tanggal transaksi yang dicast ke kalender bisnis server.

### Edge Functions / AI

- `ai-parse` menerima `localDate` dari Flutter untuk relative-date prompt dan quota day boundary.
- Source `ai-parse` sekarang mengizinkan hasil:
  - `YYYY-MM-DD` jika input hanya menyebut tanggal
  - `YYYY-MM-DDTHH:mm:ss` jika input menyebut jam eksplisit
- `gold-price` sudah memakai Vertex AI Gemini sebagai jalur AI tunggal.

## Catatan migrasi data

- Timestamp historis yang sempat diratakan oleh migration 019 **tidak bisa dipulihkan persis**.
- Saat kontrak timestamp dipulihkan, data lama dibackfill ke **00:00 Asia/Jakarta** untuk tanggal bisnis yang tersimpan.
- Artinya: tanggal bisnis lama tetap aman, tetapi jam historis aslinya memang sudah hilang.

## Caveat yang masih berlaku

- Server-side budget usage masih memakai kalender bisnis `Asia/Jakarta` karena database belum menyimpan timezone per user.
- Source `ai-parse` di repo sudah mendukung datetime eksplisit, tetapi environment runtime harus dideploy ulang agar perilaku live benar-benar match source terbaru.
- Masih ada beberapa test/analyzer issue existing di repo yang tidak berasal dari refactor date/time ini.

## Ringkasan keputusan final

1. **Tidak semua field `date` harus jadi `date-only`.**
2. **Event yang benar-benar punya waktu kejadian harus tetap timestamp UTC.**
3. **UI selalu merender timestamp via local timezone user.**
4. **Field kalender murni tetap `YYYY-MM-DD` dan tidak dipaksa membawa jam.**
