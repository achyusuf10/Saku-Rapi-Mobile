# Analisis Fitur Budget — SakuRapi

> Dokumen ini menjelaskan seluruh business logic, flow, dan tampilan fitur **Budget (Anggaran)** di SakuRapi, ditulis agar dapat dipahami oleh user. Di bagian akhir terdapat analisa masalah UX beserta rekomendasi perbaikan.

**Tanggal analisis:** 2026-03-31

---

## 1. Ringkasan Fitur

Fitur Budget membantu user **membatasi pengeluaran** per kategori dalam periode waktu tertentu. User bisa melihat secara visual berapa yang sudah terpakai, berapa sisa anggaran, dan apakah pengeluarannya masih "on track" atau sudah melewati limit.

**Contoh penggunaan:**
- "Bulan ini saya hanya mau belanja Makanan maksimal Rp 2.000.000."
- "Kuartal ini, budget Transportasi saya Rp 3.000.000, berlaku di semua dompet."
- "Setiap bulan, otomatis buat ulang budget Entertainment Rp 500.000 untuk dompet BCA."

---

## 2. Aturan Business Logic

### 2.1 Budget Hanya untuk Pengeluaran (Expense)
Budget **hanya berlaku** untuk kategori bertipe `expense`. Tipe transaksi berikut **tidak dihitung** ke dalam budget:
- Income (pemasukan)
- Transfer antar wallet
- Adjustment (koreksi saldo)
- Transfer to Asset (beli investasi)
- Debt / Loan (hutang / piutang)
- Settlement hutang/piutang

### 2.2 Scope Budget: Global vs Per-Wallet
Setiap budget memiliki scope:
- **Global (Semua Dompet):** Menghitung pengeluaran dari semua wallet user. Field `wallet_id = null`.
- **Spesifik Wallet:** Hanya menghitung pengeluaran dari satu wallet tertentu. Misal hanya mengawasi pengeluaran Makanan dari dompet "BCA".

### 2.3 Periode Budget
Budget mendukung 5 tipe periode:

| Tipe Periode | Rentang |
|---|---|
| **Weekly** | Senin s/d Minggu minggu ini |
| **Monthly** (default) | Tanggal 1 s/d akhir bulan ini |
| **Quarterly** | Awal kuartal s/d akhir kuartal (Q1: Jan–Mar, Q2: Apr–Jun, dst.) |
| **Yearly** | 1 Januari s/d 31 Desember tahun ini |
| **Custom** | Rentang tanggal bebas yang dipilih user |

### 2.4 Recurring (Otomatis Berulang)
User bisa mengaktifkan toggle **Recurring** agar budget otomatis di-clone ke periode berikutnya saat periode saat ini berakhir. Budget baru akan:
- Memiliki tanggal mulai = hari setelah budget lama berakhir
- Durasi sama dengan budget lama
- Nominal (amount) sama
- `used_amount` reset ke 0
- Flag notifikasi reset

**Catatan teknis:** Fitur ini berjalan via fungsi `auto_renew_budgets()` yang dijadwalkan harian oleh pg_cron di database.

### 2.5 Deteksi Duplikasi
Saat user membuat budget baru, sistem mengecek apakah sudah ada budget aktif **dengan kombinasi yang sama:**
- Kategori yang sama
- Scope wallet yang sama (atau sama-sama global)
- Periode yang overlap (tanggal saling berpotongan)

Jika duplikat ditemukan, user mendapat dialog konfirmasi:
- **"Ganti"** — Hapus budget lama, buat yang baru (`replaceBudget`)
- **"Simpan Keduanya"** — Batal membuat budget baru

Jika tidak ada duplikat, budget langsung dibuat.

### 2.6 Perhitungan Pemakaian Budget (`used_amount`)
Pemakaian budget **dihitung otomatis oleh database** melalui trigger `update_budget_usage()`. Setiap kali ada transaksi expense (insert/update/delete), trigger ini:
1. Mengambil kategori dari item transaksi yang berubah.
2. Mencari semua budget aktif yang cocok (berdasarkan kategori, tanggal, dan wallet scope).
3. Menghitung ulang total pengeluaran untuk budget tersebut.
4. Mengupdate field `used_amount`.

