# SakuRapi - App Coding Rules & Guidelines

## State Management
Menggunakan package : flutter_riverpod ^3.3.1
**TIDAK MENGGUNAKAN** Riverpod Generator, jadi jangan nulis controllernya kayak yang pakai generator

## 1. Aturan Dasar, Konvensi & Kualitas Kode
* **Framework & Tooling:** WAJIB gunakan FVM (`fvm flutter <command>`). State Management menggunakan Riverpod. Routing menggunakan GoRouter.
* **Prinsip SOLID & Dokumentasi:** Terapkan SOLID secara ketat. Semua class, fungsi, dan logika kompleks WAJIB diberi *docstrings* (`///`).
* **Konvensi Penamaan Model:** SEMUA *class* data dan *file*-nya WAJIB diakhiri dengan kata `Model` (Contoh: `WalletModel` di `wallet_model.dart`). Model HANYA menggunakan Dart Class biasa (TANPA Freezed), namun harus dilengkapi `copyWith`, `toMap()`, dan `fromMap()`.
* **Lokalisasi (Localization / .arb):** DILARANG KERAS melakukan *hardcode* teks (*string*) langsung di UI.
  * WAJIB gunakan sistem lokalisasi dari *file* `.arb`.
  * Sebelum menambahkan teks baru, **CEK DULU** apakah *key* tersebut sudah ada di *file* `.arb`. Jika sudah ada, langsung pakai.
  * Jika belum ada, tambahkan *key* baru dengan nama yang spesifik dan pastikan tidak duplikat.

## 2. Arsitektur Inti: 3-File Pattern (Data Layer)
Setiap fitur HANYA BOLEH terdiri dari 3 layer:
1.  **LocalDataSource:** Untuk operasi lokal (Hive).
2.  **RemoteDataSource:** Khusus Supabase RPC/Queries. WAJIB dibungkus dengan `SupabaseHandler.call<T>(function: () async { ... })`. Semua fungsi me-*return* `DataState<T>`.
3.  **Repository:** Orkestrator utama. Tangani *return type* dari `DataState` menggunakan *pattern matching* bawaan DataState (`.map(success: ..., error: ...)`).

## 3. Arsitektur UI & Komponen (Wajib Modular)
* **Reusability (Global Widget):** Sebelum membuat komponen UI baru, **WAJIB** mengecek folder `lib/global/widgets/`. Gunakan *widget* yang sudah ada (seperti `SakuButton`, `SakuTextField`, `SakuCard`) jika memungkinkan. Jangan membuat ulang kode yang sama.
* **Feature-Specific Widgets:** DILARANG KERAS menumpuk kode UI yang panjang di dalam satu file *screen* utama.
  * Jika sebuah *widget* atau komponen UI hanya dipakai di satu fitur tertentu dan tidak cocok dijadikan Global Widget, WAJIB dipecah ke file terpisah.
  * Simpan file pecahan tersebut di dalam folder `lib/features/{nama_fitur}/view/widgets/` atau `lib/features/{nama_fitur}/view/components/`.
* **Penamaan Widget Spesifik:** Widget spesifik fitur WAJIB dinamai dengan jelas dan menyertakan konteks fiturnya agar tidak membingungkan atau bentrok dengan fitur lain. (Contoh Benar: `WalletBalanceCard`, `TransactionFilterSheet`. Contoh Salah: `BalanceCard`, `FilterSheet`).

## 4. Performa Tinggi & Manajemen Memori (Anti-Lag & Anti-Junk)
Aplikasi tidak boleh patah-patah (*lag*) meskipun menangani ribuan data transaksi.
* **Rendering UI:** DILARANG menggunakan `Column` atau `ListView` biasa untuk me-render daftar panjang. WAJIB gunakan `ListView.builder`, `SliverList`, atau `GridView.builder` agar komponen dirender secara efisien (*lazy loading*).
* **Pagination:** Jika data yang ditarik dari Supabase berpotensi masif, WAJIB terapkan mekanisme *pagination*, pakai *visibility detector* untuk deteksi *trigger*-nya.
* **Const Widget:** Gunakan *constructor* `const` pada setiap *widget* sebisa mungkin untuk mencegah *rebuild* memori yang tidak perlu.

## 5. Tema, Pewarnaan & Context Extensions
Aplikasi mengusung konsep **simpel, elegan, modern, dan fancy**.
* **Responsivitas:** DILARANG gunakan ukuran piksel statis mentah. WAJIB gunakan ekstensi `ScreenUtil` (`.h`, `.w`, `.r`, `.sp`).
* **Tipografi:** WAJIB gunakan `TextStyleConstants`.
* **Pewarnaan Dinamis:** DILARANG *hardcode* warna statis. WAJIB panggil warna melalui *extension* konteks: `context.colors.primary`, `context.colors.background`, dll.
* **Custom Extensions:**
  * **Loading:** Gunakan `context.showLoadingOverlay()` HANYA untuk operasi berat yang wajib memblokir UI. Tutup di blok `finally` dengan `context.closeOverlay()`.
  * **Notifikasi & Dialog:** WAJIB gunakan `context.showAppAlert()` dan `context.showConfirmDialog()`.

