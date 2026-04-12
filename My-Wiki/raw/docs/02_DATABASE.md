# SakuRapi — Database Final v6.4
## Schema, Constraint, Trigger, RPC, dan Indexing

> Dokumen ini adalah sumber kebenaran untuk struktur database Supabase/Postgres.
> Untuk requirement produk dan flow, lihat folder [`prd/`](prd/00_INDEX.md) (PRD dipecah per section).
> Untuk aturan implementasi Flutter/Copilot, lihat `03_COPILOT_RULES.md`.

**Status:** Final for implementation  
**Database authority:** Supabase Postgres  
**Ledger rule:** `wallets.balance` hanya berubah dari trigger berbasis `transactions`

---

## 1. Prinsip Database

1. Semua tabel business wajib memakai RLS.
2. Semua write transaksi yang memengaruhi saldo harus **atomik**.
3. `transactions` adalah ledger utama.
4. `transaction_items` wajib ada minimal 1 row untuk setiap transaksi.
5. `sum(transaction_items.amount)` harus sama dengan `transactions.total_amount`.
6. Semua tanggal operasional disimpan UTC, lalu dirender dengan timezone Asia/Jakarta.
7. MVP single currency: `IDR`.

---

## 2. Schema Final

## 2.1 `public.users`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | mirror dari `auth.users.id` |
| email | text not null | email user |
| full_name | text | nama tampilan |
| avatar_url | text nullable | URL storage |
| created_at | timestamptz | default now() |
| updated_at | timestamptz | auto update |

## 2.2 `wallets`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK | owner |
| name | text not null | nama dompet |
| icon | text not null | fontawesome icon name |
| color | text not null | hex color |
| balance | numeric not null default 0 | current balance |
| initial_balance | numeric not null default 0 | saldo saat create |
| currency | text not null default 'IDR' | MVP fixed |
| exclude_from_total | boolean not null default false | dashboard toggle |
| sort_order | integer not null default 0 | urutan tampil |
| created_at | timestamptz | |
| updated_at | timestamptz | |

### Constraint
- `currency = 'IDR'` untuk MVP.
- `name` unique per user secara case-insensitive bila diperlukan.
- `initial_balance >= 0`.

## 2.3 `categories`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| user_id | uuid nullable FK | null untuk system/default global tertentu |
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

### Constraint
- parent dan child harus punya `type` yang sama.
- system category hanya untuk internal use.
- maksimal 2 level hierarchy.

## 2.4 `transactions`
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
| status | text nullable | `unpaid`, `paid`, `partial` untuk debt/loan origin |
| due_date | date nullable | tanggal jatuh tempo kalender |
| is_multi_item | boolean not null default false | |
| reference_transaction_id | uuid nullable FK self | untuk settlement |
| settlement_kind | text nullable | `debt_payment`, `loan_collection` |
| contact_id | uuid nullable FK | referensi ke `contacts.id` untuk debt/loan |
| created_at | timestamptz | |
| updated_at | timestamptz | |

### Constraint
- `total_amount > 0`
- `wallet_id != destination_wallet_id`
- `destination_wallet_id is not null` hanya jika `type = 'transfer'`
- `with_person is not null` jika `type in ('debt','loan')`
- `settlement_kind is not null` -> `reference_transaction_id is not null`
- `settlement_kind = 'debt_payment'` -> `type = 'expense'`
- `settlement_kind = 'loan_collection'` -> `type = 'income'`
- `status` nullable CHECK: `NULL` atau salah satu dari `unpaid`, `paid`, `partial`

## 2.5 `transaction_items`
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

### Constraint
- setiap transaksi minimal punya 1 item.
- `amount > 0`
- `qty > 0`
- jika `qty` dan `unit_price` ada, maka `amount = qty * unit_price` pada level aplikasi/DB validation.
- `sum(amount)` untuk semua item harus sama dengan `transactions.total_amount`.

## 2.6 `budgets`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK | owner |
| category_id | uuid FK | category yang dibudget |
| wallet_id | uuid nullable FK | null = global |
| amount | numeric not null | budget limit |
| used_amount | numeric not null default 0 | current usage |
| start_date | date not null | |
| end_date | date not null | |
| is_recurring | boolean not null default false | auto clone |
| notification_sent_50 | boolean not null default false | |
| notification_sent_80 | boolean not null default false | |
| notification_sent_100 | boolean not null default false | |
| carry_forward | boolean not null default false | rollover sisa positif ke periode baru |
| period_type | text not null default 'monthly' | `weekly`, `monthly`, `quarterly`, `yearly`, `custom` |
| created_at | timestamptz | |
| updated_at | timestamptz | |

