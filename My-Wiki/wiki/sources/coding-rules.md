---
title: "SakuRapi Coding Rules & Guidelines — Ringkasan"
type: source
tags: [coding-rules, arsitektur, riverpod, ui, formatting, conventions, sakurapi]
sources: [raw/docs/00_SakuRapi_Coding_Rules.md]
created: 2026-04-10
updated: 2026-04-10
---

# SakuRapi Coding Rules & Guidelines — Ringkasan

**Jenis**: Dokumen internal — Panduan coding dan konvensi aplikasi
**Tanggal sumber**: 2026 (versi terbaru)
**Cakupan**: 14 bagian mencakup state management, arsitektur, UI, performa, formatting, dan tooling

## Ringkasan

Dokumen ini adalah panduan utama untuk semua aturan coding di proyek SakuRapi. Mencakup konvensi state management menggunakan Riverpod, arsitektur 3-File Pattern pada data layer, aturan modularitas komponen UI, standar performa tinggi, serta konvensi formatting untuk mata uang dan tanggal yang **wajib** menggunakan extension terpusat.

Inti dari dokumen ini adalah menjaga konsistensi dan kualitas kode di seluruh codebase. Setiap fitur harus mengikuti struktur folder yang ketat, menggunakan widget global yang sudah tersedia, dan menghindari hardcoded value di mana pun. Prinsip SOLID diterapkan secara ketat, dan semua class serta fungsi wajib dilengkapi docstrings (`///`).

Dokumen juga menegaskan penggunaan MCP tools (Supabase MCP dan Dart/Flutter MCP) untuk verifikasi schema dan linting otomatis, serta aturan spesifik untuk Edge Functions yang berjalan di atas Deno (bukan Node.js).

## Poin Kunci

### State Management
- Menggunakan **flutter_riverpod ^3.3.1** — **TANPA** Riverpod Generator
- Provider yang tersedia: `StateNotifierProvider`, `FutureProvider`, `Provider`
- `.autoDispose` **wajib** untuk provider yang hanya digunakan di satu layar (screen-scoped) — mencegah memory leak
- State dari Supabase menggunakan `AsyncValue<T>` dengan `.when(data:, loading:, error:)` untuk menangani ketiga kondisi

### Arsitektur: 3-File Pattern (Data Layer)
- Setiap fitur hanya boleh terdiri dari 3 layer:
  1. **LocalDataSource** — operasi lokal menggunakan Hive
  2. **RemoteDataSource** — khusus Supabase RPC/Queries, wajib dibungkus `SupabaseHandler.call<T>(function: () async { ... })`, semua fungsi mengembalikan `DataState<T>`
  3. **Repository** — orkestrator utama, menangani `DataState` dengan pattern matching `.map(success:, error:)`
- Penamaan: `{Feature}LocalDataSource`, `{Feature}RemoteDataSource`, `{Feature}Repository`

### Aturan Model
- Semua class data wajib berakhiran **`Model`** (contoh: `WalletModel` di `wallet_model.dart`)
- Menggunakan plain Dart class — **TANPA Freezed** atau code generation
- Wajib dilengkapi method: `copyWith`, `toMap()`, `fromMap()`

### Konvensi UI & Komponen
- **ScreenUtil** wajib digunakan untuk responsivitas: `.h`, `.w`, `.r`, `.sp` — dilarang hardcode ukuran piksel
- Tipografi melalui `TextStyleConstants`
- Pewarnaan dinamis via `context.colors.primary`, `context.colors.background`, dll — dilarang hardcode warna
- **Global widgets** (`lib/global/widgets/`): `SakuButton`, `SakuTextField`, `SakuCard`, `SakuDropdown`, dll — cek folder ini dulu sebelum membuat widget baru
- **Feature widgets** ditempatkan di `view/widgets/` atau `view/components/` dengan penamaan ber-prefix fitur (contoh: `WalletBalanceCard` ✅, bukan `BalanceCard` ❌)
- Input uang wajib pakai `SakuCurrencyField` (thousand formatter bawaan)

