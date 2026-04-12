---
title: "Hutang/Piutang"
type: entity
tags: [hutang, piutang, debt, loan, settlement, fitur]
sources: [raw/docs/prd/11_HUTANG_PIUTANG.md, raw/docs/prd/04_ATURAN_KEUANGAN.md, raw/docs/02_DATABASE.md]
created: 2026-04-10
updated: 2026-04-10
---

# Hutang/Piutang

## Deskripsi

Hutang/Piutang adalah fitur manajemen pinjaman di SakuRapi. Fitur ini memungkinkan user mencatat uang yang dipinjam (hutang) maupun yang dipinjamkan (piutang) kepada orang lain, serta melacak pelunasannya. Data dikelompokkan per kontak dan ditampilkan dengan status badge untuk kemudahan tracking.

## Fitur & Aturan Utama

### Struktur 2 Tab

| Tab | Label | Deskripsi |
|-----|-------|-----------|
| 1 | **Untuk Dibayar** | Hutang saya — uang yang saya pinjam dari orang lain |
| 2 | **Untuk Diterima** | Piutang saya — uang yang saya pinjamkan ke orang lain |

### Pengelompokan per Kontak

- Data diambil menggunakan RPC **`get_debt_loan_summary`** yang mengembalikan ringkasan hutang/piutang **dikelompokkan per kontak** (contact/with_person).
- Setiap kontak menampilkan total outstanding dan jumlah transaksi.

### Section Unpaid & Paid

Masing-masing tab memiliki 2 section:

1. **Unpaid** — Hutang/piutang yang masih memiliki sisa outstanding.
2. **Paid** — Hutang/piutang yang sudah lunas sepenuhnya.

### Halaman Per-Person

Ketika user mengetuk sebuah kontak, masuk ke halaman detail per-person:

- **Summary Card** — Total hutang/piutang, total sudah dibayar, sisa outstanding.
- **Daftar Transaksi** — Dikelompokkan per tanggal (grouped by date).
- **Status Badge** — Menampilkan status tiap transaksi (unpaid, partial, paid).

### Settlement Sheet

- Untuk mencatat pelunasan (sebagian maupun penuh).
- Mode: **Create** (pelunasan baru) dan **Edit** (ubah pelunasan yang ada).
- Validasi: jumlah pelunasan **≤ sisa remaining** (tidak boleh melebihi outstanding).
- Pemilihan wallet menggunakan komponen **ChoiceChips**.

### Aturan Penting

- Field `with_person` **wajib** untuk semua transaksi hutang/piutang.
- **Settlement dikecualikan** dari laporan keuangan dan [[wiki/entities/budgeting|Budgeting]] — pelunasan tidak dihitung sebagai expense/income reguler.

## RPC Functions

Hutang/Piutang menggunakan **7 RPC functions** terkait:

| # | RPC Function | Kegunaan |
|---|-------------|----------|
| 1 | `settle_debt_or_loan(...)` | Buat pelunasan (sebagian/penuh) |
| 2 | `update_settlement(...)` | Update pelunasan yang sudah ada |
| 3 | `delete_settlement(...)` | Hapus pelunasan |
| 4 | `get_debt_loan_summary(p_type, p_wallet_id?)` | Ringkasan hutang/piutang per kontak |
| 5 | `get_debt_loan_transactions_by_person(p_with_person, p_type, p_wallet_id?)` | Detail transaksi per orang |
| 6 | `get_all_unpaid_debt_loan(p_type)` | Semua hutang/piutang yang belum lunas |
| 7 | `get_settlement_history(p_reference_transaction_id)` | Riwayat pelunasan per transaksi |

> Transaksi hutang/piutang sendiri dibuat melalui `create_transaction_with_items` dengan `type = 'debt'` atau `'loan'`.

## Cara Kerja

```
┌──────────────────────────────────────┐
│  Halaman Hutang/Piutang              │
│  ┌───────────────┬──────────────────┐│
│  │ Untuk Dibayar │ Untuk Diterima   ││
│  └───────┬───────┴────────┬─────────┘│
│          │                │          │
│  ┌───────▼──────┐ ┌──────▼────────┐ │
│  │ Section:     │ │ Section:      │ │
│  │ • Unpaid     │ │ • Unpaid      │ │
│  │ • Paid       │ │ • Paid        │ │
│  └───────┬──────┘ └──────┬────────┘ │
│          │                │          │
│          ▼                ▼          │
│  ┌──────────────────────────────┐   │
│  │ Per-Person Detail Page       │   │
│  │ • Summary Card               │   │
│  │ • Transaksi grouped by date  │   │
│  │ • Status Badge per item      │   │
│  │ • Settlement Sheet           │   │
│  └──────────────────────────────┘   │
└──────────────────────────────────────┘
```

1. User membuka halaman Hutang/Piutang → data dimuat via `get_debt_loan_summary`.
2. Pilih tab (Untuk Dibayar / Untuk Diterima).
3. Daftar kontak ditampilkan dalam section Unpaid dan Paid.
4. Ketuk kontak → masuk halaman per-person dengan detail lengkap.
5. Untuk melunasi → buka Settlement Sheet, isi jumlah dan pilih wallet.
6. Submit via RPC — settlement tercatat sebagai transaksi terpisah.

## Halaman Terkait

- [[wiki/entities/sakurapi|SakuRapi]]
- [[wiki/entities/transaksi|Transaksi]]
- [[wiki/entities/wallet|Wallet]]
- [[wiki/entities/dashboard|Dashboard]]
- [[wiki/entities/budgeting|Budgeting]]
- [[wiki/concepts/aturan-keuangan|Aturan Keuangan]]
- [[wiki/entities/database-schema|Database Schema]]
- [[wiki/entities/contacts|Contacts]]
- [[wiki/sources/prd-sakurapi-v7|PRD SakuRapi v7.0]]
- [[wiki/concepts/design-system|Design System]]
- [[wiki/sources/redesign-ui-ux|Redesign UI/UX (Sumber)]]
