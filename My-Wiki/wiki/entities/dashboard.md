---
title: "Dashboard"
type: entity
tags: [dashboard, fitur, ui, chart, hive]
sources: [raw/docs/prd/07_DASHBOARD.md]
created: 2026-04-10
updated: 2026-04-10
---

# Dashboard

## Deskripsi

Dashboard adalah halaman utama SakuRapi yang menampilkan ringkasan keuangan user secara menyeluruh. Dibangun menggunakan **CustomScrollView** dengan **RefreshIndicator** untuk pull-to-refresh. Dashboard menggunakan arsitektur split controller untuk memisahkan concern data umum dan data chart.

## Layout & Komponen

Dashboard tersusun dari komponen-komponen berikut (dari atas ke bawah):

| # | Komponen | Deskripsi |
|---|----------|-----------|
| 1 | **Greeting** | Sapaan berdasarkan waktu hari |
| 2 | **BalanceCard** | Total saldo semua wallet (dengan toggle hide untuk privasi) |
| 3 | **QuickActions** | 4 tombol aksi cepat untuk input transaksi |
| 4 | **WalletSection** | Daftar wallet dalam horizontal scroll |
| 5 | **PeriodSummary** | Ringkasan pemasukan & pengeluaran periode berjalan |
| 6 | **ChartCarousel** | 2 halaman: Expense Comparison Bar Chart + Trend Line Chart |
| 7 | **RecentTransactions** | 5 transaksi terbaru |

### BalanceCard

- Menampilkan total saldo dari semua wallet yang **tidak di-exclude** (`exclude_from_total = false`).
- Toggle hide/show untuk menyembunyikan angka saldo (privasi di tempat umum).

### ChartCarousel

Carousel dengan 2 halaman:

1. **Expense Comparison Bar Chart** — Perbandingan pengeluaran antar periode.
2. **Trend Line Chart** — Tren keuangan dari waktu ke waktu.

> **Detail lengkap**: Lihat [[wiki/entities/dashboard-charts|Dashboard Charts]] untuk breakdown menyeluruh semua chart widget, logika burn rate, perhitungan periode, dan alur data.

### PeriodSummary

- Menampilkan total income dan expense untuk periode berjalan.
- **Settlement dikecualikan** dari perhitungan period summary — pelunasan hutang/piutang tidak dihitung sebagai expense/income biasa.

## Arsitektur Controller

Dashboard menggunakan **split controller pattern**:

| Controller | Tanggung Jawab |
|------------|----------------|
| **DashboardController** | Controller induk — mengelola data greeting, balance, wallet list, recent transactions, period summary |
| **DashboardChartController** | Controller khusus chart — mengelola data dan state untuk ChartCarousel |

Pemisahan ini mencegah rebuild seluruh dashboard ketika hanya data chart yang berubah, dan sebaliknya.

## Data & Cache

- **Recent transactions** dan **period summary** di-cache ke **Hive** untuk akses offline dan startup cepat.
- Saat pull-to-refresh, data di-fetch ulang dari server dan cache diperbarui.
- Data wallet dimuat dari cache Hive [[wiki/entities/wallet|Wallet]].

## Cara Kerja

```
┌─────────────────────────────────────┐
│  CustomScrollView + RefreshIndicator │
│                                     │
│  ┌─ Greeting ─────────────────────┐ │
│  ├─ BalanceCard (toggle hide) ────┤ │
│  ├─ QuickActions (4 tombol) ──────┤ │
│  ├─ WalletSection (h-scroll) ────┤ │
│  ├─ PeriodSummary ────────────────┤ │
│  ├─ ChartCarousel (2 pages) ─────┤ │
│  └─ RecentTransactions (5) ──────┘ │
└─────────────────────────────────────┘
         │                    │
         ▼                    ▼
  DashboardController   DashboardChartController
         │                    │
         ▼                    ▼
     Hive Cache          Supabase Data
```

1. Saat membuka app, Dashboard memuat data dari cache Hive (instant).
2. Secara paralel, fetch data terbaru dari Supabase.
3. DashboardController memperbarui semua section kecuali chart.
4. DashboardChartController memperbarui ChartCarousel secara independen.
5. Pull-to-refresh memicu refresh kedua controller.

## Halaman Terkait

- [[wiki/entities/sakurapi|SakuRapi]]
- [[wiki/entities/wallet|Wallet]]
- [[wiki/entities/transaksi|Transaksi]]
- [[wiki/entities/hutang-piutang|Hutang/Piutang]]
- [[wiki/entities/budgeting|Budgeting]]
- [[wiki/concepts/aturan-keuangan|Aturan Keuangan]]
- [[wiki/sources/prd-sakurapi-v7|PRD SakuRapi v7.0]]
- [[wiki/concepts/design-system|Design System]]
- [[wiki/sources/redesign-ui-ux|Redesign UI/UX (Sumber)]]
- [[wiki/entities/reports|Reports]]
