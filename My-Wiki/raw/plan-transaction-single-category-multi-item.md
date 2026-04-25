---
title: "Rencana: Satu kategori parent untuk multi-item transaksi"
type: plan
tags: [transaction, multi-item, category, ai-parse, edge-function, flutter]
created: 2026-04-25
updated: 2026-04-25
---

# Rencana: Satu kategori di level transaksi (parent) untuk multi-item

## Konteks

Saat ini form transaksi **expense/income** mendukung multi-item: setiap baris (`TransactionItemRow`) punya picker kategori sendiri, dan `TransactionRepository.validateInput` mewajibkan **setiap** `TransactionItemModel` punya `categoryId`.

Skema DB (`transaction_items.category_id`) tetap per-baris; tidak ada perubahan skema. Yang berubah adalah **aturan produk + UX**: user hanya memilih **satu** kategori di level transaksi (di bawah dompet), dan semua baris multi-item **mengikuti** kategori itu.

## Keputusan product (disepakati)

| # | Topik | Keputusan |
|---|--------|-----------|
| 1 | Transaksi edit lama dengan multi-item dan kategori **beda** per baris | **Auto-seragamkan** saat form dibuka: `state.category` = kategori dari **baris pertama** (item pertama yang punya `categoryId`); saat simpan, semua baris diset ke kategori itu **tanpa dialog** konfirmasi. |
| 2 | Income multi-item | **Sama** dengan expense: satu kategori parent untuk seluruh baris. |
| 3 | Laporan / breakdown per kategori per baris dalam satu transaksi | **Perilaku diubah**: satu transaksi multi-item = **satu** kategori untuk semua baris; tidak lagi mendukung kategori berbeda antar baris dalam satu transaksi. |

## Tujuan

1. **UI form** — Kategori hanya satu, ditempatkan di bawah blok dompet (sumber/tujuan), untuk expense & income (non-settlement), **termasuk** saat multi-item.
2. **Baris multi-item** — Hapus picker kategori per baris; baris hanya nama, qty, unit price / subtotal (dan aksi hapus/reorder).
3. **Controller / repository** — Pastikan sebelum simpan semua item punya `categoryId` (dan metadata join jika perlu) yang **sama** dengan kategori parent; validasi domain tetap di repository, orchestration di controller.
4. **Edge Function `ai-parse`** — Prompt & contoh JSON: item **tanpa** `categoryId`; kategori hanya di level root (`categoryId` / `categoryKeyword`). Post-process: strip/abaikan `categoryId` di elemen `items` jika AI masih mengirim (backward compatible).
5. **Laporan & agregasi** — Setelah implementasi, breakdown per kategori mengacu pada kategori transaksi yang sama untuk semua item dalam satu transaksi multi-item (bukan lagi variasi per baris).

## Arsitektur (coding rules)

Ikuti alur: **Widget → Controller → Repository → Remote (RPC)**.  
Tetap: tidak memindahkan business rule finansial ke `build()`; sinkronisasi kategori ke items dilakukan di **controller** (atau helper privat repository jika dipilih satu tempat konsisten — disarankan **controller** karena sudah ada `TransactionFormState.category`).

## Rencana implementasi — Flutter

### 1. `TransactionFormPage` (`lib/features/transaction/view/ui/transaction_form_page.dart`)

- Ubah kondisi blok **Category**: tampilkan untuk expense/income **non-settlement** **tanpa** memeriksa `!formState.isMultiItem` (hapus gate `isMultiItem`).
- Letakkan blok kategori **setelah** `SakuWalletPickerTile` (dan destination wallet jika transfer), konsisten dengan permintaan "di bawah Dompet".
- `_pickCategory`: sumber `selectedId` dari `formState.category?.id` (bukan `items.first.categoryId`). Setelah pilih, tetap `ctrl.setCategory(result)`.

### 2. `TransactionCategoryPickerTile` (`transaction_category_picker_tile.dart`)

- Parameter saat ini mengandalkan `TransactionItemModel? item` untuk label/icon.  
  **Opsi A (disarankan):** tambah parameter opsional `CategoryModel? category` — jika non-null, tampilkan dari situ; fallback ke `item` untuk kompatibilitas sementara.  
  **Opsi B:** ganti API tile agar hanya terima `CategoryModel?` + `VoidCallback onTap` untuk form ini.  
  Pilih satu dan update semua pemanggil (grep pemakaian tile).

### 3. `TransactionFormController` (`transaction_form_controller.dart`)

- **`setCategory`:** untuk expense/income, terapkan kategori ke **semua** item di `state.items` (map `copyWith` categoryId/name/icon/color), bukan hanya saat `items.length == 1`.
- **`addItem`:** item baru harus disalin kategori dari `state.category` jika ada (clear category fields jika null — konsisten dengan single kategori wajib sebelum save).
- **`prefillItems`:** setelah mengisi daftar item dari voice/OCR, panggil helper internal `_syncCategoryFromStateToItems()` atau set langsung dari `setCategory` yang dipanggil dari UI setelah prefill — urutan harus jelas di `transaction_form_page` (`_applyVoicePrefill` / `_applyOcrPrefill`): build `TransactionItemModel` **tanpa** category per baris; resolve kategori parent lalu `setCategory` / satu method `applyParentCategoryToAllItems`.
- **`updateItem`:** saat user mengedit nama/qty/amount, pastikan tidak menghapus kategori baris: setelah `copyWith` pada item, **re-sync** `state.category` ke item yang di-update (atau sync semua item setelah setiap update — lebih sederhana: satu method `_syncCategoryToAllItems()` dipanggil dari `updateItem` jika `state.category != null` dan tipe expense/income).
- **`submit`:** sebelum `itemsWithOrder`, panggil sync sekali lagi (defensive) agar RPC selalu terima item lengkap.
- **`resolveEditLookups`:** untuk expense/income multi-item, `state.category` = kategori dari **item pertama** yang punya `categoryId` (urutan `items`); setelah itu panggil sync agar **semua** baris memakai kategori yang sama — data lama dengan beda kategori per baris otomatis diseragamkan tanpa dialog.

