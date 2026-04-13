---
title: "Reports"
type: entity
tags: [reports, laporan, chart, keuangan, fitur]
sources:
  - raw/docs/redesign-ui-ux/S8_REPORTS.md
  - raw/docs/plan-refactor-report-category-breakdown-combined-chart.md
  - raw/audit-report-page.md
created: 2026-04-10
updated: 2026-04-14
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
| **Category Breakdown** | Pie chart + list linear progress dalam satu section, memakai **top 5 kategori + `Lainnya`** |
| **Trend Chart** | Chart garis tren pengeluaran/pemasukan antar periode |
| **Period Tabs** | Tab pemilih periode (`SakuSubPeriodTabs`) — mingguan, bulanan, tahunan |

---

## Aturan Penting

- **Transfer tidak masuk laporan** — transfer antar wallet bukan expense/income
- **Settlement (pelunasan hutang/piutang) tidak masuk laporan** — settlement adalah penyelesaian hutang, bukan transaksi baru
- **`transfer_to_asset` (investasi) tidak masuk laporan** sebagai expense — ini adalah perpindahan aset
- Warna chart menggunakan **semantic colors** (category-based colors)
- Net positif → **income color** (`#059669`), net negatif → **expense color** (`#DC2626`)
- Breakdown kategori utama memakai **top 5 + bucket `Lainnya`**
- Item **`Lainnya`** di list kategori bersifat **expand/collapse**, bukan navigasi

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
| Category breakdown | Pie chart di atas, linear progress list di bawah, tanpa mode selector |

---

## Smart Insight System

`_ReportInsightSection` menampilkan **2–4 insight cards** yang dihitung otomatis dari data periode saat ini. Setiap card punya ikon, warna sesuai severity, dan pesan yang actionable.

### 4 Layer Insight

| # | Insight | Data Source | Threshold |
|---|---------|-------------|-----------|
| 1 | **Rasio Pengeluaran/Pemasukan** | `summary.expenseToIncomeRatio` | ≤50% 🟢, 50-75% 🟡, 75-100% 🟠, >100% 🔴 |
| 2 | **Tren Perubahan** | `expenseChange` provider + `previousSummary` | 5 tier: turun besar/kecil, stabil, naik kecil/besar |
| 3 | **Kategori Dominan** | `categoryBreakdown[0]` | Muncul jika 1 kategori > 40% total expense |
| 4 | **Hari Terboros** | `dailyTrend` (max expense) | Muncul jika peak day > 25% total expense |

### Visual Design

- Setiap card: left border berwarna sesuai severity + `FaIcon`
- Warna: `colors.income` (🟢), `colors.warning` (🟡🟠), `colors.expense` (🔴), `colors.textSecondary` (netral)
- Ikon: `FontAwesomeIcons` — shieldHalved, triangleExclamation, arrowTrendUp/Down, chartPie, calendarDay
- Semua teks dilokalisasi via `.arb` keys (`reportInsightRatio*`, `reportInsightTrend*`, `reportInsightCategory*`, `reportInsightPeakDay`)

### Teori Keuangan

Berdasarkan **Aturan 50/30/20** (Elizabeth Warren):
- 50% untuk kebutuhan dasar
- 30% untuk keinginan
- 20% untuk tabungan/investasi

Jika rasio expense/income > 80%, financial health rendah. Sistem insight memberi peringatan bertingkat agar user aware sebelum terlambat.

---

## Trend Chart (Tren Harian)

`ReportTrendChart` — bar chart ganda (Syncfusion `SfCartesianChart`) untuk visualisasi income vs expense per hari.

### Tooltip

Tooltip menampilkan **kedua series** (Pemasukan + Pengeluaran) dengan dot warna, bukan hanya series yang di-tap. String dilokalisasi via parameter `incomeLabel` / `expenseLabel` pada `buildChart()`.

### Static Builder

`buildChart()` adalah method **static** — dipakai baik inline maupun untuk fullscreen dialog. Parameter:
- `data`, `colors`, `isDark` — wajib
- `incomeLabel`, `expenseLabel` — opsional, default "Pemasukan"/"Pengeluaran"

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
- [[wiki/sources/plan-refactor-report-category-breakdown|Plan: Refactor Breakdown Kategori Reports]]
