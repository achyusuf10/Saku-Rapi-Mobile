````markdown name=docs/PRD_SakuRapi_Final_v6.0.md

# 📘 Product Requirements Document (PRD): SakuRapi — Final Edition v6.0

> **Dokumen ini adalah sumber kebenaran tunggal (Single Source of Truth) untuk pengembangan SakuRapi.**
> Semua keputusan teknis, desain, dan database HARUS mengacu ke dokumen ini.
> Dibuat: 2026-03-19 | Status: ✅ Final & Disetujui

---

## 1. Visi, Misi & Strategi Produk

| | |
|---|---|
| **Nama Aplikasi** | SakuRapi |
| **Tagline** | *"Catat keuangan rapi, tanpa capek ngetik."* |
| **Platform** | Android Only (min SDK 21 / Android 5.0) |
| **Masalah Utama** | *Friction* saat *input* manual membuat pengguna malas mencatat pengeluaran |
| **Solusi Utama (X-Factor)** | Asisten AI berupa **Voice Input (STT)** dan **Scan OCR (Kamera)** untuk *auto-fill* form transaksi |
| **Nilai Tambah** | Multi-Wallet, Parent-Child Budgeting, Wealth Management (Investasi), Laporan Visual |

---

## 2. Tech Stack & Aturan Arsitektur

### 2.1 Stack Utama
| Layer | Teknologi |
|---|---|
| **Frontend** | Flutter (dijalankan via FVM) |
| **State Management** | Riverpod |
| **Routing** | GoRouter |
| **Backend** | Supabase (Auth, PostgreSQL, Storage, Edge Functions) |
| **Local Storage** | Hive (Tema, Bahasa, Cache Kamus NLP, Cache Investasi API) |
| **AI & ML** | `google_mlkit_text_recognition` (OCR), `speech_to_text` (STT) |
| **Investasi API** | CoinGecko API (Kripto — Gratis) + GoldAPI.io atau scraping endpoint gratis (Emas) |
| **Icon** | FontAwesome Icons (`font_awesome_flutter`) — DILARANG pakai Material Icons |
| **Notifikasi** | `flutter_local_notifications` (untuk Budget Alert & Reminder) |

### 2.2 Aturan Arsitektur Kode (Mengacu `00_SakuRapi_Coding_Rules.md`)
- **3-File Pattern per Fitur:** `LocalDataSource` → `RemoteDataSource` → `Repository`
- **Model:** Plain Dart Class, wajib ada `copyWith`, `toMap()`, `fromMap()`. TANPA Freezed. Nama file & class diakhiri `Model`.
- **RemoteDataSource:** Semua fungsi WAJIB dibungkus `SupabaseHandler.call<T>(...)` dan me-return `DataState<T>`.
- **Repository:** Orkestrator, tangani `DataState` dengan `.map(success: ..., error: ...)`.
- **Lokalisasi:** WAJIB pakai `.arb`. DILARANG hardcode string di UI.
- **Responsivitas:** WAJIB pakai `ScreenUtil` (`.h`, `.w`, `.r`, `.sp`).
- **Tipografi:** WAJIB pakai `TextStyleConstants`.
- **Warna:** WAJIB pakai `context.colors.*`. DILARANG hardcode warna.
- **Loading/Dialog:** WAJIB pakai `context.showLoadingOverlay()`, `context.showAppAlert()`, `context.showConfirmDialog()`.
- **List Panjang:** WAJIB pakai `ListView.builder`, `SliverList`, atau `GridView.builder`.
- **Pagination:** Wajib diterapkan untuk data berpotensi masif dari Supabase (pakai visibility detector).
- **MCP Supabase:** WAJIB dipakai sebelum membuat Model atau RemoteDataSource. DILARANG menebak skema.
- **Logging:** `AppLogger.call` dengan format `[Sync Offline Online] [{NamaFitur}] {pesan}`.

### 2.3 Struktur Folder per Fitur
```
lib/features/{fitur}/
├── controllers/
├── datasource/
│   ├── {fitur}_local_datasource.dart
│   └── {fitur}_remote_datasource.dart
├── models/
├── repositories/
│   └── {fitur}_repository.dart
├── utils/
└── view/
    ├── ui/          ← Screen utama
    ├── widgets/     ← Widget spesifik fitur
    └── components/  ← Component spesifik fitur

lib/global/
├── widgets/         ← SakuButton, SakuTextField, SakuCard, dll.
└── services/        ← OcrService, VoiceService, TransactionParserService
```

### 2.4 Design System & Tema
- **Konsep:** Simpel, Elegan, Modern, Fancy
- **Tema Warna:** Hijau Soft sebagai primary color (contoh: `#4CAF82` atau sejenisnya)
- File `app_colors.dart` yang sudah ada **WAJIB diimprove** oleh AI:
  - Tentukan palet warna hijau soft yang harmonis (primary, secondary, accent, surface, background, error)
  - Pastikan ada versi Light Mode dan Dark Mode
  - Semua warna harus memiliki kontras yang cukup untuk aksesibilitas (WCAG AA)
