---
title: "Plan: UI Grouping + Attachment + Transaction Detail"
type: source
tags: [transaksi, ui, grouping, attachment, budget, reports, bug-fix]
sources: [raw/docs/plan-ui-grouping-attachment-transaction-detail.md]
created: 2026-04-19
updated: 2026-04-19
---

# Plan: UI Grouping + Attachment + Transaction Detail

**Status:** Planning (April 2026)
**Tanggal:** 2026-04-13
**Sumber:** `raw/docs/plan-ui-grouping-attachment-transaction-detail.md`

## Ringkasan

3 tugas UI/bug fix yang saling terkait:
1. **Group-by-date** di `BudgetDetailPage` & `ReportCategoryTransactionsPage`
2. **Fix icon kategori + wallet kosong** di `ReportCategoryTransactionsPage`
3. **Improve UI + tampilkan lampiran** di `TransactionDetailPage`

---

## Task 1: Group-by-Date

### Masalah
`BudgetDetailPage` dan `ReportCategoryTransactionsPage` masih menggunakan flat `ListView` tanpa pengelompokan tanggal. `HistoryPage` sudah punya pola yang bagus (group header + total + tiles).

### Solusi
Buat helper function `groupTransactionsByDate()` → `Map<String, List<TransactionModel>>`:
- Kunci: `'YYYY-MM-DD'` (lokal device, pakai `SakuDateUtils`)
- File: `lib/core/utils/transaction_group_utils.dart` (BARU)
- Replikasi struktur dari `HistoryPage._buildGroupedList()`

### Files
- **BARU**: `lib/core/utils/transaction_group_utils.dart`
- `lib/features/budget/view/ui/budget_detail_page.dart`
- `lib/features/reports/view/ui/report_category_transactions_page.dart`

---

## Task 2: Fix Kategori & Wallet Kosong di ReportCategoryTransactionsPage

### Root Cause

`getTransactionsByCategory()` menggunakan alias di select query yang **tidak cocok** dengan apa yang dibaca di `fromMap()`:

| Field | Select Query Alias | `fromMap()` reads | Status |
|-------|-------------------|------------------|--------|
| Wallet | `wallet:wallets!...` → key = `wallet` | `map['wallets']` | ❌ Miss |
| Kategori item | `category:categories(*)` → key = `category` | `map['categories']` | ❌ Miss |

### Fix

```dart
// Sebelum
wallet:wallets!transactions_wallet_id_fkey(*),
transaction_items(*, category:categories(*))

// Sesudah
wallets:wallets!transactions_wallet_id_fkey(*),
transaction_items(*, categories(*))
```

### Files
- `lib/features/history/datasource/history_remote_data_source.dart`

---

## Task 3: Lampiran + Improve UI di TransactionDetailPage

### Masalah
- `TransactionModel.attachmentUrl` ada tapi tidak pernah di-render di `TransactionDetailPage`
- UI section-section detail tidak dibungkus card

### Solusi

**Widget baru `_AttachmentSection`:**
- Tampil hanya jika `transaction.attachmentUrl != null`
- `Image.network(url, fit: BoxFit.cover)` fullwidth + error builder
- Label "Lampiran" di atas foto
- Tap → buka/zoom gambar

**UI Improvements:**
- Bungkus semua `_DetailSection` dalam satu card `Container`
- Tambah divider antar section
- `_AttachmentSection` setelah detail fields, sebelum items/debt section

### Files
- `lib/features/transaction/view/ui/transaction_detail_page.dart`
- `lib/l10n/app_id.arb` + `app_en.arb` — key `transactionAttachment`

---

## Halaman Terkait

- [[wiki/entities/transaksi|Transaksi]]
- [[wiki/entities/budgeting|Budgeting]]
- [[wiki/entities/reports|Reports]]
- [[wiki/entities/history|History]]