## 6. Struktur Folder
Ikuti hierarki ini secara ketat di dalam `lib/features/{fitur}/`:
* `controllers/`
* `datasource/`
* `models/`
* `repositories/`
* `utils/`
* `view/` -> Wajib dipecah menjadi `ui/` (untuk screen utama) dan `widgets/` atau `components/` (untuk pecahan UI spesifik fitur).
* Komponen yang bisa dipakai berulang lintas fitur taruh di `lib/global/widgets/`.

## 7. Konvensi Penamaan & Logging
* **Log:** Gunakan `AppLogger.call` dengan format: `[Sync Offline Online] [{NamaFitur}] {pesan_log}`. Pasang di tempat krusial (fetch data, insert, error).
* **Penamaan:** Patuhi pola `{Feature}LocalDataSource`, `{Feature}RemoteDataSource`, `{Feature}Repository`.

## 8. Penggunaan MCP (Model Context Protocol) & Perilaku Agent
Kamu (AI) telah dilengkapi dengan beberapa alat MCP. Kamu WAJIB memanfaatkannya sesuai panduan berikut:
* **Supabase MCP:** DILARANG menebak-nebak struktur database, nama tabel, tipe data, atau fungsi RPC. Sebelum membuat Model atau menulis fungsi di RemoteDataSource, WAJIB gunakan Supabase MCP untuk membaca skema database **SakuRapi** yang asli dan *up-to-date*.
* **Dart & Flutter MCP:** Gunakan alat ini secara proaktif untuk mengecek *linting*, memastikan *best practice* versi Dart terbaru, dan mendiagnosis *error build* atau masalah *widget tree*.

## 9. Penggunaan ICON
Silahkan pakai FontAwesomeIcon untuk Icon yang lebih keren, karena material icon cenderung kaku

## 10. Formatting Nilai Mata Uang & Angka (Value Formatting)

### Aturan Utama
**DILARANG KERAS** melakukan format nilai uang atau angka secara manual langsung di UI.

Contoh yang **SALAH**:
```dart
// ❌ SALAH — jangan lakukan ini
Text('Rp ${value.toStringAsFixed(0)}')
Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(value))
```

**WAJIB** menggunakan *extension* yang sudah disediakan di:
- `lib/core/extensions/int_ext.dart` → untuk tipe `int` dan `int?`
- `lib/core/extensions/double_ext.dart` → untuk tipe `double` dan `double?`

### Alasan (Future-Proof)
Penggunaan *extension* terpusat memastikan:
1. Format mata uang bisa diubah di **satu tempat** untuk seluruh aplikasi (mendukung multi-currency di masa depan).
2. Konsistensi tampilan angka di seluruh UI.
3. Tidak ada duplikasi logika formatting.

### Extension yang Tersedia

**Untuk `int` / `int?` — `lib/core/extensions/int_ext.dart`:**
```dart
int price = 150000;

price.extToRupiah();                      // → 'Rp 150.000'
price.extToRupiah(withPrefix: false);     // → '150.000'
price.extToRupiah(showDecimal: true);     // → 'Rp 150.000,00'
price.extToRibuan();                      // → '150.000'

int? nullPrice;
nullPrice.extToRupiah();                  // → '-'
```

**Untuk `double` / `double?` — `lib/core/extensions/double_ext.dart`:**
```dart
double balance = 1500000.0;

balance.toCurrency();                     // → 'Rp 1.500.000'
balance.toCurrency(withPrefix: false);    // → '1.500.000'
balance.toCurrency(showDecimal: true);    // → 'Rp 1.500.000,00'
balance.toCompactCurrency();              // → 'Rp 1,5 jt'
balance.toThousands();                    // → '1.500.000'

double pct = 0.823;
pct.toPercentage();                       // → '82,3%'
pct.toPercentage(decimalDigits: 2);       // → '82,30%'

double? nullBalance;
nullBalance.toCurrencyOrDash();           // → '-'
```

### Contoh Penggunaan di Widget
```dart
// ✅ BENAR
Text(wallet.balance.toCurrency())
Text(transaction.amount.extToRupiah())
Text(budget.usagePercentage.toPercentage())
Text(wallet.balance.toCompactCurrency())
Text(AppConstants.currentSymbol)

// ❌ SALAH
Text('Rp ${wallet.balance}')
Text(NumberFormat.currency(...).format(wallet.balance))
Text('Rp ')
```

### Cara Ganti Format di Masa Depan
Jika ingin mengganti format currency (misal IDR → USD, atau mendukung multi-currency), **cukup edit satu file** `double_ext.dart` — seluruh tampilan angka di aplikasi akan otomatis ikut berubah.