- **Aset Icon:** Disimpan lokal di `assets/icons/` untuk ikon kategori kustom. Ikon UI umum pakai FontAwesome.

---

## 3. Garis Besar Fitur SakuRapi

| No | Fitur | Prioritas |
|---|---|---|
| 1 | Otentikasi & Profil (Google Sign-In) | 🔴 P0 |
| 2 | Manajemen Dompet (Multi-Wallet, CRUD) | 🔴 P0 |
| 3 | Dashboard & Ringkasan Cepat | 🔴 P0 |
| 4 | Transaksi Reguler (Income/Expense/Transfer/Debt/Adjust) | 🔴 P0 |
| 5 | Transaksi Multi-Item / Split Bill | 🟠 P1 |
| 6 | Asisten Voice Input (STT, maks 10 detik) | 🟠 P1 |
| 7 | Asisten Scan Struk OCR (Crop + Auto-Balance) | 🟠 P1 |
| 8 | Kamus Parsing AI (API + Cache Hive, TTL 24 jam) | 🟠 P1 |
| 9 | Riwayat & Navigasi Periode (Swipeable) | 🔴 P0 |
| 10 | Laporan Visual (Bar Chart & Donut Chart) | 🟠 P1 |
| 11 | Rincian Biaya (Expense Breakdown per Kategori) | 🟠 P1 |
| 12 | Manajemen Kategori (Parent-Child + Icon Picker) | 🔴 P0 |
| 13 | Manajemen Anggaran (Budgeting Parent-Child + Auto-Renew) | 🟠 P1 |
| 14 | Manajemen Investasi (Emas, BTC, Custom Asset) | 🟡 P2 |
| 15 | Notifikasi & Reminder (Budget Alert + Pengingat Rutin) | 🟡 P2 |

---

## 4. Penjelasan Detail Fitur & Flow

### A. Otentikasi & Profil
**Deskripsi:**
- Login hanya via Google Sign-In (Supabase Auth Google Provider).
- Setelah login sukses, **Supabase Database Trigger** otomatis menyinkronkan data dari `auth.users` ke tabel `public.users` (nama, email, avatar_url).
- **FLUTTER TIDAK PERLU** memanggil insert ke `public.users` secara manual — semua diurus Trigger.
- Profil dapat diedit (nama display, avatar dari galeri → upload ke Supabase Storage).

**Flowchart:**
```
Buka App → Cek Sesi Supabase
    ├── Sesi Ada → Dashboard
    └── Sesi Tidak Ada → LoginScreen
                            → Tap "Masuk dengan Google"
                            → Supabase Auth Google OAuth
                            → [TRIGGER DB] Upsert ke public.users
                            → Dashboard
```

---

### B. Dashboard & Ringkasan Cepat
**Deskripsi:**
- **Header:** Saldo Total (hanya dompet `exclude_from_total = false`), dengan toggle 👁️ sembunyikan nominal.
- **Wallet Preview:** Maks 3 dompet teratas. Dipisah visual antara "Diikutkan ke Total" vs "Dikecualikan". Ada tombol "Lihat Semua" → `WalletListScreen`.
- **Snapshot Chart:** Bar Chart Pemasukan vs Pengeluaran bulan berjalan.
- **Top Expenses:** 3–5 kategori terbesar dengan horizontal progress bar.
- **Recent Transactions:** 3 transaksi terbaru.
- **Expandable FAB:** Tap `+` → mekar ke 3 opsi: 🎙️ Voice, 📷 OCR, 📝 Manual.

**Flowchart Wallet Preview:**
```
Dashboard → Scroll "Dompet Saya" → Tap "Lihat Semua" → WalletListScreen (CRUD) → Back
```

---

### C. Manajemen Dompet (Multi-Wallet)
**Deskripsi:**
- CRUD lengkap. Saat **Create**, wajib ada field "Saldo Awal" (`initial_balance`).
- Field `icon` (FontAwesome icon name) dan `color` (hex string) untuk personalisasi.
- Toggle `exclude_from_total` untuk dompet investasi/tersembunyi.
- **Transfer Antar Dompet:** 1 record dengan `type = 'transfer'`, field `destination_wallet_id` terisi. Trigger DB mengurangi saldo asal & menambah saldo tujuan.
- **Sesuaikan Saldo (Adjustment):** Input nominal baru → sistem hitung selisih → buat 1 record `type = 'adjustment'` dengan kategori sistem "Penyesuaian Saldo". Trigger DB update saldo.

---

