---
title: "Investasi"
type: entity
tags: [investasi, portfolio, gold, bitcoin, custom-asset, edge-function]
sources: [raw/docs/prd/15_INVESTASI.md, raw/docs/02_DATABASE.md]
created: 2026-04-10
updated: 2026-04-10
---

# Investasi

## Deskripsi

Fitur investasi memungkinkan pengguna melacak portfolio aset mereka dalam tiga jenis: **gold** (emas), **bitcoin**, dan **custom asset**. Setiap aset memiliki unit, harga beli, dan valuasi terkini. Fitur ini terintegrasi dengan Edge Function untuk mendapatkan harga pasar secara otomatis, serta mendukung pencatatan transaksi beli dan jual.

---

## Fitur & Aturan Utama

### Jenis Aset

| Jenis | Sub-type | Harga | Keterangan |
|-------|----------|-------|------------|
| **Gold — Antam** | Antam | Live price (otomatis) | Harga dari API, diperbarui harian |
| **Gold — Perhiasan** | Perhiasan | Manual only | Pengguna input harga sendiri |
| **Gold — Custom** | Custom (max 2) | Manual only | Sub-type kustom, maksimal 2 per user |
| **Bitcoin** | — | Live price (otomatis) | Harga dari API, diperbarui per jam |
| **Custom Asset** | — | Manual only | Kategori bebas, max 3 per user, dengan `unit_label` |

### Database Schema

Fitur ini menggunakan **6 tabel** database:

1. `custom_gold_types` — Sub-type emas kustom
2. `custom_asset_categories` — Kategori aset kustom (max 3 per user, dengan `unit_label`)
3. `investment_assets` — Data aset investasi pengguna
4. `investment_transactions` — Riwayat transaksi beli/jual
5. `gold_prices` — Harga emas historis
6. `bitcoin_prices` — Harga bitcoin historis

### Backend Functions

- **7 RPC functions** untuk operasi CRUD dan kalkulasi portfolio
- **2 Edge Functions**:
  - `gold-price` — Berjalan harian pukul **09:00 WIB**
  - `bitcoin-price` — Berjalan **setiap jam** (hourly)

### RPC Functions (Detail)

| # | RPC | Parameter Utama | Keterangan |
|---|-----|----------------|------------|
| 1 | `get_investment_dashboard()` | — (uses auth.uid()) | Return array of asset objects with aggregated fields |
| 2 | `create_investment_asset(...)` | p_type, p_name, p_units, p_price_per_unit, p_wallet_id?, ... | Creates asset + first buy tx, optional wallet deduction via `transfer_to_asset` |
| 3 | `topup_investment(...)` | p_asset_id, p_units, p_price_per_unit, ... | Insert buy tx, optional wallet deduction, reactivates inactive asset |
| 4 | `sell_investment(...)` | p_asset_id, p_units, p_price_per_unit, ... | Insert sell tx, optional wallet credit via `income`, auto-deactivate if remaining=0 |
| 5 | `edit_investment_transaction(...)` | p_transaction_id, p_units, ... | Edit buy tx only, reverts old wallet tx + creates new if needed |
| 6 | `delete_investment_transaction(...)` | p_transaction_id | Delete buy tx only, validates units ≥ sell total |
| 7 | `delete_investment_asset(...)` | p_asset_id, p_revert_wallet? | CASCADE delete all tx, optionally revert wallet transactions |
| 8 | `upsert_bitcoin_price(...)` | p_source, p_price_idr | INSERT ON CONFLICT UPDATE |

> **Catatan keamanan:** Semua Investment RPC menggunakan `auth.uid()` secara internal, BUKAN menerima `p_user_id`. User hanya bisa mengakses data miliknya.

> **Aturan edit/delete:** Hanya transaksi `direction = 'buy'` yang bisa di-edit/delete. Validasi: sisa buy units setelah perubahan ≥ total sell units.

### Database Schema (Ringkas)

#### Tabel `investment_assets`

| Kolom Utama | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK | owner |
| type | text not null | `gold`, `bitcoin`, `custom` |
| name | text not null | nama aset |
| is_active | boolean default true | false jika semua unit terjual |
| custom_category_id | uuid nullable FK | untuk custom asset |
| gold_sub_type | text nullable | `antam`, `perhiasan`, atau custom |

#### Tabel `investment_transactions`

| Kolom Utama | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| asset_id | uuid FK | parent asset |
| direction | text not null | `buy` atau `sell` |
| units | numeric not null | jumlah unit, CHECK > 0 |
| price_per_unit | numeric not null | harga per unit, CHECK > 0 |
| total_amount | numeric not null | units × price_per_unit |
| wallet_id | uuid nullable FK | wallet terkait (jika ada) |
| linked_transaction_id | uuid nullable FK | transaksi wallet terkait |

---

## Cara Kerja

### Smart Form (3 Mode)

Form investasi mendukung tiga mode operasi:

1. **Create** — Membuat aset baru (pilih jenis, isi unit & harga beli)
2. **Top Up** — Menambah unit ke aset yang sudah ada
3. **Edit** — Mengubah metadata aset yang sudah ada

### Sell Sheet

- Validasi **max unit** — tidak bisa jual melebihi unit yang dimiliki
- **Credit wallet toggle** — opsi untuk mengkreditkan hasil jual ke wallet
- **Harga pre-fill** dari `InvestmentPricesController` untuk aset dengan live price

### Settings Sheet

- Edit metadata aset (nama, sub-type, dll.)
- **Delete** aset dengan opsi checkbox **revert wallet** — mengembalikan saldo wallet jika dicentang

### Price Service

- `InvestmentPricesController` — controller terpusat (centralized) untuk semua harga aset
- Method utama: `getEffectivePrice(asset)` — mengembalikan harga efektif berdasarkan jenis aset (live price jika tersedia, atau harga manual terakhir)

### Halaman Inactive

- Aset berstatus **inactive** ketika seluruh unit telah dijual (unit = 0)
- Aset inactive **bisa di-reactivate** melalui aksi **top up**
- Ditampilkan di halaman terpisah dari aset aktif

---

## Halaman Terkait

- [[wiki/entities/wallet|Wallet]]
- [[wiki/entities/history|History]]
- [[wiki/entities/settings|Settings]]
- [[wiki/concepts/aturan-keuangan|Aturan Keuangan]]
- [[wiki/entities/database-schema|Database Schema]]
- [[wiki/sources/prd-sakurapi-v7|PRD SakuRapi v7.0]]
- [[wiki/concepts/design-system|Design System]]