## 11. Formatting Tanggal & Waktu (Date & Time Formatting)

### Aturan Utama
**DILARANG KERAS** melakukan format tanggal/waktu secara manual langsung di UI.

Contoh yang **SALAH**:
```dart
// ❌ SALAH — jangan lakukan ini
Text('${date.day}-${date.month}-${date.year}')
Text(DateFormat('dd MMMM yyyy').format(date))
```

**WAJIB** menggunakan *extension* yang sudah disediakan di:
- `lib/core/extensions/date_time_ext.dart` → untuk tipe `DateTime` dan `DateTime?`
- `lib/core/extensions/string_ext.dart` → untuk tipe `String` dan `String?` yang berisi nilai tanggal

### Extension yang Tersedia

**Dari `DateTime?` — `lib/core/extensions/date_time_ext.dart`:**
```dart
DateTime? date = DateTime(2025, 3, 19, 14, 30);

// Format bebas (gunakan pola DateFormat)
date.extToFormattedString();                              // → '2025-03-19'  (default)
date.extToFormattedString(outputDateFormat: 'dd/MM/yyyy'); // → '19/03/2025'
date.extToFormattedString(outputDateFormat: 'EEEE, dd MMMM yyyy'); // → 'Rabu, 19 Maret 2025'

// Format waktu
date.extToTimeString();                                   // → '14:30'  (default HH:mm)
date.extToTimeString(formatToTime: 'HH:mm:ss');           // → '14:30:00'

// Format tanggal panjang
date.extToDateStringDDMMMMYYYY();                         // → '19 Maret 2025'

// Time ago (relative time)
date.extTimeAgo();                                        // → '2 hari lalu'

// Cek kondisi tanggal
date.extIsToday;                                          // → true / false
date.extIsYesterday;                                      // → true / false
date.extIsThisWeek;                                       // → true / false
date.extIsLastWeek;                                       // → true / false
date.extIsSameDayMonthYear(DateTime.now());                // → true / false
date.extIsSameMonthYear(DateTime.now());                   // → true / false
date.extIsSameYear(DateTime.now());                        // → true / false

// Utilitas tanggal
date.extGetDate();                                        // → DateTime (tanpa jam)
date.extGetFirstDateInMonth();                            // → DateTime hari pertama bulan
date.extGetLastDateInMonth();                             // → DateTime hari terakhir bulan
date.extGetDaysInWeek();                                  // → List<DateTime> hari dalam seminggu

DateTime? nullDate;
nullDate.extToFormattedString();                          // → '-'
nullDate.extToTimeString();                               // → '-'
```

**Dari `String` / `String?` — `lib/core/extensions/string_ext.dart`:**
```dart
// Konversi String ke DateTime
'2025-03-19 14:30:00'.extToDateTime();                    // → DateTime object
'2025-03-19'.extToDateTime(originFormatDate: 'yyyy-MM-dd'); // → DateTime object
'2025-03-19'.extToDateLocal();                            // → DateTime (local timezone)
'2025-03-19T07:30:00Z'.extToDateUtc();                    // → DateTime (UTC)

// Konversi String tanggal langsung ke format lain
'2025-03-19'.extToCustomFormattedDate();                  // → '19-03-2025'  (default output)
'2025-03-19'.extToCustomFormattedDate(
  outputDateFormat: 'dd MMMM yyyy',
  originFormatDate: 'yyyy-MM-dd',
);                                                        // → '19 Maret 2025'

// Konversi String? ke format 'dd MMMM yyyy'
String? isoDate = '2025-03-19T07:30:00.000Z';
isoDate.extToDateDDMMMMYYYY();                            // → '19 Maret 2025'

// Konversi UTC string ke local (WIB +0700) langsung ke display string
'2025-03-19T07:30:00'.extToConvertToLocal();              // → '19-03-2025 - 14:30'
```

### Contoh Penggunaan di Widget
```dart
// ✅ BENAR — dari DateTime
Text(transaction.createdAt.extToDateStringDDMMMMYYYY())
Text(transaction.createdAt.extToFormattedString(outputDateFormat: 'dd MMM yyyy'))
Text(transaction.createdAt.extToTimeString())
Text(notification.createdAt.extTimeAgo())

// ✅ BENAR — dari String ISO (data dari Supabase)
Text(transaction.createdAt.extToCustomFormattedDate(outputDateFormat: 'dd MMM yyyy'))
Text(transaction.createdAt.extToDateDDMMMMYYYY() ?? '-')

// ❌ SALAH
Text('${date.day}/${date.month}/${date.year}')
Text(DateFormat('dd MMMM yyyy').format(date))
```

### Catatan Locale
Semua extension di `date_time_ext.dart` secara otomatis mengikuti locale aktif aplikasi (`appContext?.locale.languageCode`), sehingga nama hari dan bulan otomatis tampil dalam Bahasa Indonesia atau Bahasa Inggris sesuai pengaturan user — **tanpa hardcode locale**.