### D. Transaksi Manual & Multi-Item
**Deskripsi:**
- Form dengan **Progressive Disclosure**: field wajib terlihat (Nominal, Kategori, Dompet, Tanggal); field opsional (Catatan, Lampiran, Dengan Siapa) disembunyikan di balik tombol "Lebih Banyak".
- **Tab dalam form:** Pengeluaran | Pemasukan | Hutang/Piutang.
- **Mode Multi-Item (khusus Pengeluaran):** Default single-item. Tombol "+ Tambah Item" mengubah UI menjadi format list (Header Grand Total + detail item per baris). Setiap item punya nominal & kategori sendiri.
- **Hutang:** `type = 'debt'` → saldo dompet **naik** (uang masuk, tapi ada kewajiban bayar). Field `with_person` wajib diisi.
- **Piutang:** `type = 'loan'` → saldo dompet **turun** (uang keluar, tapi ada hak menagih). Field `with_person` wajib diisi.
- **Status Hutang/Piutang:** `status` bisa `'unpaid'` (default) atau `'paid'`. Saat dilunasi, buat 1 transaksi baru tipe kebalikannya untuk settle.
- **Transfer:** `type = 'transfer'`, TIDAK masuk laporan Income/Expense, butuh `destination_wallet_id`.
- **Adjustment:** `type = 'adjustment'`, otomatis pakai kategori sistem "Penyesuaian Saldo".

**Flowchart Multi-Item:**
```
FAB Tap 📝 → TransactionFormScreen (Tab Pengeluaran)
  → Tap "+ Tambah Item" → UI switch ke mode list
  → Isi Item 1 (Nominal + Kategori)
  → Tap "+ Tambah Item" lagi → Isi Item 2
  → Grand Total otomatis terakumulasi
  → Pilih Dompet & Tanggal → Tap "Simpan"
  → [TRIGGER DB] Kurangi saldo dompet → Insert transactions + transaction_items
```

### E. Asisten Voice Input (STT) AI-Powered
**Deskripsi:**
- User menahan tombol mic (maks 10 detik) untuk merekam suara (contoh input: *"Beli kopi kenangan dua puluh ribu pakai gopay"*).
- Suara diubah menjadi teks menggunakan package `speech_to_text`.
- **AI Processing Pipeline (Waterfall):**
  1. **Primary AI (Gemini Flash):** Teks dikirim ke Supabase Edge Function yang memanggil API Gemini Flash. Prompt diatur agar mengekstrak entitas dari kalimat (nominal, nama *merchant*, kategori, jenis dompet, dan tipe transaksi) menjadi JSON terstruktur.
  2. **Secondary AI (Grok):** Jika API Gemini *limit* atau *timeout*, Edge Function otomatis me-routing *request* teks yang sama ke API Grok dengan instruksi *prompt* yang sama.
  3. **Fallback (Local Manual):** Jika kedua API AI gagal/limit, teks dilempar kembali ke Flutter untuk diproses secara lokal menggunakan `TransactionParserService` (Regex + Kamus Hive).
- **Flowchart:**
  `Mic` → `speech_to_text (String)` → `Edge Function (Gemini/Grok)` → `Return JSON` → `Push TransactionFormScreen (Pre-filled)`

**Expected JSON Response (Kontrak Data dari Edge Function):**
Prompt AI di Supabase Edge Function **WAJIB** mengembalikan format JSON berikut agar dapat langsung di-mapping ke `TransactionModel` di Flutter:

```json
{
  "transaction_type": "expense", 
  "amount": 20000,
  "merchant_name": "Kopi Kenangan",
  "suggested_category": "Makanan & Minuman",
  "suggested_wallet": "GoPay",
  "notes": "Beli kopi kenangan",
  "date": "2026-03-23T07:25:00Z"
}

```


### F. Asisten Scan Struk OCR AI-Powered
**Deskripsi:**
- User memfoto struk transaksi (minimarket, restoran, dll) menggunakan kamera.
- Sistem akan memproses gambar untuk mengekstrak informasi secara mendetail, termasuk **nama barang, jumlah (qty), dan harga**, lalu memetakannya langsung ke form Transaksi Multi-Item.
- **AI Processing Pipeline (Waterfall):**
  1. **Primary AI (Gemini Flash Multimodal):** Foto struk dikirim ke Supabase Edge Function. AI di-prompt secara khusus untuk mengekstrak rincian struk menjadi format JSON terstruktur.
  2. **Secondary AI (Grok Vision/Text):** Jika Gemini limit/gagal, foto dikirim ke Grok API dengan instruksi prompt pengekstrakan rincian item yang persis sama.
  3. **Fallback (Local ML Kit):** Jika semua layanan Cloud AI limit/gagal, aplikasi menggunakan `google_mlkit_text_recognition` di lokal. Hasil teks mentah akan di-parsing oleh `TransactionParserService` lokal yang akan berusaha menangkap `Total Harga` saja jika rincian item terlalu sulit di-Regex.
- **UI Mapping:** Data JSON yang didapat dari AI akan otomatis mengisi layar `TransactionFormScreen` mode **Multi-Item**.
- **Flowchart:**
  `Foto Struk` → `Edge Function (Gemini/Grok)` → `Return JSON (beserta array rincian item & qty)` → `Push TransactionFormScreen (Mode Multi-Item, Pre-filled baris per baris, Foto attached)`

**Expected JSON Response (Kontrak Data dari Edge Function):**
Prompt AI di Supabase Edge Function **WAJIB** mengembalikan format JSON berikut agar dapat di-parsing oleh `TransactionItemModel` di Flutter:

```json
{
  "merchant_name": "Indomaret",
  "date": "2026-03-23T14:30:00Z",
  "total_amount": 45000,
  "suggested_category": "Kebutuhan Harian",
  "is_multi_item": true,
  "items": [
    {
      "item_name": "Kopi Kenangan Mantan",
      "qty": 2,
      "price_per_item": 15000,
      "subtotal": 30000,
      "notes": "2x Kopi Kenangan Mantan" 
    },
    {
      "item_name": "Roti Sobek Coklat",
      "qty": 1,
      "price_per_item": 15000,
      "subtotal": 15000,
      "notes": "1x Roti Sobek Coklat"
    }
  ]
}

```

### G. Kamus Parsing AI (API + Cache Hive)
**Deskripsi:**
- Kamus keyword-kategori disimpan di tabel `parsing_dictionaries` Supabase.
- App men-download kamus ini ke Hive. **TTL (Time-to-Live): 24 jam.**
- Flow: Cek timestamp cache di Hive → jika > 24 jam: fetch dari Supabase → simpan ke Hive + update timestamp.
- `TransactionParserService` menggunakan kamus dari Hive untuk matching.
- Jika keyword tidak ditemukan → fallback ke kategori "Lain-lain / Default".

---

### H. Riwayat & Navigasi Transaksi (History)
**Deskripsi:**
- **Tab History Utama:** Menampilkan layar riwayat dengan navigasi *swipeable* (geser kiri/kanan) untuk berpindah ke periode sebelum/selanjutnya.
- **Filter Periode Dinamis (Advanced Period Filter):** Terdapat *dropdown* / *bottom sheet* untuk mengubah rentang waktu laporan:
  - **Harian (Daily)**
  - **Mingguan (Weekly)**
  - **Bulanan (Monthly - Default)**
  - **Kuartal (Quarterly)**
  - **Tahunan (Yearly)**
  - **Custom Date Range:** Menggunakan *Date Range Picker* untuk memilih tanggal mulai dan akhir secara bebas.
- **Opsi Tampilan Daftar (View Mode Grouping):** Terdapat fitur/toggle untuk mengubah cara *list* transaksi dikelompokkan:
  1. **Berdasarkan Transaksi (Default):** Daftar di-grouping murni berdasarkan **Hari/Tanggal**. Tiap grup (*header* tanggal) menampilkan ringkasan total *income* & *expense* pada hari tersebut.
  2. **Berdasarkan Kategori:** Daftar di-grouping berdasarkan **Kategori** terlebih dahulu (misal: "Makanan & Minuman", "Transportasi"). Di dalam masing-masing *header* kategori tersebut, barulah rincian transaksinya diurutkan berdasarkan hari/tanggal.
- **Tab Perbandingan (Comparison View):** Sebuah sub-tab (berdampingan dengan Tab Daftar/List) yang menampilkan grafik atau ringkasan komparasi keuangan.
  - Skala waktu perbandingan **otomatis beradaptasi** dengan *Filter Periode* yang sedang aktif.
  - *Contoh Logika:* - Jika filter **Bulanan** aktif → Membandingkan performa Bulan Ini vs Bulan Lalu.
    - Jika filter **Mingguan** aktif → Membandingkan Minggu Ini vs Minggu Lalu.
    - Jika filter **Kuartal** aktif → Membandingkan Kuartal Ini vs Kuartal Sebelumnya.
- **Filter Dompet (Wallet Filter):** Semua riwayat dan perbandingan dapat difilter lebih spesifik hanya untuk Dompet (*Wallet*) tertentu atau "Semua Dompet".

**Catatan Teknis & State Management (Instruksi Wajib untuk AI / Developer):**
- **Single Fetch Policy:** *State management* (Riverpod) untuk layar ini WAJIB disiapkan agar mengolah satu sumber data (`List<TransactionModel>`) yang sama dari Supabase.
- *Fetching* data ke database (Supabase RPC/Query) HANYA boleh terjadi satu kali berdasarkan parameter **Rentang Tanggal (Date Range)** dan **Filter Dompet** yang sedang aktif.
- **Local Grouping:** Perubahan UI dari *View Mode Grouping* (mengelompokkan berdasarkan Hari vs Kategori) HANYA berupa *logic filtering/grouping* murni di sisi lokal Flutter menggunakan fungsi `groupBy` (bisa memanfaatkan *package* `collection`). DILARANG KERAS melakukan *query* ulang ke *database* hanya untuk mengubah mode tampilan (*grouping*), agar performa aplikasi tetap tinggi dan hemat *read operations* di Supabase.


---

### I. Manajemen Kategori
**Deskripsi:**
- Hierarki Parent-Child (maks 2 level).
- CRUD: User bisa tambah/edit/hapus kategori kustom.
- **Icon Picker:** Menggunakan FontAwesome icons. Ikon kategori kustom lokal disimpan di `assets/icons/`.
- Kategori default (`is_default = true`) tidak bisa dihapus, hanya bisa di-hide atau di-rename.
- Filter tampil berdasarkan `type` transaksi yang sedang aktif di form.

