---
title: "History"
type: entity
tags: [history, transaksi, filter, pagination, hive-cache, search, rpc]
sources: [raw/docs/prd/12_HISTORY.md, raw/docs/plan-history-search-filter-and-category-loadmore.md]
created: 2026-04-10
updated: 2026-04-13
---

# History

## Deskripsi

Halaman history menampilkan riwayat transaksi pengguna dengan berbagai opsi period, filter, dan pengelompokan. Mendukung infinite scroll dengan pagination dan caching halaman pertama ke Hive untuk performa offline.

Data fetching menggunakan RPC `get_history_transactions` (sejak April 2026) untuk mendukung server-side search dan category-level pagination.

---

## Fitur & Aturan Utama

### Period Types

| # | Period | Keterangan |
|---|--------|------------|
| 1 | **Daily** | Per hari |
| 2 | **Weekly** | Per minggu |
| 3 | **Monthly** *(default)* | Per bulan |
| 4 | **Quarterly** | Per kuartal |
| 5 | **Yearly** | Per tahun |
| 6 | **Custom** | Rentang tanggal kustom |

- Setiap period memiliki **sub-period tabs** yang di-sync dengan **swipeable PageView**
- Contoh: Monthly → tab untuk setiap bulan, bisa di-swipe kiri/kanan

### Summary Card

- Menampilkan **total income** dan **total expense** (tanpa settlement/transfer)
- Jumlah transaksi dalam period tersebut
- Format angka **compact** (misal: 1,5jt)

---

## Cara Kerja

### Filter Sheet

| Filter | Tipe | Keterangan |
|--------|------|------------|
| **Search** | Server refetch | Cari berdasarkan `note` OR `category name` — ILIKE server-side via RPC |
| **Wallet** | Server refetch | Memfilter berdasarkan wallet — trigger request ulang ke server |
| **Type** | Lokal | Filter tipe transaksi (income/expense/transfer) — difilter di client, per PRD §7.8 |
| **Grouping** | Server refetch | Pengelompokan: **By Date** atau **By Category** — mengubah mode RPC, trigger refetch |

> Filter badge di pojok kanan muncul jika `typeFilter != null || searchKeyword != null`.

#### Search UX

- `SakuTextField` dengan prefix icon search dan suffix clear button (reaktif via `ValueListenableBuilder`)
- Suffix clear button hanya muncul saat ada teks
- Hasil pencarian mencakup transaksi yang `note` OR kategori manapun dari `transaction_items`-nya mengandung keyword

### Pagination

#### Mode byDate (default)

- **Page size**: 30 transaksi per page
- `state.offset` = jumlah transaksi yang sudah diambil
- `has_more` dari RPC (jumlah transaksi tersisa > 0)

#### Mode byCategory

- **Page size**: 5 kategori per page
- `state.offset` = jumlah kategori yang sudah diambil
- Setiap "page" mengembalikan SEMUA transaksi dari 5 kategori tersebut
- Urutan kategori: berdasarkan `MAX(transaction.date) DESC` — kategori dengan transaksi terbaru duluan
- Transfer/Debt/Loan tanpa kategori explicit: dikelompokkan sebagai `"transfer"` / `"debt"` / `"loan"`

> Mode switch selalu reset offset ke 0 — semantik `state.offset` berbeda per mode tapi aman karena reset.

- **Infinite scroll**: `VisibilityDetector` — ketika item terakhir terlihat, otomatis fetch berikutnya
- **Cache**: Halaman pertama di-cache ke **Hive** untuk performa offline

---

## Halaman Terkait

- [[wiki/entities/wallet|Wallet]]
- [[wiki/entities/investasi|Investasi]]
- [[wiki/entities/settings|Settings]]
- [[wiki/concepts/aturan-keuangan|Aturan Keuangan]]
- [[wiki/sources/prd-sakurapi-v7|PRD SakuRapi v7.0]]
- [[wiki/concepts/design-system|Design System]]
- [[wiki/sources/redesign-ui-ux|Redesign UI/UX (Sumber)]]
- [[wiki/entities/reports|Reports]]
