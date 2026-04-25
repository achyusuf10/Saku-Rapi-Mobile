---
title: "Database Schema"
type: entity
tags: [database, schema, supabase, postgres, rls, trigger, rpc, index, categories, user_category_hidden]
sources: [raw/docs/02_DATABASE.md, raw/security-audit.md]
created: 2026-04-10
updated: 2026-04-25
---

# Database Schema

> Halaman ini adalah referensi untuk struktur database Supabase/Postgres SakuRapi: schema, constraint, trigger, RPC, RLS, dan indexing. Detail alur kategori global + `user_category_hidden` + migrasi Apr 2026: [[wiki/entities/categories|Categories]].

**Database authority:** Supabase Postgres
**Ledger rule:** `wallets.balance` hanya berubah dari trigger berbasis `transactions`
**MVP currency:** IDR (single currency)

---

## Prinsip Database

1. Semua tabel business wajib memakai RLS.
2. Semua write transaksi yang memengaruhi saldo harus **atomik**.
3. `transactions` adalah ledger utama.
4. `transaction_items` wajib ada minimal 1 row untuk setiap transaksi.
5. `sum(transaction_items.amount)` harus sama dengan `transactions.total_amount`.
6. Timestamp disimpan UTC; field kalender murni disimpan sebagai `date`; UI merender timestamp ke local device user.
7. MVP single currency: `IDR`.

---

## Schema (19 Tabel)

### 1. `users`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | mirror dari `auth.users.id` |
| email | text not null | email user |
| full_name | text | nama tampilan |
| avatar_url | text nullable | URL storage |
| tier | text not null | default 'free', tier langganan (free/premium) |
| tier_expires_at | timestamptz nullable | kapan tier expired, null = permanen |
| created_at | timestamptz | default now() |
| updated_at | timestamptz | auto update |

---

### 2. `wallets`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK | owner |
| name | text not null | nama dompet |
| icon | text not null | fontawesome icon name |
| color | text not null | hex color |
| balance | numeric not null default 0 | current balance (read-only di client) |
| initial_balance | numeric not null default 0 | saldo saat create |
| currency | text not null default 'IDR' | MVP fixed |
| exclude_from_total | boolean not null default false | dashboard toggle |
| sort_order | integer not null default 0 | urutan tampil |
| created_at | timestamptz | |
| updated_at | timestamptz | |

**Constraint:**
- `currency = 'IDR'` untuk MVP
- `name` unique per user (case-insensitive)
- `initial_balance >= 0`

---

### 3. `categories`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| user_id | uuid nullable FK | `null` = katalog **global** (bukan salinan per user) |
| name | text not null | |
| icon | text not null | fontawesome icon |
| color | text not null | |
| type | text not null | `income`, `expense`, `system` |
| parent_id | uuid nullable FK self | max 2 level |
| is_default | boolean not null default false | |
| sort_order | integer not null default 0 | |
| created_at | timestamptz | |
| updated_at | timestamptz | |

> **Migrasi 2026-04 (katalog global):** kolom `categories.is_hidden` **dihapus**. Preferensi *hidden* per user: `user_category_hidden` + proyeksi `is_hidden` lewat RPC. Lihat [[wiki/entities/categories|Categories]].

**Constraint:**
- Parent dan child harus punya `type` yang sama
- System category hanya untuk internal use, tidak bisa diedit user
- Maksimal 2 level hierarchy (parent → child)

Lihat detail di: [[wiki/entities/categories|Categories]]

---

### 4. `user_category_hidden`

| Kolom | Tipe | Keterangan |
|---|---|---|
| user_id | uuid | pemilik; UNIQUE berpasangan dengan `category_id` |
| category_id | uuid FK | kategori (global atau milik user) yang disembunyikan di UI |

**Semantik:** baris = pasangan (user, kategori) yang *hidden*. Katalog global (`categories.user_id` null) tetap satu baris bersama; *hide* tidak mengubah `categories`.

---