---

### J. Manajemen Anggaran (Budgeting) 🎯
**Deskripsi:**
- **Parent-Child Budget Logic:**
  - Jika budget diset di **Parent Category** (misal: "Belanja"), transaksi di semua child-nya (Bahan Makanan, Perlengkapan Rumah, dll.) **otomatis mengurangi saldo budget Parent** tersebut.
  - Budget bisa juga diset spesifik di **Child Category** saja.
- **Scope Budget:**
  - **Global:** Berlaku untuk semua transaksi di semua dompet (default).
  - **Per Dompet:** Budget hanya dihitung dari transaksi di dompet tertentu. Pilih via dropdown dompet (atau "Semua Dompet"). `wallet_id` di tabel `budgets` = NULL jika global.
- **Pembatasan Piutang:** Bisa set batas maksimal total piutang yang outstanding.
- **Auto-Renew (`is_recurring`):** Jika dicentang, sistem **secara otomatis meng-clone** budget ini untuk periode berikutnya (via Supabase Scheduled Edge Function atau pg_cron).
- **Color Coding Progress:**
  - `< 80%` → 🟢 Hijau
  - `80% – 99%` → 🟡 Kuning
  - `≥ 100%` → 🔴 Merah (Over Budget)
- **Notifikasi:** Kirim push notification saat budget mencapai 80% dan 100%.

**Flowchart:**
```
Tab Anggaran → Tap "Buat Anggaran"
  → Pilih Kategori (Expense / Piutang)
  → Isi Nominal & Rentang Waktu (start_date, end_date)
  → Pilih Scope: Semua Dompet / Dompet Tertentu
  → Centang "Ulangi Otomatis" (opsional)
  → Simpan → Tampil Progress Bar Dinamis
```

---

### K. Manajemen Investasi (Wealth Management) 💰
**Deskripsi:**
- Tab terpisah untuk mencatat & memantau aset investasi.
- **Tipe Aset:** Emas, BTC (Bitcoin), Custom (saham, reksa dana, dll.).
- **Harga Live:**
  - BTC: CoinGecko API (`https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=idr`)
  - Emas: GoldAPI atau endpoint gratis lain (fallback ke `custom_current_price` jika API gagal)
  - Cache Hive: Fetch ulang hanya jika cache > 1 jam (anti-rate limit). Bisa di-override via Pull-to-Refresh.
- **Profit/Loss:** Tampil persentase dan nilai absolut. Warna hijau (profit) / merah (loss).
- **Pembelian Aset — Potong Dompet:** Opsional centang "Potong dari Dompet [X]". Jika dicentang → buat 1 transaksi `type = 'transfer_to_asset'` → Trigger DB: saldo dompet turun, aset naik.

**Flowchart Beli Investasi:**
```
Tab Investasi → Fetch API (jika cache > 1 jam) → Tampil portofolio
  → Tap "Tambah" → Input: nama aset, jumlah, harga beli, tanggal
  → (Opsional) Centang "Potong dari Dompet [pilih dompet]"
  → Simpan
  → [TRIGGER DB] Saldo dompet turun + Aset naik
  → Tampil Profit/Loss real-time
```

---

### L. Notifikasi & Reminder 🔔
**Deskripsi:**
- **Budget Alert:** Kirim local notification saat penggunaan budget mencapai **80%** dan **100%**.
- **Reminder Catat Transaksi:** User bisa set jadwal pengingat harian (misal: "Ingatkan saya setiap jam 21:00 untuk catat pengeluaran hari ini"). Implementasi via `flutter_local_notifications` + `WorkManager` atau `AlarmManager`.
- **Piutang Jatuh Tempo:** Notifikasi pengingat jika ada piutang yang mendekati/melewati `due_date`.

---

### M. Tab Pengaturan (Settings & Preferences)
**Deskripsi:**
Tab khusus sebagai pusat kontrol preferensi pengguna dan konfigurasi aplikasi SakuRapi.

- **Daftar Menu Pengaturan:**
  1. **Edit Profil:** Pengguna dapat mengubah data personal seperti Nama dan mengelola otentikasi (Google Sign-In status).
  2. **Ganti Bahasa (Localization):** Pilihan untuk mengubah bahasa aplikasi (misal: Bahasa Indonesia, English). Perubahan akan langsung tersimpan di lokal (Hive) dan me-refresh UI tanpa perlu *restart*.
  3. **Ganti Tema (Theme):** Pilihan untuk mode tampilan: *Light Mode*, *Dark Mode*, atau *System Default*. Preferensi disimpan menggunakan Hive.
  4. **Manajemen Kategori:** Pintu masuk (*entry point*) untuk menuju layar Manajemen Kategori. Di sini pengguna bisa melakukan CRUD kategori kustom (Parent-Child) dan memilih *icon*.
  5. **Export / Import Data:**
     - Fitur untuk membackup atau memulihkan data transaksi.
     - **Status Saat Ini:** Jika menu ini di-tap, wajib memunculkan *Dialog* atau *Snackbar* informatif: *"Fitur masih dalam tahap pengembangan (Coming Soon)"*.

