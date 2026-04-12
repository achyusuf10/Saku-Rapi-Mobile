---
title: "Aturan Keuangan Fundamental"
type: concept
tags: [keuangan, aturan, trigger, wallet, balance, keputusan-final]
sources: [raw/docs/prd/04_ATURAN_KEUANGAN.md, raw/docs/02_DATABASE.md, raw/docs/03_COPILOT_RULES.md]
created: 2026-04-10
updated: 2026-04-12
---

# Aturan Keuangan Fundamental

> Halaman ini mendokumentasikan **aturan-aturan keuangan yang tidak boleh dilanggar** dalam SakuRapi. Seluruh developer, LLM, dan kontributor wajib mematuhi aturan ini tanpa pengecualian.

---

## Aturan Emas: Balance Hanya Berubah via Trigger

**Wallet balance HANYA berubah melalui tabel `transactions` via database trigger.**

Tidak ada kode Flutter, RPC manual, atau proses lain yang boleh mengubah kolom `wallet.balance` secara langsung. Satu-satunya mekanisme yang sah adalah:

```
Aksi User → RPC → INSERT INTO transactions → DB Trigger (update_wallet_balance) → wallet.balance terupdate
```

### Mengapa Aturan Ini Ada?

- **Konsistensi data**: Balance selalu sinkron dengan history transaksi
- **Audit trail**: Setiap perubahan balance pasti memiliki record transaksi
- **Keamanan**: RLS dan trigger di Supabase menjadi satu-satunya gatekeeper

### Larangan Keras

| ❌ Dilarang | ✅ Yang Benar |
|---|---|
| `UPDATE wallets SET balance = ...` dari Flutter | INSERT transaksi via RPC, trigger yang update |
| Mengubah balance di client-side lalu sync | Semua mutasi balance melalui server-side trigger |
| Kalkulasi balance manual di app | Balance dibaca dari `wallet.balance` yang di-maintain trigger |

---

## Settlement Dikecualikan dari Laporan dan Budget

Transaksi bertipe settlement (`debt_payment` dan `loan_collection`) **DIKECUALIKAN** dari laporan keuangan dan perhitungan budget, meskipun secara teknis bertipe `income` atau `expense`.

Alasannya: settlement adalah penyelesaian hutang/piutang yang sudah tercatat sebelumnya, bukan pemasukan/pengeluaran baru.

Lihat detail lengkap di → [[wiki/concepts/matrix-transaksi|Matrix Transaksi]]

---

## Pengaturan Mata Uang dan Waktu

| Aspek | Aturan |
|---|---|
| **Mata uang** | IDR only (Rupiah Indonesia) |
| **Timezone tampilan** | local device user (`toLocal()`) |
| **Timezone penyimpanan** | semua point-in-time timestamp disimpan UTC di database |
| **Field kalender** | hanya field kalender murni seperti `due_date` dan periode budget yang tetap `date-only` (`YYYY-MM-DD`) |
| **Tipe data uang** | `int` (bukan `double`) — menghindari floating-point error |
| **Format tampilan** | Helper `extToRupiah()` untuk formatting |

---

## 7 Keputusan Final

Berikut adalah keputusan arsitektural dan bisnis yang **sudah final dan TIDAK boleh dilanggar**:

### 1. Balance via Trigger Only
Wallet balance hanya berubah melalui database trigger `update_wallet_balance`. Tidak ada mekanisme lain.

### 2. Settlement ≠ Laporan
Settlement (`debt_payment`, `loan_collection`) tidak masuk laporan dan tidak masuk budget. Periode.

### 3. IDR Only
Aplikasi hanya mendukung mata uang Rupiah Indonesia (IDR). Tidak ada multi-currency.

### 4. UTC Storage, Local Rendering
Semua timestamp point-in-time (misalnya `transactions.date`, `investment_transactions.date`, `created_at`, `fetched_at`) disimpan dalam UTC. Rendering di UI menggunakan local device user, sedangkan field kalender murni seperti `due_date` dan periode budget tetap `date-only`.

### 5. Integer untuk Uang
Semua nilai moneter disimpan sebagai `int`. Tidak boleh `double` atau `float` untuk menghindari floating-point precision error.

