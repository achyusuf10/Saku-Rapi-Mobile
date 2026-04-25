---
title: "Arsitektur Aplikasi"
type: concept
tags: [arsitektur, flutter, riverpod, supabase, hive, gorouter, 3-file-pattern, model, provider, ui]
sources: [raw/docs/prd/01_TENTANG_SAKURAPI.md, raw/docs/prd/04_ATURAN_KEUANGAN.md, raw/docs/00_SakuRapi_Coding_Rules.md, raw/docs/03_COPILOT_RULES.md]
created: 2026-04-10
updated: 2026-04-25
---

# Arsitektur Aplikasi

> Halaman ini mendokumentasikan arsitektur teknis aplikasi SakuRapi — dari tech stack hingga konvensi UI.

---

## Tech Stack

| Komponen | Teknologi | Catatan |
|---|---|---|
| **Framework** | Flutter (via FVM 3.41.6) | Versi Flutter dikelola FVM |
| **State Management** | Riverpod | Tanpa code generator (tanpa `riverpod_generator`) |
| **Routing** | GoRouter | Deklaratif routing |
| **Local Storage** | Hive | Cache dan offline data |
| **Backend** | Supabase | Auth, database, Edge Functions, RLS |
| **Icons** | font_awesome_flutter | Bukan Material Icons bawaan |

---

## 3-File Data Pattern

Setiap feature yang membutuhkan data mengikuti pola **3 file** yang konsisten:

```
lib/features/<nama_fitur>/data/
├── local_data_source.dart      # Hive / cache layer
├── remote_data_source.dart     # Supabase calls via SupabaseHandler
└── repository.dart             # Orchestrator
```

### 1. `local_data_source.dart`

- Berinteraksi dengan **Hive** untuk caching dan offline access
- Menyimpan dan membaca data dari local storage
- Tidak tahu tentang Supabase atau network

### 2. `remote_data_source.dart`

- Berinteraksi dengan **Supabase** melalui `SupabaseHandler`
- Melakukan RPC calls, queries, dan mutations
- Tidak tahu tentang Hive atau local storage

### 3. `repository.dart`

- **Orchestrator** yang mengoordinasikan local dan remote data source
- Menentukan kapan pakai cache vs fetch ulang
- Pattern-match menggunakan `DataState` untuk menangani loading/success/error

```dart
// Contoh pattern matching di repository
final result = await remoteDataSource.fetchWallets();
return result.when(
  success: (data) {
    localDataSource.cacheWallets(data);
    return DataState.success(data);
  },
  error: (e) => DataState.error(e),
);
```

---

## Layering Rules

Setiap layer memiliki tanggung jawab yang jelas dan **tidak boleh dilanggar**:

| Layer | Tanggung Jawab | Contoh |
|-------|---------------|--------|
| **Widget** | Presentation dan user interaction saja | `WalletListScreen`, `TransactionFormSheet` |
| **Controller/Notifier** | Orchestration UI state | `WalletController extends StateNotifier` |
| **Repository** | Business coordination | `WalletRepository` — orchestrate local+remote |
| **RemoteDataSource** | Komunikasi Supabase/RPC/API | `WalletRemoteDataSource` |
| **LocalDataSource** | Hive/cache/local helpers | `WalletLocalDataSource` |

> **Larangan:** Business rule finansial **tidak boleh** diletakkan di `build()` widget.

---

## Aturan Model

Semua model class mengikuti konvensi ketat:

| Aturan | Detail |
|---|---|
| **Penamaan** | Class dan file berakhiran `Model` (contoh: `WalletModel`, `wallet_model.dart`) |
| **Implementasi** | Plain Dart class — **tanpa Freezed**, tanpa json_serializable |
| **Method wajib** | `copyWith()`, `toMap()`, `fromMap()` |
| **Immutability** | Field bersifat `final`, mutasi via `copyWith()` |

```dart
class WalletModel {
  final String id;
  final String name;
  final int balance;

  const WalletModel({required this.id, required this.name, required this.balance});

  WalletModel copyWith({String? id, String? name, int? balance}) {
    return WalletModel(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'balance': balance};

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      id: map['id'] as String,
      name: map['name'] as String,
      balance: map['balance'] as int,
    );
  }
}
```

---

## Aturan Provider (Riverpod)

### Tipe Provider yang Digunakan

| Tipe | Kegunaan |
|---|---|
| `StateNotifierProvider` | State yang mutable dan complex (form, list management) |
| `FutureProvider` | Data fetching one-time |
| `Provider` | Computed values, dependency injection |

### Aturan Scope

- **`.autoDispose`** untuk provider yang terikat ke satu screen (screen-scoped)
- Provider tanpa `.autoDispose` untuk data yang perlu persisten selama app lifecycle
- **Tidak menggunakan** `riverpod_generator` — semua provider ditulis manual

---

## Konvensi UI

### Styling

| Aspek | Konvensi |
|---|---|
| **Warna** | `context.colors` (extension pada BuildContext) |
| **Typography** | `TextStyleConstants` (konstanta global) |
| **Responsive sizing** | `ScreenUtil` — gunakan `.h`, `.w`, `.r`, `.sp` |
| **Format rupiah** | Extension `extToRupiah()` |
| **Localization** | File `.arb` — tidak boleh ada hardcoded string di UI |
| **Hardcoded styles** | ❌ Dilarang — semua harus via constants atau theme |

