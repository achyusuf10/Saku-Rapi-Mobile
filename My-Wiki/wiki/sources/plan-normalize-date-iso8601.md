---
title: "Plan: Normalisasi Date ISO 8601 + Local Rendering"
type: source
tags: [date, timestamp, iso8601, timezone, SakuDateUtils, migration, transaksi]
sources: [raw/docs/plan-normalize-date-iso8601-local-rendering.md]
created: 2026-04-19
updated: 2026-04-19
---

# Plan: Normalisasi Date ISO 8601 + Local Rendering

**Status:** ✅ Fully Implemented (April 2026)
**Sumber:** `raw/docs/plan-normalize-date-iso8601-local-rendering.md`

## Kontrak Final

| Jenis field | Contoh | Format |
|-------------|--------|--------|
| Calendar date | `transactions.due_date`, `budgets.start_date`, `budgets.end_date` | `YYYY-MM-DD` |
| Event timestamp | `transactions.date`, `investment_transactions.date` | UTC ISO 8601 (`YYYY-MM-DDTHH:mm:ss.sssZ`) |
| Audit/system | `created_at`, `updated_at`, `fetched_at` | UTC ISO 8601 |

## Keputusan Kunci

1. **Tidak semua field `date` harus date-only** — event yang punya waktu kejadian harus tetap timestamp UTC
2. **UI selalu merender timestamp via local timezone user** — bukan UTC
3. **Field kalender murni tetap `YYYY-MM-DD`** — tidak dipaksa membawa jam
4. **Budget usage dihitung dari kalender bisnis `Asia/Jakarta`** (timezone user belum disimpan per-user di DB)

## Implementasi

### Flutter — `SakuDateUtils`

Helper terpusat `lib/core/utils/saku_date_utils.dart`:

| Method | Dipakai untuk |
|--------|--------------|
| `formatTimestamp()` / `parseRequiredTimestamp()` | `transactions.date`, `investment_transactions.date`, `created_at` |
| `formatDate()` / `parseRequiredDate()` | `transactions.due_date`, `budgets.start_date`, `budgets.end_date` |
| `parseOptionalFlexibleLocalDateTime()` | AI-prefill yang bisa berupa date atau datetime |
| `localDayRangeUtc()` | Filter `timestamptz` by local day (dashboard, history, reports, budget) |

**Larangan:** Jangan gunakan raw `DateTime.parse()`, `.toIso8601String()`, manual timezone offset, atau `substring(0, 10)` di model/datasource.

### Supabase Migrations

- **Migration 019**: sempat meratakan event timestamp → `date` (salah)
- **Migration 021** (`021_restore_transaction_timestamps`): memulihkan kontrak yang benar
  - `transactions.date` → `timestamptz`
  - `investment_transactions.date` → `timestamptz`
  - `transactions.due_date` tetap `date`

## Catatan Migrasi

- Timestamp historis yang sempat diratakan oleh migration 019 **tidak bisa dipulihkan persis**
- Data lama dibackfill ke `00:00 Asia/Jakarta` untuk tanggal bisnis yang tersimpan
- Tanggal bisnis lama tetap aman, jam historis asli sudah hilang

## Halaman Terkait

- [[wiki/concepts/aturan-keuangan|Aturan Keuangan]]
- [[wiki/entities/transaksi|Transaksi]]
- [[wiki/entities/database-schema|Database Schema]]
- [[wiki/entities/budgeting|Budgeting]]