**Penting:** Budget untuk kategori parent juga memperhitungkan pengeluaran dari semua child category-nya. Contoh: Budget "Makanan" juga menghitung transaksi untuk sub-kategori "Restoran", "Café", "Groceries", dll.

### 2.7 Validasi
Validasi dilakukan di level repository (bukan di UI):
- **Nominal > 0** — Budget harus punya amount positif.
- **Tanggal akhir ≥ tanggal mulai** — Periode tidak boleh terbalik.
- **Duplikasi** — Saat update, sistem mengecek duplikasi (exclude budget yang sedang diedit sendiri).
- **Kategori wajib dipilih** — Form tidak bisa disimpan tanpa kategori.

---

## 3. User Flow

### 3.1 Flow Membuat Budget Baru
```
Buka Tab Budget → Tekan tombol "Tambah Anggaran"
  → Form Budget terbuka (full screen)
  → Pilih Kategori (hanya kategori expense)
  → Isi Nominal
  → Pilih Periode (default: Bulan Ini)
  → Pilih Scope Wallet (default: Semua Dompet)
  → Toggle Recurring (opsional, default: off)
  → Tekan "Simpan"
  → Sistem cek duplikasi:
      ├─ Duplikat ditemukan → Dialog: "Ganti" atau "Simpan Keduanya"
      │   ├─ "Ganti" → Hapus budget lama, buat baru → Sukses
      │   └─ "Simpan Keduanya" → Batal
      └─ Tidak ada duplikat → Budget langsung dibuat → Sukses
  → Kembali ke halaman Budget (list ter-refresh)
```

### 3.2 Flow Edit Budget
```
Buka Detail Budget → Tekan ikon Edit (pensil) di AppBar
  → Form Budget terbuka dengan data terisi otomatis
  → Ubah field yang diinginkan
  → Tekan "Simpan"
  → Sistem cek duplikasi (kecuali budget diri sendiri)
      ├─ Duplikat → Error: "Sudah ada anggaran aktif untuk kategori dan periode yang sama"
      └─ Tidak duplikat → Update berhasil
  → Kembali ke halaman Budget (pop dari detail)
```

### 3.3 Flow Hapus Budget
```
Buka Detail Budget → Tekan ikon Hapus (tong sampah) di AppBar
  → Dialog Konfirmasi: "Hapus anggaran [nama kategori]?"
      ├─ "Hapus" → Budget dihapus → Kembali ke list
      └─ "Batal" → Tetap di halaman detail
```

### 3.4 Flow Filter & Navigasi
```
Halaman Budget:
  ├─ Wallet Filter (kanan atas): Pilih "Semua" atau wallet spesifik
  │   → List budget difilter, hanya tampil budget yang scope-nya cocok
  ├─ Tab Period: Pindah antar tab Weekly / Monthly / Quarterly / Yearly / Custom
  │   → Tab hanya muncul jika ada budget dengan tipe periode tersebut
  │   → Summary card dan list budget berubah sesuai tab
  ├─ Tap Budget Card → Navigasi ke Detail Budget
  └─ Tap "Anggaran Selesai" → Navigasi ke halaman Completed Budgets
```

### 3.5 Flow Auto-Refresh
Budget list otomatis di-refresh ketika user berpindah dari tab lain (misal History) kembali ke tab Budget. Ini memastikan data `used_amount` selalu terbaru jika user baru saja menambah transaksi.

---

## 4. Apa yang Ditampilkan di UI

### 4.1 Halaman Utama Budget (`BudgetPage`)
Terdiri dari beberapa bagian:

**A. AppBar:**
- Judul "Anggaran"
- Tombol wallet filter (dropdown): Semua / per-wallet

