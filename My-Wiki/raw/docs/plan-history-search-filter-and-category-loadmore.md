# Plan: History Search Filter + Load More By Category Fix

**Tanggal**: 2026-04-13  
**Status**: Ready to implement  
**Revisi**: v2 — RPC-based approach (server-side search + category-level pagination)

---

## Overview

Dua improvement untuk fitur **Riwayat Transaksi**, diselesaikan dengan **satu RPC baru** yang menggantikan PostgREST query saat ini:

1. **Feature 1 — Search Filter (server-side)**: Tambah field pencarian teks di filter sheet. Keyword dikirim ke server via RPC, server melakukan `ILIKE` pada `transactions.note` OR `categories.name`. Trigger refetch.

2. **Feature 2 — Category-level Pagination**: Saat `groupMode == byCategory`, pagination bukan per transaksi, tapi **per kategori** (e.g., 5 kategori per page). Setiap kategori datang lengkap dengan SEMUA transaksinya untuk periode tersebut. Urutan: kategori dengan transaksi terbaru muncul duluan.

---

## Arsitektur: RPC `get_history_transactions`

### Kenapa RPC?

1. **Search cross-table**: PostgREST `.or()` tidak support filter across joined tables (`transactions.note` OR `categories.name`). RPC bisa.
2. **Category-level pagination**: PostgREST hanya bisa `LIMIT/OFFSET` per row. Kita butuh `LIMIT/OFFSET` per **distinct category**. Hanya SQL murni yang bisa.
3. **Satu endpoint, dua mode**: RPC menerima `p_group_mode` parameter — `'byDate'` atau `'byCategory'` — dan menyesuaikan pagination logic.

### RPC Signature

```sql
CREATE OR REPLACE FUNCTION get_history_transactions(
  p_start_date  timestamptz,
  p_end_date    timestamptz,
  p_wallet_id   uuid        DEFAULT NULL,
  p_type        text        DEFAULT NULL,
  p_search      text        DEFAULT NULL,
  p_group_mode  text        DEFAULT 'byDate',  -- 'byDate' | 'byCategory'
  p_limit       int         DEFAULT 30,
  p_offset      int         DEFAULT 0
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
```

### Return Format

Sama untuk kedua mode — **flat array transaksi + has_more flag**:

```json
{
  "transactions": [
    {
      "id": "...",
      "user_id": "...",
      "wallet_id": "...",
      "type": "expense",
      "total_amount": 50000,
      "date": "2026-04-12T10:00:00+07:00",
      "note": "Makan siang",
      "wallets": { "name": "BCA" },
      "destination_wallet": null,
      "transaction_items": [
        {
          "id": "...",
          "category_id": "...",
          "amount": 50000,
          "categories": { "name": "Makan", "icon": "utensils", "color": "#FF5733" }
        }
      ],
      "contacts": null
    }
  ],
  "has_more": true
}
```

Format JSON identik dengan PostgREST response saat ini → `TransactionModel.fromMap()` bekerja tanpa perubahan.

### Mode `byDate`

- `p_limit` / `p_offset` = **transaction-level** pagination (sama seperti sekarang)
- `ORDER BY date DESC, created_at DESC`
- Search: `note ILIKE '%keyword%' OR EXISTS (SELECT 1 FROM transaction_items ti JOIN categories c ... WHERE c.name ILIKE '%keyword%')`
- `has_more` = apakah ada lebih banyak transaksi setelah offset

### Mode `byCategory`

- `p_limit` / `p_offset` = **category-level** pagination (e.g., 5 kategori per page, skip 0)
- Algoritma:
  1. Tentukan "primary category" setiap transaksi = `first transaction_item` category (via `DISTINCT ON`)
  2. Rank categories by `MAX(transaction.date) DESC` → urutan berdasarkan transaksi terbaru
  3. Ambil `p_limit` kategori mulai dari `p_offset`
  4. Return **SEMUA transaksi** yang primary category-nya masuk dalam paginated set
  5. Transactions di-order: `category_latest_date DESC, category_name, date DESC` → client `groupedByCategory` langsung rapi
- `has_more` = apakah masih ada kategori yang belum diambil

### Handling Edge Cases

