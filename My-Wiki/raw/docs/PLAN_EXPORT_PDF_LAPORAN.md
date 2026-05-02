# Rencana Implementasi — Export Laporan PDF (Import/Export Hub)

| Field | Nilai |
|-----|-----|
| **Status** | **Implementasi aktif** (kode: `ExportPdfService`, widget chart PDF, hub format) |
| **Tanggal** | 2026-04-29 |
| **PRD acuan** | Selaras urutan & isi dengan [`27_EXPORT_EXCEL_LAPORAN.md`](prd/27_EXPORT_EXCEL_LAPORAN.md) dan [`export_excel_service.dart`](../../../lib/features/export/services/export_excel_service.dart). |
| **Plan Excel** | [`PLAN_EXPORT_EXCEL_LAPORAN.md`](PLAN_EXPORT_EXCEL_LAPORAN.md) — data layer & controller sama. |
| **Coding rules** | [`00_SakuRapi_Coding_Rules.md`](00_SakuRapi_Coding_Rules.md), [`wiki/concepts/coding-rules.md`](../../wiki/concepts/coding-rules.md) |
| **Package PDF** | `syncfusion_flutter_pdf` (pin 33.2.4, selaras charts/xlsio). |
| **Package screenshot** | `screenshot` — `captureFromWidget` → PNG → `PdfBitmap`. |

---

## Keputusan produk (final)

1. **Ringkasan harian (tabel)** — **Section terpisah** setelah halaman grafik: judul `exportPdfDailyTableSectionTitle`, bukan digabung dalam satu blok visual dengan KPI di halaman yang sama.
2. **Sampul** — **Ada**: header brand warna primer + teks **SakuRapi** (`exportCoverAppBrand`) + `exportReportBrandTitle` + periode + cap waktu (`exportCoverGeneratedLabel`). Logo raster opsional (fase 2 / asset); MVP teks + warna brand.
3. **Ukuran halaman** — **A4 portrait** untuk sampul, TOC, ringkasan KPI, tabel ringkasan harian, transaksi, analisis kategori, hutang, transfer. **Setiap halaman grafik** (batang & pie) — **A4 landscape** terpisah.
4. **Daftar isi** — **Wajib hyperlink in-document** (`PdfDocumentLinkAnnotation` + `PdfDestination`) **dan nomor halaman** (1-based setelah sisip TOC). **Bookmark panel** PDF (`document.bookmarks.add`) selaras entri TOC.
5. **Bahasa** — **Mengikuti locale app** (`AppLocalizations` + `localeName` / `Localizations.localeOf(context)` untuk tanggal & angka).

---

## 5. Urutan dokumen PDF (mirror Excel + keputusan di atas)

1. **Sampul** — branding + periode + dibuat.
2. **Daftar isi** — disisipkan di indeks **1** setelah seluruh body selesai, agar nomor halaman pada TOC akurat; link & bookmark mengacu objek `PdfPage` yang sama (tetap valid setelah sisip).
3. **Dashboard** — KPI tiga kotak (pemasukan, pengeluaran, saldo) + catatan partial jika perlu.
4. **Grafik batang** (landscape) — jika ada hari dengan data / capture berhasil.
5. **Grafik kategori** (landscape) — jika ada agregat pengeluaran / capture berhasil.
6. **Ringkasan harian** — **hanya tabel** harian (tanggal, pemasukan, pengeluaran), section terpisah.
7. **Data transaksi** — grid bermulti-halaman bila perlu.
8. **Analisis kategori** — tabel kategori, nominal, persen.
9. **Hutang piutang** — opsional, sama konsep Excel.
10. **Transfer** — opsional, sama konsep Excel.

---

## 6. Daftar isi (hyperlink + nomor)

- Rendering: teks baris + annotation link ke `PdfDestination(targetPage, Offset.zero)` dengan `fitToPage`.
- Nomor halaman: `document.pages.indexOf(targetPage) + 1` **setelah** `pages.insert(1, tocPage)`.

---

## 7–16. Lainnya

Prinsip teknis (chart Syncfusion + capture, tema `AppColorScheme`, logging `[Export] [Pdf]`, penyimpanan `ExportFileWriter.savePdfBytes`, pemilihan format `ExportFileFormat` di hub) tidak berubah substansinya; lihat revisi historis git untuk detail spike.

---

## 15. Pertanyaan terbuka

**Ditutup** — lihat tabel **Keputusan produk (final)** di atas.

---

*Implementasi mengikuti plan ini; penyempurnaan (logo raster, font TrueType embed, footer nomor halaman setiap lembar) dapat ditambah iteratif.*
