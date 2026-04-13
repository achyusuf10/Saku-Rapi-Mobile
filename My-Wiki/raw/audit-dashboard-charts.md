# Audit Dashboard Charts & Period Summary — Temuan & Rencana Perbaikan

> Tanggal audit: 2026-04-13
> Scope: `DashboardChartCarousel`, `DashboardComparisonChart`, `DashboardTrendReportChart`, `DashboardPeriodSummary`, `DashboardChartController`

---

## Ringkasan Temuan

Total **8 bug/issue** ditemukan — 3 dari laporan user + 5 dari audit kode.

| # | Severity | Issue | File |
|---|----------|-------|------|
| 1 | 🔴 HIGH | Tidak ada loading indicator saat switch mode chart | controller + semua widget chart |
| 2 | 🔴 HIGH | `selectChartMode()` tidak set status `loading`/`loaded` & tidak handle error | controller |
| 3 | 🟡 MEDIUM | Stale data flash saat switch mode (labels update duluan, data masih lama) | semua widget chart |
| 4 | 🟡 MEDIUM | PeriodSummary pakai label "kemarin" di daily mode (seharusnya "7 hari lalu") | period_summary |
| 5 | 🟡 MEDIUM | Tooltip comparison chart kurang info (hanya 1 series, tanpa rentang tanggal) | comparison_chart |
| 6 | 🟢 LOW | Tooltip trend chart tidak bounds-check `seriesIdx` | trend_report_chart |
| 7 | 🟢 LOW | `selectChartMode()` missing `status: loaded` di akhir (shimmer stuck selamanya) | controller |
| 8 | 🟢 LOW | Comparison tooltip hanya tampil 1 series (income ATAU expense, bukan keduanya) | comparison_chart |

---

## Detail Temuan

### Bug 1 — Tidak Ada Loading Indicator Saat Switch Mode (User Report)

**Masalah**: Ketika user ganti mode (Bulanan → Mingguan → Harian), chart langsung berubah ke data lama/kosong tanpa indikasi loading. Setelah delay, tiba-tiba chart berubah lagi ke data baru.

**Penyebab**:
- `DashboardChartCarousel`, `DashboardComparisonChart`, dan `DashboardTrendReportChart` **tidak pernah mengecek** `DashboardChartStatus.loading`
- Widget langsung render data apa adanya — jika data lama masih tersimpan, maka data lama yang tampil

**Alur yang terjadi saat switch mode**:
```
1. User tap "Mingguan"
2. selectChartMode() dipanggil
3. state.chartMode = weekly (IMMEDIATE)
4. Widget rebuild → label berubah ke "Minggu Ini/Minggu Lalu"
   → TAPI data masih data bulanan yang lama!
   → Trend chart: _fillGaps() dengan boundary mingguan + data bulanan = semua 0
   → User lihat chart kosong/aneh
5. Network fetch... (delay 1-3 detik)
6. Data baru masuk → chart rebuild lagi → data benar muncul
```

**Fix**: Tambahkan shimmer loading di semua widget chart ketika `status == loading`.

---

### Bug 2 — `selectChartMode()` Missing Loading State & Error Handling

**Masalah**: Method ini tidak set `status: loading` sebelum fetch dan tidak handle error sama sekali.

**Kode sekarang** (`dashboard_chart_controller.dart` line 231-276):
```dart
Future<void> selectChartMode(DashboardChartMode mode) async {
  state = state.copyWith(chartMode: mode);          // ❌ Langsung set mode tanpa loading
  final results = await Future.wait([...]);          // Fetch data...
  state = state.copyWith(                            // ❌ Tidak ada error check
    currentPeriodIncome: currentSummary.dataSuccess()?['income'] ?? 0,  // ❌ Fail = silent 0
    // ...
  );
  // ❌ Tidak set status: loaded
}
```

Bandingkan dengan `loadChartData()` (line 170-226) yang **sudah benar**:
```dart
state = state.copyWith(status: DashboardChartStatus.loading);  // ✅
// ... fetch ...
if (currentSummary.isError() && currentDaily.isError()) {      // ✅ Error handling
  state = state.copyWith(status: DashboardChartStatus.error, errorMessage: ...);
  return;
}
state = state.copyWith(status: DashboardChartStatus.loaded, ...);  // ✅
```

