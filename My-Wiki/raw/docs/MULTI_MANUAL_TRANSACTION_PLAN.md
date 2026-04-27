# Rencana: Multi Transaksi (Input Manual — Pengeluaran & Pemasukan)

**Tanggal:** 2026-04-27  
**Status:** Implementasi mengikuti dokumen ini.

## Tujuan

Pada form transaksi manual, tab **Pengeluaran** dan **Pemasukan** mendapat mode **Satu Transaksi** (perilaku existing) dan **Multi Transaksi** (beberapa transaksi sekaligus). Setiap transaksi memiliki field setara form tunggal saat ini, termasuk **multi item** per transaksi.

## Batasan & Asumsi

| Item | Keputusan |
|------|-----------|
| Tab | Hanya expense & income |
| Mode edit | Multi transaksi **tidak** tersedia (hanya create) |
| Atomik write | Satu RPC batch — tidak memecah jadi banyak RPC terpisah (Copilot rule #8) |
| File size | Permintaan "400 karakter/file" tidak kompatibel dengan Dart produktif; mengikuti **coding-rules**: pecah layer/widget, hindari monolit. |
| SOLID | Model + repository + remote + controller/mixin + widget terpisah |

## Backend (Supabase)

1. Fungsi `public.create_transactions_batch(p_transactions jsonb) RETURNS jsonb`.
2. `p_transactions`: array objek, struktur selaras parameter `create_transaction_with_items` (tanpa `p_` prefix di JSON keys: `wallet_id`, `type`, `total_amount`, `date`, `items`, …).
3. Validasi per elemen: `type IN ('expense','income')`, ownership wallet, sum items = total, minimal satu item, kategori wajib untuk item expense/income.
4. Semua insert dalam satu transaksi DB (function body = satu transaksi implisit).
5. Return `{"transaction_ids":[...],"count":n}`.
6. **Batas batch:** maksimal **10** transaksi per panggilan (`jsonb_array_length(p_transactions) > 10` → error di RPC; mirror validasi di client + repository). UI: banner di batas, peringatan jika tambah transaksi ditolak.
7. `GRANT EXECUTE` ke `authenticated`.
8. Terapkan migrasi ke **dev** dan **prod** + file di `supabase/migrations/`.

## Flutter — State

- `TransactionFormState`: `isMultiManualMode`, `manualMultiEntries: List<ManualTransactionEntryModel>`.
- `ManualTransactionEntryModel`: `entryKey`, `expanded`, `wallet`, `category`, `items`, `itemKeys`, `date`, `merchantName`, `note`, `attachmentUrl`, `localAttachmentPath`, `totalAmount` (sinkron sum items).
- Getter `multiManualSaveBlocked`: ada entry dengan multi-item dan total tidak cocok.

## Flutter — Controller

- Orkestrasi di **`TransactionFormMultiManualCoordinator`** (dipanggil dari `TransactionFormController`): toggle mode, add/remove entry, expand/collapse, mutasi per-entry (wallet, category, items, tanggal, lampiran, merchant, note).
- **`setManualEntryTotalAmount(index, amount)`** / `setManualMultiEntryTotalAmount`: saat entry punya **tepat satu** item, sinkronkan `totalAmount` + `items[0].amount` (setara `setTotalAmount` pada form tunggal). Jika item > 1, abaikan (total dari penjumlahan baris).
- Saat `setType` keluar dari expense/income: reset multi mode.
- Submit: jika multi → validasi semua entry → upload lampiran per entry → `createTransactionsBatch`.

## Flutter — UI

- Toggle **Satu / Multi** + **hint** (l10n) di atas area form (hanya create + expense/income).
- Daftar **card** per transaksi: header ringkas + tombol hapus; panel collapsible untuk isi form (reuse `SakuWalletPickerTile`, `TransactionCategoryPickerTile`, `TransactionDatePickerTile`, `TransactionOptionalDetailsSection`).
- **UX selaras tab transaksi tunggal (per entry):**
  - Default tiap entry = **satu item** (bukan multi-item): **`TransactionAmountSection`** untuk nominal (sama seperti form tunggal saat `!isMultiItem`).
  - **`TransactionMultiItemSection(manualMultiEntryIndex: …)`** di bawah detail opsional: jika entry masih satu item, hanya menampilkan **chip “Tambah item”** (sama seperti form tunggal); tap memanggil `addManualMultiItem` → beralih ke UI multi-item (total, reorder, baris `TransactionItemRow`, dll.).
  - Urutan field dalam card diselaraskan form tunggal: **nominal → dompet → kategori → tanggal → opsional → multi-item**.
- `TransactionMultiItemSection`: parameter opsional `manualMultiEntryIndex`; jika non-null, baca/tulis state entry tersebut.

## Flutter — Save bar

- Nonaktifkan simpan jika `multiManualSaveBlocked` atau validasi existing (wallet, dll.) gagal untuk salah satu entry.

## Testing

- Repository: validasi batch (empty, mismatch total, **entries > max** tanpa memanggil remote).
- Controller: `validateBatch`, toggle mode, add/remove entry, **`setManualMultiEntryTotalAmount`**, **`addManualMultiItem`** (bentuk multi-item).
- Widget: `TransactionMultiItemSection` — entry manual multi satu item **hanya** chip tambah item (tanpa `TransactionItemRow`).

## Pesan sukses & l10n

- Setelah simpan batch multi: pesan sukses memakai **jumlah transaksi** dari payload RPC (`count` / panjang ids), mis. `transactionSaveSuccessBatch(n)` (ICU plural di ARB).

## Checklist rollout

- [x] Migrasi SQL di repo  
- [x] MCP apply dev  
- [x] MCP apply prod  
- [x] l10n `app_id.arb` / `app_en.arb` (termasuk batch count + batas 10)  
- [x] Unit test `validateBatch` + multi manual total amount + `addManualMultiItem` (`transaction_form_controller_test`)  
- [x] Widget test `TransactionMultiItemSection` manual multi satu item (`transaction_multi_item_section_test`)  
- [x] UX per entry: `TransactionAmountSection` + chip multi-item selaras form tunggal (`transaction_manual_multi_entry_card`, `transaction_multi_item_section`, coordinator + controller)

## Referensi file (Flutter)

| Area | File |
|------|------|
| Card per entry | `lib/features/transaction/view/widgets/transaction_manual_multi_entry_card.dart` |
| Section multi-item | `lib/features/transaction/view/widgets/transaction_multi_item_section.dart` |
| Orkestrasi multi manual | `lib/features/transaction/controllers/transaction_form_multi_manual_coordinator.dart` |
| Batas konstanta | `lib/features/transaction/utils/manual_multi_batch_limits.dart` |
| Aksi simpan / pesan batch | `lib/features/transaction/view/ui/transaction_form_actions_mixin.dart` |