### 5. `transactions`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK | owner |
| wallet_id | uuid FK | wallet asal |
| destination_wallet_id | uuid nullable FK | wallet tujuan untuk transfer |
| type | text not null | `income`, `expense`, `transfer`, `debt`, `loan`, `adjustment`, `transfer_to_asset` |
| total_amount | numeric not null | grand total |
| date | timestamptz not null default now() | waktu transaksi UTC |
| merchant_name | text nullable | |
| note | text nullable | catatan header |
| attachment_url | text nullable | |
| with_person | text nullable | wajib untuk debt/loan |
| status | text nullable | `unpaid`, `paid`, `partial` (untuk debt/loan origin) |
| due_date | date nullable | tanggal jatuh tempo kalender |
| is_multi_item | boolean not null default false | |
| reference_transaction_id | uuid nullable FK self | untuk settlement |
| settlement_kind | text nullable | `debt_payment`, `loan_collection` |
| contact_id | uuid nullable FK | referensi ke `contacts.id` |
| created_at | timestamptz | |
| updated_at | timestamptz | |

**Catatan:** `date` adalah point-in-time transaksi yang disimpan sebagai `timestamptz` (UTC) lalu dirender lokal di client. `due_date` tetap field kalender murni (`YYYY-MM-DD`).

**Constraint:**
- `total_amount > 0`
- `wallet_id != destination_wallet_id`
- `destination_wallet_id is not null` hanya jika `type = 'transfer'`
- `with_person is not null` jika `type in ('debt', 'loan')`
- `settlement_kind is not null` → `reference_transaction_id is not null`
- `settlement_kind = 'debt_payment'` → `type = 'expense'`
- `settlement_kind = 'loan_collection'` → `type = 'income'`
- `status` nullable CHECK: `NULL` atau salah satu dari `unpaid`, `paid`, `partial`

---

### 6. `transaction_items`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| transaction_id | uuid FK | parent transaction |
| category_id | uuid nullable FK | wajib untuk income/expense biasa |
| item_name | text nullable | nama item OCR/manual |
| qty | numeric not null default 1 | jumlah item |
| unit_price | numeric nullable | harga per unit |
| amount | numeric not null | subtotal authoritative |
| note | text nullable | |
| sort_order | integer not null default 0 | |

**Constraint:**
- Setiap transaksi minimal punya 1 item
- `amount > 0`
- `qty > 0`
- Jika `qty` dan `unit_price` ada, maka `amount = qty * unit_price`
- `sum(amount)` untuk semua item harus sama dengan `transactions.total_amount`

---

### 7. `budgets`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK | owner |
| category_id | uuid FK | category yang dibudget (expense only) |
| wallet_id | uuid nullable FK | null = global (semua wallet) |
| amount | numeric not null | budget limit |
| used_amount | numeric not null default 0 | current usage |
| start_date | date not null | |
| end_date | date not null | |
| is_recurring | boolean not null default false | auto clone |
| carry_forward | boolean not null default false | rollover sisa positif ke periode baru |
| period_type | text not null default 'monthly' | `weekly`, `monthly`, `quarterly`, `yearly`, `custom` |
| created_at | timestamptz | |
| updated_at | timestamptz | |

**Catatan:** Kolom notification flags sudah dihapus di Migration 015. Renewal budget sekarang fokus pada period rollover + carry forward.

**Constraint:**
- Hanya boleh menunjuk category `type = 'expense'`
- `amount > 0`
- `end_date >= start_date`
- `period_type` CHECK: `weekly`, `monthly`, `quarterly`, `yearly`, `custom`
- Tidak boleh ada duplikasi budget aktif dengan scope identik

---

### 8. `custom_gold_types`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | default gen_random_uuid() |
| user_id | uuid FK → auth.users | owner |
| name | text not null | nama jenis emas custom (misal: "UBS", "Dinar") |
| created_at | timestamptz | default now() |
| updated_at | timestamptz | auto update via trigger |

**Constraint:**
- Max 2 per user (enforced via trigger `check_max_custom_gold_types`)
- RLS: user hanya akses miliknya sendiri

---

### 9. `custom_asset_categories`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | default gen_random_uuid() |
| user_id | uuid FK → auth.users | owner |
| name | text not null | nama kategori (misal: "Saham", "Reksadana") |
| unit_label | text not null default 'Unit' | satuan aset (misal: "Lot", "Lembar") |
| created_at | timestamptz | default now() |
| updated_at | timestamptz | auto update via trigger |

**Constraint:**
- Max 3 per user (enforced via trigger `check_max_custom_asset_categories`)
- `unit_label` adalah sumber tunggal satuan untuk semua aset custom yang mereferensi kategori ini
- RLS: user hanya akses miliknya sendiri

