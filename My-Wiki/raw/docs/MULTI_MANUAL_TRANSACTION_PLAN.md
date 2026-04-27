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
6. `GRANT EXECUTE` ke `authenticated`.
7. Terapkan migrasi ke **dev** dan **prod** + file di `supabase/migrations/`.

## Flutter — State

- `TransactionFormState`: `isMultiManualMode`, `manualMultiEntries: List<ManualTransactionEntryModel>`.
- `ManualTransactionEntryModel`: `entryKey`, `expanded`, `wallet`, `category`, `items`, `itemKeys`, `date`, `merchantName`, `note`, `attachmentUrl`, `localAttachmentPath`, `totalAmount` (sinkron sum items).
- Getter `multiManualSaveBlocked`: ada entry dengan multi-item dan total tidak cocok.

## Flutter — Controller

- Mixin `TransactionFormMultiManualMixin` pada `TransactionFormController` (atau kelas terpisah yang di-orchestrate) untuk: toggle mode, add/remove entry, expand/collapse, mutasi per-entry (wallet, category, items, tanggal, lampiran, merchant, note).
- Saat `setType` keluar dari expense/income: reset multi mode.
- Submit: jika multi → validasi semua entry → upload lampiran per entry → `createTransactionsBatch`.

## Flutter — UI

- Toggle **Satu / Multi** + **hint** (l10n) di atas area form (hanya create + expense/income).
- Daftar **card** per transaksi: header ringkas + tombol hapus; **ExpansionTile** atau panel collapsible untuk isi form (reuse `SakuWalletPickerTile`, `TransactionCategoryPickerTile`, `TransactionDatePickerTile`, `TransactionOptionalDetailsSection`, `TransactionMultiItemSection`).
- `TransactionMultiItemSection`: parameter opsional `manualMultiEntryIndex`; jika non-null, baca/tulis state entry tersebut.

## Flutter — Save bar

- Nonaktifkan simpan jika `multiManualSaveBlocked` atau validasi existing (wallet, dll.) gagal untuk salah satu entry.

## Testing

- Repository: validasi batch (empty, mismatch total).
- Controller: toggle mode, add/remove entry, sum items.

## Checklist rollout

- [x] Migrasi SQL di repo  
- [x] MCP apply dev  
- [x] MCP apply prod  
- [x] l10n `app_id.arb` / `app_en.arb`  
- [x] Unit test `validateBatch` (transaction_form_controller_test)
