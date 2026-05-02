# Rencana Implementasi — Export Laporan Excel (Import/Export Hub)

| Field | Nilai |
|-----|-----|
| **Status** | Rencana teknis (belum implementasi) |
| **Tanggal** | 2026-04-29 |
| **PRD acuan** | [`My-Wiki/raw/docs/prd/27_EXPORT_EXCEL_LAPORAN.md`](prd/27_EXPORT_EXCEL_LAPORAN.md) v0.2 |
| **Coding rules** | [`00_SakuRapi_Coding_Rules.md`](00_SakuRapi_Coding_Rules.md), [`wiki/concepts/coding-rules.md`](../../wiki/concepts/coding-rules.md) |
| **Package Excel** | `syncfusion_flutter_xlsio` (versi pin sesuai `pubspec` saat implementasi) |

---

## 1. Tujuan dokumen

Memberikan **urutan kerja, logika lengkap, dan batas tanggung jawab tiap layer** agar implementasi export Excel tidak meninggalkan cabang logika (filter tipe transaksi, pembatalan, partial export, sheet opsional, hutang global, dll.), sekaligus **rencana pengujian** yang dapat dieksekusi setelah kode ada.

---

## 2. Kepatuhan Coding Rules (ringkasan wajib)

| Aturan | Penerapan pada fitur ini |
|--------|---------------------------|
| **FVM** | Semua command build/test: `fvm flutter …`. |
| **Riverpod tanpa codegen** | `StateNotifier` / `Notifier` + `StateNotifierProvider.autoDispose` (atau pola setara) untuk controller yang melekat ke layar hub export — **WAJIB `autoDispose`** agar tidak bocor setelah navigasi keluar. |
| **Tidak hardcode string UI** | Semua label tombol, snackbar, dialog, placeholder Import, teks loading, **Hentikan dan buat sekarang**, dsb. lewat **ARB** (`lib/l10n/`); cek duplikasi key terlebih dahulu. |
| **Currency / date di UI** | Widget: `double_ext` / `int_ext` / `date_time_ext`; kontrak backend & query: `SakuDateUtils.localDayRangeUtc` untuk range periode (sama seperti `TransactionRemoteDataSource.getTransactions`). |
| **Warna & layout** | `context.colors`, `ScreenUtil` (`.h`, `.w`, `.sp`), `TextStyleConstants`; ikon bebas **FontAwesome** selaras settings. |
| **Arsitektur 3-layer data** | Jika ada query/RPC baru untuk export: `export_remote_data_source.dart` → `export_repository.dart`; bungkus RPC/query dengan `SupabaseHandler.call`; repository olah `DataState` dengan `.map` / `.when`. |
| **UI tidak menggembung** | Screen hub & dialog loading dipecah ke `lib/features/{export}/view/widgets/` dengan nama ber-konteks (mis. `ExportExcelProgressOverlay`). |
| **Logging** | `AppLogger.call` dengan prefix konsisten, mis. `[Export] [ExportRepository] …`. |
| **Shimmer / empty / error** | Layar hub: loading awal (jika ada) pakai shimmer; error pakai `SakuErrorWidget` + retry; empty state hanya jika skenario valid (mis. periode tanpa data — tetap boleh export dengan sheet kosong + banner?). |
| **Supabase** | Sebelum RPC/tabel baru: verifikasi skema lewat **Supabase MCP** (bukan tebak nama kolom). |

---

## 3. Lingkup fitur & struktur modul Flutter

### 3.1. Nama fitur & folder

Disarankan: `lib/features/import_export/` dengan struktur:

```
lib/features/export/
├── controllers/
├── datasource/          # hanya jika ada remote tambahan
├── models/              # DTO murni export (bukan mengganti TransactionModel)
├── repositories/
├── services/            # optional: excel_workbook_builder (pure Dart, diuji unit)
├── utils/               # mapping, agregasi murni (diuji unit)
└── view/
    ├── ui/
    └── widgets/
```

**Catatan:** `syncfusion_flutter_xlsio` boleh dipanggil dari **service/builder** yang dipanggil controller; hindari memanggil Supabase langsung dari file yang juga tulis workbook kecuali orchestration sederhana di repository.

