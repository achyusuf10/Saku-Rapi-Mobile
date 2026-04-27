---
title: "Transaksi"
type: entity
tags: [transaksi, fitur, form, rpc, multi-item]
sources: [raw/docs/prd/09_TRANSAKSI.md, raw/docs/prd/10_TRANSACTION_DETAIL.md, raw/docs/prd/04_ATURAN_KEUANGAN.md, raw/docs/02_DATABASE.md, raw/docs/MULTI_MANUAL_TRANSACTION_PLAN.md]
created: 2026-04-10
updated: 2026-04-27
---

# Transaksi

## Deskripsi

Transaksi adalah entitas inti SakuRapi — setiap pergerakan uang dicatat sebagai transaksi. Form transaksi mendukung **4 tipe utama** melalui tab-based UI, termasuk sub-mode untuk hutang/piutang. Semua submit transaksi berjalan secara **atomik via RPC** di server untuk menjamin konsistensi data.

## Tipe Transaksi

### 4 Tab Utama

| Tab | Deskripsi |
|-----|-----------|
| **Expense** | Pengeluaran dari wallet |
| **Income** | Pemasukan ke wallet |
| **Transfer** | Pemindahan antar wallet |
| **Hutang/Piutang** | Pinjaman dan penagihan dengan kontak |

### Sub-mode Hutang/Piutang

Tab Hutang/Piutang memiliki **4 sub-mode**:

| Sub-mode | Arti |
|----------|------|
| **Hutang** | Saya meminjam uang dari seseorang (uang masuk) |
| **Piutang** | Saya meminjamkan uang ke seseorang (uang keluar) |
| **Pelunasan** | Saya membayar hutang saya (uang keluar) |
| **Terima** | Saya menerima pembayaran piutang (uang masuk) |

Lihat detail manajemen di [[wiki/entities/hutang-piutang|Hutang/Piutang]].

## Field Wajib per Tipe

| Field | Expense | Income | Transfer | Hutang/Piutang |
|-------|:-------:|:------:|:--------:|:--------------:|
| Amount | ✅ | ✅ | ✅ | ✅ |
| Wallet | ✅ | ✅ | ✅ (from) | ✅ |
| Wallet tujuan | — | — | ✅ (to) | — |
| Kategori | ✅ | ✅ | — | — |
| Tanggal | ✅ | ✅ | ✅ | ✅ |
| Kontak (with_person) | — | — | — | ✅ (wajib) |
| Catatan | opsional | opsional | opsional | opsional |

**Catatan waktu:** field tanggal transaksi adalah **point-in-time event**. Jika user memilih jam, Flutter mengirim nilai sebagai **UTC ISO 8601**, lalu UI merendernya kembali dalam local timezone device user. Hanya `due_date` yang tetap date-only.

## Fitur Utama

### Multi-item Support

- Satu transaksi bisa memiliki **banyak item** (line items).
- Aturan: **SUM(items) == total_amount** dengan toleransi **0.01** (pembulatan).
- **Satu kategori untuk seluruh transaksi** (expense & income): kategori dipilih di level form (setelah wallet), bukan per baris. Semua baris disinkronkan ke `category_id` yang sama sebelum RPC; data lama dengan kategori berbeda per baris saat diedit disatukan ke kategori baris pertama.
- Prefill voice/OCR multi-item: baris tanpa `categoryId` per item; kategori hanya dari field root AI (`categoryId` / `categoryKeyword`).
- Berguna untuk mencatat belanjaan dengan rincian per item.

### Mode multi transaksi (manual, expense & income)

Hanya saat **buat** transaksi baru (bukan edit), user bisa mengaktifkan **multi transaksi**: beberapa transaksi dalam satu simpan, via RPC **`create_transactions_batch`** (atomik, batas **10** entri per batch).

**Per transaksi dalam daftar** perilaku **diselaraskan dengan tab transaksi tunggal**:

- Default **satu item** per baris: input nominal memakai **`TransactionAmountSection`** (bukan baris `TransactionItemRow` tunggal).
- **Multi-item** diaktifkan dengan chip **Tambah item** pada **`TransactionMultiItemSection`**, sama seperti form tunggal; setelah ada lebih dari satu item, tampil ringkasan total + daftar baris + reorder.
- State per entri: `ManualTransactionEntryModel` di `manualMultiEntries`; sinkron nominal satu item lewat `setManualMultiEntryTotalAmount` (setara `setTotalAmount` pada form flat).

Detail teknis, checklist migrasi, dan daftar file: [[wiki/sources/plan-multi-manual-transaction|Plan: Multi Transaksi Manual]] / [[raw/docs/MULTI_MANUAL_TRANSACTION_PLAN|MULTI_MANUAL_TRANSACTION_PLAN.md]].

### Contact Picker