**B. Tab Bar Period (dinamis):**
- Hanya muncul jika ada lebih dari 1 tipe periode
- Label: Mingguan / Bulanan / Triwulan / Tahunan / Custom

**C. Summary Card (Gauge):**
- Gauge semicircle 180° yang menunjukkan rasio pemakaian budget
- Warna gauge berubah berdasarkan level:
  - 🟢 Hijau: < 60% (aman)
  - 🟡 Kuning: 60–79% (hati-hati)
  - 🟠 Oranye: 80–99% (mendekati limit)
  - 🔴 Merah: ≥ 100% (over budget)
- Label "Bisa Dibelanjakan" + nominal sisa (hijau jika positif, merah jika over)
- 3 kolom statistik: Total Anggaran, Total Terpakai, Sisa Hari

**D. Tombol "Tambah Anggaran"**

**E. Daftar Budget (grouped):**
- Budget dikelompokkan berdasarkan parent-child category
- Budget parent ditampilkan di atas dengan garis vertikal penghubung ke child
- Setiap card menampilkan:
  - Icon & nama kategori (warna sesuai kategori)
  - Nominal budget
  - Badge sisa/over budget (warna sesuai status)
  - Progress bar
  - Sisa hari

**F. Link "Anggaran Selesai"** → Menuju halaman budget expired

**G. Empty State** — Ditampilkan jika belum ada budget sama sekali

### 4.2 Halaman Detail Budget (`BudgetDetailPage`)
Menampilkan informasi lengkap satu budget:

**A. Header:**
- Icon kategori (warna)
- Nama kategori
- Nominal budget

**B. Seksi Progress:**
- Terpakai vs Sisa (2 kolom, berwarna)
- Progress bar dengan marker "Hari Ini" (menunjukkan posisi waktu saat ini relatif terhadap periode)
- Persentase pemakaian (misal "45%")

**C. Seksi Info:**
- Periode: dd/MM – dd/MM
- Sisa hari (misal "15 hari lagi" atau "Hari Ini")
- Scope wallet: nama wallet atau "Semua Dompet"

**D. Seksi Statistik (computed):**

| Metrik | Rumus | Kegunaan |
|---|---|---|
| **Rekomendasi Harian** | `amount / totalDays` | Idealnya user cuma belanja segini per hari |
| **Proyeksi Pengeluaran** | `(usedAmount / elapsedDays) * totalDays` | Jika laju pengeluaran tetap, total sampe akhir periode segini |
| **Rata-rata Harian Aktual** | `usedAmount / elapsedDays` | Rata-rata per hari yang sudah terjadi |

Warna peringatan:
- Proyeksi pengeluaran > nominal budget → warna merah
- Rata-rata harian > rekomendasi harian → warna kuning/warning

**E. Daftar Transaksi:**
- Semua transaksi expense dalam periode budget yang kategorinya cocok
- Termasuk transaksi dari child categories (jika budget untuk parent category)
- Tap transaksi → navigasi ke detail transaksi

**F. Aksi AppBar:**
- Edit (ikon pensil) → Buka form budget
- Hapus (ikon tong sampah, merah) → Dialog konfirmasi hapus

### 4.3 Halaman Budget Selesai (`CompletedBudgetsPage`)
- Daftar semua budget yang sudah melewati `end_date` (expired)
- Setiap card: kategori, progress, wallet scope
- Tap → navigasi ke detail budget
- Empty state jika belum ada

### 4.4 Form Budget (`BudgetFormSheet`)
Full-screen form untuk membuat/mengedit budget:

| Field | Tipe Input | Wajib | Default |
|---|---|---|---|
| Kategori | Picker (hanya expense) | Ya | — |
| Nominal | Currency field (format ribuan dengan titik) | Ya | 0 |
| Periode | Bottom sheet dengan preset + custom | Tidak | Bulan Ini |
| Scope Wallet | Bottom sheet: Global / per-wallet | Tidak | Semua Dompet |
| Recurring | Toggle checkbox | Tidak | Off |