---

### 10. `investment_assets`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | default gen_random_uuid() |
| user_id | uuid FK → auth.users | owner |
| type | text not null | `gold`, `bitcoin`, `custom` CHECK |
| name | text not null | nama aset |
| gold_type | text nullable | `antam`, `perhiasan`, `custom` CHECK (for type=gold) |
| custom_gold_type_id | uuid nullable FK → custom_gold_types | jenis emas custom (jika gold_type='custom') |
| custom_category_id | uuid nullable FK → custom_asset_categories | kategori aset custom (jika type='custom') |
| unit_label | text not null default 'unit' | satuan (gram, BTC, Lot, dll) |
| price_source | text not null default 'manual' | `antaremas`, `logammulia`, `indodax`, `coingecko`, `manual` CHECK |
| current_price | numeric not null default 0 | harga terkini, CHECK >= 0 |
| is_active | boolean not null default true | false jika totalUnits = 0 |
| created_at | timestamptz | default now() |
| updated_at | timestamptz | auto update via trigger |

**Constraint:**
- `type` CHECK: `gold`, `bitcoin`, `custom`
- `gold_type` CHECK: NULL, `antam`, `perhiasan`, `custom`
- `price_source` CHECK: `antaremas`, `logammulia`, `indodax`, `coingecko`, `manual`
- `current_price >= 0`
- Auto-inactive/active dikelola oleh RPC, **bukan** trigger

---

### 11. `investment_transactions`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | default gen_random_uuid() |
| asset_id | uuid FK → investment_assets | ON DELETE CASCADE |
| user_id | uuid FK → auth.users | owner |
| direction | text not null | `buy`, `sell` CHECK |
| units | numeric not null | jumlah unit, CHECK > 0 |
| price_per_unit | numeric not null | harga per unit, CHECK > 0 |
| fee | numeric not null default 0 | biaya/fee, CHECK >= 0 |
| wallet_id | uuid nullable FK → wallets | wallet terkait |
| deduct_wallet | boolean not null default false | apakah memotong/menambah saldo wallet |
| linked_wallet_transaction_id | uuid nullable FK → transactions | transaksi wallet terkait |
| date | timestamptz not null default now() | waktu transaksi investasi UTC |
| note | text nullable | |
| created_at | timestamptz | default now() |

**Catatan:** `date` adalah point-in-time investasi yang disimpan sebagai `timestamptz` (UTC) lalu dirender lokal di client.

**Constraint:**
- `direction` CHECK: `buy`, `sell`
- `units > 0`, `price_per_unit > 0`, `fee >= 0`
- `linked_wallet_transaction_id` mereferensi transaksi ledger wallet yang dibuat oleh RPC

---

### 12. `gold_prices`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | default gen_random_uuid() |
| source | text not null | `antaremas`, `logammulia` CHECK |
| buy_price | numeric not null | harga buyback per gram, CHECK > 0 |
| sell_price | numeric not null | harga jual toko per gram, CHECK > 0 |
| fetched_at | timestamptz | default now() |

**Catatan:** **TIDAK** ada UNIQUE pada `source` — tabel ini append-only (INSERT) untuk keperluan charting historis. Client query: `SELECT ... WHERE source = ? ORDER BY fetched_at DESC LIMIT 1`.

> ⚠️ **Security:** INSERT ke tabel ini hanya boleh dilakukan service_role (via edge function). Policy publik `gold_prices_insert_all` sudah dihapus (Migration `security_fix_gold_prices_rls`). User biasa tidak bisa inject data harga palsu.

---

### 13. `bitcoin_prices`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | default gen_random_uuid() |
| source | text not null UNIQUE | `indodax`, `coingecko` CHECK |
| price_idr | numeric not null | harga BTC dalam IDR, CHECK > 0 |
| fetched_at | timestamptz | default now() |

**Catatan:** `source` UNIQUE — tabel ini UPSERT (INSERT ON CONFLICT UPDATE), hanya 2 row. Di-update via RPC `upsert_bitcoin_price` atau edge function.

---

### 14. `parsing_dictionaries`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| keyword | text not null | lowercase keyword |
| category_id | uuid FK | target category |
| created_at | timestamptz | |
| updated_at | timestamptz | |