- **Transfer / Debt / Loan tanpa kategori**: Primary category = `COALESCE(c.name, t.type)`. Muncul sebagai grup sendiri (e.g., "transfer", "debt").
- **Multi-item transaksi**: Primary category = first item's category (matching current client behavior di `TransactionModel.fromMap()` line 134).
- **Search match pada item non-pertama**: Transaksi tetap muncul — search filter menemukan match di ANY item, bukan hanya primary.

---

## Detail Perubahan per File

### 1. New Migration: `get_history_transactions` RPC

File: `supabase/migrations/XXXXXXXX_get_history_transactions_rpc.sql`

RPC SQL logic (pseudo):

```sql
-- MODE: byDate
WITH filtered_tx AS (
  SELECT DISTINCT t.id
  FROM transactions t
  LEFT JOIN transaction_items ti ON ti.transaction_id = t.id
  LEFT JOIN categories c ON c.id = ti.category_id
  WHERE t.user_id = v_user_id
    AND t.date >= p_start_date AND t.date < p_end_date
    AND (p_wallet_id IS NULL OR t.wallet_id = p_wallet_id)
    AND (p_type IS NULL OR t.type = p_type)
    AND (v_search IS NULL OR t.note ILIKE v_search OR c.name ILIKE v_search)
  ORDER BY t.date DESC, t.created_at DESC
  LIMIT p_limit OFFSET p_offset
)
-- Build full JSON for each transaction...

-- MODE: byCategory
WITH tx_primary_cat AS (
  SELECT DISTINCT ON (t.id)
    t.id AS transaction_id,
    COALESCE(c.id::text, t.type) AS primary_cat_key,
    COALESCE(c.name, t.type) AS primary_cat_name
  FROM transactions t
  LEFT JOIN transaction_items ti ON ti.transaction_id = t.id
  LEFT JOIN categories c ON c.id = ti.category_id
  WHERE t.user_id = v_user_id
    AND t.date >= p_start_date AND t.date < p_end_date
    AND (p_wallet_id IS NULL OR t.wallet_id = p_wallet_id)
    AND (p_type IS NULL OR t.type = p_type)
    AND (v_search IS NULL OR t.note ILIKE v_search OR c.name ILIKE v_search)
  ORDER BY t.id, ti.sort_order ASC
),
ranked_cats AS (
  SELECT primary_cat_key, primary_cat_name, MAX(t.date) AS latest_date
  FROM tx_primary_cat tpc
  JOIN transactions t ON t.id = tpc.transaction_id
  GROUP BY primary_cat_key, primary_cat_name
  ORDER BY latest_date DESC
),
paginated_cats AS (
  SELECT *, ROW_NUMBER() OVER () AS rn FROM ranked_cats
  -- LIMIT p_limit OFFSET p_offset applied here
)
-- Return all transactions whose primary_cat_key IN paginated set
```

### 2. `lib/features/history/datasource/history_remote_data_source.dart`

**Sebelum**: PostgREST `.from('transactions').select(...)` dengan chained filters.

**Sesudah**: Panggil RPC `get_history_transactions`:

```dart
Future<DataState<HistoryResult>> getTransactions({
  required DateTime startDate,
  required DateTime endDate,
  String? walletId,
  String? type,
  String? search,
  String groupMode = 'byDate',
  int limit = 30,
  int offset = 0,
}) {
  return SupabaseHandler.call<HistoryResult>(
    function: () async {
      final range = SakuDateUtils.localDayRangeUtc(startDate: startDate, endDate: endDate);
      final response = await _client.rpc('get_history_transactions', params: {
        'p_start_date': range.startUtc,
        'p_end_date': range.endUtcExclusive,
        'p_wallet_id': walletId,
        'p_type': type,
        'p_search': search,
        'p_group_mode': groupMode,
        'p_limit': limit,
        'p_offset': offset,
      });
      
      final data = response as Map<String, dynamic>;
      final txList = (data['transactions'] as List)
          .map((e) => TransactionModel.fromMap(e as Map<String, dynamic>))
          .toList();
      return HistoryResult(transactions: txList, hasMore: data['has_more'] as bool);
    },
  );
}
```

**HistoryResult model baru** (simple container):
```dart
class HistoryResult {
  final List<TransactionModel> transactions;
  final bool hasMore;
  const HistoryResult({required this.transactions, required this.hasMore});
}
```

> Bisa ditaruh di `history_models.dart`.

