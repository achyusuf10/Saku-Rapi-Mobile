# Rencana: AI Parse (Edge Function) — Dukungan Multi Transaksi

**Tanggal:** 2026-04-27  
**Status:** Implementasi bertahap — kontrak `transactions[]`, prefill multi manual, **UI preview multi transaksi** (Dev)  
**Edge Function terkait:** `ai-parse` (Supabase — slug `ai-parse`, aktif; dicek / deploy via MCP)

---

## UI/UX — Preview hasil AI (Text / Voice / OCR)

**Masalah:** Sheet (`TextInputSheet`, `VoiceInputSheet`, `OcrResultSheet`) memakai preview **satu transaksi** (`AiParsePreviewCard`, `OcrResultParsedBody`). User sulit memahami bila AI mengembalikan **beberapa transaksi** (kategori berbeda).

**Solusi (simpel & elegan):**

1. **Deteksi:** `VoiceParseResultModel` / `OcrParseResultModel` memiliki `aiTransactions` (list slice). `isAiMultiTransaction` = `aiTransactions.length > 1`.
2. **Header ringkas:** Satu baris informasi, mis. *"Beberapa transaksi terdeteksi (N)"* + ikon sukses — tidak membanjiri teks.
3. **Daftar vertikal:** Tiap transaksi = **kartu ringkas** (radius, border halus, warna surface):
   - Nomor urut **1 … N** (badge kecil).
   - **Kategori** (nama + ikon jika ada) + **total** transaksi tersebut (bold).
   - Jika multi-item: **sub-daftar** baris (reuse pola `AiItemTile` atau ringkas: nama + nominal).
   - **Merchant** / **catatan** hanya ditampilkan jika non-kosong (per transaksi).
4. **OCR:** Tetap tampilkan **pratinjau gambar** di atas; **hint** satu baris: *"Foto struk hanya dilampirkan pada transaksi pertama."* (l10n).
5. **Transkrip / provider:** Tetap di bawah seperti sekarang (voice/teks).
6. **Satu transaksi:** UI **tidak berubah** secara drastis — path lama `AiParsePreviewCard` / `OcrResultParsedBody` untuk `!isAiMultiTransaction`.

**File Flutter terkait:** `lib/global/widgets/ai_parse_preview_card.dart`, `lib/global/widgets/ai_multi_transaction_preview.dart` (baru, opsional), `lib/features/ocr/view/widgets/ocr_result_parsed_body.dart`, string `app_en.arb` / `app_id.arb`.

---

## 1. Latar belakang & tujuan

### 1.1 Perilaku saat ini

- **Input:** Teks (`TextInputSheet`), suara → teks (`VoiceInputSheet`), gambar struk (`OcrResultSheet`) memanggil Edge Function **`ai-parse`** (mode `text` / `voice` / `ocr`).
- **Output:** Satu objek JSON “satu transaksi”: `amount`, `items[]`, **`categoryId` / `categoryKeyword` di root saja**, `note`, `merchantName`, `type`, wallet, tanggal, dll.
- Di **`supabase/functions/ai-parse/index.ts`**, prompt teks/suara secara eksplisit: *multi-item* = beberapa baris **harga terpisah**, **satu kategori root** untuk seluruh transaksi; **`categoryId` tidak boleh di dalam item** (dan `reverseMapResponse` menghapus `categoryId` per item jika model mengembalikannya).
- **Flutter:** `VoiceParseResultModel` / `OcrParseResultModel` + `TransactionFormPrefillMixin` (`applyVoicePrefill`, `applyOcrPrefill`) mengisi **form tunggal** (`setTotalAmount`, `prefillItems`, `setCategory`, satu `note` / `merchant`).

### 1.2 Tujuan bisnis

Jika dari AI terdeteksi **beberapa kelompok pengeluaran/pemasukan dengan kategori berbeda**, hasilnya harus bisa dipetakan ke **mode Multi Transaksi** (beberapa `ManualTransactionEntryModel`), bukan dipaksa jadi satu transaksi satu kategori.

**Contoh (dari product owner):**

