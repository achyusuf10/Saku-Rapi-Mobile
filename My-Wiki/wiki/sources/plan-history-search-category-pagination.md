---
title: "Plan: History Search Filter + Category Pagination"
type: source
tags: [history, search, pagination, rpc, supabase, filter]
source_file: raw/docs/plan-history-search-filter-and-category-loadmore.md
created: 2026-04-13
updated: 2026-04-13
---

# Plan: History Search Filter + Category Pagination — Ringkasan

> Sumber: `raw/docs/plan-history-search-filter-and-category-loadmore.md`  
> Status: **Selesai diimplementasi** (April 2026)

---

## Dua Improvement

### 1. Search Filter (Server-Side)

Tambah field pencarian teks di filter sheet history. Keyword dikirim ke server via RPC, server melakukan `ILIKE` pada `transactions.note` OR `categories.name`. Tidak di-filter lokal.

### 2. Category-Level Pagination

Saat `groupMode == byCategory`, pagination bukan per transaksi tetapi **per kategori** (5 kategori per page). Setiap kategori datang lengkap dengan SEMUA transaksinya untuk periode tersebut. Urutan: kategori dengan transaksi terbaru muncul duluan.

---

## Arsitektur: RPC `get_history_transactions`

### Kenapa RPC

- PostgREST `.or()` tidak support filter cross-table (`note` OR `category.name`)
- PostgREST hanya support `LIMIT/OFFSET` per row — tidak bisa per *distinct category*
- RPC menangani kedua mode dalam satu endpoint via parameter `p_group_mode`

### Signature

```sql
CREATE OR REPLACE FUNCTION get_history_transactions(
  p_start_date  timestamptz,
  p_end_date    timestamptz,
  p_wallet_id   uuid        DEFAULT NULL,
  p_type        text        DEFAULT NULL,
  p_search      text        DEFAULT NULL,
  p_group_mode  text        DEFAULT 'byDate',
  p_limit       int         DEFAULT 30,
  p_offset      int         DEFAULT 0
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
```

### Mode byDate

- `p_limit/p_offset` = pagination per transaksi (default 30)
- Search: `note ILIKE '%keyword%' OR EXISTS (...category.name ILIKE '%keyword%')`
- `has_more` berdasarkan jumlah transaksi

### Mode byCategory

- `p_limit/p_offset` = pagination per **kategori** (default 5)
- Algoritma: rank kategori by `MAX(transaction.date) DESC` → ambil 5 → return SEMUA transaksi dari 5 kategori itu
- `has_more` berdasarkan jumlah kategori yang tersisa
- Transfer/Debt/Loan tanpa kategori: `COALESCE(c.name, t.type)` → muncul sebagai grup sendiri

### Offset Semantics

| Mode | Arti `state.offset` |
|------|---------------------|
| byDate | jumlah transaksi yang sudah diambil |
| byCategory | jumlah kategori yang sudah diambil |

Mode switch selalu reset offset ke 0 → aman berbagi field yang sama.

---

## Perubahan `setGroupMode()` & `setSearchKeyword()`

| Method | Sebelum | Sesudah |
|--------|---------|---------|
| `setGroupMode()` | sync, lokal | **async** + trigger `loadTransactions()` |
| `setSearchKeyword()` | tidak ada | **baru**, server-side, trigger `loadTransactions()` |
| `setTypeFilter()` | sync, lokal | tetap sync + lokal (per PRD §7.8) |

---

## Files Diubah

| File | Perubahan |
|------|-----------|
| `supabase/migrations/*_get_history_transactions_rpc.sql` | RPC baru |
| `lib/features/history/models/history_models.dart` | Tambah `HistoryResult` |
| `lib/features/history/datasource/history_remote_data_source.dart` | Ganti PostgREST → RPC; tambah `getTransactionsByCategory()` untuk report page |
| `lib/features/history/repositories/history_repository.dart` | Pass-through params baru |
| `lib/features/history/controllers/history_controller.dart` | State + search + pagination |
| `lib/features/history/datasource/history_local_data_source.dart` | Persist `searchKeyword` |
| `lib/features/history/view/widgets/history_filter_sheet.dart` | Search field + clear button |
| `lib/features/history/view/ui/history_page.dart` | Badge: `typeFilter != null \|\| searchKeyword != null` |
| `lib/features/reports/view/ui/report_category_transactions_page.dart` | Gunakan `getTransactionsByCategory()` |
| `lib/l10n/app_id.arb` + `app_en.arb` | Key `historySearchHint` |

---

## Lihat Juga

- [[wiki/entities/history|History]] — halaman entitas (sudah diupdate)
- [[wiki/entities/database-schema|Database Schema]] — RPC `get_history_transactions`