### 3. `lib/features/history/repositories/history_repository.dart`

Pass through parameter baru (`search`, `groupMode`). Return type berubah dari `DataState<List<TransactionModel>>` ke `DataState<HistoryResult>`.

### 4. `lib/features/history/controllers/history_controller.dart`

#### HistoryState — tambah field:
```dart
final String? searchKeyword;
```

Plus `copyWith` update (`searchKeyword`, `clearSearch`).

#### `filteredTransactions` getter:
- `typeFilter` tetap **lokal** (per PRD §7.8)
- Search sudah di-handle server-side → TIDAK filter lokal untuk search

```dart
List<TransactionModel> get filteredTransactions {
  if (typeFilter == null) return transactions;
  return transactions.where((t) => t.type == typeFilter).toList();
}
```

#### `groupedByCategory` getter — sort by latest date DESC:
```dart
Map<String, List<TransactionModel>> get groupedByCategory {
  final list = filteredTransactions;
  final map = <String, List<TransactionModel>>{};
  for (final tx in list) {
    final key = tx.categoryName ?? tx.type.toLocalizedLabel();
    (map[key] ??= []).add(tx);
  }
  // Sort: kategori dengan transaksi terbaru muncul duluan
  final sorted = map.entries.toList()
    ..sort((a, b) {
      final latestA = a.value.map((t) => t.date).reduce((x, y) => x.isAfter(y) ? x : y);
      final latestB = b.value.map((t) => t.date).reduce((x, y) => x.isAfter(y) ? x : y);
      return latestB.compareTo(latestA);
    });
  return Map.fromEntries(sorted);
}
```

#### Pagination constants:
```dart
static const _pageSize = 30;              // per transaksi (byDate)
static const _categoriesPerPage = 5;      // per kategori (byCategory)
```

#### `_currentPageSize` helper:
```dart
int get _currentPageSize => state.groupMode == HistoryGroupMode.byCategory
    ? _categoriesPerPage
    : _pageSize;
```

#### `loadTransactions()` — updated:
```dart
Future<void> loadTransactions() async {
  state = state.copyWith(status: HistoryStatus.loading, offset: 0, hasMore: true, clearError: true);
  
  final (start, end) = state.dateRange;
  final result = await _repository.getTransactions(
    startDate: start,
    endDate: end,
    walletId: state.walletId,
    search: state.searchKeyword,
    groupMode: state.groupMode == HistoryGroupMode.byCategory ? 'byCategory' : 'byDate',
    limit: _currentPageSize,
    offset: 0,
  );

  if (result.isSuccess()) {
    final data = result.dataSuccess()!;
    state = state.copyWith(
      status: HistoryStatus.loaded,
      transactions: data.transactions,
      offset: _currentPageSize,  // next offset
      hasMore: data.hasMore,
    );
  } else {
    final (message, _, _, _) = result.dataError()!;
    state = state.copyWith(status: HistoryStatus.error, errorMessage: message);
  }
}
```

> **Offset tracking**: Untuk `byDate`, offset = jumlah transaksi yang sudah diambil. Untuk `byCategory`, offset = jumlah kategori yang sudah diambil. Keduanya ditrack dengan `state.offset`, tapi artinya berbeda per mode. Ini aman karena mode switch selalu reset offset ke 0.

#### `loadMore()` — updated:
```dart
Future<void> loadMore() async {
  if (!state.hasMore || state.isLoadingMore) return;
  state = state.copyWith(isLoadingMore: true);

  final (start, end) = state.dateRange;
  final result = await _repository.getTransactions(
    startDate: start,
    endDate: end,
    walletId: state.walletId,
    search: state.searchKeyword,
    groupMode: state.groupMode == HistoryGroupMode.byCategory ? 'byCategory' : 'byDate',
    limit: _currentPageSize,
    offset: state.offset,
  );

  if (result.isSuccess()) {
    final data = result.dataSuccess()!;
    state = state.copyWith(
      transactions: [...state.transactions, ...data.transactions],
      offset: state.offset + _currentPageSize,
      hasMore: data.hasMore,
      isLoadingMore: false,
    );
  } else {
    state = state.copyWith(isLoadingMore: false);
  }
}
```