> Input teks: *"Jajan 10K Jasuke, Pentol 20K dan 2K Parkir"*  
> **Hasil yang diinginkan:**
> 1. **Transaksi 1** — multi-item: item Jasuke 10K + Pentol 20K, **kategori “Jajan”** (satu kategori induk untuk semua baris di transaksi ini).  
> 2. **Transaksi 2** — single item: Parkir 2K, **kategori Parkir** (atau setara transport).

### 1.3 Batasan scope (usulan awal)

| Area | Keputusan usulan |
|------|------------------|
| Tipe transaksi | Multi transaksi otomatis untuk **expense** dan **income**. **Transfer / hutang / piutang** tetap **satu transaksi** seperti sekarang (kompleksitas & risiko regresi). |
| UI entry | Hanya relevan jika user membuka form **Pengeluaran / Pemasukan** dan mengaktifkan / menerima **Multi Transaksi** (sudah ada `isMultiManualMode` + `manualMultiEntries`). |
| Batas jumlah | Selaraskan **maksimal 10** transaksi per batch (sudah ada di client + RPC `create_transactions_batch`). AI atau client harus **memotong / menggabungkan** dengan aturan eksplisit jika model mengembalikan lebih dari 10 kelompok. |
| OCR gambar | Jika multi transaksi: **lampiran / prefill foto struk hanya pada transaksi pertama**; transaksi lain **tanpa** file lampiran yang sama (hindari duplikasi bukti). |

---

## 2. Aturan produk (detil)

### 2.1 Kapan mengaktifkan “multi transaksi” dari AI?

**Definisi pemicu (disarankan):**

- Setelah parsing, jika **lebih dari satu “kelompok”** masing-masing punya:
  - daftar baris (`items`) dan/atau satu nominal, dan  
  - **kategori root** (short id / UUID setelah reverse map) **yang berbeda antar kelompok**,  
  maka Flutter menganggap hasil sebagai **multi transaksi** dan mengisi `manualMultiEntries` (bukan satu `items` flat dengan satu `categoryId`).

**Pengelompokan (selaras contoh “Jajan”):**

- Baris-baris yang menurut AI **masih satu kategori induk yang sama** → **satu** `ManualTransactionEntryModel` dengan **multi-item** (jika >1 baris) atau single-item (jika 1 baris).
- Baris dengan **kategori berbeda** → **entry terpisah**.

*Catatan:* Ini mengasumsikan model bisa mengembalikan **kategori per baris** atau **per kelompok** — lihat §3 (kontrak JSON).

### 2.2 Merchant & catatan **per transaksi**

- Saat multi transaksi: setiap `ManualTransactionEntryModel` punya **`merchantName`**, **`note`** sendiri.
- **Usulan splitting `note` / `merchantName` dari AI:**
  - **Per kelompok:** AI mengisi `merchantName` / `note` **di level tiap transaksi** dalam array (bukan hanya satu root).
  - Jika AI hanya mengisi satu `note` global: **transaksi pertama** dapat menerima note penuh; lainnya `null` **atau** substring generik (“Bagian dari input gabungan”) — **perlu keputusan produk** (lihat §7).

### 2.3 OCR & lampiran

- **Satu file gambar** tetap di-*pick* user sekali.
- Jika hasil parse → multi transaksi:
  - **`pendingOcrImageFileProvider` / `applyOcrImagePrefill`:** terapkan path lampiran **hanya ke entry index 0**.
  - Entry `1..n-1`: `localAttachmentPath` / `attachmentUrl` kosong kecuali user menambah manual nanti.

### 2.4 Wallet & tanggal

- **Per transaksi:** setiap elemen `transactions[]` dapat punya **`suggestedWalletId`** sendiri (UUID setelah reverse map) bila user menyebut sumber bayar berbeda per bagian (mis. *cash* vs *Bank Jago*).
- **Duplikasi ke semua:** jika hanya **satu** dompet yang berlaku untuk seluruh input, AI mengisi **root** `suggestedWalletId` dan **mengulang short id dompet yang sama pada setiap slice** agar prefill konsisten.
- **Tanggal:** `date` di root tetap dipakai untuk semua entry kecuali nanti ada override per slice (opsional).

### 2.5 Keputusan produk (kutipan jawaban)

