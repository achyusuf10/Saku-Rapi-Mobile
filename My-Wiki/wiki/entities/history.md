---
title: "History"
type: entity
tags: [history, transaksi, filter, pagination, hive-cache]
sources: [raw/docs/prd/12_HISTORY.md]
created: 2026-04-10
updated: 2026-04-10
---

# History

## Deskripsi

Halaman history menampilkan riwayat transaksi pengguna dengan berbagai opsi period, filter, dan pengelompokan. Mendukung infinite scroll dengan pagination dan caching halaman pertama ke Hive untuk performa offline.

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
| **Wallet** | Server refetch | Memfilter berdasarkan wallet — trigger request ulang ke server |
| **Type** | Lokal | Filter tipe transaksi (income/expense/transfer) — difilter di client |
| **Grouping** | Lokal | Pengelompokan tampilan: **By Date** atau **By Category** — diproses di client |

Perubahan filter **Wallet** memicu fetch ulang dari server karena data di-paginate di sisi server. Filter **Type** dan **Grouping** hanya mengubah tampilan data yang sudah ada di memori.

### Pagination

- **Page size**: 30 transaksi per halaman
- **Infinite scroll**: Menggunakan `VisibilityDetector` — ketika item terakhir terlihat, otomatis fetch halaman berikutnya
- **Cache**: Halaman pertama (page 1) di-cache ke **Hive** untuk ditampilkan saat offline atau saat loading awal

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
