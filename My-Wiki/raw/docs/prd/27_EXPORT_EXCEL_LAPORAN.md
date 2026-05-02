# 27. Export / Import — Laporan Excel (MVP)

[← Index](00_INDEX.md) · [Settings](16_SETTINGS.md)

---

## Metadata dokumen

| Field | Nilai |
|---|---|
| **Status** | Draft PRD — menunggu review |
| **Versi** | 0.2 |
| **Tanggal** | 2026-04-29 |
| **Platform MVP** | Android |
| **Library Excel** | [`syncfusion_flutter_xlsio`](https://pub.dev/packages/syncfusion_flutter_xlsio) |
| **Titik masuk** | `Settings` → tile **Export / Import** (`lib/features/settings/view/ui/settings_page.dart`, section DATA) |

---

## 1. Ringkasan & tujuan

User dapat membuka halaman **Import / Export**, memilih mode **Export**, format **Excel** (MVP), rentang **periode**, **lingkup data** (opsional: hutang/piutang dan transfer), lalu menghasilkan file `.xlsx` yang siap dibuka di Microsoft Excel / Google Sheets.

**Aturan besar (keputusan produk terkini):**

| Data | Periode export | Di Sheet 1 (Dashboard)? |
|---|---|---|
| **Pemasukan & pengeluaran** | **Wajib** ikut periode yang dipilih | **Ya** — total pemasukan, pengeluaran, saldo akhir, pie, dan bar **hanya** dari data ini |
| **Transfer antar dompet** | Opsional (centang); bila disertakan, baris transfer **difilter periode** yang sama | **Tidak** — transfer **tidak** mempengaruhi angka maupun grafik di Dashboard |
| **Hutang / piutang** | Opsional (centang); **bukan** filter periode | **Tidak** — sheet terpisah dengan cakupan **total / seluruh buku** |

**Di luar scope MVP (fase ini):**

- **Import** — hanya placeholder **“Segera hadir”** (bukan implementasi).
- **PDF & CSV** — tampil di UI sebagai pilihan dengan label **“Segera hadir”** atau nonaktif; tidak generate file.

---

## 2. User stories

1. Sebagai user, saya ingin dari Pengaturan masuk ke **Import / Export** agar satu tempat mengelola backup/laporan data.
2. Sebagai user, saya ingin **mengekspor laporan keuangan ke Excel** untuk periode yang saya pilih, dengan **pemasukan & pengeluaran selalu ikut**.
3. Sebagai user, saya ingin **mencentang opsi** untuk menyertakan **Hutang/Piutang** dan/atau **Transfer** pada file yang sama.
4. Sebagai user, saya ingin melihat **progres / status** saat data besar diambil, dan bisa **membatalkan** tanpa file tersisa membingungkan.
5. Sebagai user, jika pengambilan data lama (>15 detik), saya ingin opsi **“Hentikan dan buat sekarang”** agar Excel tetap dibuat dari data yang sudah terkumpul.
6. Sebagai user, saya ingin file tersimpan di folder **Download** Android dan mudah dibuka/dibagikan.

---

## 3. Alur navigasi & UI

### 3.1. Pengaturan

- Tile **Export / Import** (ikon tetap, label dari `l10n.profileExportImport`) **aktif** (`onTap` ke rute baru).
- Hapus badge “Coming soon” pada tile ini setelah fitur export aktif (subtitle bisa diarahkan ke ringkasan terakhir atau dikosongkan — detail copy dapat disepakati saat implementasi).

### 3.2. Halaman hub: Import / Export

Struktur layar disarankan:

1. **Segment / tab / choice chips:** `Export` | `Import`
2. **Import:** kartu atau panel dengan ilustrasi ringan + teks **“Segera hadir”** + penjelasan satu baris (tanpa aksi utama).
3. **Export:**
   - **Format file:** radio atau segmented control — **Excel (.xlsx)** aktif; **PDF**, **CSV** = “Segera hadir” (disabled atau tap menampilkan snackbar informatif).
   - **Periode:** kontrol yang konsisten dengan pola app (mis. date range atau preset Minggu/Bulan/Tahun + custom range). Berlaku untuk **pemasukan/pengeluaran** dan untuk **transfer** (jika opsi transfer aktif). **Tidak** memfilter **hutang/piutang** (lihat §4.4).
   - **Lingkup konten file (opsional):**
     - **Pemasukan & pengeluaran:** tampil sebagai bagian yang **selalu aktif** (nonaktifkan toggle atau teks “Selalu disertakan”) agar jelas bagi user.
     - **Sertakan Hutang / Piutang:** toggle/checkbox **mati default**; jika hidup, sheet Hutang Piutang dibuat dengan aturan §4.4.
     - **Sertakan Transfer:** toggle/checkbox **mati default**; jika hidup, sheet Transfer dibuat (§4.5), data transfer **sesuai periode** yang dipilih.
   - Tombol utama: **“Buat laporan”** / **“Export”** (disabled sampai periode valid).
   - Area info (opsional): menjelaskan bahwa Dashboard hanya mencerminkan pemasukan/pengeluaran periode, bukan transfer.

### 3.3. Layar / overlay loading & pembatalan

Saat proses berjalan (gabungan fetch + compose workbook):

1. **Teks utama:** mis. *“Mohon tunggu, data Anda sedang diproses…”*
2. **Indikator progres** (determinate jika chunk counter tersedia; jika tidak, indeterminate + langkah tekstual).
3. **Tombol `Batalkan`:**
   - Menghentikan fetch chunk berikutnya **untuk semua alur** yang sedang berjalan (termasuk hutang/piutang jika sedang di-fetch).
   - Membatalkan compute/`save` jika belum dimulai; **tidak** menulis file parsial ke disk (atau hapus file tmp jika sempat dibuat).
   - Menutup overlay dan kembali ke state semula.
4. **Setelah ≥ 15 detik** sejak loading tampil **dan** proses belum selesai:
   - Tampilkan tombol tambahan **“Hentikan dan buat sekarang”**:
     - Set flag **partial mode**: hentikan loop fetch chunk **untuk alur yang per-periode** (pemasukan/pengeluaran dan transfer bila ada); untuk **hutang/piutang**, putuskan konsisten: **juga hentikan** jika masih streaming, atau biarkan selesai karena satu batch — dokumentasikan di implementasi supaya tidak hung.
     - Lanjutkan pipeline **hanya** dengan dataset yang sudah ada di memori → generate Excel → simpan.
     - Di UI sukses (atau di sheet Dashboard), tampilkan **peringatan singkat** bahwa laporan **mungkin tidak lengkap** (copy disepakati, mis. banner atau snackbar sekali).

**Edge case:** Jika user tekan “Hentikan dan buat sekarang” saat **belum ada satupun** baris terambil untuk **pemasukan/pengeluaran** periode, tampilkan error ramah atau nonaktifkan tombol sampai chunk pertama selesai (disarankan: minimal 1 chunk sukses untuk jalur inti sebelum partial diizinkan).

---

## 4. Spesifikasi workbook Excel (`.xlsx`)

Semua sheet menggunakan **mata uang IDR** di mana relevan. Nama file disarankan: `SakuRapi_Laporan_YYYYMMDD_HHmm.xlsx` (timezone **Asia/Jakarta** konsisten dengan PRD utama).

### 4.0. Daftar sheet & urutan

Workbook **minimal** memuat **3 sheet** berikut (selalu ada ketika export Excel sukses):

| # | Nama sheet | Konten |
|---:|---|---|
| 1 | `Dashboard` | Ringkasan + grafik **hanya** dari pemasukan & pengeluaran **periode** |
| 2 | `Data Transaksi` | Hanya **Pemasukan** & **Pengeluaran** dalam **periode** (tanpa transfer) |
| 3 | `Analisis Kategori` | Agregasi pengeluaran per kategori dari Sheet 2 |

**Sheet tambahan** hanya jika user mengaktifkan opsi saat export:

| Opsi UI | Nama sheet | Konten |
|---:|---|---|
| Sertakan Hutang / Piutang | `Hutang Piutang` | §4.4 |
| Sertakan Transfer | `Transfer` | §4.5 |

Urutan disarankan: setelah Sheet 3, **Hutang Piutang** (jika ada) lalu **Transfer** (jika ada). Implementasi chart di Dashboard cukup merujuk Sheet 2 & 3 (posisi tetap).

### 4.1. Sheet 1 — `Dashboard`

| Area | Requirement |
|---|---|
| Judul | Teks **“Laporan Keuangan SakuRapi”** (font size menonjol, merge cell sesuai desain). |
| Periode | Tanggal periode laporan **yang dipilih user** (format konsisten, mis. `01 Apr 2026 – 30 Apr 2026`). Hanya membingkai **cakupan pemasukan/pengeluaran** & grafik harian; **bukan** periode hutang/piutang. |
| Ringkasan | **3 kotak**: **Total pemasukan**, **Total pengeluaran**, **Saldo akhir** — background **beda warna** tiap kotak. Nilai dihitung **hanya** dari transaksi yang masuk **Sheet 2** (pemasukan + pengeluaran periode, **tanpa transfer**). **Transfer tidak boleh** masuk ke ketiga angka ini. Saldo akhir untuk sheet ini = **Total pemasukan − Total pengeluaran** pada dataset yang sama (definisi selaras produk; jika app punya definisi saldo berbeda, samakan dengan laporan arus kas periode, bukan posisi seluruh dompet). |
| Grafik | **Pie chart**: sumber = **Sheet 3** (porsi **pengeluaran** per kategori). |
| Grafik | **Bar chart**: tren **harian** pemasukan vs pengeluaran; sumber agregasi harian dari **Sheet 2** saja. |

**Catatan teknis:** Verifikasi API `syncfusion_flutter_xlsio` untuk **Chart** dan referensi range antar-sheet; jika batasan library, fallback (mis. tabel ringkasan harian) + catat di tiket.

### 4.2. Sheet 2 — `Data Transaksi`

**Lingkup baris:** hanya transaksi bertipe **Pemasukan** dan **Pengeluaran** yang **tanggalnya** berada dalam **periode export**. **Baris transfer tidak ada** di sheet ini (mereka ada di Sheet `Transfer` jika opsi aktif).

**Kolom (urutan):**

`No` · `Tanggal` · `Tipe` (teks **Pemasukan** / **Pengeluaran**) · `Kategori` · `Catatan` · `Dompet` · `Nominal`

| Aspek | Requirement |
|---|---|
| **Tanpa kolom Sub-Kategori** | Hanya satu kolom **`Kategori`**. Tidak ada istilah sub-kategori di header atau dokumen ini. |
| **Satu baris per transaksi induk** | Termasuk transaksi **multi-item**: **satu baris** dengan `Nominal` = `totalAmount` induk. |
| **Kolom `Kategori`** | Nama kategori untuk tampilan satu baris: **gabungan unik** nama kategori dari semua item (urut `sort_order`), dipisah mis. `; `. Jika hanya satu item, isi = nama kategori item tersebut. |
| **`Catatan`** | Berisi `note` transaksi induk (jika ada). **Lalu** ditambahkan ringkasan **multi-item**: untuk tiap item, sertakan informasi yang relevan (mis. nama item / label, nominal baris) sehingga rincian banyak item **tidak hilang** — format implementasi tetap konsisten (contoh: baris baru dalam sel atau pemisah ` \| `). |
| Nominal | Format **IDR**. |
| Header | **Freeze panes** baris judul. |
| Baris | **Warna selang-seling** (banded rows) untuk isi tabel. |
| Tipe — warna teks | **Pemasukan** → teks **hijau**; **Pengeluaran** → teks **merah** (**disarankan** pada kolom `Tipe` dan `Nominal`). |
| Lebar kolom | **Auto-fit** + buffer kecil. |

### 4.3. Sheet 3 — `Analisis Kategori`

| Kolom | Deskripsi |
|---|---|
| `Nama Kategori` | Kategori **pengeluaran** (sesuai granularitas yang dipakai untuk mengisi Sheet 2 — konsisten dengan pengelompokan dari item). |
| `Total Nominal` | SUM nominal per kategori untuk **pengeluaran** dari Sheet 2. |
| `Persentase (%)` | `Total kategori / Total pengeluaran * 100`, format persen; handle pembagian nol. |

Sheet ini **men-feed** Pie Chart di Dashboard. Urutan baris: descending by total (opsional).

### 4.4. Sheet `Hutang Piutang` (opsional)

Hanya dibuat jika user mencentang **Sertakan Hutang / Piutang**.

**Cakupan data — bukan periode export**

- **Ringkasan di bagian atas** (selalu **global / total** untuk buku user):  
  **Total hutang yang belum dibayar** dan **Total piutang yang belum dibayar** (definisi selaras app: mis. agregasi `remaining > 0` atau status **Belum Lunas** — samakan dengan `DebtLoanTransactionModel` / `DebtStatusEnum`).
- **Tabel:** memuat **seluruh** record hutang/piutang yang relevan untuk ekspor (**tidak difilter** oleh tanggal periode yang dipilih di layar export). Jika perlu batas teknis (mis. max baris), catat sebagai P2; MVP tampilkan full set.

**Kolom tabel:**

`No` · `Tanggal` · `Tipe` (**Hutang** / **Piutang**) · `Nama Orang` · `Nominal` · `Jatuh Tempo` · `Status` (**Lunas** / **Belum Lunas**) · `Catatan`

| Aspek | Requirement |
|---|---|
| Conditional format | **Belum Lunas** → background baris **kuning**. **Lunas** → **hijau** muda. |
| Lebar kolom | Auto-fit seperti sheet transaksi. |

### 4.5. Sheet `Transfer` (opsional)

Hanya dibuat jika user mencentang **Sertakan Transfer**.

**Lingkup baris:** transaksi **transfer** antar dompet yang **tanggalnya** dalam **periode export** (sama seperti filter waktu untuk Sheet 2).

**Kolom (disarankan, disesuaikan dengan model app):**

`No` · `Tanggal` · `Dompet Asal` · `Dompet Tujuan` · `Nominal` · `Catatan`

| Aspek | Requirement |
|---|---|
| Nominal | Format **IDR**. |
| Dashboard | Angka di Sheet 1 **tidak** memasukkan baris ini. |
| Header / baris | Freeze header; banded rows opsional (disarankan konsisten dengan Sheet 2). |
| Lebar kolom | Auto-fit. |

---

## 5. Strategi data & performa

### 5.1. Prinsip

- **Pemasukan/pengeluaran periode:** hindari memuat setahun penuh sekaligus tanpa chunk; **pagination / chunk** berbasis tanggal atau cursor.
- **Transfer (jika aktif):** jalur fetch serupa, **filter periode**.
- **Hutang/piutang (jika aktif):** biasanya satu atau beberapa query agregat + list; tetap paginate jika record sangat banyak; **tidak** terikat tanggal periode UI.
- **Gabungkan** hasil ke DTO ringan sebelum menulis workbook; agregasi berat di **isolate** (`compute()`).

### 5.2. Mekanisme yang disyaratkan

1. **Chunked fetch** untuk transaksi per-periode (income/expense dan transfer terpisah atau filter gabungan di server — efisiensi keputusan tech lead).
2. **Isolate / compute** untuk agregasi harian, grouping kategori, dan penyusunan baris Excel.
3. **Cancellation** dengan flag / `CancelableOperation`; cek tiap chunk.
4. **Partial export:** Sheet 2, 3, dan Dashboard mencerminkan **hanya** data periode yang terambil; jika hutang/piutang sempat ter-load sebelum batal, dokumentasikan apakah sheet hutang ikut parsial atau di-skip.

### 5.3. Backend (Supabase / RPC)

- Query **terfilter server-side** (`date` between untuk jalur periode; hutang tanpa filter tanggal periode tersebut).
- Hindari N+1; pertimbangkan RPC khusus export untuk skala besar (opsional).

---

## 6. Penyimpanan file & izin (Android)

| Item | Requirement |
|---|---|
| Lokasi | **Folder Download** publik Android. |
| Nama file | Unik, pola §4. |
| Izin | Sesuai API level (scoped storage / `FileProvider`). |
| Berbagi | Intent buka / bagikan. |

---

## 7. Setelah export selesai

1. Dialog sukses: “Disimpan ke Unduhan”, tombol **Buka file** & **Bagikan**; pratinjau dalam app opsional.
2. Analytics (opsional P2): `export_excel_success`, `export_excel_cancel`, `export_excel_partial`.

---

## 8. Keputusan terbuka (tersisa)

1. **Chart Syncfusion:** verifikasi Pie + Bar + referensi antar-sheet pada versi terkunci; fallback jika perlu.
2. **Definisi “Saldo akhir” di Dashboard:** apakah strictly **pemasukan − pengeluaran** periode pada sheet, atau harus selaras metrik lain di app (jika beda, spesifikasi angka di UI Excel).
3. **iOS / desktop:** out of scope MVP atau abstraksi path simpan.

---

## 9. Kriteria penerimaan (acceptance)

- [ ] Hub Import/Export: Import “Segera hadir”; Export dengan periode + opsi Hutang/Piutang & Transfer.
- [ ] **Pemasukan & pengeluaran** selalu tersedia di file; **Dashboard** hanya dari keduanya (tanpa transfer).
- [ ] Sheet 2: kolom **`Kategori` + `Catatan`** saja (tanpa Sub-Kategori); multi-item tercermin di **Catatan**; satu baris per transaksi.
- [ ] Sheet hutang (jika opsi): ringkasan **global** + tabel **tanpa filter periode export**; format baris lunas/belum lunas.
- [ ] Sheet transfer (jika opsi): **periode**; tidak mempengaruhi Dashboard.
- [ ] File `.xlsx` ke **Download**; freeze header, banding, warna tipe, IDR, auto-fit.
- [ ] Loading: **Batalkan**; setelah 15 detik **Hentikan dan buat sekarang** + peringatan partial bila relevan.

---

## 10. Dependensi & rujukan kode

| Resource | Path / catatan |
|---|---|
| Settings tile | `lib/features/settings/view/ui/settings_page.dart` |
| Model transaksi | `lib/features/transaction/models/transaction_model.dart`, `transaction_item_model.dart` |
| Model hutang | `lib/features/debt_loan/models/debt_loan_transaction_model.dart` |
| Aturan bisnis | `My-Wiki/raw/docs/prd/04_ATURAN_KEUANGAN.md`, `11_HUTANG_PIUTANG.md` |
| Router | Rute baru ke hub Import/Export |

---

## 11. Rilis berikutnya (backlog singkat)

- Export **PDF** / **CSV**
- **Import** dari Excel
- Pratinjau dalam app + l10n EN
- RPC khusus export / batang progres multi-jalur

---

*PRD v0.2 — revisi lingkup export (hutang global, transfer terpisah, Dashboard tanpa transfer), Sheet 2 satu kolom Kategori + catatan multi-item.*