1. **Income:** multi transaksi dari AI berlaku juga untuk **pemasukan** (bukan hanya pengeluaran).
2. **Satu dompet untuk semua:** jika AI hanya punya satu dompet yang relevan, **duplikasikan** id dompet itu ke **setiap slice** (dan root), bukan dibiarkan null di slice.
3. **OCR split vs total:** tetap **split** paksa ke beberapa transaksi bila perlu; saat **prefill** ke form, **`grandTotal` OCR tidak dipakai sebagai sumber kebenaran** — nominal per entry dari **jumlah slice / item** (total form = penjumlahan manual entri).
4. **Penjelasan poin §3 “backward compatibility / field root” (yang ditanyakan):** maksudnya adalah: respons lama tanpa `transactions[]` harus tetap jalan. Untuk respons **baru** dengan `transactions[]` panjang ≥2, field root seperti `amount` / `items` / `categoryId` bisa kosong atau disamakan dengan transaksi pertama — itu pilihan agar **klien lama** tidak error. Di implementasi SakuRapi kita: Flutter hanya mengaktifkan multi bila `transactions.length > 1`, dan prefill mengisi entri dari **slice**, bukan dari `grandTotal` gabungan.
5. **Cakupan:** perilaku ini berlaku di **semua** jalur yang memakai `ai-parse` (teks, suara, OCR) + preview + prefill.

---

## 3. Kontrak API & Edge Function `ai-parse`

### 3.1 Prinsip “tidak membebani AI”

- **Satu panggilan** Vertex tetap dipakai per request (text/voice/ocr) — hindari **rantai panggilan** Gemini ganda untuk satu user action.
- **Token / ukuran output:**
  - Batasi panjang `items` per transaksi dan **jumlah transaksi** (≤ 10).
  - Prompt: instruksi **ringkas** + **1–2 few-shot** untuk bentuk baru `transactions[]`, hindari duplikasi besar dari prompt lama.
- **Backward compatibility:**
  - Response lama tetap didukung: `{ ... single transaction fields }`.
  - Response baru misalnya: `"transactions": [ { ...same shape as today per element... }, ... ]` **dan** field root lama **opsional** atau diset konsisten dengan transaksi pertama — **perlu dipilih** (lihat §7).

### 3.2 Bentuk JSON yang disarankan (draft)

**Opsi A — Array transaksi (disarankan untuk review):**

```json
{
  "isTransaction": true,
  "type": "expense",
  "transactions": [
    {
      "amount": 30000,
      "items": [
        { "name": "Jasuke", "qty": 1, "unitPrice": null, "subtotal": 10000 },
        { "name": "Pentol", "qty": 1, "unitPrice": null, "subtotal": 20000 }
      ],
      "categoryId": "eXX",
      "categoryKeyword": "jajan",
      "note": null,
      "merchantName": null,
      "includeReceiptImage": true
    },
    {
      "amount": 2000,
      "items": [],
      "categoryId": "eYY",
      "categoryKeyword": "parkir",
      "note": null,
      "merchantName": null,
      "includeReceiptImage": false
    }
  ],
  "suggestedWalletId": "w1",
  "date": null
}
```

- `includeReceiptImage`: hanya hint untuk client OCR (entry pertama `true`, lain `false`); bisa juga disimpulkan dari index tanpa field.
- Untuk **single transaksi**, `transactions` **absen atau panjang 1** → perilaku identik hari ini.

**Opsi B — Tetap root + `itemGroups`:** lebih kompleks untuk reverse map dan untuk model.

### 3.3 Perubahan `reverseMapResponse` (Edge)

- Reverse map **`categoryId`** dan **`suggestedWalletId`** untuk **setiap** elemen di `transactions[]`.
- Hapus **`categoryId`** dari `items` per slice (sama seperti root) — kategori induk per transaksi di form.

### 3.4 Quota & logging

- Tetap pakai RPC quota **sekali** per invoke sukses (sudah ada).
- Log struktural: `mode`, `transactionCount`, `provider` — membantu monitor lonjakan output.

---

## 4. Perubahan Flutter (ringkas — untuk fase implementasi berikutnya)

