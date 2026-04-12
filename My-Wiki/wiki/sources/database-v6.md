---
title: "SakuRapi Database Final v6.4 — Ringkasan"
type: source
tags: [database, supabase, postgres, schema, rpc, triggers, rls, investasi, sakurapi]
sources: [raw/docs/02_DATABASE.md]
created: 2026-04-10
updated: 2026-04-10
---

# SakuRapi Database Final v6.4 — Ringkasan

**Jenis**: Dokumen internal — Spesifikasi database (schema, constraint, trigger, RPC, indexing)
**Tanggal sumber**: 2026 (versi 6.4 — Final for implementation)
**Database authority**: Supabase Postgres
**Ledger rule**: `wallets.balance` hanya berubah dari trigger berbasis `transactions`

## Ringkasan

Dokumen ini adalah **sumber kebenaran tunggal** untuk seluruh struktur database SakuRapi yang berjalan di Supabase/Postgres. Versi 6.4 mendefinisikan 15 tabel bisnis, lengkap dengan constraint, trigger, RPC (Remote Procedure Call), RLS policy, dan indexing strategy.

Arsitektur database menganut prinsip **ledger-based**: tabel `transactions` menjadi catatan utama semua aktivitas keuangan, dan saldo wallet (`wallets.balance`) merupakan nilai turunan yang hanya diperbarui oleh database trigger — bukan oleh client Flutter. Semua write yang melibatkan perubahan saldo wajib dilakukan secara **atomik** melalui RPC untuk mencegah race condition.

Database mendukung fitur inti SakuRapi: multi-wallet, kategori parent-child, transaksi multi-item, budgeting berbasis expense, hutang-piutang dengan settlement tracking, investasi (emas, bitcoin, custom asset), serta kontak dan parsing dictionary untuk fitur AI. Semua tabel bisnis dilindungi oleh Row Level Security (RLS) agar user hanya dapat mengakses datanya sendiri.

Dokumen juga mencantumkan 18+ index untuk performa query, seed categories default (expense, income, system), dan accounting rules checklist yang menjadi panduan validasi di level database maupun aplikasi.

## Poin Kunci

### 15 Tabel Database

| # | Tabel | Deskripsi Singkat |
|---|-------|-------------------|
| 1 | `users` | Mirror dari `auth.users`, menyimpan profil user |
| 2 | `wallets` | Dompet user — balance hanya via trigger |
| 3 | `categories` | Kategori income/expense/system, hierarki parent-child (max 2 level) |
| 4 | `transactions` | **Ledger utama** — 7 tipe: income, expense, transfer, debt, loan, adjustment, transfer_to_asset |
| 5 | `transaction_items` | Detail item per transaksi — minimal 1 row per transaksi |
| 6 | `budgets` | Budget hanya untuk category expense, recurring support |
| 7 | `custom_gold_types` | Jenis emas custom per user (max 2) |
| 8 | `custom_asset_categories` | Kategori aset custom per user (max 3), memiliki `unit_label` |
| 9 | `investment_assets` | Aset investasi: gold, bitcoin, custom |
| 10 | `investment_transactions` | Transaksi investasi: buy/sell dengan opsional wallet deduction |
| 11 | `gold_prices` | Harga emas append-only (antaremas, logammulia) untuk charting historis |
| 12 | `bitcoin_prices` | Harga BTC via UPSERT — hanya 2 row (indodax, coingecko) |
| 13 | `parsing_dictionaries` | Keyword-to-category mapping untuk fitur AI parse |
| 14 | `notification_settings` | Pengaturan notifikasi: reminder, budget alert, debt reminder |
| 15 | `contacts` | Kontak untuk referensi hutang/piutang |

### Prinsip Database
1. **RLS wajib** pada semua 15 tabel bisnis — user hanya akses data miliknya
2. **Atomic writes** — semua write yang memengaruhi saldo harus melalui RPC
3. **`transactions` = ledger utama** — sumber kebenaran untuk semua aktivitas keuangan
4. **`transaction_items` wajib** — minimal 1 row per transaksi
5. **`sum(items.amount) == total_amount`** — integritas data wajib dijaga
6. **UTC untuk semua tanggal** operasional, render dengan timezone Asia/Jakarta
7. **IDR only** — MVP single currency

### Constraint Penting
- `wallets.balance` hanya berubah via trigger — **dilarang** update langsung dari client
- Transfer wajib punya `destination_wallet_id`, tidak boleh sama dengan wallet asal
- `debt`/`loan` wajib punya `with_person`
- Settlement amount tidak boleh melebihi remaining dari transaksi referensi
- `settlement_kind = 'debt_payment'` → `type = 'expense'`; `settlement_kind = 'loan_collection'` → `type = 'income'`
- Budget hanya boleh terkait category `type = 'expense'`
- Max 2 custom gold types dan max 3 custom asset categories per user

### Trigger & Function

| Trigger | Tujuan |
|---------|--------|
| `handle_new_user()` | Upsert `public.users` setelah registrasi di `auth.users` |
| `seed_default_categories()` | Insert kategori default saat user baru dibuat |
| `seed_notification_settings()` | Insert pengaturan notifikasi default |
| `update_wallet_balance()` | Update saldo wallet setelah insert/update/delete pada `transactions` |
| `update_budget_usage()` | Recalculate budget usage setelah perubahan `transaction_items` |
| `set_updated_at()` | Auto-update timestamp pada semua tabel mutable |
| `auto_renew_budgets()` | pg_cron daily — clone recurring budgets dengan period-aware calculation, carry_forward support |
| `check_max_custom_gold_types()` | Enforce max 2 jenis emas custom per user |
| `check_max_custom_asset_categories()` | Enforce max 3 kategori aset custom per user |