### Constraint
- hanya boleh menunjuk category `type = 'expense'`
- `amount > 0`
- `end_date >= start_date`
- `period_type` CHECK: salah satu dari `weekly`, `monthly`, `quarterly`, `yearly`, `custom`
- tidak boleh ada duplikasi budget aktif dengan scope identik tanpa keputusan merge.

## 2.7 `custom_gold_types`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | default gen_random_uuid() |
| user_id | uuid FK → auth.users | owner |
| name | text not null | nama jenis emas custom (misal: "UBS", "Dinar") |
| created_at | timestamptz | default now() |
| updated_at | timestamptz | auto update via trigger |

### Constraint
- Max 2 per user (enforced via trigger `check_max_custom_gold_types`)
- RLS: user hanya akses miliknya sendiri (SELECT/INSERT/UPDATE/DELETE)

## 2.8 `custom_asset_categories`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | default gen_random_uuid() |
| user_id | uuid FK → auth.users | owner |
| name | text not null | nama kategori (misal: "Saham", "Reksadana") |
| unit_label | text not null default 'Unit' | satuan aset (misal: "Lot", "Lembar") |
| created_at | timestamptz | default now() |
| updated_at | timestamptz | auto update via trigger |

### Constraint
- Max 3 per user (enforced via trigger `check_max_custom_asset_categories`)
- `unit_label` adalah sumber tunggal satuan untuk semua aset custom yang mereferensi kategori ini
- RLS: user hanya akses miliknya sendiri (SELECT/INSERT/UPDATE/DELETE)

## 2.9 `investment_assets`
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

### Constraint
- `type` CHECK: `gold`, `bitcoin`, `custom`
- `gold_type` CHECK: NULL, `antam`, `perhiasan`, `custom`
- `price_source` CHECK: `antaremas`, `logammulia`, `indodax`, `coingecko`, `manual`
- `current_price >= 0`
- Max 3 custom asset categories per user (enforced via trigger `check_max_custom_asset_categories` pada tabel `custom_asset_categories`)
- Max 2 custom gold types per user (enforced via trigger `check_max_custom_gold_types` pada tabel `custom_gold_types`)
- Auto-inactive/active dikelola oleh RPC (sell_investment, topup_investment, edit/delete_investment_transaction)

## 2.10 `investment_transactions`
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
| linked_wallet_transaction_id | uuid nullable FK → transactions | transaksi wallet terkait (transfer_to_asset/income) |
| date | timestamptz not null default now() | tanggal transaksi |
| note | text nullable | |
| created_at | timestamptz | default now() |

### Constraint
- `direction` CHECK: `buy`, `sell`
- `units > 0`, `price_per_unit > 0`, `fee >= 0`
- `linked_wallet_transaction_id` mereferensi transaksi ledger wallet yang dibuat oleh RPC

## 2.11 `gold_prices`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | default gen_random_uuid() |
| source | text not null | `antaremas`, `logammulia` CHECK |
| buy_price | numeric not null | harga buyback per gram (yang didapat user saat jual), CHECK > 0 |
| sell_price | numeric not null | harga jual toko per gram (yang dibayar user saat beli), CHECK > 0 |
| fetched_at | timestamptz | default now() |

### Catatan
- **TIDAK** ada UNIQUE pada `source` — tabel ini append-only (INSERT) untuk keperluan charting historis di masa depan
- Client Flutter query: `SELECT ... WHERE source = ? ORDER BY fetched_at DESC LIMIT 1`
- Index: `(source, fetched_at DESC)` untuk query performa

## 2.12 `bitcoin_prices`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | default gen_random_uuid() |
| source | text not null UNIQUE | `indodax`, `coingecko` CHECK |
| price_idr | numeric not null | harga BTC dalam IDR, CHECK > 0 |
| fetched_at | timestamptz | default now() |

### Catatan
- `source` UNIQUE — tabel ini UPSERT (INSERT ON CONFLICT UPDATE), hanya 2 row
- Di-update via RPC `upsert_bitcoin_price` atau direct upsert dari edge function

## 2.13 `parsing_dictionaries`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| keyword | text not null | lowercase keyword |
| category_id | uuid FK | target category |
| created_at | timestamptz | |
| updated_at | timestamptz | |

## 2.14 `notification_settings`
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

## 2.15 `contacts`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | default gen_random_uuid() |
| user_id | uuid FK | owner |
| name | text not null | nama kontak |
| phone | text nullable | nomor telepon |
| created_at | timestamptz | default now() |
| updated_at | timestamptz | auto update |