### 3.2. Routing

- Tambah path konstanta di `AppRouter` (mis. `importExport = '/settings/import-export'`).
- **`SettingsPage`:** aktifkan `onTap` tile Export/Import → `context.push(AppRouter.importExport)`; hilangkan badge coming soon sesuai PRD; subtitle dari l10n.
- Guard: hanya user login (sudah ditangani shell auth global); tidak perlu argumen rute untuk MVP.

---

## 4. Model state & orchestration controller

### 4.1. Input user (single source of truth sebelum export)

| Field | Tipe | Aturan |
|------|------|--------|
| `dateRange` | `DateTime start` + `DateTime end` (inklusif hari lokal) | Validasi `start <= end`; normalisasi ke local day sebelum `localDayRangeUtc`. |
| `includeDebtSheet` | `bool` | Default `false`. |
| `includeTransferSheet` | `bool` | Default `false`. |
| `format` | enum / tetap `excel` | PDF/CSV: UI “Segera hadir” saja. |

Pemasukan & pengeluaran **selalu** di-fetch untuk periode di atas (tidak perlu flag).

### 4.2. State mesin export (disarankan enum + fields)

Diskret agar tidak ada “setengah jalan” tak terdefinisi:

1. **idle** — siap, form valid/invalid.
2. **fetching** — sedang chunk + mengumpulkan list.
3. **buildingWorkbook** — fetch selesai atau partial; sedang `save`/`write` Excel (bisa gabung dengan fetching jika streaming — MVP satu fase setelah data lengkap lebih mudahb bug).
4. **success** — path file + flags: `isPartial`, `includedDebt`, `includedTransfer`.
5. **cancelled** — kembali idle, tidak ada file.
6. **error** — pesan untuk `SakuErrorWidget` / snackbar.

**Flags paralel UI:**

- `showStopAndBuildButton` — `true` iff elapsed ≥ 15s sejak masuk `fetching` **dan** belum sukses/error.
- `allowPartialTrigger` — `true` iff minimal **satu** chunk **income/expense** untuk periode telah sukses (sesuai edge case PRD).

### 4.3. Objek batal (`Cancellation`)

Wajib satu mekanisme yang dilempar ke repository/service:

- `CancelToken` / `ValueNotifier<bool> isCancelled` / `Completer` pattern — pilih satu dan **dokumentasikan**.
- Setiap **antara chunk** dan sebelum **mulai menulis file**: cek token; jika batal → hentikan loop, lempar `ExportCancelledException` (tidak ditampilkan sebagai error merah ke user, kembali idle).
- **Batalkan** juga meng-set flag agar **tidak** lanjut `buildWorkbook`.

### 4.4. Partial (“Hentikan dan buat sekarang”)

Urutan logika ketat:

1. Set `partialMode = true`.
2. Set token agar **loop chunk income/expense** dan **loop chunk transfer** (jika ada) **berhenti setelah chunk yang sedang berjalan selesai** — tidak start chunk baru.
3. **Hutang/piutang:** putuskan salah satu dan **tetap di seluruh codebase**:
   - **A)** partial juga memutus fetch hutang jika masih berjalan (konsisten “hentikan semua get”), atau
   - **B)** hutang diambil dalam **satu** atau sedikit request; biarkan selesai agar sheet hutang tidak setengah.

   Disarankan **A** untuk konsistensi UX; dokumentasikan di kode.

4. Lanjut **buildingWorkbook** dengan data di memori:
   - Dashboard + Sheet 2 + 3 dari income/expense yang terambut.
   - Sheet transfer hanya jika opsi aktif **dan** minimal satu chunk transfer pernah sukses (atau kosongkan sheet dengan header saja? — preferensi: **sheet tetap dibuat dengan 0 baris data** jika opsi on tapi tidak ada data).
   - Sheet hutang: jika opsi aktif dan fetch hutang selesai sebelum batal → isi penuh; jika terbatal sebelum selesai → **skip sheet** atau sheet dengan pesan — **putuskan di implementasi: skip sheet + snackbar** agar tidak menyesatkan.