#### `setSearchKeyword()` — NEW (triggers refetch):
```dart
Future<void> setSearchKeyword(String? keyword) async {
  final normalized = (keyword?.trim().isEmpty ?? true) ? null : keyword?.trim();
  if (normalized == state.searchKeyword) return;
  if (normalized == null) {
    state = state.copyWith(clearSearch: true);
  } else {
    state = state.copyWith(searchKeyword: normalized);
  }
  _persist();
  await loadTransactions();
}
```

#### `setGroupMode()` — NOW ASYNC + REFETCH:
```dart
Future<void> setGroupMode(HistoryGroupMode mode) async {
  if (mode == state.groupMode) return;
  state = state.copyWith(groupMode: mode);
  _persist();
  await loadTransactions(); // refetch: page size & ordering berbeda per mode
}
```

#### `resetFilters()` — include clearSearch

#### `_persist()` / `_restoreInitialState()` — include searchKeyword

### 5. `lib/features/history/datasource/history_local_data_source.dart`

Tambah `searchKeyword` di `saveFilterPrefs()` / `loadFilterPrefs()`.

### 6. `lib/features/history/view/widgets/history_filter_sheet.dart`

- Tambah `currentSearchKeyword` param ke constructor
- Tambah `_searchController` (TextEditingController) di state
- Tambah `SakuTextField` di atas section type filter (prefix icon: search)
- `_FilterResult` — tambah `searchKeyword` field
- Apply: pass `_searchController.text`
- Reset: clear search

Di `showHistoryFilterSheet()`:
- Pass `historyState.searchKeyword` ke sheet
- Setelah result: panggil `controller.setSearchKeyword(result.searchKeyword)` → triggers refetch
- Apply groupMode: panggil `controller.setGroupMode(result.groupMode)` → triggers refetch

### 7. `lib/features/history/view/ui/history_page.dart`

Badge filter button: visible jika `typeFilter != null || searchKeyword != null`

### 8. `lib/l10n/app_id.arb` + `lib/l10n/app_en.arb`

Tambah keys:
- `historySearchHint`: "Cari catatan atau kategori..." / "Search notes or category..."

---

## Summary Perubahan

| # | File | Perubahan |
|---|------|-----------|
| 1 | `supabase/migrations/..._get_history_transactions_rpc.sql` | **NEW** — RPC function |
| 2 | `lib/features/history/models/history_models.dart` | Tambah `HistoryResult` model |
| 3 | `lib/features/history/datasource/history_remote_data_source.dart` | Ganti PostgREST → RPC call |
| 4 | `lib/features/history/datasource/history_local_data_source.dart` | Persist searchKeyword |
| 5 | `lib/features/history/repositories/history_repository.dart` | Pass-through params baru |
| 6 | `lib/features/history/controllers/history_controller.dart` | State + search + category pagination |
| 7 | `lib/features/history/view/widgets/history_filter_sheet.dart` | Tambah search text field |
| 8 | `lib/features/history/view/ui/history_page.dart` | Badge update |
| 9 | `lib/l10n/app_id.arb` | Keys baru |
| 10 | `lib/l10n/app_en.arb` | Keys baru |

---

## Urutan Implementasi

1. **RPC** — buat dan test di Supabase dulu (via MCP)
2. **Models** — `HistoryResult`
3. **Remote Data Source** — ganti ke RPC call
4. **Repository** — pass-through
5. **Controller** — state + search + pagination logic
6. **Local Data Source** — persist search
7. **Filter Sheet UI** — search field
8. **History Page** — badge
9. **Localization** — keys
10. **Test** — `fvm flutter analyze`

---

## Notes

- `typeFilter` tetap **lokal** (per PRD §7.8) — tidak dikirim ke RPC. Client filter setelah data diterima.
- `setGroupMode()` sekarang async + refetch — ada 1 caller di `showHistoryFilterSheet()` yang perlu diupdate.
- `state.offset` punya arti berbeda per mode: jumlah transaksi (byDate) vs jumlah kategori (byCategory). Mode switch selalu reset ke 0 → aman.
- RPC JSON output harus identik dengan PostgREST response → `TransactionModel.fromMap()` bekerja tanpa perubahan.
- `_categoriesPerPage = 5` sangat efisien: 1 query mengambil 5 kategori + semua transaksinya. Rata-rata user punya ~10 kategori per bulan → 2 page sudah habis.