Tombol "Simpan" hanya aktif jika kategori sudah dipilih dan nominal > 0.

---

## 5. Notifikasi Budget Alert

### 5.1 Kapan Alert Muncul
Alert budget **bukan** background job — dicek saat user membuka halaman Budget:
1. Saat budget list selesai di-load, `BudgetAlertChecker` dijalankan.
2. Cek semua budget aktif yang `isNearLimit` (≥ 80%) atau `isOverBudget` (≥ 100%).
3. Kirim **notifikasi lokal** jika flag terkait belum terkirim.

### 5.2 Level Notifikasi

| Threshold | Flag | Pesan |
|---|---|---|
| ≥ 80% (belum 100%) | `notification_sent_80` | "Anggaran [kategori] sudah terpakai 80%!" |
| ≥ 100% | `notification_sent_100` | "Anggaran [kategori] sudah melebihi limit!" |

**Prioritas:** Alert 100% dicek lebih dulu. Jika sudah over 100%, alert 80% **tidak** dikirim (untuk menghindari notifikasi ganda).

### 5.3 Prasyarat
- Setting `budget_alert_enabled = true` di notification settings user.
- User harus membuka halaman Budget agar pengecekan berjalan (bukan background worker).

---

## 6. Mekanisme Data & Cache

### 6.1 Alur Data
```
Supabase (Remote) → Cache ke Hive (Local) → Tampilkan di UI
                     ↑
                     └─ Fallback: jika network error, sajikan dari Hive cache
```

### 6.2 Computed Providers (Real-time dari State)
Beberapa metrik dihitung secara real-time dari state budget:
- **Total budget** = jumlah semua `amount` budget di tab/filter yang aktif
- **Total terpakai** = jumlah semua `used_amount`
- **Spendable** = total budget − total terpakai (minimum 0)
- **Usage ratio** = total terpakai / total budget
- **Budget over** = semua budget dengan `usedAmount ≥ amount`
- **Budget near limit** = semua budget dengan usage ratio ≥ 80% dan belum over

---

## 7. Analisa & Rekomendasi UX

Berdasarkan analisis mendalam terhadap kode sumber, berikut temuan masalah UX dan rekomendasi perbaikannya:

---

### 🔴 Masalah Kritis

#### 7.1 Recurring Budget Belum Berjalan (pg_cron Belum Aktif)
**Masalah:** Fungsi `auto_renew_budgets()` sudah ada di database, tapi jadwal pg_cron-nya masih **di-comment** (belum diaktifkan). Artinya jika user mengaktifkan toggle "Recurring", budget **tidak akan otomatis di-clone** ke periode berikutnya.

**Dampak:** User mengira budget-nya akan otomatis diperpanjang, tapi kenyataannya tidak. Bisa menyebabkan hilangnya kontrol anggaran di bulan berikutnya.

**Rekomendasi:**
- Aktifkan pg_cron extension di Supabase Dashboard.
- Uncomment schedule `auto_renew_budgets`.
- Atau, sebagai fallback, jalankan pengecekan recurring di sisi app saat budget list di-load (client-side auto-renew check).

---

#### 7.2 Transaksi di Detail Budget Tidak Menampilkan Transaksi Sub-Kategori (Parent Budget)
**Masalah:** Saat menampilkan daftar transaksi di halaman detail, sistem mengambil `category.children` dari data join. Namun query join budget (`*, categories(*), wallets(*)`) hanya mengambil **record kategori itu sendiri**, tanpa nested children. Akibatnya `category.children` kemungkinan kosong.

**Dampak:** Jika user membuat budget untuk kategori parent "Makanan", angka `used_amount` di progress bar sudah BENAR (karena trigger DB menghitung sub-kategori). Tapi daftar transaksi di halaman detail **mungkin tidak menampilkan** transaksi sub-kategori seperti "Restoran" atau "Café". Terjadi inkonsistensi: progress bar bilang Rp 500.000 terpakai, tapi list transaksi hanya menunjukkan sebagian kecil.