---

## 5. Nilai Default Kategori

Saat aplikasi pertama kali dijalankan (onboarding), atau akun baru dibuat, **Supabase Trigger/Function** otomatis mengisi tabel `categories` dengan data default berikut (`is_default = true`, `user_id = user baru`):

### A. PENGELUARAN (Expense) 🔴

| Parent | Child |
|---|---|
| **Kebutuhan Rumah Tangga** | Belanja Dapur / Bahan Makanan |
| | Perlengkapan Rumah |
| | Makan di Luar / Jajan |
| **Kesehatan & Kebugaran** | Olahraga / Gym |
| | Suplemen & Nutrisi |
| | Medis / Dokter / Obat |
| **Transportasi** | Bensin / Tol / Parkir |
| | Transportasi Umum / Ojol |
| | Servis Kendaraan |
| **Tagihan & Kewajiban** | Listrik & Air |
| | Internet & Pulsa |
| | Cicilan / Asuransi |
| **Teknologi & Edukasi** | Langganan Digital |
| | Kursus / Buku |
| | Server & Hosting |
| **Keluarga & Sosial** | Kebutuhan Pasangan |
| | Kondangan / Donasi |
| | Nongkrong / Hiburan |
| **Lain-lain** | Biaya Admin / Pajak / Selisih |
| | Pengeluaran Tak Terduga |

### B. PEMASUKAN (Income) 🟢

| Parent | Child |
|---|---|
| **Gaji & Pendapatan Utama** | Gaji Bulanan |
| | Bonus / THR |
| **Pendapatan Tambahan** | Pekerjaan Sampingan / Freelance |
| | Hasil Investasi / Dividen |
| | Pencairan Dana |
| **Lain-lain** | Hadiah / Pemberian |

### C. HUTANG / PIUTANG 🟠
Tidak memakai hierarki Parent-Child. Identifikasi orang via field `with_person`.

### D. SISTEM (Auto-Generated, `user_id = NULL`)
| Nama Kategori | Dipakai Untuk |
|---|---|
| Penyesuaian Saldo | Transaksi `type = 'adjustment'` |
| Transfer ke Aset | Transaksi `type = 'transfer_to_asset'` |

---

## 6. ERD — Database Schema (Final & Revised)

### Tabel `public.users`
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | uuid PK | Mirror dari `auth.users.id` |
| `email` | text | |
| `full_name` | text | |
| `avatar_url` | text nullable | URL dari Supabase Storage |
| `created_at` | timestamptz | default now() |
| `updated_at` | timestamptz | auto-update via trigger |

> ⚙️ **Trigger:** `on_auth_user_created` → UPSERT ke `public.users` saat user baru sign up / sign in Google.

---

### Tabel `wallets`
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | uuid PK | |
| `user_id` | uuid FK → `auth.users` | |
| `name` | text | Nama dompet (BCA, Cash, dll.) |
| `icon` | text | Nama icon FontAwesome |
| `color` | text | Hex color string |
| `balance` | numeric | Saldo saat ini (dikelola trigger) |
| `initial_balance` | numeric | Saldo awal saat create (tidak berubah) |
| `currency` | text | Default: 'IDR' |
| `exclude_from_total` | boolean | Default: false |
| `sort_order` | integer | Urutan tampil di UI |
| `created_at` | timestamptz | |
| `updated_at` | timestamptz | |

> ⚙️ **RLS:** User hanya bisa akses wallets miliknya sendiri.

---

### Tabel `categories`
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | uuid PK | |
| `user_id` | uuid nullable FK → `auth.users` | NULL = kategori sistem global |
| `name` | text | |
| `icon` | text | Nama icon FontAwesome |
| `color` | text | Hex color string |
| `type` | text | enum: `'income'`, `'expense'`, `'system'` |
| `parent_id` | uuid nullable FK → `categories.id` | Self-referential untuk parent-child |
| `is_default` | boolean | Default: false |
| `is_hidden` | boolean | Default: false (user bisa hide kategori default) |
| `sort_order` | integer | |
| `created_at` | timestamptz | |

---

### Tabel `transactions`
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | uuid PK | |
| `user_id` | uuid FK → `auth.users` | |
| `wallet_id` | uuid FK → `wallets.id` | Dompet asal |
| `destination_wallet_id` | uuid nullable FK → `wallets.id` | Dompet tujuan (khusus transfer) |
| `type` | text | enum: `'income'`, `'expense'`, `'transfer'`, `'debt'`, `'loan'`, `'adjustment'`, `'transfer_to_asset'` |
| `total_amount` | numeric | Grand total transaksi |
| `date` | timestamptz | Tanggal transaksi |
| `merchant_name` | text nullable | Nama merchant (dari OCR atau input manual) |
| `note` | text nullable | Catatan umum (untuk single-item atau header multi-item) |
| `attachment_url` | text nullable | URL foto struk dari Supabase Storage |
| `with_person` | text nullable | Nama kontak (wajib untuk debt/loan) |
| `status` | text nullable | enum: `'unpaid'`, `'paid'` (khusus debt/loan) |
| `due_date` | timestamptz nullable | Jatuh tempo (khusus debt/loan, untuk notifikasi) |
| `is_multi_item` | boolean | Default: false. True jika ada transaction_items |
| `created_at` | timestamptz | |
| `updated_at` | timestamptz | |