**Fix**: Mirror pattern dari `loadChartData()` — set `loading`, handle error, set `loaded`.

---

### Bug 3 — Stale Data Flash

**Masalah**: Terkait erat dengan Bug 1 & 2. Saat mode berubah, widget rebuild langsung dengan data lama. Khusus di TrendReportChart, ini menyebabkan:

1. `chartState.chartMode` = weekly (baru)
2. `chartState.currentPeriodDaily` = data monthly (lama)
3. `periodRanges(now, weekly)` → boundary mingguan
4. `_fillGaps(data_bulanan, start_minggu, end_minggu)` → data lama tidak cocok dengan boundary baru → semua jadi 0
5. Chart tampil kosong sebentar → lalu data baru masuk

**Fix**: Dengan menambahkan loading shimmer (Bug 1 fix), data lama tidak akan terlihat.

---

### Bug 4 — PeriodSummary Label Salah untuk Daily Mode

**Masalah**: Sejak daily mode diubah dari "hari ini saja" menjadi "rolling 7 hari", label di PeriodSummary masih pakai "Kemarin" (`dashboardYesterday`).

**Kode** (`dashboard_period_summary.dart` line 39-45):
```dart
if (isMonthly) {
  periodLabel = l10n.dashboardLastMonth;
} else if (isDaily) {
  periodLabel = l10n.dashboardYesterday;  // ❌ Harusnya "7 Hari Lalu"
} else {
  periodLabel = l10n.dashboardLastWeek;
}
```

Badge akan tampil: "↓ 12% dari **kemarin**" → Seharusnya: "↓ 12% dari **7 hari lalu**"

**Fix**: Ganti `l10n.dashboardYesterday` → `l10n.dashboardPrev7Days` untuk daily mode.

---

### Bug 5 — Tooltip Comparison Chart Kurang Informatif (User Request)

**Masalah User**: Ingin tooltip comparison chart menampilkan rentang tanggal periode (misal "7 Apr — 13 Apr").

**Masalah tambahan dari audit**: Tooltip saat ini hanya menampilkan 1 series (Income ATAU Expense, tergantung bar yang di-tap), bukan keduanya.

**Kode sekarang** (`dashboard_comparison_chart.dart` line 150-191):
```dart
builder: (data, point, series, pointIdx, seriesIdx) {
  final isIncome = seriesIdx == 0;
  final value = isIncome ? d.income : d.expense;  // Hanya 1 nilai
  // Label hanya "Bulan Ini" tanpa tanggal
}
```

**Fix**:
1. Tambahkan parameter date range ke `_ComparisonData`
2. Tampilkan kedua series (Income + Expense) di tooltip
3. Tampilkan rentang tanggal (e.g., "Bulan Ini (1 Apr — 30 Apr)")

---

### Bug 6 — Tooltip Trend Chart Tidak Bounds-Check `seriesIdx`

**Masalah**: Jika Syncfusion memanggil tooltip builder dengan `seriesIdx > 2`, app crash `RangeError`.

**Kode** (`dashboard_trend_report_chart.dart` line 251):
```dart
'${names[seriesIdx]}: ...'  // ❌ Bisa crash jika seriesIdx out of bounds
```

**Fix**: Clamp `seriesIdx` ke range valid.

---

### Bug 7 — Missing `status: loaded` di `selectChartMode()`

Sudah termasuk dalam fix Bug 2.

---

### Bug 8 — Comparison Tooltip Hanya Tampil 1 Series

Sudah termasuk dalam fix Bug 5.

---

## Investigasi Bug User: "Weekly Chart Tidak Tampil Pengeluaran Hari Ini"

### Analisis Boundary

Tracing `periodRanges()` untuk weekly (hari ini 13 April 2026):
```
weekday = now.weekday (misal 1 = Senin)
currentStart = DateTime(2026, 4, 13) - Duration(days: 0) = 13 April (Senin)
currentEnd = 13 April + 7 hari - 1ms = 19 April 23:59:59.999

localDayRangeUtc:
  startUtc = 13 April 00:00 WIB → 12 April 17:00 UTC
  endUtcExclusive = 20 April 00:00 WIB → 19 April 17:00 UTC

Query: date >= 12 Apr 17:00 UTC AND date < 19 Apr 17:00 UTC
→ Semua transaksi 13-19 April WIB tercakup ✅
```

