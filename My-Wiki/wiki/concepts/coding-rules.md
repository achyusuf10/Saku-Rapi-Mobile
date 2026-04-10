---
title: "Coding Rules"
type: concept
tags: [coding-rules, arsitektur, konvensi, flutter, riverpod, copilot, testing, forbidden]
sources: [raw/docs/00_SakuRapi_Coding_Rules.md, raw/docs/03_COPILOT_RULES.md]
created: 2026-04-10
updated: 2026-04-10
---

# Coding Rules

> Halaman ini merangkum **seluruh aturan implementasi** SakuRapi — dari coding rules dasar hingga guardrails Copilot. Berlaku untuk semua developer dan AI coding assistant.

**Prioritas konflik:** Jika ada pertentangan, dahulukan `00_SakuRapi_Coding_Rules.md` di atas `03_COPILOT_RULES.md`.

---

## Aturan Dasar

| Area | Rule |
|---|---|
| Flutter versioning | **WAJIB** gunakan FVM (`fvm flutter <command>`) |
| State management | Riverpod (`flutter_riverpod ^3.3.1`), **TANPA** Riverpod Generator |
| Routing | GoRouter |
| Local storage | Hive |
| Backend | Supabase |
| Prinsip | SOLID secara ketat |
| Dokumentasi | Semua class, fungsi, dan logika kompleks WAJIB diberi docstrings (`///`) |
| Model | Suffix `Model` (contoh: `WalletModel`), plain Dart class (tanpa Freezed), dilengkapi `copyWith`, `toMap()`, `fromMap()` |

### State Management Detail

- Gunakan `StateNotifierProvider`, `FutureProvider`, atau `Provider` biasa sesuai kebutuhan
- **Auto Dispose:** Jika provider hanya digunakan di satu layar, WAJIB gunakan `.autoDispose`
- Saat mengambil data dari Supabase, gunakan `AsyncValue<T>` dan tangani `.when(data: ..., loading: ..., error: ...)`

---

## Arsitektur: 3-File Pattern

Setiap fitur data HANYA BOLEH terdiri dari 3 layer:

```
Widget (Presentation) → Controller/Notifier (UI State) → Repository (Business Coordination)
                                                             ↓                    ↓
                                                   RemoteDataSource        LocalDataSource
                                                   (Supabase/RPC)            (Hive)
```

### Layer Rules

| Layer | Tanggung Jawab |
|---|---|
| **Widget** | Presentation dan user interaction saja |
| **Controller/Notifier** | Orchestration UI state |
| **Repository** | Business coordination, pattern matching `DataState.map(success:..., error:...)` |
| **RemoteDataSource** | Khusus Supabase RPC/Queries, dibungkus `SupabaseHandler.call<T>()`, return `DataState<T>` |
| **LocalDataSource** | Operasi lokal Hive/cache |

### Penamaan File

- `{feature}_local_data_source.dart`
- `{feature}_remote_data_source.dart`
- `{feature}_repository.dart`

> Business rule finansial **tidak boleh** diletakkan di `build()` widget.

---

## Struktur Folder

```
lib/features/{fitur}/
├── controllers/
├── datasource/
├── models/
├── repositories/
├── utils/
└── view/
    ├── ui/           # screen utama
    ├── widgets/      # pecahan UI spesifik fitur
    └── components/   # komponen alternatif

lib/global/widgets/   # widget reusable lintas fitur
```

---

## UI & Komponen

### Global Widgets

Sebelum membuat komponen UI baru, **WAJIB** cek folder `lib/global/widgets/` terlebih dahulu. Widget yang sudah tersedia antara lain:

- `SakuButton` — tombol standar
- `SakuTextField` — input text
- `SakuCard` — card container
- `SakuDropdown` — dropdown picker
- `SakuCurrencyField` — input uang (dengan thousand formatter)
- `SakuEmptyState` — tampilan data kosong
- `SakuErrorState` — tampilan error dengan retry

### Feature-Specific Widgets

- DILARANG menumpuk kode UI panjang di satu file screen utama
- Pecah ke `view/widgets/` atau `view/components/`
- Penamaan harus jelas dengan konteks fitur: `WalletBalanceCard` ✅, `BalanceCard` ❌

---

## Performa

