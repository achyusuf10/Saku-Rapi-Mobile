---
title: "Matrix Transaksi"
type: concept
tags: [transaksi, matrix, tipe-transaksi, settlement, income, expense, transfer, debt, loan, adjustment]
sources: [raw/docs/prd/09_TRANSAKSI.md, raw/docs/prd/11_HUTANG_PIUTANG.md, raw/docs/prd/04_ATURAN_KEUANGAN.md]
created: 2026-04-10
updated: 2026-04-10
---

# Matrix Transaksi

> Halaman referensi utama untuk memahami **7 tipe transaksi** dan **aturan settlement** di SakuRapi. Halaman ini adalah salah satu referensi terpenting dalam wiki — selalu rujuk ke sini saat bekerja dengan logika transaksi.

---

## 7 Tipe Transaksi

SakuRapi memiliki tepat 7 tipe transaksi dasar. Setiap tipe memiliki perilaku berbeda terhadap wallet balance, laporan keuangan, dan budget.

### Tabel Ringkasan

| Tipe | Efek Balance | Masuk Laporan? | Masuk Budget? | Field Wajib Tambahan |
|---|---|---|---|---|
| `income` | ➕ wallet | ✅ Ya | ❌ Tidak | — |
| `expense` | ➖ wallet | ✅ Ya | ✅ Ya | — |
| `transfer` | ➖ asal, ➕ tujuan | ❌ Tidak | ❌ Tidak | `destination_wallet_id` |
| `debt` | ➕ wallet | ❌ Tidak | ❌ Tidak | `with_person` |
| `loan` | ➖ wallet | ❌ Tidak | ❌ Tidak | `with_person` |
| `adjustment` | ➕ atau ➖ (koreksi) | ❌ Tidak | ❌ Tidak | — |
| `transfer_to_asset` | ➖ wallet | ❌ Tidak | ❌ Tidak | — |

---

## Detail per Tipe

### 1. Income (Pemasukan)

- **Efek**: Menambah balance wallet
- **Laporan**: ✅ Masuk laporan pemasukan
- **Budget**: ❌ Tidak mempengaruhi budget (budget hanya untuk pengeluaran)
- **Contoh**: Gaji, bonus, hadiah, cashback

### 2. Expense (Pengeluaran)

- **Efek**: Mengurangi balance wallet
- **Laporan**: ✅ Masuk laporan pengeluaran
- **Budget**: ✅ Mengurangi sisa budget kategori terkait
- **Contoh**: Makan, transportasi, belanja, tagihan

### 3. Transfer (Antar Wallet)

- **Efek**: Mengurangi balance wallet asal, menambah balance wallet tujuan
- **Laporan**: ❌ Tidak masuk laporan (bukan pemasukan/pengeluaran riil)
- **Budget**: ❌ Tidak mempengaruhi budget
- **Field wajib**: `destination_wallet_id` — wallet tujuan transfer
- **Contoh**: Pindah dana dari rekening ke e-wallet

### 4. Debt (Hutang — Pinjaman Masuk)

- **Efek**: Menambah balance wallet (uang masuk dari pinjaman)
- **Laporan**: ❌ Tidak masuk laporan (bukan pemasukan riil)
- **Budget**: ❌ Tidak mempengaruhi budget
- **Field wajib**: `with_person` — nama orang/pihak pemberi pinjaman
- **Catatan**: Menciptakan kewajiban outstanding yang harus diselesaikan
- **Contoh**: Pinjam uang dari teman, kasbon

### 5. Loan (Piutang — Pinjamkan Keluar)

- **Efek**: Mengurangi balance wallet (uang keluar untuk dipinjamkan)
- **Laporan**: ❌ Tidak masuk laporan (bukan pengeluaran riil)
- **Budget**: ❌ Tidak mempengaruhi budget
- **Field wajib**: `with_person` — nama orang/pihak peminjam
- **Catatan**: Menciptakan piutang outstanding yang harus ditagih
- **Contoh**: Meminjamkan uang ke teman, talangan

### 6. Adjustment (Penyesuaian)

- **Efek**: Menambah atau mengurangi balance (koreksi saldo)
- **Laporan**: ❌ Tidak masuk laporan
- **Budget**: ❌ Tidak mempengaruhi budget
- **Contoh**: Koreksi saldo awal, penyesuaian selisih

### 7. Transfer to Asset (Transfer ke Aset)

