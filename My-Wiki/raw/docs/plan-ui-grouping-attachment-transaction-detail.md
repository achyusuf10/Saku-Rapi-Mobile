# Plan: UI Grouping + Attachment + Transaction Detail Improvements

## Date
2026-04-13

## Scope
3 tugas UI/bug fix yang saling terkait:

1. **Group-by-date** di `BudgetDetailPage` & `ReportCategoryTransactionsPage`
2. **Fix icon kategori kosong + wallet kosong** di `ReportCategoryTransactionsPage`
3. **Improve UI + tampilkan lampiran** di `TransactionDetailPage`

---

## Task 1: Group-by-date di BudgetDetailPage & ReportCategoryTransactionsPage

### Root Cause
Keduanya masih menggunakan flat `ListView` tanpa pengelompokan tanggal.  
History Page sudah punya pola yang bagus: group header (tanggal + total) + card berisi tiles.

### Approach
- Buat helper function `groupTransactionsByDate(List<TransactionModel>)` → `Map<String, List<TransactionModel>>`
  - Kunci adalah `'YYYY-MM-DD'` (lokal device, pakai `SakuDateUtils`)
  - Diletakkan di `lib/core/utils/transaction_group_utils.dart`
- Buat widget shared `TransactionGroupedListView` (atau cukup inline di tiap halaman, tergantung kebutuhan). Karena keduanya punya konteks berbeda (BudgetDetail pakai Riverpod, ReportCategory pakai StatefulWidget + fetch manual), buat utility function saja — tidak perlu shared widget.
- Replikasi struktur dari `HistoryPage._buildGroupedList()`:  
  date header row → card container → tiles list → dividers

### Files
- **NEW** `lib/core/utils/transaction_group_utils.dart` — `groupTransactionsByDate()`
- `lib/features/budget/view/ui/budget_detail_page.dart` — ganti flat ListView → grouped
- `lib/features/reports/view/ui/report_category_transactions_page.dart` — ganti flat ListView → grouped

---

## Task 2: Fix kategori & wallet kosong di ReportCategoryTransactionsPage

### Root Cause Analysis

`getTransactionsByCategory()` di `HistoryRemoteDataSource` menggunakan select:

```dart
wallet:wallets!transactions_wallet_id_fkey(*),
destination_wallet:wallets!transactions_destination_wallet_id_fkey(*),
transaction_items(*, category:categories(*))
```

**Bug 1 — walletName selalu null:**  
PostgREST menggunakan alias `wallet` (dari `wallet:wallets!...`), sehingga response key adalah `wallet`.  
Tapi `TransactionModel.fromMap()` membaca `map['wallets']` → tidak ketemu → `walletName = null`.

**Bug 2 — categoryName/Icon/Color selalu null:**  
PostgREST menggunakan alias `category` (dari `category:categories(*)`), sehingga setiap item memiliki key `category`.  
Tapi `TransactionItemModel.fromMap()` membaca `map['categories']` → tidak ketemu → semua field kategori null.

### Fix
Ubah select query di `getTransactionsByCategory()` agar alias-nya cocok dengan yang dibaca `fromMap`:

```dart
// Sebelum
wallet:wallets!transactions_wallet_id_fkey(*),
transaction_items(*, category:categories(*))

// Sesudah
wallets:wallets!transactions_wallet_id_fkey(*),
transaction_items(*, categories(*))
```

- `wallets:` alias → response key = `wallets` ✓ (cocok `map['wallets']`)
- `categories(*)` tanpa alias → response key = `categories` ✓ (cocok `map['categories']`)
- `destination_wallet:wallets!...(*)` tetap → sudah cocok dengan `map['destination_wallet']` ✓

### Files
- `lib/features/history/datasource/history_remote_data_source.dart` — fix select aliases

---

## Task 3: Improve UI + Attachment di TransactionDetailPage

### Issues
1. **Lampiran tidak ditampilkan** — `TransactionModel.attachmentUrl` ada tapi tidak pernah di-render di halaman ini
2. **UI** bisa diimprove: detail sections saat ini tidak dibungkus card → kurang clean; bisa dibungkus dalam satu `Container` card seperti `_HeaderCard`

### Approach

**Attachment section:**
- Tambah `_AttachmentSection` widget
- Hanya muncul jika `transaction.attachmentUrl != null`
- Tampilkan foto fullwidth yang bisa di-tap untuk membuka/zoom
- Pakai `Image.network(url, fit: BoxFit.cover)` dengan error builder
- Tambah label "Lampiran" di atas foto

**UI Improvements:**
- Bungkus semua `_DetailSection` dalam satu card `Container` (style sama dengan history tile card)
- Tambah divider antar section di dalam card
- `_AttachmentSection` diletakkan setelah detail fields, sebelum items/debt section

### Files
- `lib/features/transaction/view/ui/transaction_detail_page.dart` — tambah `_AttachmentSection`, improve card wrapping
- `lib/l10n/app_id.arb` + `app_en.arb` — tambah key `transactionAttachment`

---

## Execution Order

1. Fix `getTransactionsByCategory` aliases (Task 2 bug fix — quick win, unblocks testing)
2. Group-by-date utility + BudgetDetailPage (Task 1a)
3. Group-by-date ReportCategoryTransactionsPage (Task 1b)
4. TransactionDetailPage attachment + UI (Task 3)
5. Run `fvm flutter analyze`

---

## Non-Goals
- Tidak ada perubahan pada RPC atau Supabase schema
- Tidak ada perubahan pada `HistoryTransactionTile` widget
- Tidak perlu pagination baru di BudgetDetail atau ReportCategoryTransactions
