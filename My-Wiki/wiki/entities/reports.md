---
title: "Reports"
type: entity
tags: [reports, laporan, chart, keuangan, fitur]
sources:
  - raw/docs/redesign-ui-ux/S8_REPORTS.md
created: 2026-04-10
updated: 2026-04-10
---

# Reports

Fitur laporan keuangan di SakuRapi — menampilkan ringkasan pemasukan, pengeluaran, dan tren berdasarkan periode. Laporan menggunakan chart dan tabel untuk visualisasi data.

---

## Halaman

| File | Deskripsi |
|------|-----------|
| `report_page.dart` | Halaman utama laporan — menampilkan summary, chart, dan breakdown per kategori |
| `report_category_transactions_page.dart` | Detail transaksi per kategori — drill-down dari chart/tabel |

---

## Komponen UI

| Komponen | Deskripsi |
|----------|-----------|
| **Report Summary Card** | Ringkasan total income, expense, dan net (saldo bersih) per periode |
| **Category Pie Chart** | Chart pie per kategori pengeluaran/pemasukan |
| **Category Bar Chart** | Chart bar per kategori — perbandingan visual antar kategori |
| **Trend Chart** | Chart garis tren pengeluaran/pemasukan antar periode |
| **Period Tabs** | Tab pemilih periode (`SakuSubPeriodTabs`) — mingguan, bulanan, tahunan |

---

## Aturan Penting

- **Transfer tidak masuk laporan** — transfer antar wallet bukan expense/income
- **Settlement (pelunasan hutang/piutang) tidak masuk laporan** — settlement adalah penyelesaian hutang, bukan transaksi baru
- **`transfer_to_asset` (investasi) tidak masuk laporan** sebagai expense — ini adalah perpindahan aset
- Warna chart menggunakan **semantic colors** (category-based colors)
- Net positif → **income color** (`#059669`), net negatif → **expense color** (`#DC2626`)

---

## Design (Post-Redesign)

| Elemen | Spesifikasi |
|--------|-------------|
| Summary card | Flat `SakuCard` — tanpa gradient |
| Chart colors | Semantic (category-based) — bukan hardcoded |
| Chart background | Neutral `surface` color |
| Axis labels | `textSecondary` color |
| Grid lines | `border` color dengan 30% alpha |
| Tooltip | Clean `surface` background + border |

---

## Halaman Terkait

- [[wiki/entities/dashboard|Dashboard]]
- [[wiki/entities/transaksi|Transaksi]]
- [[wiki/entities/budgeting|Budgeting]]
- [[wiki/entities/history|History]]
- [[wiki/concepts/aturan-keuangan|Aturan Keuangan]]
- [[wiki/concepts/matrix-transaksi|Matrix Transaksi]]
- [[wiki/concepts/design-system|Design System — Financial Trust]]
- [[wiki/sources/redesign-ui-ux|Redesign UI/UX (Sumber)]]