- **Efek**: Mengurangi balance wallet (dana dikonversi ke aset investasi)
- **Laporan**: ❌ Tidak masuk laporan (bukan pengeluaran, tapi konversi bentuk)
- **Budget**: ❌ Tidak mempengaruhi budget
- **Contoh**: Beli emas, beli saham, top-up reksadana

---

## Aturan Settlement

Settlement adalah mekanisme penyelesaian hutang (`debt`) dan piutang (`loan`). Settlement **bukan** tipe transaksi tersendiri, melainkan transaksi `income` atau `expense` dengan penanda khusus.

### Tabel Settlement

| Settlement Kind | Arti | Type Transaksi | Efek Balance |
|---|---|---|---|
| `debt_payment` | Bayar hutang | `expense` | ➖ wallet (uang keluar untuk bayar hutang) |
| `loan_collection` | Terima pembayaran piutang | `income` | ➕ wallet (uang masuk dari piutang dilunasi) |

### Aturan Kritis Settlement

1. **DIKECUALIKAN dari laporan dan budget** — Meskipun type-nya `income` atau `expense`, settlement **tidak masuk** laporan keuangan dan **tidak mempengaruhi** budget. Ini karena dana yang bergerak adalah penyelesaian transaksi sebelumnya, bukan pemasukan/pengeluaran baru.

2. **Amount ≤ sisa outstanding** — Jumlah settlement tidak boleh melebihi sisa hutang/piutang yang belum dilunasi. Validasi ini dilakukan di level RPC/database.

3. **Wajib punya `reference_transaction_id`** — Setiap settlement harus merujuk ke transaksi hutang/piutang asli yang sedang diselesaikan.

4. **Pembayaran parsial diperbolehkan** — User bisa melunasi sebagian. Sisa outstanding berkurang sesuai jumlah yang dibayar.

### Alur Settlement

```
[Debt/Loan asli] → outstanding tercatat
        ↓
[User pilih "Bayar" / "Terima Pembayaran"]
        ↓
[INSERT transaksi: type=expense/income, settlement_kind=debt_payment/loan_collection]
        ↓
[reference_transaction_id → pointing ke debt/loan asli]
        ↓
[DB Trigger: update wallet balance + kurangi outstanding]
        ↓
[Settlement TIDAK masuk laporan/budget]
```

---

## Diagram Relasi Tipe → Laporan → Budget

```
income ──────────► Laporan ✅    Budget ❌
expense ─────────► Laporan ✅    Budget ✅
transfer ────────► Laporan ❌    Budget ❌
debt ────────────► Laporan ❌    Budget ❌
loan ────────────► Laporan ❌    Budget ❌
adjustment ──────► Laporan ❌    Budget ❌
transfer_to_asset► Laporan ❌    Budget ❌

--- Settlement (pengecualian) ---
debt_payment ────► type=expense  BUT  Laporan ❌  Budget ❌
loan_collection ─► type=income   BUT  Laporan ❌  Budget ❌
```

---

## Validasi dan Guardrails

| Validasi | Berlaku untuk |
|---|---|
| `destination_wallet_id` wajib diisi | `transfer` |
| `with_person` wajib diisi | `debt`, `loan` |
| `reference_transaction_id` wajib diisi | settlement (`debt_payment`, `loan_collection`) |
| Amount ≤ outstanding | settlement |
| Amount > 0 | semua tipe |
| `wallet_id` valid dan milik user | semua tipe |

---

## Catatan Penting

- **Income tidak masuk budget**: Budget di SakuRapi hanya mengontrol pengeluaran, bukan pemasukan
- **Transfer bukan pengeluaran**: Memindahkan uang antar wallet sendiri tidak dihitung sebagai expense
- **Debt ≠ Income**: Menerima pinjaman menambah saldo tapi bukan pemasukan riil
- **Loan ≠ Expense**: Meminjamkan uang mengurangi saldo tapi bukan pengeluaran riil

---

## Halaman Terkait

- [[wiki/concepts/aturan-keuangan|Aturan Keuangan Fundamental]] — Aturan emas dan keputusan final
- [[wiki/entities/transaksi|Transaksi]] — Entitas transaksi dan field-fieldnya
- [[wiki/entities/wallet|Wallet]] — Entitas wallet
- [[wiki/concepts/arsitektur-app|Arsitektur App]] — Guardrails keuangan dalam arsitektur
- [[wiki/concepts/ai-pipeline|AI Pipeline]] — Bagaimana AI mengisi tipe transaksi
- [[wiki/sources/prd-sakurapi-v7|PRD SakuRapi v7.0]] — Dokumen sumber
