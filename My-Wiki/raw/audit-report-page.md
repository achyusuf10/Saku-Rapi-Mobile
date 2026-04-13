# Audit Report Page — Smart Insight & Tren Harian

> Tanggal audit: 2026-04-13
> Scope: `ReportPage` → `_ReportInsightSection`, `_ReportTrendSection`, `ReportTrendChart`
> File: `report_page.dart`, `report_trend_chart.dart`, `report_controller.dart`, `report_model.dart`

---

## Ringkasan

| Area | Status | Keterangan |
|------|--------|------------|
| Tren Harian (chart) | ✅ Konsep benar | Bar chart income vs expense per hari — sudah tepat |
| Tren Harian (tooltip) | ✅ Fixed | Tooltip sekarang tampil kedua series (Income + Expense) + lokalisasi |
| Tren Harian (gap fill) | ⚠️ Minor | Hari tanpa transaksi tidak muncul (deferred — low priority) |
| Smart Insight | ✅ Implemented | 4 multi-layer insight: ratio, trend, dominant category, peak day |

---

## 1. Audit Tren Harian

### 1.1 Konsep — ✅ Sudah Benar

Tren Harian menampilkan **bar chart ganda** per hari: bar hijau (income) dan bar merah (expense). Ini adalah visualisasi standar untuk melihat pola harian:
- Hari mana yang paling boros?
- Apakah ada spike di tanggal tertentu?
- Pattern gajian (income spike) vs pattern belanja

**Data flow**: `getDailyTrend()` → query transaksi → aggregate per tanggal lokal → `ReportDailyTrendModel(date, income, expense)` → `ReportTrendChart` (Syncfusion ColumnSeries)

**Filter sudah benar**:
- `type IN ('income', 'expense')` — transfer di-exclude ✅
- `settlement_kind IS NULL` — settlement di-exclude ✅
- UTC timezone handling via `SakuDateUtils.localDayRangeUtc()` ✅

### 1.2 Bug Minor — Tooltip Hanya 1 Series

**File**: `report_trend_chart.dart` line 75-104

```dart
builder: (data, point, series, pointIdx, seriesIdx) {
  final d = data as ReportDailyTrendModel;
  final isIncome = seriesIdx == 0;
  // Hanya tampil 1 series berdasarkan bar yang di-tap
  '${isIncome ? "Income" : "Expense"}: ${isIncome ? d.income : d.expense}'
}
```

**Masalah**: Ketika user tap bar Income, hanya tampil Income. Tap bar Expense, hanya tampil Expense. User harus tap 2 kali untuk lihat keduanya.

**Rekomendasi**: Tampilkan kedua series + net di tooltip (mirip fix yang sudah dilakukan di comparison chart dashboard).

### 1.3 Bug Minor — Tidak Ada Gap Fill

**File**: `report_remote_data_source.dart` line 210-239

Data dari Supabase hanya berisi hari yang ada transaksinya. Jika user punya transaksi di tanggal 1, 3, 5 — chart hanya menampilkan 3 bar, tanpa bar di tanggal 2 dan 4.

Ini membuat chart **misleading** untuk periode panjang (3 bulan / tahunan) karena:
- Terlihat seperti transaksi setiap hari padahal ada gap
- Spacing antar bar tidak proporsional

**Rekomendasi**: Untuk periode pendek (harian, mingguan, bulanan), gap fill agar hari tanpa transaksi tetap muncul sebagai bar 0. Untuk periode panjang (3 bulan / tahunan), biarkan tanpa gap fill karena terlalu banyak data point.

### 1.4 Catatan — Hardcoded String di Tooltip

```dart
'${isIncome ? "Income" : "Expense"}: ...'
```

Ini pakai hardcoded English "Income" / "Expense" bukan dari `.arb` localization. Harusnya pakai `l10n.reportIncome` / `l10n.reportExpense` — tapi karena `buildChart` adalah `static`, tidak ada akses ke `l10n`.

---

## 2. Audit Smart Insight