| Aturan | Detail |
|---|---|
| Rendering list | WAJIB `ListView.builder`, `SliverList`, atau `GridView.builder` (DILARANG `Column`/`ListView` biasa untuk list panjang) |
| Pagination | WAJIB untuk data masif dari Supabase, gunakan `visibility_detector` untuk trigger |
| Const constructors | Gunakan `const` pada setiap widget sebisa mungkin |

---

## Tema & Styling

| Area | Rule |
|---|---|
| Responsivitas | WAJIB `ScreenUtil`: `.h`, `.w`, `.r`, `.sp` (DILARANG raw pixel) |
| Tipografi | WAJIB `TextStyleConstants` (DILARANG inline `TextStyle`) |
| Warna | WAJIB `context.colors.primary`, `context.colors.background`, dll (DILARANG hardcode warna) |
| Loading overlay | `context.showLoadingOverlay()` untuk blocking, tutup di `finally` dengan `context.closeOverlay()` |
| Notifikasi | `context.showAppAlert()` dan `context.showConfirmDialog()` |

---

## Formatting Nilai (Currency)

**DILARANG KERAS** format nilai uang secara manual di UI. WAJIB gunakan extension.

### Extension `int` / `int?` (`lib/core/extensions/int_ext.dart`)

| Method | Contoh Output |
|---|---|
| `price.extToRupiah()` | `Rp 150.000` |
| `price.extToRupiah(withPrefix: false)` | `150.000` |
| `price.extToRupiah(showDecimal: true)` | `Rp 150.000,00` |
| `price.extToRibuan()` | `150.000` |
| `nullPrice.extToRupiah()` | `-` |

### Extension `double` / `double?` (`lib/core/extensions/double_ext.dart`)

| Method | Contoh Output |
|---|---|
| `balance.toCurrency()` | `Rp 1.500.000` |
| `balance.toCurrency(withPrefix: false)` | `1.500.000` |
| `balance.toCurrency(showDecimal: true)` | `Rp 1.500.000,00` |
| `balance.toCompactCurrency()` | `Rp 1,5 jt` |
| `balance.toThousands()` | `1.500.000` |
| `pct.toPercentage()` | `82,3%` |
| `pct.toPercentage(decimalDigits: 2)` | `82,30%` |
| `nullBalance.toCurrencyOrDash()` | `-` |

### Input Uang

Gunakan `SakuCurrencyField` (widget global) untuk input berupa uang — otomatis thousand formatter.

---

## Formatting Tanggal

**DILARANG KERAS** format tanggal secara manual di UI. WAJIB gunakan extension.

### Extension `DateTime?` (`lib/core/extensions/date_time_ext.dart`)

| Method | Contoh Output |
|---|---|
| `date.extToFormattedString()` | `2025-03-19` (default) |
| `date.extToFormattedString(outputDateFormat: 'dd/MM/yyyy')` | `19/03/2025` |
| `date.extToTimeString()` | `14:30` |
| `date.extToDateStringDDMMMMYYYY()` | `19 Maret 2025` |
| `date.extTimeAgo()` | `2 hari lalu` |
| `date.extIsToday` | `true / false` |
| `date.extIsYesterday` | `true / false` |
| `date.extIsThisWeek` | `true / false` |
| `date.extIsLastWeek` | `true / false` |
| `date.extIsSameDayMonthYear(other)` | `true / false` |
| `date.extIsSameMonthYear(other)` | `true / false` |
| `date.extIsSameYear(other)` | `true / false` |

### Extension `String` / `String?` (`lib/core/extensions/string_ext.dart`)

| Method | Contoh Output |
|---|---|
| `str.extToDateTime()` | `DateTime` object |
| `str.extToDateLocal()` | `DateTime` (local timezone) |
| `str.extToDateUtc()` | `DateTime` (UTC) |
| `str.extToCustomFormattedDate()` | `19-03-2025` (default) |
| `str.extToDateDDMMMMYYYY()` | `19 Maret 2025` |
| `str.extToConvertToLocal()` | `19-03-2025 - 14:30` |

> Semua extension date otomatis mengikuti locale aktif aplikasi — tanpa hardcode locale.

---

## Localization

- WAJIB gunakan file `.arb` untuk semua string UI
- **CEK DULU** apakah key sudah ada di file `.arb` sebelum menambahkan key baru
- DILARANG KERAS hardcode teks langsung di UI

---

## Logging

Gunakan `AppLogger.call` dengan format standar:

```
[Sync|Offline|Online] [{NamaFitur}] {pesan_log}
```

Pasang di tempat krusial: fetch data, insert, error.

---

## Naming Conventions

| Komponen | Pola Penamaan |
|---|---|
| Local data source | `{Feature}LocalDataSource` |
| Remote data source | `{Feature}RemoteDataSource` |
| Repository | `{Feature}Repository` |
| Widget spesifik fitur | Prefix dengan nama fitur (contoh: `WalletBalanceCard`) |
| Model class & file | Suffix `Model` (contoh: `WalletModel` di `wallet_model.dart`) |

---

## Icons

**Gunakan `FontAwesomeIcon`** (package `font_awesome_flutter`) untuk semua icon UI utama. Material Icons cenderung kaku dan tidak sesuai estetika SakuRapi.

---

## Edge Functions

Edge Functions SakuRapi berjalan di atas **Deno dan TypeScript** (bukan Node.js).

```typescript
// ✅ BENAR
const apiKey = Deno.env.get('GEMINI_API_KEY');

// ❌ SALAH
const apiKey = process.env.GEMINI_API_KEY;
```

---

## UI State Handling

| State | Implementasi |
|---|---|
| **Loading** | `ShimmerWidget` — DILARANG menggunakan `CircularProgressIndicator` |
| **Empty** | `SakuEmptyState` — ilustrasi + pesan persuasif |
| **Error** | `SakuErrorState` — dengan tombol "Coba Lagi" (retry) |
| **Blocking** | `context.showLoadingOverlay()`, tutup di `finally` dengan `context.closeOverlay()` |

---

## Testing Minimum

### Unit Test

- Repository CRUD (create/update/delete transaction)
- Controller history filter/grouping
- Parser fallback lokal
- Budget usage calculation
- Settlement validation

### Widget Test

- Form transaksi manual
- Multi-item input
- Wallet picker/filter
- Permission fallback state

### Integration Test

- Login → dashboard
- Create expense
- Create transfer
- Multi-item save
- Budget usage update
- Investment buy with wallet deduction

### Key Assertions

- Saldo wallet berubah sesuai ledger
- Transfer **tidak** masuk report
- Settlement **tidak** masuk report/budget
- Investment deduction **tidak** double count

---

## Forbidden Actions (Copilot)

Copilot dan developer **DILARANG**:

1. Membuat kolom DB tambahan tanpa referensi dokumen
2. Memakai Freezed/generator model tanpa instruksi eksplisit
3. Menyimpan nominal uang sebagai `double` untuk logic inti
4. Menghitung transfer sebagai expense atau income
5. Memasukkan settlement ke report utama
6. Mengupdate `wallets.balance` dari Flutter client
7. Memanggil provider AI langsung dari Flutter dengan API key
8. Memecah satu write atomik menjadi beberapa write rawan race condition
9. Menaruh business rules ke dalam widget
10. Menambah dependency berat tanpa alasan jelas

---

## Definition of Done

Sebuah task implementasi dianggap selesai jika memenuhi **8 kriteria**:

1. ✅ Mengikuti PRD (product requirements)
2. ✅ Mengikuti schema database
3. ✅ Tidak melanggar rules finansial
4. ✅ Tidak ada hardcoded text/color
5. ✅ Ada state loading/error/empty bila relevan
6. ✅ Ada validasi domain
7. ✅ Ada test minimal yang relevan
8. ✅ Tidak memindahkan logic inti ke widget

---

## Conflict Priority

Jika menemukan konflik antar dokumen, ikuti urutan prioritas berikut:

1. **`02_DATABASE.md`** — Schema dan constraint (tertinggi)
2. **`docs/prd/`** — Business intent dan flow
3. **`03_COPILOT_RULES.md`** — Cara implementasi
4. **Jangan asumsi** — Tandai sebagai `TODO/QUESTION`

> **`00_SakuRapi_Coding_Rules.md`** mengambil prioritas di atas **`03_COPILOT_RULES.md`** jika terjadi pertentangan pada aturan coding.

---

## Halaman Terkait

- [[wiki/concepts/arsitektur-app|Arsitektur App]]
- [[wiki/concepts/aturan-keuangan|Aturan Keuangan]]
- [[wiki/entities/database-schema|Database Schema]]
- [[wiki/concepts/roadmap-status|Roadmap & Status]]
- [[wiki/entities/sakurapi|SakuRapi]]