> Beberapa *migration* hanya memutakhirkan tabel ini jika `to_regclass('public.parsing_dictionaries')` ada, agar aman bila tabel belum/ tidak dipasang di lingkungan tertentu.

---

### 15. `notification_settings` ⚠️ DIHAPUS

> **Dihapus di Migration 015** (`20260412100000_015_remove_notification.sql`). Tabel ini tidak ada lagi di database. `DROP TABLE notification_settings CASCADE` juga menghapus trigger `trg_notification_settings_updated_at` dan RLS policies `notification_settings_select_own` / `notification_settings_update_own`.

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK | owner |
| reminder_enabled | boolean not null default false | daily reminder |
| reminder_time | time nullable | |
| budget_alert_enabled | boolean not null default true | |
| budget_alert_50_enabled | boolean not null default false | early warning 50% |
| debt_reminder_enabled | boolean not null default true | |
| debt_reminder_days_before | integer not null default 3 | |
| created_at | timestamptz | |
| updated_at | timestamptz | |

---

### 16. `contacts`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | default gen_random_uuid() |
| user_id | uuid FK | owner |
| name | text not null | nama kontak |
| phone | text nullable | nomor telepon |
| created_at | timestamptz | default now() |
| updated_at | timestamptz | auto update |

**Constraint:**
- `name` wajib tidak kosong
- Digunakan sebagai referensi `transactions.contact_id` untuk hutang/piutang
- Data di-upsert dari phonebook device via RPC `upsert_contact`

Lihat detail di: [[wiki/entities/contacts|Contacts]]

---

### 17. `ai_usage_quotas`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | default gen_random_uuid() |
| tier | text not null | 'free' atau 'premium' |
| mode | text not null | 'text', 'voice', atau 'ocr' |
| daily_limit | int not null | batas per hari |
| created_at | timestamptz | default now() |
| updated_at | timestamptz | auto update |

**Constraint:** UNIQUE(tier, mode)
**RLS:** select untuk semua authenticated users

Seed data: free (text=5, voice=5, ocr=3), premium (text=20, voice=20, ocr=10)

---

### 18. `ai_usage_logs`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | default gen_random_uuid() |
| user_id | uuid FK | references users(id) on delete cascade |
| mode | text not null | 'text', 'voice', atau 'ocr' |
| provider | text nullable | model/provider yang dipakai saat parse |
| created_at | timestamptz | default now() |
| usage_date | date not null | tanggal lokal user saat kuota dihitung |

**Index:** (user_id, mode, usage_date) untuk query kuota harian; `created_at` tetap dipakai sebagai audit timestamp UTC
**RLS:** select hanya row milik sendiri (user_id = auth.uid())

Lihat detail di: [[wiki/analysis/refactor-ai-parse-gemini-quota|Refactor AI Parse]]

### 19. `user_reports`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | default gen_random_uuid() |
| user_id | uuid FK | references auth.users(id) ON DELETE CASCADE |
| category | text not null | `bug_report`, `feature_request`, `account_issue`, `payment_issue`, `other` |
| title | text not null | judul laporan |
| description | text not null | deskripsi detail |
| attachment_url | text nullable | URL foto lampiran (Supabase Storage `attachments/{userId}/reports/`) |
| status | text not null default 'pending' | status admin |
| created_at | timestamptz | default now() |

**RLS:** INSERT-only — user hanya bisa insert laporan miliknya sendiri (`auth.uid() = user_id`). Tidak ada SELECT / UPDATE / DELETE policy untuk user.

Lihat detail di: [[wiki/entities/user-report|User Report]]

---

## Triggers & Functions

| Nama | Event | Tujuan |
|---|---|---|
| `handle_new_user()` | after insert on `auth.users` | upsert `public.users` |
| `seed_default_categories()` | *(tidak lagi dipasang ke `auth.users`)* | Fungsi tetap ada (RETURNS trigger) sebagai *no-op*; trigger `trg_seed_default_categories` **dihapus** pada migrasi katalog global **Apr 2026**. Kategori bawaan = **baris global** di `categories`, bukan *copy* per pendaftaran. |
| `seed_notification_settings()` | after insert on `public.users` | insert default notification settings — **Dihapus di Migration 015** |
| `update_wallet_balance()` | after insert/update/delete on `transactions` | update saldo wallet |
| `update_budget_usage()` | after insert/update/delete on `transaction_items` | recalc budget usage |
| `set_updated_at()` | before update | applied to: wallets, categories, transactions, budgets, contacts, investment_assets, custom_gold_types, custom_asset_categories (9 tabel; `notification_settings` dihapus di Migration 015) |
| `auto_renew_budgets(p_today date default current_date)` | pg_cron daily + on-demand | clone recurring budgets; period-aware date calculation; carry_forward support; bisa disinkronkan pakai tanggal lokal client |
| `check_max_custom_gold_types()` | before insert on `custom_gold_types` | max 2 jenis emas custom per user |
| `check_max_custom_asset_categories()` | before insert on `custom_asset_categories` | max 3 kategori custom per user |

