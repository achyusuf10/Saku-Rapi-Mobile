---
title: "SakuRapi Merged Copilot Rules — Ringkasan"
type: source
tags: [copilot-rules, guardrails, financial-rules, testing, arsitektur, conventions, sakurapi]
sources: [raw/docs/03_COPILOT_RULES.md]
created: 2026-04-10
updated: 2026-04-10
---

# SakuRapi Merged Copilot Rules — Ringkasan

**Jenis**: Dokumen internal — Panduan implementasi untuk Copilot/AI assistant dan developer
**Tanggal sumber**: 2026 (Merged Rules Final — Bagian A: Coding Rules + Bagian B: Copilot Rules v6.1)
**Status**: Wajib diikuti
**Aturan konflik**: Bagian A (00_SakuRapi_Coding_Rules.md) **lebih prioritas** dari Bagian B pada konflik

## Ringkasan

Dokumen ini adalah penggabungan penuh dari dua dokumen utama SakuRapi: `00_SakuRapi_Coding_Rules.md` (Bagian A) dan `03_COPILOT_RULES.md` (Bagian B — Copilot Rules v6.1). Bagian A berisi aturan coding dan konvensi umum (diringkas terpisah di [[wiki/sources/coding-rules|Coding Rules]]). Ringkasan ini fokus pada **poin-poin unik di Bagian B** yang tidak tercakup di Bagian A, terutama guardrails finansial, aturan layering, forbidden actions, testing minimum, dan feature-specific rules.

Tujuan utama dokumen Bagian B adalah **mencegah Copilot** dari: mengarang schema database, salah menghitung saldo/budget/laporan, menyebarkan business logic ke widget, dan membuat implementasi yang bertentangan dengan rule finansial produk. Dokumen ini berfungsi sebagai "pagar pengaman" yang menjaga agar output AI selalu konsisten dengan arsitektur dan aturan bisnis SakuRapi.

Bagian B juga mendefinisikan testing minimum yang wajib dipenuhi, Definition of Done untuk setiap task, serta prioritas referensi yang jelas saat terjadi konflik antar dokumen.

## Poin Kunci

### Tujuan Dokumen
Mencegah Copilot/AI dari 4 kesalahan utama:
1. **Mengarang schema** database yang tidak ada
2. **Salah menghitung** saldo, budget, atau laporan
3. **Menyebarkan business logic** ke dalam widget
4. **Membuat implementasi** yang bertentangan dengan aturan finansial

### Tech Stack Ringkas
- **FVM** untuk Flutter versioning
- **Riverpod** tanpa generator untuk state management
- **GoRouter** untuk routing
- **Hive** untuk local storage
- **Supabase** untuk backend
- **3-File Pattern**: LocalDataSource → RemoteDataSource → Repository
- **`.arb`** untuk lokalisasi
- **FontAwesome** untuk icon UI utama

### Layering Rules (Pemisahan Tanggung Jawab)

| Layer | Tanggung Jawab |
|-------|---------------|
| **Widget** | Presentation dan user interaction saja |
| **Controller/Notifier** | Orkestrasi UI state |
| **Repository** | Business coordination |
| **RemoteDataSource** | Komunikasi Supabase/RPC/API |
| **LocalDataSource** | Hive/cache/local helpers |

> **Rule kunci:** Business rule finansial **tidak boleh** diletakkan di `build()` widget.

### 10 Guardrails Finansial (Non-Negotiable)
1. Saldo wallet **tidak boleh diubah langsung** dari Flutter
2. Semua perubahan saldo harus berasal dari `transactions`
3. Semua transaksi harus punya minimal 1 `transaction_item`
4. `sum(transaction_items.amount)` == `transactions.total_amount`
5. Transfer **bukan** expense
6. `transfer_to_asset` **bukan** expense
7. Settlement hutang/piutang **bukan** income/expense untuk report
8. Budget hanya menghitung transaksi expense non-settlement
9. AI Voice/OCR hanya prefill — user tetap review sebelum save
10. Currency MVP hanya IDR

### Money, Date, dan Domain Handling

**Money handling:**
- **Dilarang** `double` untuk kalkulasi bisnis — gunakan `int` minor unit atau `Decimal`
- Formatting uang hanya di presentation layer, bukan sebagai source of truth

**Date handling:**
- Timestamp disimpan **UTC**
- Grouping harian/mingguan/bulanan menggunakan timezone **Asia/Jakarta**
- Jangan campur `DateTime.now()` lokal untuk logic inti tanpa normalisasi timezone

**Domain validation (sebelum save):**
- `total_amount > 0` (kecuali adjustment berdasarkan selisih)
- Transfer wajib wallet tujuan, tidak boleh sama dengan wallet asal
- `with_person` wajib untuk `debt`/`loan`
- Settlement tidak boleh melebihi outstanding principal
- Multi-item: total item harus == total transaksi

### Atomic Write via RPC
5 RPC kunci untuk write kompleks (jangan multi-step dari client):
1. `create_transaction_with_items(...)`
2. `update_transaction_with_items(...)`
3. `create_adjustment_transaction(...)`
4. `create_investment_with_optional_wallet_deduction(...)`
5. `settle_debt_or_loan(...)`

