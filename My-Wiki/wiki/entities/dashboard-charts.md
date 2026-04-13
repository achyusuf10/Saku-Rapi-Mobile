---
title: "Dashboard Charts — Breakdown Lengkap"
type: entity
tags: [dashboard, chart, trend, comparison, burn-rate, insight, carousel]
sources:
  - lib/features/dashboard/view/widgets/dashboard_chart_carousel.dart
  - lib/features/dashboard/view/widgets/dashboard_comparison_chart.dart
  - lib/features/dashboard/view/widgets/dashboard_trend_report_chart.dart
  - lib/features/dashboard/view/widgets/dashboard_period_summary.dart
  - lib/features/dashboard/controllers/dashboard_chart_controller.dart
  - lib/features/dashboard/datasource/dashboard_remote_data_source.dart
  - lib/features/dashboard/repositories/dashboard_repository.dart
created: 2026-04-14
updated: 2026-04-14
---

# Dashboard Charts — Breakdown Lengkap

> Halaman ini menjelaskan **semua** yang ditampilkan di bagian chart & ringkasan periode dashboard SakuRapi: apa yang dilihat user, dari mana datanya, bagaimana dihitung, dan apa logika di balik setiap keputusan desain.

---

## Daftar Isi

1. [Gambaran Umum](#gambaran-umum)
2. [Alur Data: Dari Supabase ke Layar](#alur-data)
3. [Period Ranges — Bagaimana Rentang Waktu Dihitung](#period-ranges)
4. [DashboardPeriodSummary — Ringkasan Keuangan Periode](#period-summary)
5. [DashboardChartCarousel — Wadah 2 Chart](#chart-carousel)
6. [Halaman 1: DashboardComparisonChart — Laporan Pengeluaran](#comparison-chart)
7. [Halaman 2: DashboardTrendReportChart — Laporan Tren](#trend-report-chart)
8. [Smart Insight — Logika Burn Rate](#smart-insight)
9. [Diagram Arsitektur](#diagram-arsitektur)
10. [Catatan Penting & Gotchas](#catatan-penting)

---

<a id="gambaran-umum"></a>
## 1. Gambaran Umum

Di halaman Home (Dashboard), ada 2 komponen utama yang berkaitan dengan chart:

| Komponen | Widget | Fungsi |
|----------|--------|--------|
| **Period Summary** | `DashboardPeriodSummary` | Menampilkan angka pemasukan, pengeluaran, dan selisih bersih periode ini, + perubahan % vs periode lalu |
| **Chart Carousel** | `DashboardChartCarousel` | Wadah berisi 2 chart yang bisa di-swipe: Laporan Pengeluaran (bar) & Laporan Tren (line) |

Keduanya berbagi **controller yang sama**: `DashboardChartController` — satu sumber data untuk semua widget chart.

### 3 Mode Periode

User bisa memilih mode periode lewat tombol dropdown di kanan atas carousel:

| Mode | Label UI | Arti |
|------|----------|------|
| **Bulanan** | "Bulanan" | Bulan ini vs bulan lalu (1-30/31 hari) |
| **Mingguan** | "Mingguan" | Minggu ini (Sen-Mgg) vs minggu lalu |
| **Harian** | "Harian" | 7 hari terakhir vs 7 hari sebelumnya |

> **Kenapa "Harian" = 7 hari?**
> Awalnya "Harian" berarti "hari ini saja", tapi hanya 1 data point di chart tidak informatif dan membingungkan. Sekarang diubah menjadi "rolling 7 hari" agar chart tetap bermakna dan user bisa melihat tren mingguan terkini.

---

<a id="alur-data"></a>
## 2. Alur Data: Dari Supabase ke Layar

```
Supabase (tabel: transactions)
    │
    │ query: filter by user_id, date range, type in (income, expense), settlement_kind IS NULL
    │
    ▼
DashboardRemoteDataSource
    │
    │ getPeriodSummary()  → { income: double, expense: double }
    │ getDailyAggregation() → [{ date: "2026-04-01", income: 50000, expense: 120000 }, ...]
    │
    ▼
DashboardRepository
    │
    │ Pattern match DataState (success → cache + return, error → fallback ke Hive cache)
    │
    ▼
DashboardChartController (StateNotifier)
    │
    │ 6 parallel requests: current summary, prev summary, current daily, prev daily, m2 daily, m3 daily
    │ Menyimpan semua ke DashboardChartState
    │
    ▼
Widget-widget (via ref.watch(dashboardChartControllerProvider))
    │
    ├─ DashboardPeriodSummary  → baca currentPeriodIncome/Expense, previousPeriodExpense
    ├─ DashboardComparisonChart → baca currentPeriod & previousPeriod Income/Expense
    └─ DashboardTrendReportChart → baca currentPeriodDaily, previousPeriodDaily, month2Daily, month3Daily
```

### Apa yang Diquery dari Supabase?

1. **getPeriodSummary(startDate, endDate)**: Ambil semua transaksi dalam rentang tanggal, filter hanya `type = income/expense`, dan `settlement_kind IS NULL` (pelunasan hutang dikecualikan). Jumlahkan masing-masing.

2. **getDailyAggregation(startDate, endDate)**: Sama seperti di atas, tapi dikelompokkan per tanggal. Hasilnya list: `[{ date, income, expense }]`.

> **Kenapa settlement_kind IS NULL?**
> Pelunasan hutang/piutang bukan pengeluaran/pemasukan "asli" — itu hanya pengembalian uang. Kalau dihitung, chart jadi misleading (seolah-olah kamu menghabiskan uang, padahal cuma bayar hutang).

### Cache & Offline

- **Period summary** di-cache ke Hive → bisa tampil walaupun offline
- **Daily aggregation** TIDAK di-cache → chart kosong kalau offline (acceptable karena chart sifatnya visual/supplementary)

---

<a id="period-ranges"></a>
## 3. Period Ranges — Bagaimana Rentang Waktu Dihitung

Method `periodRanges()` dan `extraPeriodRanges()` di controller menghitung 4 rentang waktu untuk setiap mode:

### periodRanges() → (currentStart, currentEnd, prevStart, prevEnd)

| Mode | Current Period | Previous Period |
|------|---------------|-----------------|
| **Bulanan** | 1 bulan ini → akhir bulan ini | 1 bulan lalu → akhir bulan lalu |
| **Mingguan** | Senin minggu ini → Minggu minggu ini | Senin minggu lalu → Minggu minggu lalu |
| **Harian** | 6 hari lalu → akhir hari ini | 13 hari lalu → 7 hari lalu (tepat sebelum current) |

Contoh mode Harian (hari ini = 14 April):
```
Current: 8 Apr → 14 Apr (7 hari)
Previous: 1 Apr → 7 Apr (7 hari)
```

### extraPeriodRanges() → (m2Start, m2End, m3Start, m3End)

Digunakan untuk menghitung "rata-rata 3 periode lalu" di chart tren:

| Mode | Periode 2 | Periode 3 |
|------|-----------|-----------|
| **Bulanan** | 2 bulan lalu | 3 bulan lalu |
| **Mingguan** | 2 minggu lalu | 3 minggu lalu |
| **Harian** | 14-20 hari lalu | 21-27 hari lalu |

> Jadi "rata-rata 3 periode" = rata-rata dari **periode lalu (prev) + periode 2 + periode 3** — bukan termasuk periode sekarang.

### Teknis: Boundary & Millisecond Trick

Semua `end` menggunakan `subtract(Duration(milliseconds: 1))` dari awal periode berikutnya. Ini memastikan query `gte(start) + lt(end)` tidak bocor ke hari berikutnya.

---

<a id="period-summary"></a>
## 4. DashboardPeriodSummary — Ringkasan Keuangan Periode

**File**: `dashboard_period_summary.dart` (218 baris)

### Apa yang Ditampilkan?

```
┌─────────────────────────────────────────────┐
│  Ringkasan Bulanan                          │
│                                             │
│  ● Pemasukan    ● Pengeluaran   ● Selisih   │
│  Rp1.200.000    Rp850.000       Rp350.000   │
│                                             │
│  ↓ 12,5% dari bulan lalu                    │
│                                             │
│                   Lihat Laporan Lengkap →    │
└─────────────────────────────────────────────┘
```

1. **Judul**: "Ringkasan {Bulanan/Mingguan/Harian}" — berubah sesuai mode
2. **3 angka**: Pemasukan, Pengeluaran, Selisih (net = income - expense)
   - Selisih hijau kalau positif (surplus), merah kalau negatif (defisit)
3. **Badge perubahan**: Persentase perubahan pengeluaran vs periode lalu
   - ↓ hijau = pengeluaran turun (bagus!)
   - ↑ merah = pengeluaran naik (hati-hati)
   - — abu-abu = tidak berubah
4. **Link "Lihat Laporan Lengkap"** → navigasi ke halaman Reports

### Cara Hitung Persentase Perubahan

```
expenseChange = ((currentExpense - previousExpense) / previousExpense) × 100
```

Contoh: Bulan ini Rp850rb, bulan lalu Rp970rb → ((850-970)/970)×100 = -12.4% → tampil "↓ 12,4%"

### Label Periode Sebelumnya

| Mode | Label |
|------|-------|
| Bulanan | "bulan lalu" |
| Mingguan | "minggu lalu" |
| Harian | "kemarin" |

> **Catatan**: Untuk mode Harian, label masih "kemarin" walaupun periodenya sebenarnya 7 hari. Ini mungkin perlu diperbarui ke "7 hari lalu" untuk konsistensi.

---

<a id="chart-carousel"></a>
## 5. DashboardChartCarousel — Wadah 2 Chart

**File**: `dashboard_chart_carousel.dart` (260 baris)

### Struktur Visual

```
┌─────────────────────────────────────────────┐
│  ◀  Laporan Pengeluaran  ▶   [Bulanan ▼]   │
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │                                     │    │
│  │     [ Chart Content - PageView ]    │    │
│  │                                     │    │
│  └─────────────────────────────────────┘    │
│                                             │
│              ●━━━━━━━━━━━━━● ○              │
└─────────────────────────────────────────────┘
```

### Komponen

1. **Header Row**:
   - ◀ Arrow kiri (disabled di halaman pertama)
   - Judul halaman: "Laporan Pengeluaran" atau "Laporan Tren"
   - ▶ Arrow kanan (disabled di halaman terakhir)
   - `_ModeSelector`: Dropdown PopupMenuButton untuk pilih Bulanan/Mingguan/Harian

2. **PageView** (height: 400.w fixed):
   - Halaman 0: `DashboardComparisonChart`
   - Halaman 1: `DashboardTrendReportChart`

3. **Dot Indicator**: Animasi dot berubah ukuran saat swipe

### Mode Selector

Implementasi: `PopupMenuButton<DashboardChartMode>` yang:
- Tampil sebagai chip biru muda dengan label mode aktif + dropdown arrow
- Menu muncul di atas tombol dengan 3 opsi
- Mode terpilih diberi ✓ check dan bold
- Saat dipilih, memanggil `controller.selectChartMode(mode)` yang:
  1. Simpan ke Hive (persist pilihan user)
  2. Update state
  3. Fetch ulang semua 6 data source

### Kenapa PageView Height Fixed?

`SizedBox(height: 400.w)` — menggunakan `.w` (bukan `.h`) agar scaling ikut width. Fixed height mencegah layout jump saat switch page atau data berubah.

---

<a id="comparison-chart"></a>
## 6. Halaman 1: DashboardComparisonChart — Laporan Pengeluaran

**File**: `dashboard_comparison_chart.dart` (413 baris)

### Apa yang Ditampilkan?

Bar chart yang membandingkan **total pengeluaran & pemasukan** antara 2 periode (sekarang vs sebelumnya).

```
┌─────────────────────────────────────────────┐
│  Total Pengeluaran      Total Pemasukan     │
│  Rp850rb  ↓12%          Rp1,2jt             │
│                                             │
│  ● Pemasukan  ● Pengeluaran                 │
│                                             │
│      ████                                   │
│      ████   ██                              │
│  ████████   ████                            │
│  ████████   ████   ████                     │
│  ████████   ████   ████   ██                │
│  ─────────────────────────────              │
│  Bulan Ini        Bulan Lalu                │
│                                             │
│  💡 Pengeluaranmu bulan ini 12% lebih       │
│     rendah dari bulan lalu. Bagus!          │
└─────────────────────────────────────────────┘
```

### Komponen Visual

1. **Summary Row** (atas):
   - "Total Pengeluaran" + angka compact + badge % change (jika ada)
   - "Total Pemasukan" + angka compact
   - Badge: ↓ hijau (pengeluaran turun) atau ↑ merah (naik)

2. **Legend**: 2 item — ● Pemasukan (hijau) dan ● Pengeluaran (merah)

3. **Syncfusion Bar Chart** (`SfCartesianChart`):
   - X-axis: 2 kategori — label periode (e.g., "Bulan Ini", "Bulan Lalu")
   - Y-axis: Angka format compact (1,5 jt, 300 rb)
   - 2 series per kategori: Income bar + Expense bar (grouped)
   - Tooltip: saat tap bar, tampil angka detail

4. **Smart Insight** (bawah): Kalimat analisis sederhana

### Label per Mode

| Mode | Current | Previous |
|------|---------|----------|
| Bulanan | "Bulan Ini" | "Bulan Lalu" |
| Mingguan | "Minggu Ini" | "Minggu Lalu" |
| Harian | "7 Hari Ini" | "7 Hari Lalu" |

### Insight Laporan Pengeluaran

Logika sederhana — 3 skenario berdasarkan `expenseChange`:

| Kondisi | Pesan | Nada |
|---------|-------|------|
| `< -2%` | "Pengeluaranmu {period} ini {X}% lebih rendah dari {prev}. Bagus, terus pertahankan!" | Positif |
| `> +2%` | "Pengeluaranmu {period} ini {X}% lebih tinggi dari {prev}. Coba kurangi yang tidak perlu." | Peringatan |
| `-2% → +2%` | "Pengeluaranmu stabil dibandingkan {prev}." | Netral |
| Tidak ada data | "Mulai catat transaksi untuk melihat insight." | Netral |

> Threshold ±2% digunakan agar tidak terlalu sensitif terhadap perubahan kecil.

### Format Angka Compact

Y-axis menggunakan `_compactLabel()`:
- ≥ 1.000.000 → "1,5 jt"
- ≥ 1.000 → "300 rb"
- < 1.000 → angka langsung

---

<a id="trend-report-chart"></a>
## 7. Halaman 2: DashboardTrendReportChart — Laporan Tren

**File**: `dashboard_trend_report_chart.dart` (600 baris)

### Apa yang Ditampilkan?

Line chart **kumulatif** yang menunjukkan bagaimana pengeluaran menumpuk hari demi hari, dibandingkan dengan periode lalu dan rata-rata 3 periode.

```
┌─────────────────────────────────────────────┐
│  ── Bulan Ini    ╌╌ Bulan Lalu    ╌╌ Avg 3  │
│                                             │
│                            ╱──── Current    │
│                         ╱──                 │
│                      ╱──                    │
│                   ╱──                       │
│                ╱── ╌╌╌╌╌╌╌ Previous         │
│             ╱──╌╌╌╌                         │
│          ╱──╌╌                              │
│       ╱──╌╌   ╌╌╌╌╌╌╌╌╌╌╌ Avg 3 periods    │
│    ╱──╌╌╌╌╌╌╌                               │
│  ──╌╌                                      │
│  01/04  05/04  10/04  15/04  20/04  25/04   │
│                                             │
│  ⚠️ Pengeluaranmu diprediksi mencapai       │
│     Rp1,8jt — lebih boros Rp300rb dari      │
│     biasanya. Batasi jadi Rp35rb/hari.      │
└─────────────────────────────────────────────┘
```

### 3 Garis di Chart

| # | Garis | Visual | Arti |
|---|-------|--------|------|
| 1 | **Periode Sekarang** | Solid merah + area gradient | Kumulatif pengeluaran hari demi hari bulan/minggu/7-hari ini |
| 2 | **Periode Sebelumnya** | Dashed merah transparan | Kumulatif pengeluaran periode lalu (sebagai perbandingan) |
| 3 | **Rata-rata 3 Periode** | Dashed abu-abu | Rata-rata kumulatif dari 3 periode sebelumnya (baseline "normal") |

### Kenapa Kumulatif?

Kalau chart menampilkan pengeluaran per hari biasa, grafiknya zigzag tidak beraturan — sulit dilihat trennya. Dengan kumulatif, garis selalu naik, dan kamu bisa langsung lihat:
- **Garis sekarang di atas garis rata-rata?** → Kamu lebih boros dari biasanya
- **Garis sekarang di bawah?** → Kamu lebih hemat
- **Kemiringan garis?** → Semakin curam = semakin cepat uang habis

### Proses Data: Step by Step

#### Step 1: Gap Fill (`_fillGaps`)

Data dari Supabase hanya berisi tanggal yang ada transaksinya. Tapi chart butuh data untuk **setiap** tanggal dalam range.

```
Input dari Supabase:
  [{ date: "2026-04-01", expense: 50000 },
   { date: "2026-04-03", expense: 120000 }]

Setelah _fillGaps (range 1-5 April):
  [{ date: "2026-04-01", expense: 50000 },
   { date: "2026-04-02", expense: 0 },      ← ditambahkan
   { date: "2026-04-03", expense: 120000 },
   { date: "2026-04-04", expense: 0 },      ← ditambahkan
   { date: "2026-04-05", expense: 0 }]      ← ditambahkan
```

#### Step 2: Konversi ke Kumulatif (`_toCumulative`)

```
Expense per hari:  [50000, 0, 120000, 0, 0]
Kumulatif:         [50000, 50000, 170000, 170000, 170000]
                    ↑       ↑       ↑
                    hari 1  hari 2  hari 3 (naik karena ada transaksi)
```

#### Step 3: Hitung Rata-rata 3 Periode (`_computeAvg3Cumulative`)

Ambil kumulatif dari 3 periode sebelumnya, rata-ratakan per hari:

```
prev kumulatif:   [40000, 80000, 130000, 160000, 180000]
month2 kumulatif: [30000, 60000, 100000, 140000, 160000]
month3 kumulatif: [50000, 90000, 150000, 190000, 210000]

Rata-rata:        [40000, 76667, 126667, 163333, 183333]
                   (40+30+50)/3  (80+60+90)/3  ...
```

> Jika panjang periode berbeda (misal Feb 28 hari, Mar 31 hari), nilai terakhir dari serie yang lebih pendek dipakai sebagai "carry forward".

### X-Axis Labels

| Mode | Format | Contoh |
|------|--------|--------|
| Bulanan | dd/MM | 01/04, 05/04, 10/04... |
| Mingguan | Nama hari (id_ID) | Sen, Sel, Rab, Kam, Jum, Sab, Mgg |
| Harian (7 hari) | dd/MM | 08/04, 09/04, ... 14/04 |

Untuk mode Bulanan (30+ data points), label dirotasi 45° dan yang tumpang tindih di-hide otomatis oleh Syncfusion.

### Legend per Mode

| Mode | Garis 1 | Garis 2 | Garis 3 |
|------|---------|---------|---------|
| Bulanan | "Bulan Ini" | "Bulan Lalu" | "Rata-rata 3 bulan lalu" |
| Mingguan | "Minggu Ini" | "Minggu Lalu" | "Rata-rata 3 minggu lalu" |
| Harian | "7 Hari Ini" | "7 Hari Lalu" | "Rata-rata 3 minggu lalu" |

### Tooltip

Saat tap titik di chart, muncul tooltip menunjukkan:
- Tanggal/hari
- Nama series + angka compact (e.g., "Bulan Ini: Rp1,2jt")

### Fitur Interaktif

Chart mendukung **pinch zoom** dan **panning** horizontal (hanya axis X) — berguna di mode Bulanan yang punya 30+ data points.

---

<a id="smart-insight"></a>
## 8. Smart Insight — Logika Burn Rate

Insight adalah kalimat analisis otomatis yang muncul di bawah chart. Tujuannya: **memberi tahu user apakah pengeluarannya sehat atau tidak, dengan bahasa yang mudah dimengerti**.

### Insight Laporan Tren (Burn Rate)

Konsep dasarnya: **Burn Rate** = seberapa cepat kamu menghabiskan uang per hari.

```
Burn Rate = Total pengeluaran sejauh ini ÷ Jumlah hari yang sudah lewat
```

Lalu burn rate diproyeksikan ke akhir periode dan dibandingkan dengan rata-rata 3 periode sebelumnya.

### Logika per Mode

#### Mode Bulanan & Mingguan

```
burnRate = currentTotal / daysElapsed
projectedTotal = burnRate × daysTotal
excess = projectedTotal - avg3Total
```

Dimana:
- `currentTotal` = total pengeluaran kumulatif hari ini
- `daysElapsed` = hari ke berapa dalam periode (misal tanggal 14 = hari ke-14)
- `daysTotal` = total hari dalam periode (misal April = 30 hari)
- `avg3Total` = total rata-rata pengeluaran 3 periode lalu

3 tier:

| Kondisi | Warna | Pesan |
|---------|-------|-------|
| `excess > avg3Total × 10%` | 🔴 Merah | "⚠️ Pengeluaranmu diprediksi mencapai {projected} — lebih boros {excess} dari biasanya ({avg}). Coba batasi pengeluaranmu jadi sekitar {dailyCap}/hari agar tetap aman." |
| `excess > 0` | 🟡 Kuning | "Pengeluaranmu sedikit lebih tinggi dari biasanya. Diperkirakan {projected}, biasanya {avg}. Tetap pantau agar tidak melonjak!" |
| `excess ≤ 0` | 🟢 Hijau | "🎉 Pengeluaranmu terkendali! Diperkirakan hanya {projected}, lebih hemat {saving} dari biasanya ({avg}). Selisihnya bisa kamu tabung!" |

**dailyCap** (hanya di tier merah): berapa maksimal yang boleh dihabiskan per hari sisa periode agar total akhir ≤ rata-rata:

```
dailyCap = (avg3Total - currentTotal) / daysRemaining
```

> Jika `dailyCap` negatif (sudah terlanjur lewat), di-clamp ke 0.

#### Mode Harian (7-Hari Rolling)

Berbeda dari bulanan/mingguan — tidak ada "proyeksi" karena periodenya sudah selesai (7 hari penuh). Jadi langsung bandingkan rata-rata harian:

```
burnRate = currentTotal / 7
avg3DailyRate = avg3Total / 7
excess = burnRate - avg3DailyRate
```

3 tier:

| Kondisi | Warna | Pesan |
|---------|-------|-------|
| `excess > avg3DailyRate × 10%` | 🔴 Merah | "⚠️ Rata-rata pengeluaranmu {burnRate}/hari, lebih tinggi {excess}/hari dari kebiasaanmu ({avg}/hari). Coba perhatikan pengeluaran yang bisa dikurangi." |
| `excess > 0` | 🟡 Kuning | "Pengeluaran harianmu sedikit lebih tinggi dari kebiasaanmu ({burnRate}/hari vs {avg}/hari). Tetap pantau ya!" |
| `excess ≤ 0` | 🟢 Hijau | "🎉 Pengeluaranmu lebih hemat dari kebiasaan! Rata-rata {burnRate}/hari, di bawah kebiasaanmu {avg}/hari. Terus pertahankan!" |

### Edge Cases

| Situasi | Handling |
|---------|----------|
| Tidak ada data sama sekali | "Mulai catat transaksi untuk melihat insight." (warning icon) |
| Ada data sekarang, tapi tidak ada historis (avg = 0) | "Pengeluaranmu periode ini: {total}. Terus catat transaksi agar bisa melihat tren." (warning icon) |
| `daysElapsed = 0` (hari pertama, belum ada data) | Sama seperti no data |

### Kenapa Burn Rate?

Alasan dipilih Burn Rate dibanding metode lain:

1. **Actionable**: Bukan cuma bilang "kamu boros" — tapi kasih tahu berapa yang harus dibatasi per hari
2. **Mudah dimengerti**: "Rp50rb/hari" lebih konkret dari "pengeluaranmu 15% di atas rata-rata"
3. **Prediktif**: Proyeksi ke akhir periode memberi "early warning" — masih bisa diperbaiki sebelum bulan berakhir
4. **Data minimal**: Cuma butuh data pengeluaran, tidak perlu income atau budget setup

---

<a id="diagram-arsitektur"></a>
## 9. Diagram Arsitektur

```
┌──────────────────────────────────────────────────────────────┐
│                     SUPABASE (Postgres)                       │
│  transactions table                                          │
│  Columns: user_id, date, type, total_amount, settlement_kind │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────┐
│         DashboardRemoteDataSource                │
│                                                  │
│  getPeriodSummary(start, end)                    │
│    → SELECT type, total_amount WHERE date BETWEEN│
│    → Filter: type IN (income, expense)           │
│    → Filter: settlement_kind IS NULL             │
│    → SUM per type → { income, expense }          │
│                                                  │
│  getDailyAggregation(start, end)                 │
│    → Same query + GROUP BY date(local)           │
│    → Returns [{ date, income, expense }]         │
└──────────────────────────┬───────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────┐
│            DashboardRepository                   │
│                                                  │
│  getPeriodSummary → remote + cache to Hive       │
│  getDailyAggregation → remote only (no cache)    │
└──────────────────────────┬───────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────────┐
│              DashboardChartController (StateNotifier)             │
│                                                                  │
│  State: DashboardChartState                                      │
│  ├── chartMode: monthly | weekly | daily                         │
│  ├── currentPeriodIncome/Expense    (untuk PeriodSummary + Bar)  │
│  ├── previousPeriodIncome/Expense   (untuk PeriodSummary + Bar)  │
│  ├── currentPeriodDaily             (untuk Trend chart)          │
│  ├── previousPeriodDaily            (untuk Trend chart)          │
│  ├── month2Daily                    (untuk avg 3 periode)        │
│  ├── month3Daily                    (untuk avg 3 periode)        │
│  └── status: initial|loading|loaded|error                        │
│                                                                  │
│  Methods:                                                        │
│  ├── loadChartData() → 6 parallel requests                       │
│  ├── selectChartMode(mode) → save + reload                       │
│  ├── periodRanges(now, mode) → (cur, prev) boundaries            │
│  └── extraPeriodRanges(now, mode) → (m2, m3) boundaries          │
└────────┬────────────────────┬────────────────────┬───────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌──────────────────────┐
│ PeriodSummary   │  │ ComparisonChart  │  │ TrendReportChart     │
│                 │  │ (Bar Chart)      │  │ (Cumulative Line)    │
│ Income/Expense/ │  │                  │  │                      │
│ Net + % change  │  │ 2 groups x 2    │  │ 3 lines:             │
│                 │  │ bars each        │  │ current, prev, avg3  │
│ Badge vs prev   │  │                  │  │                      │
│                 │  │ Insight: simple  │  │ Insight: burn rate   │
│ Link → Reports  │  │ % comparison     │  │ + projection + cap   │
└─────────────────┘  └─────────────────┘  └──────────────────────┘
```

### Hive Persistence

```
Hive key: "dashboard_chart_mode"
Values: "monthly" | "weekly" | "daily"
Default: "monthly"
```

Mode terakhir yang dipilih user disimpan dan dipakai saat app dibuka kembali.

---

<a id="catatan-penting"></a>
## 10. Catatan Penting & Gotchas

### Timezone Handling

- Semua `transactions.date` disimpan sebagai **UTC timestamp** di Supabase
- Query menggunakan `SakuDateUtils.localDayRangeUtc()` yang mengkonversi range tanggal lokal ke UTC boundary
- Display (x-axis labels) menggunakan tanggal lokal (`parseOptionalDate` → format tanpa timezone)
- Ini memastikan transaksi yang dicatat jam 23:30 WIB masuk ke tanggal yang benar

### Settlement Exclusion

- `settlement_kind IS NULL` memfilter pelunasan hutang/piutang
- Ini **non-negotiable** (PRD §4.2) — pelunasan bukan expense/income asli
- Tanpa filter ini, user yang rajin bayar hutang akan kelihatan "boros" di chart

### Library Chart

- Menggunakan **Syncfusion Flutter Charts** (`syncfusion_flutter_charts`)
- Free untuk individual/small business di bawah $1M revenue
- Dipilih karena feature-rich: tooltips, zoom/pan, gradient area, dashed lines

### Performance

- 6 parallel requests saat mode change → `Future.wait()` (tidak sequential)
- `ValueKey` pada chart widget memastikan rebuild hanya saat data berubah
- Chart height fixed → tidak ada layout reflow saat data loading

### Loading State (post-audit fix)

- `selectChartMode()` sekarang set `status: loading` sebelum fetch → shimmer muncul
- `DashboardChartCarousel` menampilkan `ShimmerWidget.box()` menggantikan `PageView` saat loading
- `DashboardPeriodSummary` menampilkan shimmer menggantikan body content saat loading
- Error handling mirror `loadChartData()`: jika kedua fetch gagal → `status: error` + `errorMessage`

### Tooltip Enhancements (post-audit fix)

- **Comparison chart**: Tooltip sekarang menampilkan **kedua** series (Income + Expense) dan **rentang tanggal** periode (e.g., "7 Apr — 13 Apr")
- **Trend chart**: `seriesIdx` di-clamp ke `0..2` untuk menghindari `RangeError`

### Keputusan Desain yang Pernah Dibuat

1. **Daily mode = 7 hari rolling** (bukan single day) → alasan: 1 data point tidak bisa bikin chart
2. **Burn rate + daily cap** (bukan % saja) → alasan: lebih actionable dan mudah dipahami
3. **3-period average** (bukan 2) → alasan: 3 lebih stabil, mengurangi noise dari 1 bulan outlier
4. **Kumulatif** (bukan per-hari) → alasan: tren lebih jelas, tidak zigzag

---

## Halaman Terkait

- [[wiki/entities/dashboard|Dashboard]] — Overview dashboard secara keseluruhan
- [[wiki/entities/reports|Reports]] — Halaman laporan lengkap
- [[wiki/concepts/aturan-keuangan|Aturan Keuangan]] — Guardrails keuangan (termasuk settlement exclusion)
- [[wiki/concepts/arsitektur-app|Arsitektur App]] — 3-file pattern, controller convention
- [[wiki/concepts/design-system|Design System]] — Warna, tipografi, visual rules