> **Catatan:** Logic auto-inactive/active aset investasi (berdasarkan net_units) dikelola langsung di dalam RPC (`sell_investment`, `topup_investment`, `edit_investment_transaction`, `delete_investment_transaction`), **BUKAN** via trigger terpisah.

---

## RPC (Remote Procedure Calls)

### History RPC

- **`get_history_transactions`** — Query riwayat transaksi dengan dual-mode pagination dan server-side search. Parameter: `p_start_date`, `p_end_date`, `p_wallet_id`, `p_type`, `p_search`, `p_group_mode` (`'byDate'`|`'byCategory'`), `p_limit`, `p_offset`. Returns `jsonb {transactions: [...], has_more: bool}`. SECURITY DEFINER, `auth.uid()` internal.
  - Mode `byDate`: pagination per transaksi (default 30), search via `note ILIKE` OR `category.name ILIKE`
  - Mode `byCategory`: pagination per kategori (default 5), kembalikan semua transaksi dari kategori yang di-page, diurutkan by `MAX(date) DESC`

### Transaction RPCs

- **`create_transaction_with_items`** — Membuat transaksi beserta items secara atomik
- **`update_transaction_with_items`** — Update transaksi dan items secara atomik
- **`delete_transaction`** — Hapus transaksi (cascade ke items)
- **`create_adjustment_transaction`** — Koreksi saldo wallet via transaksi adjustment

### Settlement RPCs

- **`settle_debt_or_loan`** — Bayar/tagih hutang/piutang (partial atau full)
- **`update_settlement`** — Edit settlement yang sudah ada
- **`delete_settlement`** — Hapus settlement

### Debt/Loan Query RPCs

- **`get_debt_loan_summary`** — Ringkasan hutang/piutang grouped by person/contact
- **`get_debt_loan_transactions_by_person`** — Daftar transaksi hutang/piutang per orang
- **`get_all_unpaid_debt_loan`** — Semua hutang/piutang yang belum lunas
- **`get_settlement_history`** — Riwayat pembayaran untuk satu transaksi asal

### Contact RPC

- **`upsert_contact`** — Insert atau update kontak (dari phonebook)

### Budget RPC

- **`replace_budget`** — Atomic DELETE old + INSERT new dalam satu transaction (untuk duplicate overlap)

### Category RPCs

- **`get_user_categories()`** — Gabungan katalog global + kategori user; field `is_hidden` di *response* berasal dari proyeksi (termasuk `user_category_hidden`), bukan kolom `categories.is_hidden` (dihapus 2026-04). `SECURITY DEFINER`, `auth.uid()` internal.
- **`toggle_category_hidden(p_category_id, p_is_hidden)`** — Toggle baris `user_category_hidden` / *unhide*; perbaikan PL/pgSQL memakai `p_uid` agar tidak ambigu dengan kolom `user_id` (migrasi `20260425220000`).

> Detail migrasi + skrip *retry* prod: [[wiki/entities/categories|Categories]].

### Investment RPCs

- **`get_investment_dashboard`** — Dashboard investasi (menggunakan `auth.uid()` internal)
- **`create_investment_asset`** — Buat aset + first buy transaction, optional wallet deduction
- **`topup_investment`** — Tambah pembelian, optional wallet deduction, reactivate jika inactive
- **`sell_investment`** — Jual aset, optional wallet credit via `income` type, auto-deactivate jika remaining=0
- **`edit_investment_transaction`** — Edit buy transaction, revert + create wallet tx jika diperlukan
- **`delete_investment_transaction`** — Hapus buy transaction, revert wallet jika linked
- **`delete_investment_asset`** — CASCADE delete semua transactions, optional revert wallet
- **`upsert_bitcoin_price`** — INSERT ON CONFLICT UPDATE untuk bitcoin_prices