### Caching Strategy
- **Parsing dictionary**: cache 24 jam
- **Harga investasi**: cache 1 jam
- **History grouping**: dilakukan lokal — jangan refetch hanya karena ganti grouping

### UI Rules

**Wajib:**
- Semua string UI dari `.arb`
- Semua warna dari theme/context extensions
- Semua icon utama dari `font_awesome_flutter`
- Loading, empty, dan error state wajib ada
- Submit button harus **anti double-tap**
- Permission diminta just-in-time

**Dilarang:**
- Hardcoded text dan color
- Logika hitung total tersebar di widget tree
- Mengubah state domain dari beberapa tempat tanpa single source of truth

### Feature-Specific Rules

**Dashboard:**
- Jangan fetch seluruh histori — ambil ringkasan seperlunya
- Total saldo hanya dari wallet `exclude_from_total = false`

**History:**
- Query backend hanya untuk date range + filter wallet
- Grouping by date/category dilakukan **lokal**
- Mengganti grouping **tidak boleh** memicu refetch bila source sama

**Transactions:**
- Single-item tetap membuat 1 row `transaction_items`
- Multi-item hanya untuk expense
- Delete/edit harus menjaga konsistensi saldo

**Voice & OCR:**
- Output AI = **suggestion**, bukan final
- Parse gagal sebagian → form tetap terbuka dengan field parsial
- **Jangan** auto-save hasil AI
- API key AI **tidak boleh** di client

**Budget:**
- Hanya category expense
- Parent budget boleh terpakai oleh child expense
- Alert 80%/100% harus idempotent per periode

**Investments:**
- Harga live hanya untuk **display**
- Avg buy price = source of truth pembelian
- Jika potong wallet → buat transaksi `transfer_to_asset`
- Jangan potong wallet langsung dari tabel investments

### 10 Forbidden Actions untuk Copilot
1. Membuat kolom DB tambahan tanpa referensi dokumen
2. Memakai Freezed/generator model tanpa instruksi eksplisit
3. Menyimpan nominal uang sebagai `double` untuk logic inti
4. Menghitung transfer sebagai expense/income
5. Memasukkan settlement ke report utama
6. Meng-update `wallets.balance` dari Flutter client
7. Memanggil provider AI langsung dari Flutter dengan API key
8. Memecah satu write atomik menjadi beberapa write rawan race condition
9. Menaruh business rules ke dalam widget
10. Menambah dependency berat tanpa alasan jelas

### Testing Minimum

**Unit test (5 area):**
- Repository create/update/delete transaction
- Controller history filter/grouping
- Parser fallback lokal
- Budget usage calculation
- Settlement validation

**Widget test (4 area):**
- Form transaksi manual
- Multi-item input
- Wallet picker/filter
- Permission fallback state

**Integration test (6 skenario):**
- Login → dashboard
- Create expense
- Create transfer
- Multi-item save
- Budget usage update
- Investment buy with wallet deduction

**4 Assertion penting:**
1. Saldo wallet berubah sesuai ledger
2. Transfer tidak masuk report
3. Settlement tidak masuk report/budget
4. Investment deduction tidak double count

### Definition of Done
Sebuah task dianggap selesai jika:
- Mengikuti PRD
- Mengikuti schema database
- Tidak melanggar rules finansial
- Tidak ada hardcoded text/color
- Ada state loading/error/empty bila relevan
- Ada validasi domain (bukan hanya validasi UI)
- Ada test minimal yang relevan
- Tidak memindahkan logic inti ke widget

### Prioritas pada Konflik
1. **`02_DATABASE.md`** — untuk schema dan constraint (otoritas tertinggi)
2. **`docs/prd/`** — untuk business intent dan flow
3. **Dokumen ini** — untuk cara implementasi
4. Jangan membuat asumsi baru tanpa menandai sebagai **TODO/QUESTION**

> **Catatan:** Pada konflik antara Bagian A dan Bagian B dalam dokumen ini sendiri, **Bagian A (Coding Rules) yang dimenangkan**.

## Relevansi untuk SakuRapi

Dokumen ini adalah panduan implementasi yang paling komprehensif untuk Copilot/AI assistant. Guardrails finansial yang didefinisikan di sini bersifat **non-negotiable** dan menjadi fondasi integritas data keuangan aplikasi. Forbidden actions list mencegah kesalahan umum yang sering dilakukan oleh AI coding assistant. Testing minimum dan Definition of Done memberikan standar kualitas yang terukur untuk setiap deliverable.

## Halaman Terkait

- [[wiki/concepts/arsitektur-app|Arsitektur App]]
- [[wiki/concepts/aturan-keuangan|Aturan Keuangan]]
- [[wiki/sources/coding-rules|Coding Rules (source)]]
- [[wiki/entities/database-schema|Database Schema]]
- [[wiki/concepts/roadmap-status|Roadmap & Status]]