### 6. AI Hanya Prefill
AI (voice/OCR/text parser) hanya mengisi form sebagai prefill. User WAJIB review dan konfirmasi sebelum transaksi disimpan. Tidak ada auto-save dari hasil AI.

### 7. Just-in-Time Permission
Permission (kamera, mikrofon, dll) diminta saat fitur dibutuhkan, bukan saat app launch.

---

## Accounting Rules Checklist (Database Validation)

Checklist lengkap validasi aturan keuangan di level database (dari `02_DATABASE.md`):

- ✅ Transfer wajib punya `destination_wallet_id`
- ✅ Transfer tidak boleh pakai wallet yang sama sebagai source dan destination
- ✅ `debt` dan `loan` wajib punya `with_person`
- ✅ `debt` dan `loan` boleh punya `contact_id` (FK ke `contacts`)
- ✅ `transaction_items` minimal 1 row per transaksi
- ✅ Total item wajib sama dengan total header transaksi
- ✅ Settlement wajib merefer ke transaksi asal via `reference_transaction_id`
- ✅ Settlement `debt_payment` hanya valid sebagai `type = 'expense'`
- ✅ Settlement `loan_collection` hanya valid sebagai `type = 'income'`
- ✅ Settlement amount tidak boleh melebihi remaining dari transaksi referensi
- ✅ Budget hanya boleh terkait category `expense`
- ✅ Investasi buy/sell yang melibatkan wallet harus melalui ledger transaksi (buy→`transfer_to_asset`, sell→`income`)
- ✅ Investment asset auto-inactive ketika net_units ≤ 0 (dikelola RPC, bukan trigger)
- ✅ Max 2 custom gold types per user
- ✅ Max 3 custom asset categories per user
- ✅ Gold prices append-only (INSERT, tidak UPSERT) untuk charting historis
- ✅ Bitcoin prices UPSERT via RPC (hanya 2 row)
- ✅ Semua Investment RPC menggunakan `auth.uid()` internal
- ✅ Edit/delete investment transaction hanya untuk `direction = 'buy'`
- ✅ Contacts di-upsert dari phonebook, referensi aman meskipun kontak diedit

---

## Copilot Guardrails (10 Aturan Non-Negotiable)

Dari `03_COPILOT_RULES.md`, 10 guardrails finansial yang wajib dipatuhi:

1. Saldo wallet **tidak boleh diubah langsung dari Flutter**
2. Semua perubahan saldo wallet harus berasal dari `transactions`
3. Semua transaksi harus punya minimal 1 `transaction_item`
4. `sum(transaction_items.amount)` harus sama dengan `transactions.total_amount`
5. Transfer **bukan** expense
6. `transfer_to_asset` **bukan** expense
7. Settlement hutang/piutang **bukan** income/expense operasional untuk report
8. Budget hanya menghitung transaksi expense non-settlement
9. AI Voice/OCR hanya prefill; user tetap review sebelum save
10. Currency MVP hanya IDR

---

## Implikasi untuk Development

- **Backend**: Setiap fitur yang mengubah balance harus melalui RPC + INSERT transaction
- **Frontend**: Tidak boleh ada logic yang memodifikasi balance di Dart code
- **Testing**: Wajib test bahwa balance konsisten setelah setiap jenis transaksi
- **Code review**: Reject PR yang mengubah balance di luar mekanisme trigger

---

## Halaman Terkait

- [[wiki/concepts/matrix-transaksi|Matrix Transaksi]] — Detail 7 tipe transaksi dan aturan settlement
- [[wiki/entities/wallet|Wallet]] — Entitas wallet dan propertinya
- [[wiki/entities/transaksi|Transaksi]] — Entitas transaksi
- [[wiki/concepts/arsitektur-app|Arsitektur App]] — Financial guardrails dalam arsitektur
- [[wiki/sources/prd-sakurapi-v7|PRD SakuRapi v7.0]] — Dokumen sumber aturan keuangan
- [[wiki/entities/database-schema|Database Schema]] — 15 tabel Supabase/Postgres
- [[wiki/concepts/coding-rules|Coding Rules]] — Aturan coding dan konvensi
- [[wiki/sources/database-v6|Database v6.4]] — Sumber database schema
- [[wiki/sources/copilot-rules|Copilot Rules]] — Sumber copilot guardrails