> **Catatan:** Semua Investment RPC menggunakan `auth.uid()` secara internal, **BUKAN** menerima `p_user_id` sebagai parameter. Flutter boleh memanggil RPC melalui RemoteDataSource. Jangan membangun multi-step write yang rentan race condition langsung dari client.

### AI Quota RPCs

- **`check_ai_quota(p_mode)`** — Cek apakah user masih punya kuota AI. Auto-downgrade jika tier expired.
- **`log_ai_usage(p_mode, p_provider)`** — Catat penggunaan AI setelah parse berhasil. Return `{used, limit, remaining}`.
- **`get_all_ai_quotas()`** — Ambil semua kuota user (text/voice/ocr) untuk UI. Auto-downgrade jika expired.

> **Catatan:** Semua AI Quota RPC menggunakan `SECURITY DEFINER` dan `auth.uid()` internal. Batas hari dihitung dari `usage_date` (tanggal lokal user yang dikirim client), sedangkan `created_at` tetap UTC untuk audit.

---

## RLS (Row Level Security)

### Tabel yang dilindungi RLS (17 tabel)

users, wallets, categories, **user_category_hidden**, transactions, transaction_items, budgets, investment_assets, investment_transactions, gold_prices, bitcoin_prices, custom_gold_types, custom_asset_categories, parsing_dictionaries, contacts, ai_usage_quotas, ai_usage_logs, **user_reports**.

> `notification_settings` dihapus di Migration 015 — tidak lagi ada di daftar ini.

### Prinsip RLS

- User hanya boleh membaca/menulis data **miliknya sendiri**
- `categories` dengan `user_id IS NULL` readable oleh user terautentikasi (katalog **global** bersama)
- `user_category_hidden`: hanya baris `user_id = (SELECT auth.uid())` (preferensi *hide* per user)
- System categories **tidak boleh** diedit user
- Akses storage attachment dibatasi ke owner
- **Semua 44 policy menggunakan pattern `(SELECT auth.uid())`** — bukan `auth.uid()` langsung. Pattern ini mencegah PostgreSQL re-evaluate function per row, sehingga query lebih cepat untuk tabel besar. (Dioptimasi via Migration `security_optimize_rls_subselect`)

```sql
-- ✅ Pattern yang benar di semua policy SakuRapi
USING (user_id = (SELECT auth.uid()))

-- ❌ Jangan gunakan — di-evaluate per row
USING (user_id = auth.uid())
```

---

## Indexes (Minimum 28)

| Index | Tujuan |
|---|---|
| `transactions(user_id, date DESC)` | Query history per user |
| `transactions(wallet_id, date DESC)` | Query per wallet |
| `transactions(reference_transaction_id)` | Lookup settlement |
| `transactions(contact_id)` | Lookup by contact |
| `transactions(destination_wallet_id)` | Lookup transfer destination *(ditambah security audit)* |
| `transaction_items(transaction_id, sort_order)` | Items per transaction |
| `budgets(user_id, start_date, end_date)` | Budget per periode |
| `budgets(wallet_id)` | Filter budget per wallet *(ditambah security audit)* |
| `categories(user_id, type, parent_id)` | Filter kategori |
| `categories(parent_id)` | Self-join parent-child *(ditambah security audit)* |
| `user_category_hidden(user_id, category_id)` | UNIQUE; preferensi *hide* per user *(constraint)* |
| `wallets(user_id, sort_order)` | Urutan wallet |
| `contacts(user_id, name)` | Lookup kontak |
| `investment_assets(user_id)` | Basic user filter |
| `investment_assets(user_id, type)` | Filter by asset type |
| `investment_assets(user_id) WHERE is_active = true` | Partial index aset aktif |
| `investment_assets(custom_gold_type_id)` | FK join ke custom_gold_types *(ditambah security audit)* |
| `investment_assets(custom_category_id)` | FK join ke custom_asset_categories *(ditambah security audit)* |
| `investment_transactions(asset_id)` | Join to asset |
| `investment_transactions(asset_id, direction)` | Filter buy/sell |
| `investment_transactions(user_id)` | User filter |
| `investment_transactions(wallet_id)` | FK join ke wallets *(ditambah security audit)* |
| `investment_transactions(linked_wallet_transaction_id)` | FK join ke transactions *(ditambah security audit)* |
| `gold_prices(source, fetched_at DESC)` | Latest price per source |
| `bitcoin_prices(source)` | Unique per source (via UNIQUE constraint) |
| `custom_gold_types(user_id)` | User filter |
| `custom_asset_categories(user_id)` | User filter |
| `ai_usage_logs(user_id, mode, usage_date)` | Query kuota harian |