> ⚙️ **Trigger:** Setiap INSERT/UPDATE/DELETE di `transactions` otomatis mengupdate `wallets.balance`.
> ⚙️ **Catatan Single-Item:** Untuk transaksi single-item, `category_id` disimpan langsung di `transactions` (via join ke `transaction_items` dengan 1 record), atau buat 1 record `transaction_items` otomatis. **Keputusan:** Selalu gunakan `transaction_items` (min. 1 record) agar konsisten — tidak perlu kolom `category_id` di `transactions`.

---

### Tabel `transaction_items`
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | uuid PK | |
| `transaction_id` | uuid FK → `transactions.id` | |
| `category_id` | uuid nullable FK → `categories.id` | |
| `amount` | numeric | Nominal item ini |
| `note` | text nullable | Catatan per item |
| `sort_order` | integer | Urutan item |

> ⚙️ **Aturan:** Setiap transaksi memiliki **minimal 1** `transaction_item`. Ini menjaga konsistensi dan menyederhanakan logika laporan.

---

### Tabel `budgets`
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | uuid PK | |
| `user_id` | uuid FK → `auth.users` | |
| `category_id` | uuid FK → `categories.id` | Kategori yang di-budget |
| `wallet_id` | uuid nullable FK → `wallets.id` | NULL = budget global semua dompet |
| `amount` | numeric | Batas nominal budget |
| `used_amount` | numeric | Sudah terpakai (dikelola trigger/RPC) |
| `start_date` | date | |
| `end_date` | date | |
| `is_recurring` | boolean | Default: false. Auto-clone untuk periode berikutnya |
| `notification_sent_80` | boolean | Default: false. Flag notif 80% sudah dikirim |
| `notification_sent_100` | boolean | Default: false. Flag notif 100% sudah dikirim |
| `created_at` | timestamptz | |
| `updated_at` | timestamptz | |

> ⚙️ **Trigger:** Setiap INSERT ke `transaction_items` yang kategorinya match dengan budget → update `budgets.used_amount` + cek threshold notifikasi.
> ⚙️ **Parent-Child Logic:** Trigger menghitung budget usage dengan memperhitungkan semua `category_id` turunan dari `budgets.category_id`.
> ⚙️ **Auto-Renew:** Supabase pg_cron job berjalan setiap hari tengah malam, cek `budgets` dengan `is_recurring = true` dan `end_date = kemarin` → clone untuk periode berikutnya.

---

### Tabel `investments`
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | uuid PK | |
| `user_id` | uuid FK → `auth.users` | |
| `type` | text | enum: `'gold'`, `'crypto'`, `'custom'` |
| `name` | text | Nama aset (Bitcoin, Emas 24K, BBCA, dll.) |
| `symbol` | text nullable | Simbol ticker (BTC, AAPL, dll.) |
| `amount` | numeric | Jumlah unit yang dimiliki |
| `avg_buy_price` | numeric | Rata-rata harga beli per unit (IDR) |
| `custom_current_price` | numeric nullable | Override harga terkini manual (jika API tidak tersedia) |
| `linked_wallet_id` | uuid nullable FK → `wallets.id` | Dompet yang dipotong saat beli |
| `notes` | text nullable | |
| `created_at` | timestamptz | |
| `updated_at` | timestamptz | |

---

### Tabel `parsing_dictionaries`
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | uuid PK | |
| `keyword` | text | Kata kunci (lowercase, contoh: "indomaret", "grab", "bensin") |
| `category_id` | uuid FK → `categories.id` | Kategori yang diasosiasikan |
| `created_at` | timestamptz | |

> 📌 Cache di Hive dengan key `parsing_dict_cache` dan `parsing_dict_last_fetch` (timestamp). TTL = 24 jam.

---

### Tabel `notification_settings` *(NEW)*
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | uuid PK | |
| `user_id` | uuid FK → `auth.users` | |
| `reminder_enabled` | boolean | Default: false |
| `reminder_time` | time | Jam pengingat harian (contoh: 21:00) |
| `budget_alert_enabled` | boolean | Default: true |
| `debt_reminder_enabled` | boolean | Default: true |
| `debt_reminder_days_before` | integer | Berapa hari sebelum jatuh tempo (default: 3) |
| `updated_at` | timestamptz | |

---

## 7. PostgreSQL Triggers & Functions (Dibuat via Supabase MCP)

