# SakuRapi — Database Final v6.1
## Schema, Constraint, Trigger, RPC, dan Indexing

> Dokumen ini adalah sumber kebenaran untuk struktur database Supabase/Postgres.
> Untuk requirement produk dan flow, lihat `01_PRD.md`.
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
| due_date | timestamptz nullable | |
| is_multi_item | boolean not null default false | |
| reference_transaction_id | uuid nullable FK self | untuk settlement |
| settlement_kind | text nullable | `debt_payment`, `loan_collection` |
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
| notification_sent_80 | boolean not null default false | |
| notification_sent_100 | boolean not null default false | |
| created_at | timestamptz | |
| updated_at | timestamptz | |

### Constraint
- hanya boleh menunjuk category `type = 'expense'`
- `end_date >= start_date`
- tidak boleh ada duplikasi budget aktif dengan scope identik tanpa keputusan merge.

## 2.7 `investments`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK | owner |
| type | text not null | `gold`, `crypto`, `custom` |
| name | text not null | nama aset |
| symbol | text nullable | ticker/symbol |
| amount | numeric not null | jumlah unit |
| avg_buy_price | numeric not null | harga beli rata-rata |
| custom_current_price | numeric nullable | fallback manual |
| linked_wallet_id | uuid nullable FK | wallet referensi |
| notes | text nullable | |
| created_at | timestamptz | |
| updated_at | timestamptz | |

## 2.8 `parsing_dictionaries`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| keyword | text not null | lowercase keyword |
| category_id | uuid FK | target category |
| created_at | timestamptz | |
| updated_at | timestamptz | |

## 2.9 `notification_settings`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK | owner |
| reminder_enabled | boolean not null default false | daily reminder |
| reminder_time | time nullable | |
| budget_alert_enabled | boolean not null default true | |
| debt_reminder_enabled | boolean not null default true | |
| debt_reminder_days_before | integer not null default 3 | |
| created_at | timestamptz | |
| updated_at | timestamptz | |

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
| `set_updated_at()` | before update on all mutable tables | update timestamp |
| `auto_renew_budgets()` | pg_cron daily | clone recurring budgets |

## 3.2 RPC yang disarankan
Agar write atomik dan Copilot tidak menyebar logika:
- `create_transaction_with_items(...)`
- `update_transaction_with_items(...)`
- `create_adjustment_transaction(...)`
- `create_investment_with_optional_wallet_deduction(...)`
- `settle_debt_or_loan(...)`

### Rule
Flutter boleh memanggil RPC ini melalui RemoteDataSource.  
Jangan membangun multi-step write yang rentan race condition langsung dari client.

---

## 4. RLS Policy

Semua tabel business wajib mengaktifkan RLS.

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
- `transaction_items(transaction_id, sort_order)`
- `budgets(user_id, start_date, end_date)`
- `categories(user_id, type, parent_id)`
- `wallets(user_id, sort_order)`

### Performance rules
- History list wajib pagination / infinite scroll.
- Jangan fetch semua transaksi sepanjang masa untuk dashboard.
- Grouping history dilakukan lokal dari satu fetch source.
- Cache dictionary 24 jam.
- Cache harga investasi 1 jam.
- Upload attachment dilakukan async dengan UI progress state.

---

## 6. Accounting Rules Checklist untuk Database Validation

- Transfer wajib punya `destination_wallet_id`.
- Transfer tidak boleh pakai wallet yang sama sebagai source dan destination.
- `debt` dan `loan` wajib punya `with_person`.
- `transaction_items` minimal 1 row per transaksi.
- Total item wajib sama dengan total header transaksi.
- Settlement wajib merefer ke transaksi asal.
- Settlement `debt_payment` hanya valid sebagai `expense`.
- Settlement `loan_collection` hanya valid sebagai `income`.
- Budget hanya boleh terkait category `expense`.
- Investasi tidak boleh memotong saldo wallet langsung tanpa ledger transaksi.

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
  - Bensin / Tol / Parkir
  - Transportasi Umum / Ojol
  - Servis Kendaraan
- Tagihan & Kewajiban
  - Listrik & Air
  - Internet & Pulsa
  - Cicilan / Asuransi
- Teknologi & Edukasi
  - Langganan Digital
  - Kursus / Buku
  - Server & Hosting
- Keluarga & Sosial
  - Kebutuhan Pasangan
  - Kondangan / Donasi
  - Nongkrong / Hiburan
- Lain-lain
  - Biaya Admin / Pajak / Selisih
  - Pengeluaran Tak Terduga

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
- investasi yang memotong wallet harus membuat `transfer_to_asset`.