5. Set `isPartial = true` pada state sukses; tampilkan `context.showAppAlert` / banner sekali bahwa data periode mungkin tidak lengkap.

### 4.5. Timer 15 detik

- `Timer?` atau `Stopwatch` dimulai saat masuk `fetching`.
- Di `dispose` controller/provider: **cancel timer** (cegah leak).
- Tombol partial hanya mount jika syarat §4.2.

---

## 5. Pengambilan data (repository layer)

### 5.1. Transaksi periode — income & expense (inti)

**Sumber ada:** `TransactionRepository.getTransactions(startDate, endDate, limit, offset)`.

**Logika:**

1. Gunakan **range tanggal yang sama** dengan layar (`start`/`end` local day).
2. Loop `offset += limit` sampai:
   - jumlah baris `< limit` **atau**
   - `isCancelled` **atau**
   - `partialMode && userTriggeredPartial` (hentikan setelah iterasi saat ini).

3. Setiap response:
   - **Filter in-memory** baris dengan `type == income || type == expense` **saja** untuk Sheet 2 & agregat Dashboard/Sheet 3.
   - **Jangan** masukkan `transfer`, `debt`, `loan`, `adjustment`, `transferToAsset` ke agregat Dashboard — selaras PRD (“hanya pemasukan & pengeluaran”).

**Keputusan produk teknis (catat di kode + tes):**

- `adjustment` & `transferToAsset` **tidak** masuk Dashboard dan tidak masuk Sheet 2. Jika di masa depan harus ikut, ubah PRD dulu.

4. **Gagal jaringan** pada satu chunk:
   - Map ke `DataState.error`; UI: `SakuErrorWidget` + retry dari awal (clear list).
   - Jangan simpan file parsial.

5. **Items:** pastikan model punya `items` terisi dari join yang sudah ada di remote (sudah ada di `getTransactions` select). Jika ada kasus item kosong, tangani sesuai validasi domain (fallback baris kosong / error export).

### 5.2. Transaksi periode — transfer (opsional)

**Sumber:** sama `getTransactions`, periode sama, chunk sama atau terpisah.

**Efisiensi:** Satu loop chunk dapat mengumpulkan tiga keranjang (`incomeExpenseAll`, `transfersAll`) dengan filter `type` di memori — **mengurangi round-trip**. Atau dua loop terpisah — lebih sederhana tapi lebih lambat. **Disarankan satu loop** dengan partisi memori.

**Partial:** transfer mengikuti aturan partial yang sama dengan income/expense (henti chunk).

### 5.3. Hutang / piutang — seluruh buku (opsional)

**PRD:** bukan filter periode; ringkasan global “belum dibayar”; tabel seluruh record relevan.

**API ada hari ini (audit repo):**

- `getSummary(type)` — per kontak.
- `getTransactionsByPerson(withPerson, type)` — detail per orang.
- `getAllUnpaid(type)` — hanya belum lunas.

**Kesenjangan PRD vs API:** PRD minta tabel **lunas + belum lunas** full book. `getAllUnpaid` saja tidak cukup.

**Rencana implementasi (pilih satu sebelum coding — verifikasi MCP):**

1. **Preferensi:** RPC baru mis. `get_all_debt_loan_for_export` mengembalikan flat list `DebtLoanTransactionModel` dengan pagination cursor — mendukung batal & skala besar.
2. **Fallback tanpa RPC:** Untuk setiap `type in {debt, loan}`:
   - panggil `getSummary`,
   - untuk setiap `withPerson` unik panggil `getTransactionsByPerson`,
   
   **Konsekuensi:** banyak round-trip; wajib **progress** di UI; **batalkan** antar person; dokumentasikan risiko timeout.

3. **Ringkasan atas “Total hutang/piutang belum dibayar”:** boleh dihitung:
   - dari **agregasi baris hasil export** yang `remaining > 0` / status belum lunas, **atau**
   - dari endpoint khusus agregat (jika ada).
   
   Wajib **konsisten** dengan definisi app (`DebtLoanTransactionModel.remaining`, `DebtStatusEnum`).

**Batalkan:** sama seperti chunk — cek token antar panggilan person/batch.