**Rekomendasi:**
- Buat query terpisah untuk mengambil child category IDs berdasarkan `budget.categoryId`.
- Atau join `categories` dengan children saat fetch budget.

---

#### 7.3 Replace Budget Tidak Atomik (Race Condition)
**Masalah:** Fungsi `replaceBudget()` di repository melakukan **dua operasi terpisah**: delete budget lama → create budget baru. Jika delete berhasil tapi create gagal (misal network error di tengah), budget lama hilang tanpa pengganti.

**Dampak:** User bisa kehilangan budget existing tanpa mendapat budget baru.

**Rekomendasi:**
- Gunakan RPC function di Supabase yang menggabungkan delete + insert dalam satu transaksi database (atomik).
- Atau setidaknya, jika create gagal, tampilkan error yang jelas dan sarankan user membuat budget baru secara manual.

---

### 🟠 Masalah Menengah

#### 7.4 Deteksi Period Saat Edit Hanya Mengenali "Bulan Ini"
**Masalah:** Fungsi `_detectPeriodKey()` di form hanya mengecek apakah tanggal cocok dengan **bulan ini**. Jika user mengedit budget yang dibuat dengan tipe "Weekly", "Quarterly", atau "Yearly", form akan menampilkannya sebagai "Custom".

**Dampak:** Saat mengedit budget quarterly, user melihat label "Custom (01/01 – 31/03)" alih-alih "Triwulan Ini". Membingungkan dan bisa memicu user mengubah periode tanpa sengaja.

**Rekomendasi:**
- Tambahkan deteksi untuk semua tipe periode (weekly, quarterly, yearly) berdasarkan tanggal start/end budget.
- Atau simpan `periodType` dari data budget lama dan gunakan langsung sebagai `_selectedPeriodKey`.

---

#### 7.5 Budget Masa Depan Tidak Terlihat
**Masalah:** Query `getActiveBudgets()` hanya mengambil budget yang `start_date ≤ today ≤ end_date`. Budget yang sudah dibuat untuk bulan depan **tidak akan muncul** di list sampai periodenya tiba.

**Dampak:** User tidak bisa melihat atau mengelola budget yang sudah dijadwalkan untuk periode mendatang. Mereka mungkin lupa pernah membuat budget tersebut.

**Rekomendasi:**
- Tambahkan section "Budget Mendatang" yang menampilkan budget dengan `start_date > today`.
- Atau perluas filter untuk menampilkan budget upcoming.

---

#### 7.6 Halaman Detail Tidak Di-refresh Setelah Edit
**Masalah:** Setelah berhasil mengedit budget dari halaman detail, sistem langsung melakukan `Navigator.pop()` — user dikembalikan ke list. State halaman detail **tidak di-update** dengan data baru.

**Dampak:** Jika user ingin memverifikasi perubahan yang baru dilakukan, harus membuka detail lagi. Flow terasa terputus.

**Rekomendasi:**
- Setelah edit sukses, refresh data budget di detail page (bukan pop langsung).
- Atau jika tetap pop, pastikan list budget sudah menampilkan data terbaru.

---

#### 7.7 Duplikasi Hanya Dicek Saat Create, Bukan Saat Edit (Perilaku Beda)
**Masalah:** Saat **create**, jika ada duplikat → dialog "Ganti atau Simpan Keduanya". Saat **edit**, jika terdeteksi duplikat → langsung error message "Sudah ada anggaran aktif untuk kategori dan periode yang sama". User tidak punya opsi untuk mengganti yang lama.

**Dampak:** Inkonsistensi UX. User bingung kenapa saat create boleh pilih "ganti", tapi saat edit langsung ditolak.

**Rekomendasi:**
- Samakan flow: saat edit terdeteksi duplikat, beri opsi yang sama (ganti / batal).
- Atau jelaskan alasan penolakan di error message secara lebih detail.

---

### 🟡 Masalah Ringan