**Kesimpulan boundary**: Kalkulasi range weekly secara logis **sudah benar**. Transaksi hari ini seharusnya tercakup.

### Kemungkinan Penyebab Sebenarnya

1. **Stale data dari mode sebelumnya** (Bug 1 & 3) — User mungkin baru switch dari monthly ke weekly, dan yang tampil masih data monthly → terlihat seolah-olah data weekly kosong
2. **`selectChartMode()` fail silently** (Bug 2) — Jika network error, semua value jadi 0 tanpa error message
3. **Transaksi adalah settlement** — `settlement_kind IS NULL` filter mungkin meng-exclude transaksi tersebut (butuh verifikasi data)
4. **Transaksi adalah transfer** — Filter `type IN ('income', 'expense')` meng-exclude transfer (ini by design)

**Rekomendasi**: Fix Bug 1, 2, 3 terlebih dahulu. Setelah loading indicator + error handling benar, jika masalah masih ada, perlu debug data langsung di Supabase.

---

## Audit Konsep Keuangan

### ✅ Yang Sudah Benar

1. **Settlement exclusion** — Pelunasan hutang/piutang tidak dihitung sebagai expense/income → Benar (PRD §4.2)
2. **Transfer exclusion** — Transfer antar wallet bukan expense/income → Benar
3. **Burn rate sebagai metrik** — Appropriate untuk personal finance tracking
4. **3-period average** — Menggunakan 3 periode (bukan 2) mengurangi noise dari 1 bulan outlier → Best practice
5. **Kumulatif line chart** — Lebih informatif dari per-day scatter untuk melihat tren akumulasi

### ⚠️ Potensi Misconception

1. **Daily mode daysElapsed = 7 selalu** — Ini benar karena daily = rolling 7 hari (sudah selesai), jadi memang 7. Bukan bug, tapi bisa membingungkan pembaca kode.

2. **Burn rate projection awal bulan** — Di hari ke-1 atau ke-2 bulan, burn rate sangat volatile (1 transaksi besar di hari 1 = proyeksi sangat tinggi). Ini bisa misleading tapi acceptable untuk MVP — bisa ditambahkan minimum `daysElapsed >= 3` untuk menampilkan insight.

3. **Avg3 bisa bias jika ada bulan tanpa data** — Jika user baru mulai pakai app dan hanya punya data 1 bulan, avg3 = (1_bulan_data + 0 + 0) / 3, yang jauh lebih kecil dari realita. Edge case `avg3Total <= 0` sudah di-handle, tapi kasus "ada data tapi sangat sedikit" belum.

---

## Rencana Implementasi — ✅ Semua Selesai

### ✅ Todo 1: Fix Loading State di Chart Widgets
**File**: `dashboard_chart_carousel.dart`, `dashboard_period_summary.dart`
**Detail**: Ditambahkan `ShimmerWidget.box()` saat `status == DashboardChartStatus.loading` di carousel (mengganti PageView) dan period summary (mengganti body content)

### ✅ Todo 2: Fix `selectChartMode()` di Controller
**File**: `dashboard_chart_controller.dart`
**Detail**: Set `status: loading` di awal, tambah error handling (mirror `loadChartData()`), set `status: loaded` di akhir

### ✅ Todo 3: Fix PeriodSummary Label Daily Mode
**File**: `dashboard_period_summary.dart`
**Detail**: Ganti `l10n.dashboardYesterday` → `l10n.dashboardPrev7Days` untuk daily mode

### ✅ Todo 4: Enhance Comparison Chart Tooltip
**File**: `dashboard_comparison_chart.dart`
**Detail**: Tambah `dateRange` ke `_ComparisonData`, tampilkan date range + kedua series (Income + Expense) di tooltip

### ✅ Todo 5: Bounds-Check Tooltip Trend Chart
**File**: `dashboard_trend_report_chart.dart`
**Detail**: Clamp `seriesIdx` ke `0..names.length-1` untuk menghindari `RangeError`

### ✅ Todo 6: Audit & Test
**Detail**: `fvm flutter analyze` → No issues found