### 5.4. Konkurensi & memori

- Akumulasi di `List<TransactionModel>` untuk periode bisa besar; pertimbangkan **kapasitas awal** `growable` atau gabung list per chunk tanpa spread berlebihan.
- Agregasi berat (group-by hari, group-by kategori) jalankan di **`compute()` / isolate** dengan **DTO serializable** (jangan kirim `BuildContext`).

---

## 6. Transformasi data → baris Excel (utils)

Semua fungsi berikut **murni** (tanpa I/O), **ber-docstring**, **unit-testable**:

### 6.1. Baris Sheet 2 (satu baris per `TransactionModel`)

Prasyarat: `type` adalah `income` atau `expense`.

| Kolom | Sumber & aturan |
|-------|------------------|
| No | indeks urut 1..n setelah sort (disarankan sort sama seperti query: `date` desc, `created_at` desc — samakan dengan History jika relevan). |
| Tanggal | Format untuk sel Excel: konsisten; gunakan objek `DateTime` local user; hindari string manual acak — helper terpusat satu fungsi `DateTime exportCellDate(DateTime d)`. |
| Tipe | Label lokal **Pemasukan** / **Pengeluaran** — untuk **isi sel** boleh bahasa Indonesia tetap (Excel tidak lewat app l10n viewer); opsional: ikut locale app jika `AppLocalizations` bisa di-inject ke isolate (biasanya **tidak**); **putuskan:** default ID tetap di file Excel atau ikut `locale` — dokumentasikan. |
| Kategori | Gabungan unik `item.categoryName` berurutan `sort_order`, pisah `"; "`. |
| Catatan | `transaction.note` + suffix multi-item: untuk tiap item, format tetap mis. `\n• {itemName|kategori} — {amount}` (spec konkret di kode + snapshot tes). |
| Dompet | `walletName` atau fallback `'-'`. |
| Nominal | `totalAmount`; format **cell** Excel IDR via number format Syncfusion, bukan string `Rp` manual kecuali library memaksa. |

### 6.2. Sheet 3 — Analisis kategori

Input: daftar baris Sheet 2 dengan `Tipe == Pengeluaran` (atau filter `expense` sebelum mapping label).

- Group by **nama kategori** — jika satu baris punya gabungan kategori `A; B`, putuskan:
  - **Opsi disarankan:** bagi **proporsional** berdasarkan `item.amount` per kategori **dari transaksi asli** (butuh data item), atau

**Spesifikasi MVP disarankan:** agregasi dari **item-level** sebelum flatten ke satu baris transaksi: loop `items` expense-only, accumulate `amount` by `categoryName`. Ini cocok dengan Pie tanpa double-count gabungan string.

### 6.3. Sheet 1 — angka ringkasan & data chart

- `totalIncome` = sum `totalAmount` untuk `type == income` pada dataset inti.
- `totalExpense` = sum untuk `type == expense`.
- `saldoAkhirPeriod` = `totalIncome - totalExpense` (selaraskan teks PRD §8 jika nanti beda dengan metrik app).

**Bar chart harian:**

- Map `DateTime` (date-only local) → `{ income: double, expense: double }`.
- Libatkan **hanya** income/expense; **tanpa** transfer.

**Pie chart:**

- Sumber = Sheet 3 ranges.

### 6.4. Sheet Hutang

Map dari `DebtLoanTransactionModel` + label Indonesia Hutang/Piutang, status Lunas/Belum Lunas dari `remaining` / `DebtStatusEnum`.

Warna baris: rules PRD (kuning / hijau).

### 6.5. Sheet Transfer

Map `TransactionModel` dengan `type == transfer`: kolom dompet asal/tujuan dari `walletName` / `destinationWalletName`, nominal, catatan, tanggal.

---

## 7. Pembangunan workbook (`syncfusion_flutter_xlsio`)

### 7.1. Urutan sheet

1. Buat **Data Transaksi** & **Analisis Kategori** (isi cell).
2. **Dashboard** — tulis judul, periode, kotak ringkasan, lalu pasang chart refer ke range sheet lain.
3. **Hutang Piutang** (opsional).
4. **Transfer** (opsional).

