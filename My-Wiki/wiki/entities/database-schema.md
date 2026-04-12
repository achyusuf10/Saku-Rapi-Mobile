---
title: "Database Schema"
type: entity
tags: [database, schema, supabase, postgres, rls, trigger, rpc, index]
sources: [raw/docs/02_DATABASE.md]
created: 2026-04-10
updated: 2026-04-10
---

# Database Schema

> Halaman ini adalah referensi lengkap untuk seluruh struktur database Supabase/Postgres SakuRapi. Dokumen ini merupakan **sumber kebenaran tunggal** untuk schema, constraint, trigger, RPC, RLS, dan indexing.

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
6. Semua tanggal operasional disimpan UTC, lalu dirender dengan timezone Asia/Jakarta.
7. MVP single currency: `IDR`.

---

## Schema (15 Tabel)

### 1. `public.users`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | mirror dari `auth.users.id` |
| email | text not null | email user |
| full_name | text | nama tampilan |
| avatar_url | text nullable | URL storage |
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
| user_id | uuid nullable FK | null = global/default |
| name | text not null | |
| icon | text not null | fontawesome icon |
| color | text not null | |
| type | text not null | `income`, `expense`, `system` |
| parent_id | uuid nullable FK self | max 2 level |
| is_default | boolean not null default false | |
| is_hidden | boolean not null default false | |
| sort_order | integer not null default 0 | |
| created_at | timestamptz | |
| updated_at | timestamptz | |

**Constraint:**
- Parent dan child harus punya `type` yang sama
- System category hanya untuk internal use, tidak bisa diedit user
- Maksimal 2 level hierarchy (parent → child)

Lihat detail di: [[wiki/entities/categories|Categories]]

---

### 4. `transactions`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK | owner |
| wallet_id | uuid FK | wallet asal |
| destination_wallet_id | uuid nullable FK | wallet tujuan untuk transfer |
| type | text not null | `income`, `expense`, `transfer`, `debt`, `loan`, `adjustment`, `transfer_to_asset` |
| total_amount | numeric not null | grand total |
| date | timestamptz not null | UTC |
| merchant_name | text nullable | |
| note | text nullable | catatan header |
| attachment_url | text nullable | |
| with_person | text nullable | wajib untuk debt/loan |
| status | text nullable | `unpaid`, `paid`, `partial` (untuk debt/loan origin) |
| due_date | timestamptz nullable | |
| is_multi_item | boolean not null default false | |
| reference_transaction_id | uuid nullable FK self | untuk settlement |
| settlement_kind | text nullable | `debt_payment`, `loan_collection` |
| contact_id | uuid nullable FK | referensi ke `contacts.id` |
| created_at | timestamptz | |
| updated_at | timestamptz | |

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

### 5. `transaction_items`

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

### 6. `budgets`

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
| notification_sent_50 | boolean not null default false | **Dihapus di Migration 015** |
| notification_sent_80 | boolean not null default false | **Dihapus di Migration 015** |
| notification_sent_100 | boolean not null default false | **Dihapus di Migration 015** |
| carry_forward | boolean not null default false | rollover sisa positif ke periode baru |
| period_type | text not null default 'monthly' | `weekly`, `monthly`, `quarterly`, `yearly`, `custom` |
| created_at | timestamptz | |
| updated_at | timestamptz | |

**Constraint:**
- Hanya boleh menunjuk category `type = 'expense'`
- `amount > 0`
- `end_date >= start_date`
- `period_type` CHECK: `weekly`, `monthly`, `quarterly`, `yearly`, `custom`
- Tidak boleh ada duplikasi budget aktif dengan scope identik

---

### 7. `custom_gold_types`

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

### 8. `custom_asset_categories`

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

### 9. `investment_assets`

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

### 10. `investment_transactions`

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
| date | timestamptz not null default now() | tanggal transaksi |
| note | text nullable | |
| created_at | timestamptz | default now() |

**Constraint:**
- `direction` CHECK: `buy`, `sell`
- `units > 0`, `price_per_unit > 0`, `fee >= 0`
- `linked_wallet_transaction_id` mereferensi transaksi ledger wallet yang dibuat oleh RPC

---

### 11. `gold_prices`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | default gen_random_uuid() |
| source | text not null | `antaremas`, `logammulia` CHECK |
| buy_price | numeric not null | harga buyback per gram, CHECK > 0 |
| sell_price | numeric not null | harga jual toko per gram, CHECK > 0 |
| fetched_at | timestamptz | default now() |

**Catatan:** **TIDAK** ada UNIQUE pada `source` — tabel ini append-only (INSERT) untuk keperluan charting historis. Client query: `SELECT ... WHERE source = ? ORDER BY fetched_at DESC LIMIT 1`.

---