#### 7.8 Spendable Menampilkan 0 Saat Over Budget (Bukan Negatif)
**Masalah:** Fungsi `calculateSpendable()` menggunakan `remaining > 0 ? remaining : 0`. Jika user sudah over budget Rp 200.000, yang ditampilkan di summary card adalah "Rp 0" — bukan "−Rp 200.000".

**Dampak:** User tidak tahu **seberapa banyak** mereka over budget. Mereka hanya tahu "sudah habis" tapi tidak tahu skala masalahnya.

**Rekomendasi:**
- Tampilkan angka negatif (misal "−Rp 200.000") dengan warna merah.
- Ini memberi motivasi lebih kuat untuk mengurangi pengeluaran.

---

#### 7.9 Completed Budgets Tanpa Pagination
**Masalah:** Query `getCompletedBudgets()` mengambil **semua** budget expired tanpa limit. Setelah beberapa tahun, data bisa mencapai ratusan.

**Dampak:** Loading lambat dan boros data di halaman "Anggaran Selesai".

**Rekomendasi:**
- Implementasikan pagination (misal 20 per halaman) dengan pakai visibility detector seperti di halaman riwayat. kalau bisa bikin global widgetnya untuk deteksi load more ini (Tampilkan jika loading, jika data sudah habis, jika loadmore error (ada button retry)), agar kedepannya bisa dipakai di fitur lain

---

#### 7.10 Tidak Ada Fitur Budget Rollover / Carry-Forward
**Masalah:** Jika budget bulan ini masih sisa Rp 300.000, sisa tersebut **hilang** saat budget kedaluwarsa. Budget recurring bulan depan selalu mulai dari Rp 0 terpakai.

**Dampak:** User yang berhemat di bulan ini tidak mendapat "hadiah" sisa budget buat bulan depan. Kurang memotivasi.

**Rekomendasi:**
- Tambahkan opsi "Carry-forward sisa" pada budget recurring — nominal budget bulan depan = amount + sisa bulan ini.
- Ini fitur umum di aplikasi budgeting populer.

---

#### 7.11 Tidak Ada Notifikasi 50% (Early Warning)
**Masalah:** Alert hanya ada di 80% dan 100%. User baru tahu saat sudah terlambat.

**Dampak:** Kurang proaktif dalam memberi peringatan awal.

**Rekomendasi:**
- Tambahkan threshold opsional 50% sebagai "info" (bukan warning).
- Bisa di-setting oleh user di notification preferences.

---

#### 7.12 Tidak Ada Konfirmasi Saat Menutup Form yang Sudah Diisi
**Masalah:** Jika user sedang mengisi form budget (sudah pilih kategori, isi nominal) lalu menekan tombol close (×), form langsung tertutup **tanpa peringatan**.

**Dampak:** Data yang sudah diisi hilang. User harus mengisi ulang dari awal.

**Rekomendasi:**
- Tambahkan dialog konfirmasi "Perubahan belum disimpan. Yakin keluar?" jika ada field yang sudah dimodifikasi (state dirty check).

---

#### 7.13 Custom Period Tidak Bisa Dibedakan di Tab Bar
**Masalah:** Jika user membuat dua budget custom dengan periode berbeda (misal "1 Feb – 20 Feb" dan "2 Feb – 10 Feb"), keduanya masuk ke **satu tab "Custom"** yang sama. Tab bar hanya menampilkan label generik "Custom" tanpa menunjukkan rentang tanggal masing-masing.

Ini terjadi karena provider `budgetAvailablePeriodTypesProvider` mengambil `periodType` dari semua budget lalu mengubahnya ke `Set` (type unik). Karena dua budget tersebut sama-sama bertipe `custom`, hanya satu tab "Custom" yang muncul.

**Dampak:**
- Kedua budget custom dicampur dalam satu tab, summary gauge-nya juga dihitung gabungan.
- User tidak bisa membedakan atau mengelola budget custom yang periodenya berbeda.
- "Sisa hari" di summary card mengambil **minimum** dari semua budget custom, yang bisa sangat menyesatkan. Misal budget pertama sisa 20 hari tapi budget kedua sisa 5 hari → yang tampil hanya "5 hari" untuk keseluruhan gauge.