**Penamaan sheet:** persis seperti PRD (`Dashboard`, `Data Transaksi`, `Analisis Kategori`, `Hutang Piutang`, `Transfer`).

### 7.2. Styling Sheet 2

- Freeze panes baris header.
- Banded rows.
- Conditional font color untuk kolom Tipe (hijau/merah) — atau Conditional Formatting Syncfusion jika didukung; jika tidak, set style per cell saat loop.
- Number format IDR untuk kolom Nominal.
- `autoFitColumn` per kolom setelah isi (dengan batas max width jika satu cell catatan sangat panjang — cegah layout Excel rusuk; mis. max 60).

### 7.3. Chart

- Verifikasi dokumen Syncfusion versi terpasang: Pie + Bar + referensi antar-sheet.
- Jika chart gagal di MVP: fallback PRD — tabel ringkasan harian + catatan README di sheet Dashboard (spanduk teks), **jangan** gagal total export.

### 7.4. Penyimpanan file

- Path: **Download publik Android** sesuai PRD.
- Gunakan API yang kompatibel scoped storage (cek `path_provider` + `permission_handler` jika perlu).
- Nama file: `SakuRapi_Laporan_YYYYMMDD_HHmm.xlsx` dengan timezone Asia/Jakarta.
- **Buka/Bagikan:** `share_plus` + `FileProvider` (`AndroidManifest` + `file_paths.xml`) jika belum ada di proyek.

### 7.5. Isolate untuk XlsIO

- Jika `Workbook.save` / serialize besar, jalankan di isolate hanya jika **thread-safe** menurut dokumentasi package; jika tidak, tetap di isolate **data prep** saja, save di main **async** dengan `Future` agar frame tidak jank — ukur dengan DevTools.

---

## 8. UX layar hub (checklist)

- [ ] Tab Export / Import; Import = **Segera hadir** (l10n).
- [ ] Excel aktif; PDF/CSV disabled / snackbar.
- [ ] Periode: reuse widget pola app (`Saku` date range / period selector) jika ada.
- [ ] Checkbox hutang + checkbox transfer + blok “Pemasukan & pengeluaran selalu disertakan” (read-only visual).
- [ ] Tombol export disabled jika periode tidak valid.
- [ ] Dialog / overlay progres dengan teks loading (l10n), **Batalkan**, **Hentikan dan buat sekarang** (muncul ≥15s).
- [ ] Sukses: dialog **Buka** / **Bagikan**; jika partial, alert tambahan.
- [ ] Shimmer hanya jika ada prefetch halaman (opsional); untuk export langsung overlay boleh beda — selaras rules “jangan CircularProgress tengah layar kosong” (overlay dengan copy tetap OK).

---

## 9. Izin & manifest Android

- Audit `AndroidManifest.xml` untuk write/read external storage sesuai `targetSdk`.
- Tambah `queries` / `FileProvider` jika share intent membutuhkan.
- Uji di **Android 10+** fisik atau emulator.

---

## 10. Lokalisasi — daftar key baru (indikatif)

Tambahkan ke `app_id.arb` / `app_en.arb` (nama final disesuaikan konvensi yang ada):

- Judul halaman hub, label segment Import/Export, **Segera hadir** (jika belum ada).
- Label checkbox hutang/transfer, penjelasan Dashboard tidak termasuk transfer.
- Pesan loading, **Batalkan**, **Hentikan dan buat sekarang**.
- Pesan sukses, gagal, dibatalkan, **partial / data tidak lengkap**.
- Label tombol buka file / bagikan.

**Dilarang** menyisakan string mentah diDart.

---

## 11. Rencana pengujian

### 11.1. Unit test (`test/…`)

Target file utils / pure functions:

| Kasus | Yang diuji |
|-------|------------|
| Filter tipe | Dari list `TransactionModel` campuran, hasil Sheet 2 hanya income+expense; transfer tidak mempengaruhi agregat dashboard. |
| Multi-item catatan | Satu transaksi dua item → satu baris; catatan berisi dua entry; kategori gabungan benar. |
| Agregasi kategori | Total per kategori dari item expense sama dengan yang diharapkan (gunakan fixture JSON/map). |
| Agregasi harian | Income/expense per tanggal benar; timezone tidak menggeser hari (gunakan `SakuDateUtils` fixture). |
| Partial flag | Simulasi list terpotong: Dashboard sama dengan partial sum. |
| Mapping hutang | `remaining`, status lunas/belum, warna baris logic (optional: return “style token” bukan Color langsung agar test headless). |
| Edge: nominal nol, tanpa note, tanpa items (invalid — harus error atau skip sesuai keputusan). |

** tooling:** `fvm flutter test`.

### 11.2. Widget / golden (opsional)

- Hub screen: satu golden test layout **idle** (mock provider).
- Dialog progres: presence tombol setelah pump dengan fake timer (`fake_async`).

### 11.3. Integration / manual QA (wajib dicentang sebelum merge)

Gunakan skenario di perangkat/emulator Android nyata:

| ID | Skenario | Harapan |
|----|----------|---------|
| M1 | Export periode 1 minggu, hanya inti, data sedikit | 3 sheet; angka Dashboard = sum Sheet 2; buka di Google Sheets / Excel. |
| M2 | Export tahun penuh (banyak data), biarkan selesai | Tidak ANR; file valid; memori stabil kasar. |
| M3 | Export besar, tekan **Batalkan** di tengah | Tidak ada file sampah di Download; app kembali normal. |
| M4 | Export besar, tunggu ≥15s, **Hentikan dan buat sekarang** | File terbentuk; isi parsial; pesan partial tampil. |
| M5 | Opsi hutang ON | Sheet Hutang ada; total atas masuk akal; banding sampel dengan app. |
| M6 | Opsi transfer ON | Sheet Transfer ada; **tidak** mengubah total Dashboard vs run tanpa transfer sheet (angka Dashboard identik untuk inti). |
| M7 | Hutang OFF, Transfer OFF | Hanya 3 sheet. |
| M8 | Periode tanpa transaksi | File tetap terbentuk atau dialog “tidak ada data” — **putuskan produk**: PRD mengizinkan workbook kosong dengan header; samakan. |
| M9 | Offline / gagal API satu chunk | Error UI + retry; tidak corrupt. |
| M10 | Share & open intent | File dibuka aplikasi eksternal tanpa crash. |

### 11.4. Regression

- Settings tile tidak merusak navigasi lain.
- `autoDispose`: navigasi keluar saat fetching — tidak crash (token disposed aman).

---

## 12. Urutan implementasi (milestones)

1. **Boilerplate:** fitur folder, rute, ARB, tile settings.
2. **Hub UI** tanpa export sungguhan (mock success).
3. **Repository chunk** + cancel + partial + gabung list (tanpa Excel).
4. **Utils** agregasi + mapping + unit tests.
5. **Excel builder** + save Download + integrasi end-to-end.
6. **Charts** + polish styling.
7. **Hutang** path (RPC baru atau fallback summary loop) + tests.
8. **Transfer** sheet + gabung loop tunggal.
9. **QA checklist** §11.3 + perbaikan memori.

---

## 13. Risiko & mitigasi

| Risiko | Mitigasi |
|--------|----------|
| Chart XlsIO tidak mendukung referensi silang | Fallback tabel; spike 0.5 hari di awal milestone 6. |
| Fetch hutang N+1 lambat | RPC batch; atau limit + disclaimer “bagian hutang dibatasi”. |
| File besar crash OOM | Chunk write tidak layak → kurangi periode atau naikkan `limit` bertahap; profil memori. |
| Lisensi Syncfusion | Pastikan lisensi/community sesuai penggunaan komersial app — cek legal. |

---

## 14. Setelah implementasi

- Update [`27_EXPORT_EXCEL_LAPORAN.md`](prd/27_EXPORT_EXCEL_LAPORAN.md) jika ada penyimpangan kecil yang disepakati.
- Tambahkan satu baris di `wiki/CHANGELOG` atau dokumen release internal jika ada.

---

*Dokumen ini adalah rencana teknis; tidak menggantikan PRD untuk keputusan produk.*