### Constraint
- `name` wajib tidak kosong.
- Digunakan sebagai referensi `transactions.contact_id` untuk hutang/piutang.
- Data di-upsert dari phonebook device via RPC `upsert_contact`.

---

## 3. Trigger, Function, RPC, dan Job

## 3.1 Trigger / function wajib
| Nama | Event | Tujuan |
|---|---|---|
| `handle_new_user()` | after insert on `auth.users` | upsert `public.users` |
| `seed_default_categories()` | after insert on `public.users` | insert kategori default |
| `seed_notification_settings()` | after insert on `public.users` | insert default notification settings |
| `update_wallet_balance()` | after insert/update/delete on `transactions` | update saldo wallet |
| `update_budget_usage()` | after insert/update/delete on `transaction_items` | recalc budget usage |
| `set_updated_at()` | before update on all mutable tables | update timestamp (applied to: wallets, categories, transactions, budgets, notification_settings, contacts, investment_assets, custom_gold_types, custom_asset_categories) |
| `auto_renew_budgets()` | pg_cron daily | clone recurring budgets; period-aware date calculation (weekly +7d, monthly +1mo, quarterly +3mo, yearly +1yr, custom smart: end-of-month detection vs duration preservation); carry_forward support (sisa positif ditambah ke amount budget baru); reset notification_sent_50/80/100 |
| `check_max_custom_gold_types()` | before insert on `custom_gold_types` | max 2 jenis emas custom per user |
| `check_max_custom_asset_categories()` | before insert on `custom_asset_categories` | max 3 kategori custom per user |

> **Catatan:** Logic auto-inactive/active aset investasi (berdasarkan net_units) dikelola langsung di dalam RPC (`sell_investment`, `topup_investment`, `edit_investment_transaction`, `delete_investment_transaction`), BUKAN via trigger terpisah.

## 3.2 RPC yang sudah diimplementasi
Agar write atomik dan Copilot tidak menyebar logika:

### Transaction RPCs
- `create_transaction_with_items(p_wallet_id, p_destination_wallet_id?, p_type, p_total_amount, p_date, p_merchant_name?, p_note?, p_attachment_url?, p_with_person?, p_status?, p_due_date?, p_is_multi_item, p_reference_transaction_id?, p_settlement_kind?, p_items jsonb, p_contact_id?)` → jsonb
- `update_transaction_with_items(p_transaction_id, p_wallet_id, p_destination_wallet_id?, p_type, p_total_amount, p_date, p_merchant_name?, p_note?, p_attachment_url?, p_with_person?, p_status?, p_due_date?, p_is_multi_item, p_reference_transaction_id?, p_settlement_kind?, p_items jsonb, p_contact_id?)` → jsonb
- `delete_transaction(p_transaction_id)` → jsonb
- `create_adjustment_transaction(p_wallet_id, p_target_balance, p_date?, p_note?)` → jsonb

### Settlement RPCs
- `settle_debt_or_loan(p_reference_transaction_id, p_settlement_kind, p_amount, p_wallet_id, p_date?, p_note?)` → jsonb
- `update_settlement(p_settlement_id, p_amount, p_wallet_id, p_note?)` → jsonb
- `delete_settlement(p_settlement_id)` → jsonb

### Debt/Loan Query RPCs
- `get_debt_loan_summary(p_type, p_wallet_id?)` → TABLE(with_person, contact_id, transaction_count, total_principal, total_settled, remaining, has_unpaid)
- `get_debt_loan_transactions_by_person(p_with_person, p_type, p_wallet_id?)` → TABLE(id, wallet_id, wallet_name, type, total_amount, date, note, with_person, contact_id, status, due_date, settlement_kind, reference_transaction_id, total_settled, remaining, created_at)
- `get_all_unpaid_debt_loan(p_type)` → TABLE(id, wallet_id, wallet_name, type, total_amount, date, note, with_person, contact_id, status, due_date, total_settled, remaining, created_at)
- `get_settlement_history(p_reference_transaction_id)` → TABLE(id, wallet_id, wallet_name, type, total_amount, date, note, with_person, settlement_kind, reference_transaction_id, created_at)

### Contact RPC
- `upsert_contact(p_name, p_phone?)` → uuid