**Rekomendasi:**
- Buat tab per-custom-budget dengan label yang menunjukkan rentang tanggal (misal "1/02 – 20/02").

---

#### 7.14 Period Default Selalu "Bulan Ini" Saat Buat Budget Baru
**Masalah:** Setiap kali buka form create, periode selalu default ke "Bulan Ini" — padahal user mungkin baru saja membuat budget quarterly dan ingin membuat budget quarterly lain.

**Dampak:** Friksi kecil tapi berulang.

**Rekomendasi:**
- Simpan periode terakhir yang dipilih user dan gunakan sebagai default untuk form berikutnya.
- Atau inherit dari tab yang sedang aktif di halaman budget.

---

## 8. Ringkasan Prioritas Perbaikan

| # | Masalah | Prioritas | Effort |
|---|---|---|---|
| 7.1 | pg_cron recurring belum aktif | 🔴 Kritis | Rendah (config saja) |
| 7.2 | Transaksi sub-kategori tidak tampil di detail | 🔴 Kritis | Sedang |
| 7.3 | Replace budget tidak atomik | 🔴 Kritis | Sedang |
| 7.4 | Deteksi period saat edit hanya "bulan ini" | 🟠 Menengah | Rendah |
| 7.5 | Budget masa depan tidak terlihat | 🟠 Menengah | Sedang |
| 7.6 | Detail tidak refresh setelah edit | 🟠 Menengah | Rendah |
| 7.7 | Duplikasi handling beda create vs edit | 🟠 Menengah | Rendah |
| 7.8 | Spendable 0 (bukan negatif) | 🟡 Ringan | Rendah |
| 7.9 | Completed budgets tanpa pagination | 🟡 Ringan | Sedang |
| 7.10 | Tidak ada budget rollover | 🟡 Ringan | Tinggi |
| 7.11 | Tidak ada notifikasi 50% | 🟡 Ringan | Rendah |
| 7.12 | Tidak ada konfirmasi tutup form | 🟡 Ringan | Rendah |
| 7.13 | Custom period tidak bisa dibedakan di tab bar | 🟠 Menengah | Sedang |
| 7.14 | Period default selalu "bulan ini" | 🟡 Ringan | Rendah |

---

## 9. Referensi File

| File | Deskripsi |
|---|---|
| `lib/features/budget/controllers/budget_controller.dart` | Controller utama + providers |
| `lib/features/budget/models/budget_model.dart` | Data model + computed properties |
| `lib/features/budget/repositories/budget_repository.dart` | Orkestrator remote + local + validasi |
| `lib/features/budget/datasource/budget_remote_data_source.dart` | Query Supabase |
| `lib/features/budget/datasource/budget_local_data_source.dart` | Cache Hive |
| `lib/features/budget/view/ui/budget_page.dart` | Halaman utama budget |
| `lib/features/budget/view/ui/budget_detail_page.dart` | Halaman detail budget |
| `lib/features/budget/view/ui/completed_budgets_page.dart` | Halaman budget selesai |
| `lib/features/budget/view/widgets/budget_form_sheet.dart` | Form create/edit budget |
| `lib/features/budget/view/widgets/budget_summary_card.dart` | Summary card dengan gauge |
| `lib/features/budget/view/widgets/budget_group_card.dart` | Card parent-child grouping |
| `lib/features/budget/view/widgets/budget_progress_bar.dart` | Progress bar berwarna |
| `lib/features/budget/view/widgets/budget_card_tile.dart` | Tile budget individual |
| `lib/features/notification/controllers/budget_alert_checker.dart` | Pengecekan alert budget |
| `supabase/migrations/*_003_triggers_functions.sql` | Trigger `update_budget_usage()` |
| `supabase/migrations/*_007_cron_storage.sql` | Function `auto_renew_budgets()` |