### 4. `TransactionMultiItemSection` + `TransactionItemRow`

- `TransactionMultiItemSection`: hapus passing `categoryType` ke `TransactionItemRow` jika tidak dipakai.
- `TransactionItemRow`: hapus seluruh blok UI kategori + `_pickCategory` + import `CategoryPickerSheet` / `CategoryType` yang tidak perlu. Perbarui docstring baris: tidak lagi menampilkan kategori per item.

### 5. `TransactionFormPage` — prefill Voice / OCR

- **`_applyVoicePrefill`:** saat membangun `TransactionItemModel` dari `voiceResult.items`, **jangan** set field kategori per item; resolve kategori **hanya** dari `voiceResult.categoryId` / `categoryKeyword` (sama seperti top-level hari ini), lalu `setCategory` + `prefillItems` dengan item tanpa category (atau prefill lalu `setCategory`).
- **`_applyOcrPrefill`:** analog untuk OCR multi-item — hapus mapping `categoryId` per `ocrItem`; top-level saja.

### 6. Model & kontrak (opsional tapi rapi)

- `VoiceItemModel` / `OcrItemModel`: field `categoryId` bisa di-mark deprecated atau diabaikan saat mapping ke `TransactionItemModel`; parsing JSON lama boleh tetap membaca field lalu **diabaikan** di layer mapping ke form.
- Perbarui docstring di `voice_parse_result_model.dart` / `ocr_parse_result_model.md` agar kontrak Edge Function selaras.

### 7. `TransactionRepository.validateInput`

- **Opsi A:** tetap "setiap item wajib `categoryId`" — dipenuhi karena controller selalu sync sebelum submit (minim diff).  
- **Opsi B:** untuk `items.length > 1`, izinkan validasi alternatif: cukup cek konsistensi + parent — memerlukan API `validateInput` menerima `CategoryModel?` atau flag — **tidak disarankan** kecuali ada kebutuhan tegas.

Rekomendasi: **Opsi A** + sync di controller.

### 8. UI lain yang mengasumsikan kategori per item di form

- Grep: `TransactionItemRow`, `transaction_category_picker_tile`, tests terkait form multi-item.

## Rencana implementasi — Edge Function `ai-parse`

File: `supabase/functions/ai-parse/index.ts`

### 1. System prompt — mode text/voice (`buildTextSystemPrompt`)

- Ubah deskripsi field `items[]`: setiap elemen **hanya** `name`, `qty`, `unitPrice` (opsional), `subtotal` — **tanpa** `categoryId`.
- Perjelas: **satu** `categoryId` / `categoryKeyword` di root untuk seluruh transaksi **expense dan income** (termasuk multi-item); tidak ada pengecualian income.
- Perbarui **few-shot examples** yang saat ini menampilkan `categoryId` di dalam item (mis. contoh ikan/ayam/sayur).

### 2. System prompt — mode OCR (vision)

- Sama: item struk tanpa `categoryId`; kategori hanya top-level untuk **expense dan income** (konsisten dengan form).

### 3. `reverseMapResponse`

- Setelah reverse-map `categoryId` root, untuk setiap elemen `items`: **hapus** `categoryId` dari object item sebelum return (atau jangan reverse-map per item). Tetap toleran jika model lama mengirim `categoryId` per item — jangan biarkan UUID pendek tertinggal salah map.

### 4. Versi / komentar header

- Bump komentar versi di header file (mis. v47 → v48) agar deploy mudah dilacak.

### 5. Deploy

- Setelah merge: deploy Edge Function ke project Supabase (dev lalu prod sesuai workflow tim).

## Testing (minimum)

- Unit: `TransactionFormController.setCategory` dengan 3 item → semua item dapat `categoryId` yang sama.
- Unit: `updateItem` tidak menghapus kategori setelah edit nama/qty.
- Widget/integration ringan: buka form expense → tambah item → pastikan hanya satu tile kategori.
- Manual: voice multi-item + OCR multi-item setelah deploy `ai-parse`.

## Risiko & mitigasi

| Risiko | Mitigasi |
|--------|----------|
| Data edit lama: multi-item beda kategori per baris | **Auto-seragamkan** ke kategori item pertama; tanpa dialog; saat simpan semua baris memakai `state.category`. |
| AI lama masih mengirim `categoryId` per item | Strip di Edge Function + abaikan di Flutter mapping. |
| RPC / trigger mengharuskan category per row | Tetap kirim per-row **sama** — hanya UI yang disederhanakan. |

## Checklist eksekusi (urutan disarankan)

- [ ] Tulis / sesuaikan test controller untuk sync kategori.
- [ ] Refactor `TransactionFormController` (setCategory, addItem, updateItem, submit).
- [ ] Refactor UI: `transaction_form_page`, `transaction_category_picker_tile`, `transaction_item_row`, `transaction_multi_item_section`.
- [ ] Refactor prefill: `transaction_form_page` (voice + OCR).
- [ ] Update `ai-parse/index.ts` (prompt + examples + reverseMapResponse).
- [ ] Deploy Edge Function; verifikasi parse dari app.
- [ ] Update docstring model voice/OCR jika kontrak publik diubah.