### Budget RPCs
- `replace_budget(p_old_budget_id uuid, p_user_id uuid, p_category_id uuid, p_wallet_id uuid, p_amount numeric, p_start_date date, p_end_date date, p_is_recurring boolean, p_period_type text, p_carry_forward boolean)` → jsonb  
  Atomic DELETE old + INSERT new dalam satu transaction. Digunakan ketika user mengganti budget yang sudah ada (duplicate overlap).

### Investment RPCs
- `get_investment_dashboard()` → jsonb (menggunakan `auth.uid()` internal, return array of asset objects with aggregated fields: total_buy_units, total_sell_units, total_units, total_invested, total_fee, avg_buy_price, transactions_count)
- `create_investment_asset(p_type, p_name, p_gold_type?, p_custom_gold_type_id?, p_custom_category_id?, p_unit_label?, p_price_source?, p_current_price?, p_units, p_price_per_unit, p_fee?, p_date?, p_note?, p_deduct_wallet?, p_wallet_id?)` → jsonb (creates asset + first buy transaction, optional wallet deduction via `transfer_to_asset` ledger)
- `topup_investment(p_asset_id, p_units, p_price_per_unit, p_fee?, p_date?, p_note?, p_deduct_wallet?, p_wallet_id?)` → jsonb (inserts buy transaction, optional wallet deduction, reactivates inactive asset)
- `sell_investment(p_asset_id, p_units, p_price_per_unit, p_date?, p_note?, p_credit_wallet?, p_wallet_id?)` → jsonb (inserts sell transaction, optional wallet credit via `income` type, auto-deactivates if remaining=0)
- `edit_investment_transaction(p_transaction_id, p_units, p_price_per_unit, p_fee?, p_date?, p_note?, p_deduct_wallet?, p_wallet_id?)` → jsonb (rewrites buy transaction only, reverts old wallet tx + creates new if needed, validates units ≥ sell total)
- `delete_investment_transaction(p_transaction_id)` → jsonb (deletes buy transaction only, reverts wallet if linked, validates units ≥ sell total)
- `delete_investment_asset(p_asset_id, p_revert_wallet?)` → jsonb (CASCADE deletes all transactions, optionally reverts all linked wallet transactions)
- `upsert_bitcoin_price(p_source, p_price_idr)` → void (INSERT ON CONFLICT UPDATE untuk bitcoin_prices)

> **Catatan:** Semua Investment RPC menggunakan `auth.uid()` secara internal, BUKAN menerima `p_user_id` sebagai parameter. Ini memastikan keamanan — user hanya bisa mengakses data miliknya.

### Rule
Flutter boleh memanggil RPC ini melalui RemoteDataSource.  
Jangan membangun multi-step write yang rentan race condition langsung dari client.

---

## 4. RLS Policy

Semua tabel business wajib mengaktifkan RLS (15 tabel: users, wallets, categories, transactions, transaction_items, budgets, investment_assets, investment_transactions, gold_prices, bitcoin_prices, custom_gold_types, custom_asset_categories, parsing_dictionaries, notification_settings, contacts).

### Prinsip umum
- user hanya boleh membaca/menulis data miliknya sendiri.
- `categories` dengan `user_id is null` boleh dibaca oleh semua user terautentikasi.
- system categories tidak boleh diedit user.
- akses storage attachment dibatasi ke owner.

---

## 5. Indexing & Performance

### Index minimum
- `transactions(user_id, date desc)`
- `transactions(wallet_id, date desc)`
- `transactions(reference_transaction_id)`
- `transactions(contact_id)`
- `transaction_items(transaction_id, sort_order)`
- `budgets(user_id, start_date, end_date)`
- `categories(user_id, type, parent_id)`
- `wallets(user_id, sort_order)`
- `contacts(user_id, name)`
- `investment_assets(user_id)` — basic user filter
- `investment_assets(user_id, type)` — filter by asset type
- `investment_assets(user_id) WHERE is_active = true` — partial index for active assets
- `investment_transactions(asset_id)` — join to asset
- `investment_transactions(asset_id, direction)` — filter buy/sell
- `investment_transactions(user_id)` — user filter
- `gold_prices(source, fetched_at DESC)` — latest price per source
- `bitcoin_prices(source)` — unique per source (already via UNIQUE constraint)
- `custom_gold_types(user_id)` — user filter
- `custom_asset_categories(user_id)` — user filter

### Performance rules
- History list wajib pagination / infinite scroll.
- Jangan fetch semua transaksi sepanjang masa untuk dashboard.
- Grouping history dilakukan lokal dari satu fetch source.
- Cache dictionary 24 jam.
- Cache harga investasi 12 jam (TTL-based di Hive, keys: `investment_btc_price`, `investment_gold_price`).
- Harga emas di-fetch via Edge Function `gold-price` (pg_cron daily 09:00 WIB).
- Harga bitcoin di-fetch via Edge Function `bitcoin-price` (pg_cron hourly).
- Upload attachment dilakukan async dengan UI progress state.

