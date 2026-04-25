---
title: "SakuRapi Database — Ringkasan sumber 02 + evolusi"
type: source
tags: [database, supabase, postgres, schema, rpc, triggers, rls, investasi, sakurapi, categories]
sources: [raw/docs/02_DATABASE.md]
created: 2026-04-10
updated: 2026-04-25
---

# SakuRapi Database — Ringkasan sumber 02 + evolusi

**Jenis:** Dokumen internal — ringkasan *snapshot* lama + **status skema saat ini (Apr 2026)**
**Tanggal sumber asli:** `raw/docs/02_DATABASE.md` (diberi label v6.4, fokus implementasi lama)
**Otoritas skema terkini (Flutter + Supabase, repo + wiki):** [[wiki/entities/database-schema|Database Schema]] — 19 tabel, trigger/RPC/RLS termasuk kategori global.

> File `02_DATABASE.md` di `raw/docs/` **tidak lagi** menjelaskan kategori, *seed* pendaftaran, dan hitungan tabel sebagaimana app berjalan hari ini. Bagian bawah memuat ringkasan evolusi. Untuk detail kategori: [[wiki/entities/categories|Categories]].

**Database authority:** Supabase Postgres
**Ledger rule:** `wallets.balance` hanya berubah dari trigger berbasis `transactions`

## Ringkasan

Arsitektur inti (ledger, RPC atomik, RLS) **tetap valid**. **Per 2026-04**, skema berkembang dari *baseline* v6.4: antara lain tabel notifikasi lokal di-drop (migrasi 015), tabel/ kuota/ laporan AI & *user report*, **tabel `user_category_hidden`**, katalog kategori **global** (`categories.user_id` null), *drop* kolom `categories.is_hidden`, RPC `get_user_categories` / `toggle_category_hidden`, serta **penghapusan trigger** `trg_seed_default_categories` (fungsi `seed_default_categories` *no-op*).

## Inventaris tabel (Apr 2026) — sejalan dengan `database-schema`

| # | Tabel | Catatan |
|---|-------|--------|
| 1 | `users` | Mirror profil dari auth |
| 2 | `wallets` | Saldo hanya lewat trigger |
| 3 | `categories` | Katalog global (`user_id` null); **tanpa** `is_hidden` (2026-04) |
| 4 | `user_category_hidden` | Preferensi *hide* per (user, `category_id`) |
| 5 | `transactions` | Ledger |
| 6 | `transaction_items` | Detail item |
| 7 | `budgets` | Hanya *expense* |
| 8 | `custom_gold_types` | *Max* 2 per user |
| 9 | `custom_asset_categories` | *Max* 3 per user |
| 10 | `investment_assets` | |
| 11 | `investment_transactions` | |
| 12 | `gold_prices` | Append-only |
| 13 | `bitcoin_prices` | UPSERT 2 sumber |
| 14 | `parsing_dictionaries` | *Skip* aman bila tabel belum ada |
| 15 | *`notification_settings`* | **Dihapus** (migrasi 015) — *section* tersisa di doc entitas hanya sejarah |
| 16 | `contacts` | |
| 17 | `ai_usage_quotas` | |
| 18 | `ai_usage_logs` | |
| 19 | `user_reports` | |

Penomoran 1–19 = selaras [[wiki/entities/database-schema|Database Schema]]; **18 tabel hidup** di produk bila `notification_settings` (§15) tidak dihitung. Penambahan kunci vs baseline `02_DATABASE`: **`user_category_hidden`**, tabel/ kuota/ laporan AI, *user report*, dsb.

## Prinsip (tetap)

1. RLS **wajib** pada tabel business (lihat bagian *RLS* di [[wiki/entities/database-schema|Database Schema]])
2. *Atomic writes* ke saldo lewat RPC + trigger, bukan update saldo dari klien
3. `transactions` = ledger utama; `sum(items) = total`
4. **IDR / UTC** — konsisten dengan produk
5. **Kategori (2026-04):** bawaan app = baris global; *hide* = `user_category_hidden` + RPC, bukan `UPDATE` kolom lama

## Trigger & function — delta besar

| Nama | Perilaku terkini (2026) |
|------|---------------------|
| `handle_new_user` | Setelah *sign-up*, upsert `public.users` (tetap) |
| `seed_default_categories` | **Tidak** mem-*fire* lewat trigger; fungsi *no-op*; **tidak** *insert* 60 baris per user pendaftaran setelah *katalog global* |
| `trg_seed_default_categories` | **Dihapus** (katalog global) |
| `set_updated_at` | Tetap; `categories` termasuk tabel *mutable* |
| Lain-lain (wallet, budget, invest, max custom) | Lihat tabel penuh di entitas *Database Schema* |

## RPC — tambahan kategori (2026-04)

- `get_user_categories()` — *response* `is_hidden` berasal dari proyeksi, bukan kolom tabel lama
- `toggle_category_hidden(p_category_id, p_is_hidden)` — `user_category_hidden`; perbaikan plpgsql `p_uid` (migrasi `20260425220000`)

*(RPC transaksi, hutang, invest, kuota, dll. tidak diulang penuh di sini; lihat entitas.)*

## RLS (ringkas)

- **~17+** tabel dengan RLS mode produk; daftar terverifikasi: [[wiki/entities/database-schema#rls-row-level-security|Database Schema]]
- Kategori `user_id` null: readable (global); `user_category_hidden` hanya baris milik `auth.uid()`

## Indexing

- 28+ indeks minimum di entitas; **UNIQUE** `user_category_hidden` (user_id, category_id) termasuk
- *Snapshot* 02 menyebut ~18+ indeks — baca entitas untuk daftar *current*

## Sumber sementara vs sumber wajib

| Situasi | Rujuk |
|--------|--------|
| Kode hari ini + *migration* di repo | `supabase/migrations/`, lalu [[wiki/entities/database-schema|Database Schema]] + [[wiki/entities/categories|Categories]] |
| Teks lama 02 hanya bila cek sejarah | `raw/docs/02_DATABASE.md` |

## Halaman Terkait

- [[wiki/entities/database-schema|Database Schema]]
- [[wiki/entities/categories|Categories]]
- [[wiki/entities/wallet|Wallet]]
- [[wiki/entities/transaksi|Transaksi]]
- [[wiki/entities/budgeting|Budgeting]]
- [[wiki/entities/investasi|Investasi]]
- [[wiki/entities/hutang-piutang|Hutang-Piutang]]
- [[wiki/entities/contacts|Contacts]]
- [[wiki/concepts/aturan-keuangan|Aturan Keuangan]]