### 2.1 Kondisi Saat Ini — 🔴 Kurang Informatif

**File**: `report_page.dart` line 541-596

Smart Insight saat ini hanya punya **3 kondisi**:

| Kondisi | Teks (dari `.arb`) | Masalah |
|---------|---------------------|---------|
| `expenseChange < -2` | "Pengeluaranmu turun {X}% dari periode sebelumnya. Bagus!" | ✅ Positif tapi **tidak ada konteks** |
| `expenseChange > 2` | "Pengeluaranmu naik {X}% dari periode sebelumnya. Perhatikan lebih." | ⚠️ **Tidak ada solusi**, hanya peringatan |
| `abs(change) ≤ 2` | "Pengeluaranmu relatif stabil dibanding periode sebelumnya." | ⚠️ Generik |
| `total == 0` | "Mulai catat transaksi untuk melihat insight laporan." | ✅ OK |

### 2.2 Masalah Utama

1. **Tidak actionable** — "Perhatikan lebih" tanpa memberitahu perhatikan apa
2. **Tidak ada konteks angka** — User tidak tahu berapa rupiah naik/turunnya
3. **Tidak ada analisis kategori** — Insight tidak memanfaatkan data `categoryBreakdown` yang sudah tersedia
4. **Threshold terlalu simpel** — Hanya cek % change, tidak melihat rasio expense/income atau pola spending
5. **Satu insight untuk semua** — Hanya 1 kalimat, padahal data yang tersedia cukup untuk 2-3 insight berbeda
6. **Tidak ada severity visual** — Semua insight pakai warna yang sama (ikon kuning)

### 2.3 Data yang Sudah Tersedia (tapi belum dipakai)

Dari `ReportState` kita sudah punya:

| Data | Getter | Kegunaan Potensial |
|------|--------|-------------------|
| `summary.totalIncome` | ✅ | Rasio expense/income |
| `summary.totalExpense` | ✅ | Total pengeluaran |
| `summary.expenseToIncomeRatio` | ✅ | Analisis financial health |
| `previousSummary` | ✅ | Perbandingan tren |
| `categoryBreakdown` | ✅ | Kategori terbesar |
| `dailyTrend` | ✅ | Hari terboros |
| `expenseChange` (provider) | ✅ | % perubahan |
| `incomeChange` (provider) | ✅ (belum dipakai di insight) | % perubahan income |

### 2.4 Rekomendasi: Multi-layer Smart Insight

Sistem insight yang lebih kaya dengan **beberapa insight sekaligus**, menggunakan data yang sudah tersedia:

#### Insight 1: Expense vs Income Ratio (Financial Health)

Berdasarkan `summary.expenseToIncomeRatio`:

| Rasio | Level | Pesan (contoh) |
|-------|-------|----------------|
| ≤ 0.5 (50%) | 🟢 Sehat | "Kamu membelanjakan 45% dari pemasukanmu. Sisanya bisa ditabung atau investasi." |
| 0.5 – 0.75 | 🟡 Perlu perhatian | "Kamu membelanjakan 70% dari pemasukanmu. Idealnya pengeluaran di bawah 50% agar ada ruang menabung." |
| 0.75 – 1.0 | 🟠 Waspada | "Kamu membelanjakan 92% dari pemasukanmu. Hampir tidak ada sisa untuk darurat. Coba kurangi pengeluaran {kategori terbesar}." |
| > 1.0 | 🔴 Bahaya | "Pengeluaranmu melebihi pemasukan sebesar Rp{selisih}. Kamu sedang 'berhutang' ke tabunganmu." |

> **Teori**: Aturan 50/30/20 (Elizabeth Warren) — 50% kebutuhan, 30% keinginan, 20% tabungan. Jika pengeluaran >80% dari pemasukan, financial health rendah.

#### Insight 2: Tren Perubahan (sudah ada, tapi diperkaya)