### Performa & Manajemen Memori
- **DILARANG** `Column`/`ListView` biasa untuk daftar panjang — wajib `ListView.builder`, `SliverList`, atau `GridView.builder`
- Pagination wajib diterapkan dengan `visibility_detector` sebagai trigger
- `const` constructor wajib digunakan sedapat mungkin untuk mencegah rebuild

### Formatting Mata Uang (WAJIB pakai extension)
- **int**: `int_ext.dart` → `extToRupiah()`, `extToRibuan()`
- **double**: `double_ext.dart` → `toCurrency()`, `toCompactCurrency()`, `toPercentage()`, `toCurrencyOrDash()`
- Contoh: `wallet.balance.toCurrency()` ✅, bukan `'Rp ${wallet.balance}'` ❌
- Alasan: future-proof untuk multi-currency — cukup edit satu file untuk mengubah format seluruh aplikasi

### Formatting Tanggal & Waktu (WAJIB pakai extension)
- **DateTime**: `date_time_ext.dart` → `extToFormattedString()`, `extToTimeString()`, `extToDateStringDDMMMMYYYY()`, `extTimeAgo()`, plus utilitas cek tanggal (`extIsToday`, `extIsYesterday`, dll)
- **String**: `string_ext.dart` → `extToDateTime()`, `extToDateLocal()`, `extToDateUtc()`, `extToCustomFormattedDate()`, `extToDateDDMMMMYYYY()`
- Locale otomatis mengikuti pengaturan user — tanpa hardcode locale
- **DILARANG** manual `DateFormat` di UI

### Penanganan Edge Cases di UI
- **Loading**: `ShimmerWidget` sebagai placeholder — dilarang `CircularProgressIndicator` standar
- **Empty state**: `SakuEmptyState` dengan ilustrasi dan pesan persuasif
- **Error state**: `SakuErrorState` / `SakuErrorWidget` dengan tombol "Coba Lagi" (retry)
- **Blocking operation**: `context.showLoadingOverlay()` dengan `context.closeOverlay()` di blok `finally`
- **Notifikasi & dialog**: `context.showAppAlert()` dan `context.showConfirmDialog()`

### Lokalisasi & Icon
- Semua teks UI wajib dari file `.arb` — cek key yang sudah ada sebelum menambah baru
- Icon menggunakan **FontAwesomeIcon** — bukan Material Icons

### Logging
- Menggunakan `AppLogger.call` dengan format: `[Sync|Offline|Online] [{Feature}] {message}`
- Dipasang di titik krusial: fetch data, insert, dan error

### MCP Tools
- **Supabase MCP**: Wajib digunakan untuk verifikasi schema database sebelum membuat Model atau RemoteDataSource — dilarang menebak struktur
- **Dart & Flutter MCP**: Digunakan untuk cek linting, best practice, dan diagnosis error

### Edge Functions
- Berjalan di atas **Deno + TypeScript** (bukan Node.js)
- Gunakan `Deno.env.get('KEY')` — bukan `process.env`

### Prinsip Umum
- SOLID diterapkan secara ketat
- Docstrings (`///`) wajib untuk semua class, fungsi, dan logika kompleks
- Struktur folder per fitur: `controllers/`, `datasource/`, `models/`, `repositories/`, `utils/`, `view/` (dipecah ke `ui/` dan `widgets/`/`components/`)

## Relevansi untuk SakuRapi

Dokumen ini adalah fondasi teknis utama yang mengatur bagaimana seluruh codebase SakuRapi ditulis. Setiap developer dan AI assistant **wajib** merujuk dokumen ini sebelum menulis kode apapun. Aturan formatting terpusat (currency & date extension) sangat krusial untuk menjaga konsistensi tampilan dan mendukung skalabilitas ke multi-currency di masa depan. Arsitektur 3-File Pattern memastikan separation of concerns yang jelas antara akses data lokal, remote, dan orkestrasi bisnis.

## Halaman Terkait

- [[wiki/concepts/arsitektur-app|Arsitektur App]]
- [[wiki/concepts/aturan-keuangan|Aturan Keuangan]]
- [[wiki/entities/sakurapi|SakuRapi]]