### 12. `bitcoin_prices`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | default gen_random_uuid() |
| source | text not null UNIQUE | `indodax`, `coingecko` CHECK |
| price_idr | numeric not null | harga BTC dalam IDR, CHECK > 0 |
| fetched_at | timestamptz | default now() |

**Catatan:** `source` UNIQUE — tabel ini UPSERT (INSERT ON CONFLICT UPDATE), hanya 2 row. Di-update via RPC `upsert_bitcoin_price` atau edge function.

---

### 13. `parsing_dictionaries`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| keyword | text not null | lowercase keyword |
| category_id | uuid FK | target category |
| created_at | timestamptz | |
| updated_at | timestamptz | |

---

### 14. `notification_settings` ⚠️ DIHAPUS

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

### 15. `contacts`

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

## Triggers & Functions

| Nama | Event | Tujuan |
|---|---|---|
| `handle_new_user()` | after insert on `auth.users` | upsert `public.users` |
| `seed_default_categories()` | after insert on `public.users` | insert kategori default |
| `seed_notification_settings()` | after insert on `public.users` | insert default notification settings — **Dihapus di Migration 015** |
| `update_wallet_balance()` | after insert/update/delete on `transactions` | update saldo wallet |
| `update_budget_usage()` | after insert/update/delete on `transaction_items` | recalc budget usage |
| `set_updated_at()` | before update | applied to: wallets, categories, transactions, budgets, contacts, investment_assets, custom_gold_types, custom_asset_categories (9 tabel; `notification_settings` dihapus di Migration 015) |
| `auto_renew_budgets()` | pg_cron daily | clone recurring budgets; period-aware date calculation; carry_forward support; reset notification flags |
| `check_max_custom_gold_types()` | before insert on `custom_gold_types` | max 2 jenis emas custom per user |
| `check_max_custom_asset_categories()` | before insert on `custom_asset_categories` | max 3 kategori custom per user |

> **Catatan:** Logic auto-inactive/active aset investasi (berdasarkan net_units) dikelola langsung di dalam RPC (`sell_investment`, `topup_investment`, `edit_investment_transaction`, `delete_investment_transaction`), **BUKAN** via trigger terpisah.

---

## RPC (Remote Procedure Calls)

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

---

## RLS (Row Level Security)

### Tabel yang dilindungi RLS (14 tabel)

users, wallets, categories, transactions, transaction_items, budgets, investment_assets, investment_transactions, gold_prices, bitcoin_prices, custom_gold_types, custom_asset_categories, parsing_dictionaries, contacts.

> `notification_settings` dihapus di Migration 015 — tidak lagi ada di daftar ini.

### Prinsip RLS

- User hanya boleh membaca/menulis data **miliknya sendiri**
- `categories` dengan `user_id IS NULL` boleh dibaca oleh semua user terautentikasi (global/default categories)
- System categories **tidak boleh** diedit user
- Akses storage attachment dibatasi ke owner

---

## Indexes (Minimum 20)

| Index | Tujuan |
|---|---|
| `transactions(user_id, date DESC)` | Query history per user |
| `transactions(wallet_id, date DESC)` | Query per wallet |
| `transactions(reference_transaction_id)` | Lookup settlement |
| `transactions(contact_id)` | Lookup by contact |
| `transaction_items(transaction_id, sort_order)` | Items per transaction |
| `budgets(user_id, start_date, end_date)` | Budget per periode |
| `categories(user_id, type, parent_id)` | Filter kategori |
| `wallets(user_id, sort_order)` | Urutan wallet |
| `contacts(user_id, name)` | Lookup kontak |
| `investment_assets(user_id)` | Basic user filter |
| `investment_assets(user_id, type)` | Filter by asset type |
| `investment_assets(user_id) WHERE is_active = true` | Partial index aset aktif |
| `investment_transactions(asset_id)` | Join to asset |
| `investment_transactions(asset_id, direction)` | Filter buy/sell |
| `investment_transactions(user_id)` | User filter |
| `gold_prices(source, fetched_at DESC)` | Latest price per source |
| `bitcoin_prices(source)` | Unique per source (via UNIQUE constraint) |
| `custom_gold_types(user_id)` | User filter |
| `custom_asset_categories(user_id)` | User filter |

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

- [[wiki/entities/wallet|Wallet]]
- [[wiki/entities/transaksi|Transaksi]]
- [[wiki/entities/budgeting|Budgeting]]
- [[wiki/entities/investasi|Investasi]]
- [[wiki/entities/hutang-piutang|Hutang Piutang]]
- [[wiki/entities/categories|Categories]]
- [[wiki/entities/contacts|Contacts]]
- [[wiki/concepts/aturan-keuangan|Aturan Keuangan]]
- [[wiki/concepts/matrix-transaksi|Matrix Transaksi]]
