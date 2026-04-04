# Product Requirements Document (PRD): Modul Investasi "SakuRapi"

## 1. Ringkasan Eksekutif
Fitur Investasi dalam aplikasi keuangan SakuRapi memungkinkan pengguna mencatat, memantau portofolio, dan melakukan transaksi jual-beli aset secara dinamis. Pendekatan pengembangan menggunakan prinsip *DRY (Don't Repeat Yourself)* pada antarmuka (penggunaan *Smart Form*) dan efisiensi *query database* (*BFF/Caching layer* untuk harga). 

**Tech Stack Target:**
* **Frontend:** Flutter (Mobile App).
* **Backend & Database:** Supabase (PostgreSQL, Edge Functions/Cronjob).

---

## 2. Arsitektur Data & Logika Kategori Aset

Setiap aset memiliki status aktif/inaktif. Jika total unit aset mencapai angka `0` (karena dijual semua), aset tersebut otomatis berstatus **Inaktif** dan disembunyikan dari daftar portofolio aktif di Dashboard.

Setiap transaksi pembelian/top-up pada semua kategori wajib memiliki *field* dasar: Tanggal Transaksi, Pilih Dompet Sumber, Toggle "Potong dari Dompet" (*Boolean*), Biaya Tambahan/Fee, dan Catatan.

### 2.1. Emas
* **Karakteristik Induk:** Memiliki "Nama Asset" dan "Jenis Emas" (Pilihan default: `Antam`, `Perhiasan`, ditambah opsi pembuatan `[Custom Jenis Emas]`).
    * *Constraint:* Pengguna dibatasi hanya boleh membuat maksimal **2** Jenis Emas Custom. Terdapat fitur CRUD untuk mengelola Jenis Emas Custom ini.
* **Satuan Unit:** Gram.
* **Harga Jual (Nilai Pasar):** Ditarik otomatis dari *database* Supabase. Harga referensi bisa dipilih: `antaremas.com` (Default), `logammulia.com`, atau `Manual Input` (diinput langsung oleh user).
* **Business Logic Rule:** Jika Jenis Emas yang dipilih adalah `Perhiasan`, sistem **wajib** memaksa/mengunci preferensi "Harga Jual" ke `Manual Input`.

### 2.2. Bitcoin
* **Karakteristik Induk:** Memiliki "Nama Asset". Difokuskan untuk Bitcoin (BTC).
* **Satuan Unit:** Desimal dinamis (mendukung hingga 8 angka di belakang koma / Satoshi).
* **Harga Jual (Nilai Pasar):** Ditarik otomatis dari *database* Supabase. Harga referensi bisa dipilih: `Indodax` (Default), `CoinGecko`, atau `Manual Input`.

### 2.3. Custom (Aset Lainnya)
* **Karakteristik Induk (Master Data):** Memiliki "Nama Asset" dan "Satuan" (misal: Lot, Lembar). 
    * *Constraint:* Maksimal *user* hanya bisa membuat **3** Master Kategori Custom.
* **Harga Jual (Nilai Pasar):** Bersifat statis berdasarkan `Manual Input` terakhir dari pengguna.
* **Architecture Rule:** Teks "Satuan" (misal: Lembar) **hanya disimpan di level Master/Induk**. Tabel riwayat transaksi hanya menyimpan angka/nominal unitnya saja. Jika "Satuan" diubah di pengaturan master, UI pada riwayat transaksi otomatis berubah mengikuti string satuan terbaru.

---

## 3. Spesifikasi UI/UX & Interaksi Halaman

### 3.1. Halaman Utama (Dashboard Investasi)
* **Total Porto (Header Card):**
    * Menampilkan Total Nilai Aset (IDR) secara besar.
    * Indikator Profit/Loss di bawahnya (*Hijau = Untung, Merah = Rugi*), dikalkulasi dari `Total Nilai Pasar - Total Modal`.
* **Daftar Aset Aktif:**
    * *Layout:* *Vertical scroll list* panjang.
    * *Filter Rule:* Hanya menampilkan aset dengan `total_unit > 0`.
    * *Section Headers:* Dikelompokkan berdasarkan kategori ("Emas", "Bitcoin", "Custom").
    * *Asset Card (ListTile):* Berisi Ikon Aset, Nama Aset, Jumlah Unit, Total Nilai IDR saat ini, dan persentase profit/loss.
* **Menu Aset Inaktif:** Terdapat *text button* di paling bawah daftar untuk melihat "Aset Inaktif" (Aset yang saldonya 0).

### 3.2. Halaman Detail Aset (Analitik & Riwayat)
Diakses dengan men-tap *Asset Card* di Dashboard.
* **App Bar:** Terdapat ikon *Settings/Gear* untuk membuka pengaturan Master Aset (*BottomSheet*).
* **Summary Card:** Menampilkan Nilai Total (Rp) dan komparasi *Current Market Price* vs *Average Buy Price*.
    * **Khusus Kategori Custom:** Terdapat ikon *Edit (Pencil)* kecil di sebelah nominal *Current Market Price*. Jika ditekan, muncul *Dialog Box* untuk meng-*update* nilai harga jual secara instan.
* **Quick Actions:** Tombol **[+ Top Up]** dan **[- Jual]** diletakkan berdampingan secara proporsional.
* **TabBar Riwayat:**
    * **Riwayat Beli:** Menampilkan daftar Top-Up. Data: Tanggal, Jumlah Unit (+), Harga Beli Eksekusi, Fee, Total IDR (Ikon Panah Hijau ke Bawah).
    * **Riwayat Jual:** Menampilkan daftar Pencairan. Data: Tanggal, Jumlah Unit (-), Harga Jual Eksekusi, Total IDR (Ikon Panah Merah ke Atas).

### 3.3. Smart Form (Create / Top-Up / Edit Transaksi)
Sistem menggunakan satu halaman *form* dinamis (`SmartFormScreen`). Visibilitas komponen, validasi, dan status *read-only* dirender berdasarkan **Mode Interaksi** dan **Kategori Aset**.

#### A. MODE 1: "CREATE NEW" (Buat Aset & Transaksi Pertama)
*Form* kosong dan interaktif penuh. Men-*trigger* RPC untuk membuat Master Aset sekaligus baris transaksi pertama.

* **Langkah 1: Pemilihan Kategori**
    * UI: 3 *Cards* di bagian atas (Emas | Bitcoin | Custom). Pilihan ini mendikte *field* apa yang muncul di bawahnya.
* **Langkah 2: Identitas Aset (Dinamis berdasarkan Kategori)**
    * **Jika EMAS:**
        * *Dropdown Jenis Emas:* Pilihan `Antam`, `Perhiasan`, `[+ Tambah Custom]`. Jika `[+ Tambah Custom]` ditekan, munculkan *TextField* baru "Nama Jenis Emas Baru" (Max 2 item custom di database).
        * *TextField Nama Asset:* (Contoh: "Emas Kawin").
        * *TextField Unit (Gram):* Harus > 0.
        * *TextField Harga Beli Per Unit.*
        * *Dropdown Sumber Harga Jual:* `antaremas.com`, `logammulia.com`, `Manual Input`. (Terkunci ke `Manual Input` jika jenis emas = Perhiasan).
    * **Jika BITCOIN:**
        * *TextField Nama Asset:* (Contoh: "Tabungan BTC").
        * *TextField Unit (BTC):* Mendukung desimal hingga 8 angka.
        * *TextField Harga Beli Total / Per Unit.*
        * *(Sumber Harga Jual disembunyikan. Default ke API Indodax di backend).*
    * **Jika CUSTOM:**
        * *Dropdown Kategori Custom:* Menampilkan daftar master yang ada + opsi `[+ Buat Kategori Baru]`. Jika opsi baru dipilih, render 2 *TextField* sebaris: "Nama Kategori" dan "Satuan" (Max 3 master kategori).
        * *TextField Nama Asset.*
        * *TextField Unit.* (Label dinamis mengikuti "Satuan" di atas).
        * *TextField Harga Beli.*
        * *TextField Harga Jual (Nilai Pasar):* Wajib diisi sebagai nilai awal aset.
* **Langkah 3: Data Transaksi Universal (Selalu Muncul)**
    * *DatePicker Tanggal Transaksi* (Default: Hari ini).
    * *TextField Biaya Tambahan/Fee.*
    * *Switch "Potong dari Dompet":* Jika `true`, munculkan *Dropdown* pilih Dompet Sumber.
    * *TextField Catatan.*

#### B. MODE 2: "TOP-UP" (Nabung Rutin Aset Eksisting)
Diakses dari Halaman Detail Aset. Hanya untuk menambah baris transaksi `buy`, **bukan** mengedit identitas aset.
* **Locked UI:** *Field* "Kategori", "Jenis Emas/Satuan", dan "Nama Asset" dirender sebagai `readOnly: true` (Latar warna abu-abu muda). *User* dilarang memindahkan transaksi ke aset lain.
* **Hidden UI:** *Field* "Preferensi Sumber Harga Jual" dihilangkan.
* **Active UI:** *User* hanya mengisi *field* transaksi: Tanggal, Unit Baru, Harga Beli Baru, Fee, Switch Potong Dompet, Dompet Sumber, dan Catatan.
* **Action:** Tombol "Simpan Top Up" men-*trigger* penambahan row ke `investment_transactions`.

#### C. MODE 3: "EDIT TRANSAKSI" (Revisi Riwayat Beli)
Diakses dengan men-tap salah satu *row* di Tab "Riwayat Beli".
* **UI Behavior:** Sama persis dengan Mode 2 (Identitas Aset dikunci), tetapi semua *field* transaksi diisi dengan *pre-filled data* historis.
* **Ekstra UI:** Terdapat ikon **Trash/Delete** (warna merah) di *AppBar*.
* **Sync Logic (Crucial):**
    * *Jika Edit Disimpan:* Backend/RPC harus melakukan *revert* saldo dompet lama, memotong saldo dompet baru (atau nominal baru), dan merealkalkulasi `Average Buy Price`.
    * *Jika Dihapus:* RPC menghapus *row* riwayat, mengembalikan dana secara utuh ke dompet utama, dan menghitung ulang total unit.

### 3.4. BottomSheet Jual (Pencairan)
Muncul dari bawah layar saat tombol **[- Jual]** ditekan.
* **UI Info:** Menampilkan "Sisa Saldo Unit".
* **TextField Unit Dijual:** *Validation Constraint:* Angka tidak boleh melebihi "Sisa Saldo Unit".
* **TextField Harga Jual Eksekusi:** *Pre-filled* dengan harga pasar saat ini, namun **Editable** (User bisa mengubah jika harga *deal* berbeda karena *spread*).
* **Switch "Tarik Pendapatan ke Dompet":**
    * *Jika OFF:* Hanya mencatat histori `sell` di `investment_transactions`.
    * *Jika ON:* Membuka dropdown pemilih dompet. Mencatat histori `sell` **DAN** menambahkan row "Pemasukan" ke tabel keuangan utama.

### 3.5. Pengaturan & Manajemen Master Aset
Diakses via ikon *Settings* di Halaman Detail Aset.
* **UI Dinamis:**
    * *Emas:* Edit Nama Asset, Jenis Emas, Preferensi Sumber Harga.
    * *Bitcoin:* Edit Nama Asset, Preferensi Sumber Harga.
    * *Custom:* Edit Nama Asset, Edit Satuan Asset.
* **Hapus Master Asset (Delete Parent):**
    * Tombol bahaya di paling bawah.
    * *Wajib memunculkan Alert Dialog:* "Semua riwayat (Beli & Jual) akan terhapus."
    * Terdapat *Checkbox Opsional*: "Kembalikan saldo dompet terkait?"

---

## 4. Backend & Integrasi (Supabase)

### 4.1. Edge Function Emas (Cronjob Pukul 09:00 WIB)
Dilarang *scraping* dari Flutter. Harus jalan di *server*.
* **Eksekusi Paralel (`Promise.all`):**
    * *Thread 1 (Antaremas):* Fetch via WordPress REST API -> Cari Regex `"Buyback per 1 Gr"`. Jika gagal, *fallback* ke AI.
    * *Thread 2 (LogamMulia):* Langsung gunakan AI Scraping Chain (System Prompt: *"Output murni JSON `{"buy": x, "sell": y}`"*).
    * *AI Fallback Chain:* Gemini -> Grok -> OpenRouter.
* **Database Action:** `INSERT` ke tabel `gold_prices` (Untuk *charting* di masa depan). Klien Flutter melakukan `SELECT ... ORDER BY created_at DESC LIMIT 1`.

### 4.2. Edge Function Bitcoin (Cronjob Setiap Jam `0 * * * *`)
* **Eksekusi Paralel:**
    * *Thread 1:* Indodax API (`https://indodax.com/api/ticker/btcidr`).
    * *Thread 2:* CoinGecko API (`https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=idr`).
* **Database Action:** `UPDATE` baris eksisting di tabel `bitcoin_prices` (Bukan *Insert*, agar tabel tetap kecil). Histori *chart* nantinya menembak langsung *endpoint public kline* API tersebut.

---

## 5. Edge Cases & Error Handling (Panduan Copilot)

Bagian ini mendefinisikan antisipasi teknis untuk kondisi tidak wajar (*anomalies*). Copilot **wajib** mengimplementasikan solusi berikut pada *UI validation* maupun *RPC layer*:

### 5.1. Edge Case: Perubahan Transaksi Menyebabkan Saldo Negatif
* **Masalah:** Saat di "Mode Edit Transaksi", *user* mengubah (menurunkan) jumlah Unit Beli di masa lalu sedemikian rupa sehingga kalkulasi (Total Unit Beli - Total Unit Jual) saat ini menjadi kurang dari `< 0`.
* **Solusi Logika (RPC):** Sebelum meng-*commit* edit atau menghapus transaksi beli, `RPC` harus memeriksa apakah `SUM(buy_units) - SUM(sell_units)` akan menjadi negatif. Jika ya, batalkan transaksi (*ROLLBACK*) dan lempar pesan *error* ke Flutter: *"Edit ditolak. Unit aset tidak boleh kurang dari riwayat penjualan."*

### 5.2. Edge Case: API Emas/Bitcoin Timeout atau Error 500
* **Masalah:** API Indodax *down* atau Edge Function `gold-price` gagal mengeksekusi *AI chain* karena limit *quota*.
* **Solusi Logika:** *Database* menggunakan arsitektur *Caching/BFF*. Aplikasi klien akan membaca harga terakhir (`Last Known Price`) dari tabel `gold_prices` atau `bitcoin_prices`. Tambahkan indikator UI di bawah harga pada aplikasi: *"Terakhir diperbarui: [Timestamp]*" agar *user* menyadari data sedang lambat tersinkronisasi.

### 5.3. Edge Case: Saldo Dompet Utama Tidak Cukup Saat Edit/Hapus
* **Masalah:** *User* menghapus transaksi `sell` investasi, yang berarti RPC harus me-*revert* (menarik kembali) pemasukan dari dompet utama. Namun, uang di dompet utama sudah habis dipakai untuk hal lain.
* **Solusi Logika:** Sistem SakuRapi harus mengizinkan saldo dompet utama menjadi negatif (*Negative Balance Allowance*) untuk menjaga integritas data matematis antar-tabel. Tampilkan peringatan visual di *Dashboard* dompet utama jika saldo menjadi merah.

### 5.4. Edge Case: Penjualan Keseluruhan Aset (Sell All)
* **Masalah:** *User* menjual seluruh sisa unit aset sehingga sisa saldo = `0.00`.
* **Solusi Logika:**
    * *Backend:* Trigger pada tabel transaksi atau pengecekan di dalam RPC `sell_investment` harus otomatis mengubah flag `is_active = false` pada `investment_assets`.
    * *Frontend:* Aset tersebut dihilangkan dari *list* atas dan dipindahkan ke dalam "Menu Aset Inaktif". Jika sewaktu-waktu *user* iseng melakukan "Top-Up" pada riwayat yang sudah inaktif ini, flag otomatis kembali ke `is_active = true`.

### 5.5. Edge Case: Satuan Custom Berubah
* **Masalah:** *User* memiliki aset Custom dengan 10 riwayat transaksi yang berlabel "Lot". Kemudian *user* mengedit master aset tersebut dan mengubah string menjadi "Lembar".
* **Solusi Logika:** Flutter UI **dilarang** melakukan *hardcode* atau menyimpan label string "Satuan" ke dalam model transaksi. Tabel transaksi hanya boleh me-`return` *value* desimal. UI harus selalu melakukan *mapping* label dengan cara membaca `asset.unit_label` dari objek *parent*.