- Untuk tipe Hutang/Piutang, field `with_person` **wajib diisi**.
- Sumber kontak:
  1. **Phonebook** — dari kontak HP
  2. **Tersimpan** — kontak yang pernah digunakan sebelumnya
  3. **Manual** — ketik nama langsung

### Lampiran (Attachment)

- User bisa melampirkan foto/dokumen (misalnya foto struk).
- Upload menggunakan **lazy upload** ke Supabase Storage — file diupload di background, tidak memblokir submit form.

### Submit & Validasi

- Submit transaksi melalui **RPC call** yang berjalan secara **atomik** di server.
- **Anti double-submit flag** — mencegah duplikasi jika user menekan tombol submit berkali-kali.
- Validasi utama:
  - `amount > 0` — jumlah harus positif
  - Transfer: wallet asal **≠** wallet tujuan
  - Settlement: jumlah pelunasan **≤** sisa outstanding

## Database Schema

### Tabel `transactions`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK | owner |
| wallet_id | uuid FK | wallet asal |
| destination_wallet_id | uuid nullable FK | wallet tujuan (transfer) |
| type | text not null | `income`, `expense`, `transfer`, `debt`, `loan`, `adjustment`, `transfer_to_asset` |
| total_amount | numeric not null | grand total, CHECK > 0 |
| date | timestamptz not null | waktu transaksi UTC (point-in-time) |
| merchant_name | text nullable | |
| note | text nullable | |
| attachment_url | text nullable | |
| with_person | text nullable | wajib untuk debt/loan |
| status | text nullable | `unpaid`, `paid`, `partial` (debt/loan) |
| due_date | date nullable | tanggal jatuh tempo kalender |
| is_multi_item | boolean not null default false | |
| reference_transaction_id | uuid nullable FK self | untuk settlement |
| settlement_kind | text nullable | `debt_payment`, `loan_collection` |
| contact_id | uuid nullable FK | referensi ke contacts |
| created_at / updated_at | timestamptz | timestamp audit UTC |

**Catatan:** `date` adalah waktu kejadian transaksi yang disimpan sebagai `timestamptz` (UTC) lalu dirender lokal di client. `due_date` tetap field kalender murni (`YYYY-MM-DD`).

### Tabel `transaction_items`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| transaction_id | uuid FK | parent transaction |
| category_id | uuid nullable FK | wajib untuk income/expense |
| item_name | text nullable | nama item OCR/manual |
| qty | numeric not null default 1 | CHECK > 0 |
| unit_price | numeric nullable | harga per unit |
| amount | numeric not null | subtotal, CHECK > 0 |
| note | text nullable | |
| sort_order | integer not null default 0 | |

**RPC Functions:**
- `create_transaction_with_items(...)` → jsonb
- `create_transactions_batch(p_transactions jsonb)` → jsonb — banyak transaksi expense/income sekaligus (max 10)
- `update_transaction_with_items(...)` → jsonb
- `delete_transaction(p_transaction_id)` → jsonb

## Cara Kerja

```
┌────────────────────────────────────┐
│  Form Transaksi (4 Tab)            │
│  ┌──────┬────────┬────────┬──────┐ │
│  │Expense│Income │Transfer│H/P   │ │
│  └──────┴────────┴────────┴──────┘ │
│                                    │
│  Isi field → Validasi client-side  │
│  → Anti double-submit lock         │
│  → Submit via RPC (atomik)         │
└────────────────┬───────────────────┘
                 │
                 ▼
┌────────────────────────────────────┐
│  Supabase Server                   │
│  - Insert transaksi                │
│  - DB trigger update_wallet_balance│
│  - Lazy upload attachment          │
└────────────────────────────────────┘
```

1. User memilih tab tipe transaksi.
2. Mengisi field sesuai tipe (lihat matrix di atas).
3. Opsional: tambah multi-item, kontak, lampiran.
4. Client melakukan validasi lokal.
5. Submit via RPC — server memproses secara atomik.
6. DB trigger memperbarui saldo [[wiki/entities/wallet|Wallet]].

## Halaman Terkait

- [[wiki/entities/sakurapi|SakuRapi]]
- [[wiki/entities/wallet|Wallet]]
- [[wiki/entities/dashboard|Dashboard]]
- [[wiki/entities/hutang-piutang|Hutang/Piutang]]
- [[wiki/entities/budgeting|Budgeting]]
- [[wiki/concepts/aturan-keuangan|Aturan Keuangan]]
- [[wiki/entities/database-schema|Database Schema]]
- [[wiki/entities/categories|Categories]]
- [[wiki/sources/prd-sakurapi-v7|PRD SakuRapi v7.0]]
- [[wiki/concepts/design-system|Design System]]
- [[wiki/sources/redesign-ui-ux|Redesign UI/UX (Sumber)]]
- [[wiki/sources/plan-multi-manual-transaction|Plan: Multi Transaksi Manual]]