| Layer | Perubahan |
|-------|-----------|
| **Model** | Perluas `VoiceParseResultModel` / `OcrParseResultModel` (atau model baru `AiMultiTransactionParseResult`) untuk membaca `transactions[]` + flag “multi dari AI”. |
| **Provider** | `pendingVoicePrefillProvider` / `pendingOcrPrefillProvider` bisa membawa struktur baru; pastikan serialisasi jika perlu. |
| **Prefill** | `TransactionFormPrefillMixin`: jika multi dari AI → `setMultiManualMode(true)` lalu isi `manualMultiEntries` dengan mapping items/category/note/merchant/wallet/date; panggil `applyOcrImagePrefill` hanya untuk entry pertama. |
| **Sheet** | `TextInputSheet`, `VoiceInputSheet`, `OcrResultSheet` (dan preview card jika ada): copy/teks penjelasan bahwa hasil bisa **beberapa transaksi**; tombol terima harus konsisten. |
| **l10n** | String untuk “AI mendeteksi beberapa transaksi” / error jika >10 kelompok. |

---

## 5. Alur end-to-end (ringkas)

1. User input → `ai-parse` → JSON.  
2. Client validasi schema + batas 10.  
3. Jika `transactions.length > 1` (atau aturan pemicu lain):  
   - navigasi / state: form expense/income + **multi manual** ON;  
   - isi N entry;  
   - OCR image → entry 0 saja.  
4. Jika satu transaksi: path existing **tanpa** ubah UX lama.

---

## 6. Pengujian yang direncanakan

- Unit: parser map JSON baru → model; pemotongan >10; fallback response lama.
- Widget/integration: prefill multi entry + lampiran hanya pertama.
- Edge: contoh prompt fixed + assert JSON shape (jika ada harness Deno).
- Regresi: input lama satu transaksi + multi-item satu kategori tidak berubah.

---

## 7. Pertanyaan terbuka untuk product / reviewer

1. **Income:** Apakah multi transaksi otomatis juga wajib untuk **income** (mis. beberapa sumber berbeda dalam satu kalimat), atau **hanya expense** pada fase 1?  
2. **Satu `note` / `merchantName` global** dari model: distribusi ke entry — cukup **tempel semua di entry pertama** saja, atau **duplikasi** ke semua, atau **kosongkan** yang lain?  
3. **OCR `grandTotal` vs jumlah baris** setelah split: jika total struk tidak sama dengan jumlah subtotal per kelompok, apakah **menolak split**, **menyesuaikan** entry terakhir, atau **memaksa satu transaksi**?  
4. **Versi API:** Preferensi **hanya `transactions[]`** (tanpa root `items`) untuk response baru, atau **dual-field** dengan transaksi pertama mirror ke root untuk kompatibilitas alat debug?  
5. **Voice raw transcript:** Tetap disimpan di entry pertama saja atau di semua?

---

## 8. Referensi kode (baseline saat dokumen ini dibuat)

- Edge: `supabase/functions/ai-parse/index.ts` — `buildTextSystemPrompt`, `buildOcrSystemPrompt`, `reverseMapResponse`, timeout text/vision.  
- Flutter:  
  - `lib/features/voice/models/voice_parse_result_model.dart`  
  - `lib/features/ocr/models/ocr_parse_result_model.dart`  
  - `lib/features/transaction/view/ui/transaction_form_prefill_mixin.dart`  
  - `lib/features/voice/view/ui/text_input_sheet.dart`, `voice_input_sheet.dart`  
  - `lib/features/ocr/view/ui/ocr_result_sheet.dart`  
- Multi transaksi manual: `My-Wiki/raw/docs/MULTI_MANUAL_TRANSACTION_PLAN.md` + `ManualTransactionEntryModel`.

---

## 9. Checklist implementasi (setelah plan disetujui)

- [ ] Setujui kontrak JSON (§3.2) + jawaban §7  
- [ ] Update prompt + `reverseMapResponse` + sanitizer di `ai-parse`  
- [ ] Deploy Edge Function (dev → prod) + catat versi  
- [ ] Update model + prefill + sheets + l10n  
- [ ] Uji manual skenario contoh “Jajan / Parkir” + OCR multi + regressi single  
- [ ] Ingest wiki `wiki/sources/plan-multi-manual-transaction` atau dokumen terkait AI pipeline

---

*Dokumen ini dibuat sebagai bahan review; tidak mengubah perilaku aplikasi hingga disetujui dan diimplementasikan terpisah.*