### Performance Rules

- History list wajib pagination / infinite scroll
- Jangan fetch semua transaksi sepanjang masa untuk dashboard
- Grouping history dilakukan lokal dari satu fetch source
- Cache dictionary 24 jam
- Cache harga investasi 12 jam (TTL-based di Hive)
- Harga emas di-fetch via Edge Function `gold-price` (pg_cron daily 09:00 WIB)
- Harga bitcoin di-fetch via Edge Function `bitcoin-price` (pg_cron hourly)
- Upload attachment dilakukan async dengan UI progress state

---

## Accounting Rules Checklist

Checklist validasi database untuk memastikan integritas data keuangan:

1. Transfer wajib punya `destination_wallet_id`
2. Transfer tidak boleh pakai wallet yang sama sebagai source dan destination
3. `debt` dan `loan` wajib punya `with_person`
4. `debt` dan `loan` boleh punya `contact_id` (FK ke `contacts`)
5. `transaction_items` minimal 1 row per transaksi
6. Total item wajib sama dengan total header transaksi
7. Settlement wajib merefer ke transaksi asal via `reference_transaction_id`
8. Settlement `debt_payment` hanya valid sebagai `type = 'expense'`
9. Settlement `loan_collection` hanya valid sebagai `type = 'income'`
10. Settlement amount tidak boleh melebihi remaining dari transaksi referensi
11. Budget hanya boleh terkait category `expense`
12. Investasi buy/sell yang melibatkan wallet harus melalui ledger transaksi (buy → `transfer_to_asset`, sell → `income`)
13. Investment asset auto-inactive ketika net_units ≤ 0 (dikelola RPC, bukan trigger)
14. Max 2 custom gold types per user (trigger)
15. Max 3 custom asset categories per user (trigger)
16. `custom_asset_categories.unit_label` adalah sumber tunggal satuan untuk aset custom
17. Gold prices append-only (INSERT, tidak UPSERT) untuk charting historis
18. Bitcoin prices UPSERT via `upsert_bitcoin_price` RPC (hanya 2 row)
19. Semua Investment RPC menggunakan `auth.uid()` internal, bukan parameter `p_user_id`
20. Edit/delete investment transaction hanya untuk `direction = 'buy'`
21. Edit/delete buy transaction divalidasi: sisa buy units setelah perubahan tidak boleh < total sell units
22. `contacts` di-upsert dari phonebook, referensi aman meskipun kontak diedit
23. Katalog kategori bawaan = baris `categories` dengan `user_id` null; *hide* UI per user lewat `user_category_hidden` + RPC, bukan kolom `categories.is_hidden`

---

## Final Database Decisions

Jika ada konflik implementasi:

- `transactions` adalah **ledger utama**
- `wallets.balance` adalah **hasil turunan ledger**
- `transaction_items` adalah **detail authoritative** untuk item breakdown
- Budget hanya untuk category expense
- Settlement tidak masuk report/budget
- Investasi yang memotong wallet harus membuat `transfer_to_asset`
- `contacts` menyimpan referensi kontak untuk hutang/piutang, diakses via `contact_id`
- Settlement memiliki RPC terpisah
- Debt/loan query memiliki RPC khusus grouped by contact

---

## Halaman Terkait

- [[wiki/concepts/keamanan|Keamanan & Security Posture]]
- [[wiki/entities/wallet|Wallet]]
- [[wiki/entities/transaksi|Transaksi]]
- [[wiki/entities/budgeting|Budgeting]]
- [[wiki/entities/investasi|Investasi]]
- [[wiki/entities/hutang-piutang|Hutang Piutang]]
- [[wiki/entities/categories|Categories]]
- [[wiki/entities/contacts|Contacts]]
- [[wiki/concepts/aturan-keuangan|Aturan Keuangan]]
- [[wiki/concepts/matrix-transaksi|Matrix Transaksi]]