| Kondisi | Pesan (contoh) |
|---------|----------------|
| Turun signifikan (>10%) | "Pengeluaranmu turun Rp{selisih} ({X}%) dari periode lalu. Hemat di {kategori yang turun terbesar}." |
| Turun sedikit (2-10%) | "Pengeluaranmu turun sedikit ({X}%). Pertahankan!" |
| Stabil (-2% s/d 2%) | "Pengeluaranmu stabil. Total Rp{amount} periode ini." |
| Naik sedikit (2-10%) | "Pengeluaranmu naik Rp{selisih} ({X}%). Cek apakah ada kebutuhan dadakan atau bisa dikurangi." |
| Naik signifikan (>10%) | "Pengeluaranmu naik Rp{selisih} ({X}%). Penyebab terbesar: {kategori naik terbesar}. Coba batasi di kategori ini." |

#### Insight 3: Kategori Dominan

Berdasarkan `categoryBreakdown[0]` (kategori terbesar):

| Kondisi | Pesan (contoh) |
|---------|----------------|
| 1 kategori > 50% total | "Kategori {nama} mendominasi {X}% dari total pengeluaranmu (Rp{amount}). Coba cek apakah bisa dikurangi." |
| Proporsi merata | (Tidak tampilkan insight ini) |

#### Insight 4: Hari Terboros

Berdasarkan `dailyTrend` (hari dengan expense tertinggi):

| Kondisi | Pesan (contoh) |
|---------|----------------|
| Ada 1 hari > 30% total expense | "Pengeluaran terbesar di tanggal {tgl} sebesar Rp{amount}. Ini {X}% dari total pengeluaran periode ini." |

### 2.5 Rekomendasi Implementasi

**Approach**: Tidak perlu AI / backend. Semua bisa dihitung di Flutter dari data yang sudah ada.

**Struktur widget**: Ganti 1 Container menjadi **Column** berisi 2-4 insight card kecil, masing-masing dengan:
- Ikon + warna level (🟢🟡🟠🔴)
- Judul singkat (1 baris)
- Pesan detail (1-2 baris)

**Prioritas implementasi**:
1. ⭐ **Expense/Income Ratio** — Paling impactful, langsung menunjukkan financial health
2. ⭐ **Tren Perubahan** (perkaya yang ada) — Sudah ada, tinggal diperkaya dengan angka rupiah + solusi
3. **Kategori Dominan** — Bonus insight, memanfaatkan data yang ada
4. **Hari Terboros** — Bonus insight, memanfaatkan dailyTrend

**Lokalisasi**: Tambahkan key baru di `.arb` — jangan hardcode.

---

## 3. Status Implementasi

### ✅ Todo 1: Fix Tooltip Trend Chart — DONE
- Tooltip sekarang tampil **kedua series** (Pemasukan + Pengeluaran) dengan dot warna
- String dilokalisasi via parameter `incomeLabel` / `expenseLabel`
- Fullscreen dialog juga di-update

### ✅ Todo 2: Perkaya Smart Insight — Expense/Income Ratio — DONE
- 4 tier: ≤50% 🟢, 50-75% 🟡, 75-100% 🟠, >100% 🔴
- Kasus khusus: belum ada income → info text

### ✅ Todo 3: Perkaya Smart Insight — Tren dengan Angka — DONE
- 5 tier: turun besar (<-10%), turun kecil (-2 s/d -10%), stabil, naik kecil (2-10%), naik besar (>10%)
- Angka rupiah + % ditampilkan
- Naik besar → referensi ke kategori terbesar

### ✅ Todo 4: Tambah Insight — Kategori Dominan — DONE
- Threshold: kategori dominan jika >40% total expense
- Tampilkan nama kategori + % + rupiah

### ✅ Todo 5: Tambah Insight — Hari Terboros — DONE
- Threshold: peak day jika >25% total expense
- Tampilkan tanggal + rupiah + % dari total

### ⏳ Todo 6: Fix Gap Fill Trend Chart (Optional) — DEFERRED
- Low priority, tidak mempengaruhi UX signifikan