---

## 6. Accounting Rules Checklist untuk Database Validation

- Transfer wajib punya `destination_wallet_id`.
- Transfer tidak boleh pakai wallet yang sama sebagai source dan destination.
- `debt` dan `loan` wajib punya `with_person`.
- `debt` dan `loan` boleh punya `contact_id` (FK ke `contacts`).
- `transaction_items` minimal 1 row per transaksi.
- Total item wajib sama dengan total header transaksi.
- Settlement wajib merefer ke transaksi asal via `reference_transaction_id`.
- Settlement `debt_payment` hanya valid sebagai `type = 'expense'`.
- Settlement `loan_collection` hanya valid sebagai `type = 'income'`.
- Settlement amount tidak boleh melebihi remaining dari transaksi referensi.
- Budget hanya boleh terkait category `expense`.
- Investasi buy/sell yang melibatkan wallet harus melalui ledger transaksi (via RPC: buy→`transfer_to_asset`, sell→`income`).
- Investment asset auto-inactive ketika net_units ≤ 0 (dikelola oleh RPC, bukan trigger).
- Max 2 custom gold types per user (trigger `check_max_custom_gold_types` pada tabel `custom_gold_types`).
- Max 3 custom asset categories per user (trigger `check_max_custom_asset_categories` pada tabel `custom_asset_categories`).
- `custom_asset_categories.unit_label` adalah sumber tunggal satuan untuk aset custom.
- Gold prices append-only (INSERT, tidak UPSERT) untuk keperluan charting historis.
- Bitcoin prices UPSERT via `upsert_bitcoin_price` RPC (hanya 2 row: indodax, coingecko).
- Semua Investment RPC menggunakan `auth.uid()` internal, bukan parameter `p_user_id`.
- Edit/delete investment transaction hanya untuk `direction = 'buy'`.
- Edit/delete buy transaction divalidasi: sisa buy units setelah perubahan tidak boleh < total sell units.
- `contacts` di-upsert dari phonebook, referensi aman meskipun kontak diedit.

---

## 7. Default Seed Categories

## 7.1 Expense
- Kebutuhan Rumah Tangga
  - Belanja Dapur / Bahan Makanan
  - Perlengkapan Rumah
  - Makan di Luar / Jajan
- Kesehatan & Kebugaran
  - Olahraga / Gym
  - Suplemen & Nutrisi
  - Medis / Dokter / Obat
- Transportasi
  - Bensin
  - Tol
  - Parkir
  - Transportasi Umum
  - Ojol
  - Servis Kendaraan
- Tagihan & Kewajiban
  - Listrik & Air
  - Internet & Pulsa
  - Cicilan / Asuransi
- Teknologi & Edukasi
  - Langganan Digital
  - Kursus
  - Buku
  - Server & Hosting
- Keluarga & Sosial
  - Kebutuhan Pasangan
  - Kondangan / Donasi
  - Nongkrong / Hiburan
- Lain-lain
  - Biaya Admin / Pajak / Selisih
  - Pengeluaran Tak Terduga
  - Pengeluaran yang tidak diketahui

## 7.2 Income
- Gaji & Pendapatan Utama
  - Gaji Bulanan
  - Bonus / THR
- Pendapatan Tambahan
  - Pekerjaan Sampingan / Freelance
  - Hasil Investasi / Dividen
  - Pencairan Dana
- Lain-lain
  - Hadiah / Pemberian

## 7.3 System Categories
- Penyesuaian Saldo
- Transfer ke Aset

---

## 8. Final Database Decisions

Jika ada konflik implementasi:
- `transactions` adalah ledger utama,
- `wallets.balance` adalah hasil turunan ledger,
- `transaction_items` adalah detail authoritative untuk item breakdown,
- budget hanya untuk category expense,
- settlement tidak masuk report/budget,
- investasi yang memotong wallet harus membuat `transfer_to_asset`,
- `contacts` menyimpan referensi kontak untuk hutang/piutang, diakses via `contact_id`,
- `asset_types` menyimpan jenis aset kustom untuk investasi, diakses via `asset_type_id`,
- settlement memiliki RPC terpisah (`settle_debt_or_loan`, `update_settlement`, `delete_settlement`),
- debt/loan query memiliki RPC khusus grouped by contact.
