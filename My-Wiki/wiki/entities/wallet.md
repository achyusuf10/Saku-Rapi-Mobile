---
title: "Wallet"
type: entity
tags: [wallet, fitur, saldo, hive]
sources: [raw/docs/prd/08_WALLETS.md, raw/docs/prd/04_ATURAN_KEUANGAN.md, raw/docs/02_DATABASE.md]
created: 2026-04-10
updated: 2026-04-10
---

# Wallet

## Deskripsi

Wallet (dompet) adalah entitas utama untuk menyimpan dan mengelompokkan uang di SakuRapi. User dapat memiliki **banyak wallet** (multi-wallet) — masing-masing dengan nama, ikon, warna, dan saldo sendiri. Saldo wallet bersifat **read-only di sisi client**; perubahan saldo hanya terjadi melalui **DB trigger `update_wallet_balance`** di server, menjamin konsistensi data sesuai prinsip Consistent Money Model.

## Fitur & Aturan Utama

### CRUD Wallet

- **Create**: Melalui `WalletFormSheet` — user mengisi nama, initial balance, ikon, warna, dan toggle `exclude_from_total`.
- **Edit**: Melalui `WalletFormSheet` yang sama, **tanpa field initial balance** (saldo hanya berubah via transaksi atau adjustment).
- **Delete**: **Diblokir** jika wallet masih memiliki transaksi terkait. User harus menghapus/memindahkan transaksi terlebih dahulu.

### Aturan Nama

- Nama wallet **unik per user** (case-insensitive). Tidak boleh ada dua wallet dengan nama yang sama meskipun berbeda huruf besar/kecil.

### Saldo & Adjustment

- Saldo wallet **tidak bisa diedit langsung**. Saldo hanya berubah melalui:
  1. Transaksi baru (expense, income, transfer, dll.)
  2. **Wallet Adjustment** — koreksi saldo manual melalui `WalletAdjustSheet`.
- Adjustment menggunakan RPC **`create_adjustment_transaction`** yang membuat transaksi bertipe `adjustment`.
- Adjustment menciptakan audit trail yang jelas — tidak ada perubahan saldo tanpa transaksi.

### Exclude from Total

- Flag `exclude_from_total` — jika diaktifkan, saldo wallet **tidak dihitung** dalam total saldo yang ditampilkan di [[wiki/entities/dashboard|Dashboard]].
- Berguna untuk wallet "tabungan terpisah" atau wallet khusus yang tidak ingin dicampur ke gambaran keuangan harian.

### Ordering

- Wallet diurutkan berdasarkan **`sort_order` ASC**, lalu **`created_at` ASC** sebagai tiebreaker.

### Cache

- Data wallet di-cache ke **Hive** untuk akses offline dan performa UI yang cepat.

## Database Schema (`wallets`)

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK | owner |
| name | text not null | nama dompet |
| icon | text not null | fontawesome icon name |
| color | text not null | hex color |
| balance | numeric not null default 0 | current balance (read-only, via trigger) |
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

**RPC Terkait:**
- `create_adjustment_transaction(p_wallet_id, p_target_balance, p_date?, p_note?)` → jsonb

## Cara Kerja

```
┌─────────────────────┐
│   Client (Flutter)   │
│   READ-ONLY saldo    │
└──────────┬──────────┘
           │ RPC / Insert
           ▼
┌─────────────────────┐
│   Supabase (Server)  │
│   DB Trigger:        │
│   update_wallet_     │
│   balance            │
└──────────┬──────────┘
           │ Saldo terupdate
           ▼
┌─────────────────────┐
│   Client sync &      │
│   cache ke Hive      │
└─────────────────────┘
```

1. User melakukan transaksi atau adjustment.
2. Data dikirim ke Supabase via RPC (atomik).
3. DB trigger `update_wallet_balance` menghitung ulang saldo.
4. Client mengambil data terbaru dan menyimpan ke cache Hive.

## Halaman Terkait

- [[wiki/entities/sakurapi|SakuRapi]]
- [[wiki/entities/transaksi|Transaksi]]
- [[wiki/entities/dashboard|Dashboard]]
- [[wiki/entities/budgeting|Budgeting]]
- [[wiki/concepts/aturan-keuangan|Aturan Keuangan]]
- [[wiki/entities/database-schema|Database Schema]]
- [[wiki/sources/prd-sakurapi-v7|PRD SakuRapi v7.0]]
- [[wiki/concepts/design-system|Design System]]
- [[wiki/sources/redesign-ui-ux|Redesign UI/UX (Sumber)]]