### Contoh Penggunaan

```dart
// Warna via context extension
Container(color: context.colors.primary)

// Typography via constants
Text('Hello', style: TextStyleConstants.heading1)

// Responsive sizing
SizedBox(height: 16.h, width: 200.w)
Padding(padding: EdgeInsets.all(12.r))
Text('Label', style: TextStyle(fontSize: 14.sp))

// Format rupiah
Text(amount.extToRupiah()) // → "Rp 150.000"
```

---

## Global Widgets

SakuRapi memiliki widget library yang konsisten:

| Widget | Kegunaan |
|---|---|
| `SakuButton` | Tombol utama dan sekunder |
| `SakuTextField` | Input teks standar |
| `SakuCurrencyField` | Input khusus nilai uang (format otomatis) |
| `SakuCard` | Card container standar |
| `ShimmerWidget` | Loading placeholder (shimmer effect) |
| `SakuEmptyState` | Tampilan saat data kosong |
| `SakuErrorState` | Tampilan saat terjadi error |

### Loading Pattern

| Situasi | Widget |
|---|---|
| **Loading data** (non-blocking) | `ShimmerWidget` — **bukan** `CircularProgressIndicator` |
| **Loading aksi** (blocking) | `showLoadingOverlay()` / `closeOverlay()` |

> **Penting**: `CircularProgressIndicator` **tidak digunakan** di SakuRapi. Selalu gunakan `ShimmerWidget` untuk loading state.

---

## Financial Guardrails dalam Code

Aturan keuangan yang harus ditegakkan di level arsitektur:

| Guardrail | Implementasi |
|---|---|
| **Integer untuk uang** | Semua nilai moneter bertipe `int`, bukan `double` |
| **UTC timestamp storage** | Semua timestamp point-in-time disimpan sebagai UTC ISO 8601 |
| **Calendar date storage** | Field kalender murni seperti `due_date` dan periode budget disimpan sebagai `YYYY-MM-DD`; event time seperti `transactions.date` dan `investment_transactions.date` tetap timestamp UTC |
| **Local rendering** | UI menampilkan timestamp dalam local device user (`toLocal()`) |
| **Balance via trigger** | Tidak ada code Dart yang mengubah `wallet.balance` secara langsung |
| **AI prefill only** | Hasil AI parsing hanya mengisi form, user wajib konfirmasi |

---

## Struktur Folder Umum

```
lib/
├── app/                    # App-level config (theme, router, etc.)
├── core/                   # Shared utilities, constants, extensions
│   ├── constants/          # TextStyleConstants, dll
│   ├── extensions/         # context.colors, extToRupiah, dll
│   ├── widgets/            # SakuButton, SakuTextField, ShimmerWidget, dll
│   └── handlers/           # SupabaseHandler, dll
├── features/               # Feature modules
│   ├── auth/
│   ├── wallet/
│   │   ├── data/           # 3-File Pattern
│   │   ├── providers/      # Riverpod providers
│   │   └── presentation/   # Screens & widgets
│   ├── transaction/
│   ├── budget/
│   ├── ...
└── main.dart
```

---

## Testing Requirements

### Unit Test
- Repository create/update/delete transaction
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
- Login → Dashboard
- Create expense
- Create transfer
- Multi-item save
- Budget usage update
- Investment buy with wallet deduction

### Assertion Penting
- Saldo wallet berubah sesuai ledger
- Transfer tidak masuk report
- Settlement tidak masuk report/budget
- Investment deduction tidak double count

### Definition of Done
Sebuah task selesai jika:
1. Mengikuti PRD
2. Mengikuti schema database
3. Tidak melanggar rules finansial
4. Tidak ada hardcoded text/color
5. Ada state loading/error/empty
6. Ada validasi domain
7. Ada test minimal
8. Business logic tidak di widget

---

## Halaman Terkait

- [[wiki/concepts/aturan-keuangan|Aturan Keuangan Fundamental]] — Guardrails keuangan
- [[wiki/concepts/matrix-transaksi|Matrix Transaksi]] — Tipe transaksi
- [[wiki/concepts/ai-pipeline|AI Pipeline]] — Arsitektur AI parsing
- [[wiki/concepts/roadmap-status|Roadmap & Status]] — Status development
- [[wiki/entities/wallet|Wallet]] — Entitas wallet
- [[wiki/entities/transaksi|Transaksi]] — Entitas transaksi
- [[wiki/sources/prd-sakurapi-v7|PRD SakuRapi v7.0]] — Dokumen sumber
- [[wiki/concepts/coding-rules|Coding Rules]] — Aturan coding dan konvensi
- [[wiki/entities/database-schema|Database Schema]] — Skema terkini (termasuk katalog kategori global)
- [[wiki/sources/coding-rules|Coding Rules (Sumber)]] — Ringkasan coding rules
- [[wiki/sources/copilot-rules|Copilot Rules (Sumber)]] — Ringkasan copilot guardrails
- [[wiki/concepts/design-system|Design System]]