### RPC (Remote Procedure Call)

**Transaction RPCs:**
- `create_transaction_with_items(...)` → Buat transaksi + items secara atomik
- `update_transaction_with_items(...)` → Update transaksi + items secara atomik
- `delete_transaction(p_transaction_id)` → Hapus transaksi
- `create_adjustment_transaction(p_wallet_id, p_target_balance, ...)` → Penyesuaian saldo

**Settlement RPCs:**
- `settle_debt_or_loan(...)` → Bayar hutang atau terima piutang
- `update_settlement(...)` → Edit settlement
- `delete_settlement(...)` → Hapus settlement

**Debt/Loan Query RPCs:**
- `get_debt_loan_summary(p_type, p_wallet_id?)` → Ringkasan per orang
- `get_debt_loan_transactions_by_person(...)` → Daftar transaksi per orang
- `get_all_unpaid_debt_loan(p_type)` → Semua hutang/piutang belum lunas
- `get_settlement_history(p_reference_transaction_id)` → Riwayat pembayaran

**Contact RPC:**
- `upsert_contact(p_name, p_phone?)` → Upsert kontak dari phonebook

**Budget RPC:**
- `replace_budget(...)` → Atomic DELETE old + INSERT new untuk replace budget overlap

**Investment RPCs (7 fungsi):**
- `get_investment_dashboard()` → Dashboard investasi (aggregated fields per aset)
- `create_investment_asset(...)` → Buat aset + transaksi beli pertama, opsional wallet deduction
- `topup_investment(...)` → Tambah pembelian, reactivate aset jika inactive
- `sell_investment(...)` → Jual aset, opsional wallet credit via `income`, auto-deactivate jika habis
- `edit_investment_transaction(...)` → Edit transaksi buy only, validasi unit
- `delete_investment_transaction(...)` → Hapus transaksi buy only, validasi unit
- `delete_investment_asset(...)` → CASCADE delete semua transaksi, opsional revert wallet
- `upsert_bitcoin_price(...)` → UPSERT harga BTC

> **Penting:** Semua Investment RPC menggunakan `auth.uid()` secara internal — **bukan** menerima `p_user_id` sebagai parameter. Ini menjamin keamanan: user hanya bisa mengakses data miliknya.

### Indexing (18+ Index)
- `transactions(user_id, date desc)`, `transactions(wallet_id, date desc)`, `transactions(reference_transaction_id)`, `transactions(contact_id)`
- `transaction_items(transaction_id, sort_order)`
- `budgets(user_id, start_date, end_date)`
- `categories(user_id, type, parent_id)`
- `wallets(user_id, sort_order)`
- `contacts(user_id, name)`
- `investment_assets(user_id)`, `(user_id, type)`, partial index `WHERE is_active = true`
- `investment_transactions(asset_id)`, `(asset_id, direction)`, `(user_id)`
- `gold_prices(source, fetched_at DESC)`
- `custom_gold_types(user_id)`, `custom_asset_categories(user_id)`

### Default Seed Categories
- **Expense** (7 parent + children): Kebutuhan Rumah Tangga, Kesehatan & Kebugaran, Transportasi, Tagihan & Kewajiban, Teknologi & Edukasi, Keluarga & Sosial, Lain-lain
- **Income** (3 parent + children): Gaji & Pendapatan Utama, Pendapatan Tambahan, Lain-lain
- **System** (2): Penyesuaian Saldo, Transfer ke Aset

### Performance Rules
- History list wajib pagination / infinite scroll
- Jangan fetch seluruh transaksi untuk dashboard
- Grouping history dilakukan lokal dari satu fetch source
- Cache parsing dictionary 24 jam
- Cache harga investasi 12 jam (TTL-based di Hive)
- Harga emas via Edge Function `gold-price` (pg_cron daily 09:00 WIB)
- Harga bitcoin via Edge Function `bitcoin-price` (pg_cron hourly)

### Final Database Decisions
- `transactions` = ledger utama
- `wallets.balance` = hasil turunan ledger (derived)
- Budget hanya untuk category expense
- Settlement **tidak masuk** report dan budget
- Investasi yang memotong wallet harus membuat `transfer_to_asset`
- Settlement memiliki RPC terpisah (`settle_debt_or_loan`, `update_settlement`, `delete_settlement`)
- Debt/loan query memiliki RPC khusus grouped by contact

## Relevansi untuk SakuRapi

Dokumen ini adalah **otoritas tertinggi** untuk schema database. Jika ada konflik antara dokumen ini dengan dokumen lain, 02_DATABASE.md yang dimenangkan. Semua developer dan AI assistant wajib merujuk dokumen ini sebelum membuat Model, menulis RemoteDataSource, atau merancang query. Prinsip ledger-based dan atomic write via RPC menjadi tulang punggung integritas data finansial SakuRapi.

## Halaman Terkait

- [[wiki/entities/database-schema|Database Schema]]
- [[wiki/entities/wallet|Wallet]]
- [[wiki/entities/transaksi|Transaksi]]
- [[wiki/entities/budgeting|Budgeting]]
- [[wiki/entities/investasi|Investasi]]
- [[wiki/entities/hutang-piutang|Hutang-Piutang]]
- [[wiki/entities/categories|Categories]]
- [[wiki/entities/contacts|Contacts]]
- [[wiki/concepts/aturan-keuangan|Aturan Keuangan]]