| Nama Function/Trigger | Event | Fungsi |
|---|---|---|
| `handle_new_user()` | AFTER INSERT on `auth.users` | UPSERT ke `public.users` |
| `seed_default_categories()` | AFTER INSERT on `public.users` | Insert kategori default untuk user baru |
| `update_wallet_balance()` | AFTER INSERT/UPDATE/DELETE on `transactions` | Update `wallets.balance` berdasarkan tipe & amount transaksi |
| `update_budget_usage()` | AFTER INSERT/UPDATE/DELETE on `transaction_items` | Update `budgets.used_amount`, check threshold notif |
| `handle_investment_wallet_deduction()` | AFTER INSERT on `investments` (jika linked_wallet_id tidak null) | Kurangi saldo dompet terkait |
| `auto_renew_budgets()` | pg_cron (daily midnight) | Clone budgets `is_recurring = true` yang expired |
| `set_updated_at()` | BEFORE UPDATE on semua tabel | Auto-update kolom `updated_at` |

---

## 8. External API Specifications

### 8.1 CoinGecko (Bitcoin Price)
- **Endpoint:** `GET https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=idr`
- **Auth:** Tidak perlu (free tier, rate limit: 10-30 req/menit)
- **Cache:** Hive, TTL = 1 jam

### 8.2 Harga Emas (Gratis)
- **Opsi 1:** `GET https://api.harga-emas.org/` (emas.org Indonesian API jika tersedia)
- **Opsi 2:** Web scraping Logam Mulia via Supabase Edge Function (proxy) untuk menghindari CORS
- **Opsi 3:** Fallback → user input `custom_current_price` manual
- **Cache:** Hive, TTL = 1 jam

---

## 9. Aturan RLS (Row Level Security) Supabase

Semua tabel wajib mengaktifkan RLS dengan policy:
```sql
-- Contoh untuk tabel wallets:
CREATE POLICY "Users can only see their own wallets"
ON wallets FOR ALL
USING (auth.uid() = user_id);
```

Tabel `categories` memiliki exception: user bisa **READ** kategori dengan `user_id IS NULL` (kategori sistem global).

---

## 10. Panduan Pengembangan Bertahap (untuk Prompt Engineering)

```
Phase 0: Fondasi → Setup Project, Design System, Global Widgets, DB Schema + Triggers
Phase 1: Auth + Onboarding
Phase 2: Core — Manajemen Dompet
Phase 3: Core — Transaksi Manual (Single & Multi-Item)
Phase 4: Dashboard
Phase 5: Riwayat & Laporan (History + Charts)
Phase 6: Manajemen Kategori
Phase 7: Voice Input (STT)
Phase 8: OCR Scan Struk
Phase 9: Kamus Parsing AI + Cache
Phase 10: Manajemen Anggaran (Budgeting)
Phase 11: Manajemen Investasi
Phase 12: Notifikasi & Reminder
Phase 13: Polish & QA (Lokalisasi lengkap, Accessibility, Performance tuning)
```

````

---

Berikut adalah rangkuman **perubahan & penambahan signifikan** yang aku buat dari PRD asli:

### 🔧 Perubahan Database
| # | Perubahan | Alasan |
|---|---|---|
| 1 | Kolom `category_id` **dihapus dari `transactions`**, digantikan dengan minimal 1 record di `transaction_items` | Konsistensi data — single item & multi-item punya struktur yang sama |
| 2 | Tambah `destination_wallet_id` di `transactions` | Untuk transfer antar dompet |
| 3 | Tambah `is_multi_item`, `merchant_name`, `due_date` di `transactions` | Mendukung OCR, multi-item flag, dan piutang jatuh tempo |
| 4 | `type` di `transactions` dipecah jadi: `debt` & `loan` (bukan `debt_loan`) + tambah `transfer_to_asset` | Logika hutang vs piutang berbeda arah saldo |
| 5 | Tambah `icon`, `color`, `sort_order`, `initial_balance` di `wallets` | Personalisasi + urutan tampil |
| 6 | Tambah `color`, `is_hidden`, `sort_order` di `categories` | UX lebih baik |
| 7 | `wallet_id` di `budgets` → **NULL = global**, terisi = per-dompet | Sesuai keputusan kamu |
| 8 | Tambah `used_amount`, `notification_sent_80`, `notification_sent_100` di `budgets` | Tracking usage & notif flag |
| 9 | Tambah tabel `notification_settings` | Fitur reminder & budget alert |
| 10 | Tambah kolom `symbol`, `linked_wallet_id`, `notes` di `investments` | Mendukung potong dompet & custom aset |

### ✅ Keputusan Teknis yang Sudah Dikunci
- **API Investasi:** CoinGecko (BTC, gratis) + fallback emas manual
- **Notifikasi:** `flutter_local_notifications` + WorkManager
- **Design:** Tema hijau soft, `app_colors.dart` wajib diimprove oleh AI
- **Trigger DB:** Semua dibuat via Supabase MCP di prompt coding
- **Note di transaksi:** Selalu di `transaction_items` (minimal 1 item per transaksi)
