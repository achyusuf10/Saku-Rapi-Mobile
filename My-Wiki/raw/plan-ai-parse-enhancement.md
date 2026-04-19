# Plan: Enhancement AI Parse — Kirim Wallet + Kategori Lengkap, Perbaiki Prefill

> Status: **DRAFT v3 — Menunggu Review**
> Tanggal: 2026-04-19

---

## Ringkasan

Memperkaya data yang dikirim ke Edge Function `ai-parse` (kategori + daftar wallet user) agar AI menghasilkan prefill yang lebih akurat. Wallet & kategori sama-sama pakai **short ID mapping** di prompt untuk efisiensi token. Juga menambahkan **multi-item support untuk text/voice** — jika user menyebut harga per item, AI akan return array items seperti OCR.

---

## Keputusan yang Sudah Final

| # | Keputusan | Jawaban |
|---|-----------|---------|
| 1 | Data wallet ke AI | Cukup `{id, name}` — tanpa icon/balance |
| 2 | Wallet `excludeFromTotal` | Tetap dikirim |
| 3 | Wallet tidak cocok | AI return `null`, prefill tidak menampilkan wallet |
| 4 | Icon/color kategori ke AI | Tidak — lookup lokal di Flutter dari `CategoryModel` |
| 5 | Child categories | Tetap kirim semua (parent + child) |
| 6 | Rename field wallet | `suggestedWallet` → `suggestedWalletId`, `destinationWallet` → `destinationWalletId` |
| 7 | Icon kategori di prefill | ✅ **Sudah jalan** — `setCategory()` → copy `icon` ke item → `SakuCategoryIcon` render otomatis |
| 8 | Default fallback kategori | Expense → "Pengeluaran yang tidak diketahui", Income → "Hadiah/Pemberian" |
| 9 | Multi-item text/voice | ✅ Support — jika user sebut harga per item, AI return `items[]` seperti OCR. Jika hanya 1 item / tidak ada detail harga per item → tetap single-item mode (field `amount`) |

---

## Pertimbangan Efisiensi & Performa

### Token Efficiency di Prompt

UUID panjang ~36 char per entry. Dengan short ID mapping:
- **Kategori** sudah pakai short ID: `e1`, `e2`, `i1` → hemat ~90% token
- **Wallet** akan pakai pola sama: `w1`, `w2`, `w3` → hemat ~90% token
- Short ID di-inject ke user prompt sebagai compact JSON one-liner

**Contoh prompt injection (user prompt):**
```
beli makan 25rb pakai gopay
Categories: {"e1":"Kebutuhan Rumah Tangga","e2":"Makan di Luar","e3*":"Pengeluaran yang tidak diketahui","i1":"Gaji Bulanan","i2*":"Hadiah/Pemberian"}
Wallets: {"w1":"Kas","w2":"Bank BCA","w3":"GoPay"}
```
- Asterisk `*` = default fallback category (tidak tambah token signifikan)
- Total tambahan token dari wallet list: ~30-60 token (sangat ringan)

### Tidak Kirim Data Berlebihan

| Data | Kirim? | Alasan |
|------|--------|--------|
| `icon`, `color` kategori | ❌ | AI tidak perlu, lookup lokal |
| `balance` wallet | ❌ | Irrelevant untuk parsing |
| `parent_id` kategori | ❌ | AI tidak perlu tahu hierarki, cukup nama saja |
| `is_default` kategori | ✅ (via asterisk di prompt map) | Agar AI tahu fallback, tapi cost = 1 char per default category |

### Processing Speed

- Model text/voice tetap `gemini-2.5-flash-lite` (timeout 10s) — paling cepat
- Model OCR tetap `gemini-2.5-flash` (timeout 20s) — perlu vision capability
- Tambahan wallet list di prompt **tidak signifikan** ke latency (< 100 token ekstra)
- Tidak ada API call tambahan (wallet sudah ada di client memory)

---

## Kondisi Saat Ini (Before)

### Request ke Edge Function

**Text/Voice:**
```json
{
  "mode": "text",
  "text": "beli makan 25rb pakai gopay",
  "localDate": "2026-04-19",
  "categories": [{"id": "uuid-cat-1", "name": "Makan", "type": "expense"}, ...]
}
```

**OCR:**
```json
{
  "mode": "ocr",
  "image": "<base64>",
  "mimeType": "image/jpeg",
  "localDate": "2026-04-19",
  "categories": [...]
}
```

**❌ Wallet tidak dikirim.** AI menebak nama wallet free text → form matching exact `name.toLowerCase()` → sering gagal.

### Response AI saat ini

```json
{
  "suggestedWallet": "GoPay",    // ← free text, bisa tidak cocok
  "destinationWallet": "BCA"      // ← free text, bisa tidak cocok
}
```

---

## Rencana Perubahan

### PART A: Kirim Wallet ke AI (Short ID Mapping)

#### A1. Flutter — Bangun list wallet

**File:** 3 controller (voice, text, OCR)

```dart
// Di controller, ambil dari walletListProvider
final wallets = ref.read(walletListProvider);
final walletMaps = wallets
    .map((w) => {'id': w.id, 'name': w.name})
    .toList();
```

Semua wallet dikirim termasuk `excludeFromTotal = true`.

#### A2. Flutter — Teruskan ke datasource via repository

**File:** 2 repository + 2 datasource

Request body bertambah:
```json
{
  "mode": "text",
  "text": "...",
  "localDate": "2026-04-19",
  "categories": [{"id": "uuid", "name": "Makan", "type": "expense"}],
  "wallets": [{"id": "uuid", "name": "Kas"}, {"id": "uuid", "name": "GoPay"}]
}
```

#### A3. Edge Function — Wallet Short ID Mapping

**File:** `ai-parse/index.ts`

Tambah fungsi `buildWalletMapping()` — pola identik dengan `buildIdMapping()` untuk kategori:

```typescript
// Input:  [{id: "uuid-123", name: "GoPay"}, {id: "uuid-456", name: "Bank BCA"}]
// Output: shortToUuid = {w1: "uuid-123", w2: "uuid-456"}
//         promptMap   = {w1: "GoPay", w2: "Bank BCA"}
```

Inject ke user prompt:
```
Wallets: {"w1":"Kas","w2":"Bank BCA","w3":"GoPay"}
```

Update system prompt rules:
- `suggestedWalletId`: pilih wallet short ID yang paling cocok dari list. `null` jika tidak ada yang cocok.
- `destinationWalletId`: HANYA untuk transfer. `null` untuk tipe lain.

`reverseMapResponse()` — extend untuk convert `suggestedWalletId` & `destinationWalletId` short ID → UUID.

Validasi: `MAX_WALLETS = 50`.

#### A4. Flutter — Model & Form: wallet ID-based matching

**File:** 2 model + 1 form page

Model changes:
- `suggestedWallet` (String?) → `suggestedWalletId` (String? UUID)
- `destinationWallet` (String?) → `destinationWalletId` (String? UUID)
- `fromEdgeFunctionMap()`: parse dari key `suggestedWalletId` / `destinationWalletId`

Form page changes (`_applyVoicePrefill`, `_applyOcrPrefill`):
```dart
// BEFORE: name matching (unreliable)
final walletName = voiceResult.suggestedWallet!.toLowerCase();
final matched = wallets.where((w) => w.name.toLowerCase() == walletName);

// AFTER: ID matching (exact, reliable)
if (voiceResult.suggestedWalletId != null) {
  final matched = wallets.where((w) => w.id == voiceResult.suggestedWalletId);
  if (matched.isNotEmpty) ctrl.setWallet(matched.first);
}
```

Jika `suggestedWalletId == null` → tidak set wallet di prefill (user pilih manual).

---

### PART B: Perkaya Kategori — Default Fallback

#### B1. Flutter — Tambah `is_default` ke category maps

**File:** 3 controller

```dart
final categoryMaps = categories.map((c) => {
  'id': c.id,
  'name': c.name,
  'type': c.type.name,
  'is_default': c.isDefault,  // ← tambahan baru
}).toList();
```

Tidak kirim `parent_id`, `icon`, `color` — tidak relevan untuk AI.

#### B2. Edge Function — Tandai default di prompt + instruksi fallback

**File:** `ai-parse/index.ts`

Di `buildIdMapping()`: tandai kategori default dengan asterisk di prompt map.

```typescript
// Contoh prompt map yang dihasilkan:
// {"e1":"Kebutuhan Rumah Tangga","e2":"Makan di Luar","e15*":"Pengeluaran yang tidak diketahui","i1":"Gaji Bulanan","i6*":"Hadiah/Pemberian"}
```

Tambah rule di system prompt (text + OCR):
```
CATEGORY FALLBACK: Jika tidak ada kategori yang cocok, pilih kategori bertanda * (default).
Untuk expense gunakan default expense (*), untuk income gunakan default income (*).
JANGAN mengarang kategori baru — hanya pilih dari list yang diberikan.
```

---

### PART C: Pastikan Response Lengkap Semua Tipe Transaksi

#### C1. Edge Function — Update rules di system prompt

Tambah/perkuat instruksi:
1. **amount wajib**: "Jika amount tidak disebutkan, isi `0`"
2. **date + time**: "Jika disebutkan waktu spesifik, sertakan jam (yyyy-MM-ddTHH:mm). Jika hanya tanggal, tetap yyyy-MM-ddTHH:mm dengan waktu 00:00. Jika tidak disebutkan, null"
3. **note**: "Deskripsi item/jasa. Jangan masukkan angka, tanggal, nama wallet, nama orang"
4. **merchantName**: "Nama toko/merchant jika diketahui, null jika tidak"

**Field matrix per tipe** (tidak berubah dari sekarang, sudah lengkap):

| Field | Expense | Income | Transfer | Debt/Loan |
|-------|:-------:|:------:|:--------:|:---------:|
| amount | ✅ (0 jika kosong) | ✅ | ✅ | ✅ |
| categoryId | ✅ e-prefix (fallback e*) | ✅ i-prefix (fallback i*) | null | null |
| suggestedWalletId | ✅ w-prefix / null | ✅ | ✅ (from) | ✅ |
| destinationWalletId | null | null | ✅ (to) | null |
| withPerson | null | null | null | ✅ wajib |
| note | opsional | opsional | opsional | opsional |
| merchantName | opsional | opsional | null | null |
| date | opsional | opsional | opsional | opsional |
| debtLoanKind | null | null | null | ✅ |

#### C2. Edge Function — Update response schema field names

**Text/Voice output schema berubah:**
```json
{
  "isTransaction": true,
  "amount": 50000,
  "items": [],
  "categoryId": "<short ID / null>",
  "categoryKeyword": "makan",
  "note": "Beli nasi goreng",
  "type": "expense|income|transfer|debt|loan",
  "debtLoanKind": "debt|loan|debt_payment|loan_collection|null",
  "suggestedWalletId": "<short wallet ID / null>",
  "destinationWalletId": "<short wallet ID / null>",
  "withPerson": "Budi|null",
  "merchantName": "Warteg Bu Rani|null",
  "date": "2026-04-19T19:30|null"
}
```

> **Baru:** field `items` ditambahkan ke text/voice schema. Lihat PART E untuk detail.

**OCR output schema berubah:**
```json
{
  "isTransaction": true,
  "type": "expense|income|transfer|debt|loan|debt_payment|loan_collection",
  "merchantName": "INDOMARET|null",
  "date": "2026-04-19T14:30|null",
  "grandTotal": 29000,
  "items": [{"name": "...", "qty": 1, "unitPrice": 8500, "subtotal": 8500, "categoryId": "e1|null"}],
  "categoryId": "<short ID / null>",
  "categoryKeyword": "belanja",
  "suggestedWalletId": "<short wallet ID / null>",
  "destinationWalletId": "<short wallet ID / null>",
  "withPerson": "null",
  "note": "null"
}
```

Perubahan vs sekarang:
- `suggestedWallet` → `suggestedWalletId` (short ID, bukan free text)
- `destinationWallet` → `destinationWalletId` (short ID, bukan free text)

#### C3. Edge Function — Update few-shot examples

Few-shot examples di system prompt harus di-update:
- Ganti `"suggestedWallet":"GoPay"` → `"suggestedWalletId":"w3"` (contoh)
- Ganti `"destinationWallet":"..."` → `"destinationWalletId":"..."`
- Tambah catatan di few-shot: "wallet IDs refer to the Wallets list provided"

**Catatan penting:** Few-shot example tidak bisa pakai wallet ID spesifik karena wallet list dinamis per user. Solusi:
- Gunakan placeholder: `"suggestedWalletId":"<matching wallet ID or null>"`
- Atau instruksi di system prompt sudah cukup jelas tanpa perlu few-shot wallet khusus

---

### PART D: Icon Kategori di Prefill ✅ SUDAH JALAN

**Tidak ada perubahan diperlukan.** Sudah terverifikasi:
1. `ctrl.setCategory(matched)` → copy `category.icon` ke `items.first.categoryIcon`
2. `TransactionCategoryPickerTile` → render `SakuCategoryIcon(iconName: item.categoryIcon!)`
3. Flow sudah lengkap dari AI response → form prefill → icon visible

---

### PART E: Multi-Item Support untuk Text/Voice

Saat ini text/voice hanya return single `amount` + `categoryId`. Tapi jika user menyebut beberapa item dengan harga masing-masing (contoh: "Beli ikan 20K, ayam 10K, sayur 5K pakai cash"), AI seharusnya return multiple items — persis seperti OCR.

#### Kapan Multi-Item Aktif?

| Input text | Mode |
|-----------|------|
| "makan siang 25rb" | **Single-item** — hanya `amount: 25000`, `items: []` |
| "beli ikan 20K ayam 10K pakai cash" | **Multi-item** — `amount: 30000`, `items: [{name:"Ikan",qty:1,subtotal:20000},{name:"Ayam",qty:1,subtotal:10000}]` |
| "belanja indomaret 50rb" | **Single-item** — hanya total, tidak ada detail item |
| "gaji masuk 5jt" | **Single-item** — income, tidak ada items |
| "transfer 100rb ke BCA" | **Single-item** — transfer, tidak ada items |

**Rule:** Multi-item hanya untuk **expense/income** dan hanya jika user **eksplisit menyebut harga per item**. Transfer/debt/loan → selalu `items: []`.

#### E1. Edge Function — Update text/voice system prompt

**File:** `ai-parse/index.ts` → `buildTextSystemPrompt()`

Tambah field `items` ke output schema:
```json
{"isTransaction":true,"amount":0,"items":[{"name":"","qty":1,"unitPrice":null,"subtotal":0,"categoryId":"e1|null"}],"categoryId":"e1|null","categoryKeyword":"", ...}
```

Tambah rules:
```
MULTI-ITEM RULES:
- "items": array of line items. ONLY populate if user explicitly mentions MULTIPLE items with INDIVIDUAL prices.
- If items is populated: "amount" = sum of all items subtotal.
- If items is empty []: "amount" = the single total amount.
- Each item: {"name":"<item name>","qty":<number, default 1>,"unitPrice":<number|null>,"subtotal":<number>,"categoryId":"<short ID|null>"}
- Per-item categoryId follows the same rules (e-prefix for expense, i-prefix for income, null otherwise).
- For transfer/debt/loan: items MUST be [].
- Do NOT split a single purchase into fake items. Only split when user clearly lists separate items with separate prices.
```

Tambah few-shot example multi-item:
```
Input: "Beli ikan 20K, ayam 10K, sayur 5rb pakai cash"
Output: {"isTransaction":true,"amount":35000,"items":[{"name":"Ikan","qty":1,"unitPrice":20000,"subtotal":20000,"categoryId":"e1"},{"name":"Ayam","qty":1,"unitPrice":10000,"subtotal":10000,"categoryId":"e1"},{"name":"Sayur","qty":1,"unitPrice":5000,"subtotal":5000,"categoryId":"e1"}],"categoryId":null,"categoryKeyword":"belanja","note":null,"type":"expense","debtLoanKind":null,"suggestedWalletId":"<matching wallet ID or null>","destinationWalletId":null,"withPerson":null,"merchantName":null,"date":null}
```

#### E2. Flutter — Update `VoiceParseResultModel`

**File:** `voice_parse_result_model.dart`

Tambah field baru:
```dart
final List<VoiceItemModel> items;  // baru
```

Tambah class `VoiceItemModel` (di file yang sama atau file terpisah):
```dart
class VoiceItemModel {
  final String? name;
  final int qty;
  final int? unitPrice;
  final int subtotal;
  final String? categoryId;

  const VoiceItemModel({this.name, this.qty = 1, this.unitPrice, required this.subtotal, this.categoryId});

  factory VoiceItemModel.fromMap(Map<String, dynamic> map) => VoiceItemModel(
    name: map['name'] as String?,
    qty: (map['qty'] as num?)?.toInt() ?? 1,
    unitPrice: (map['unitPrice'] as num?)?.toInt(),
    subtotal: (map['subtotal'] as num?)?.toInt() ?? 0,
    categoryId: map['categoryId'] as String?,
  );
}
```

Di `fromEdgeFunctionMap()`:
```dart
items: (data['items'] as List<dynamic>?)
    ?.map((e) => VoiceItemModel.fromMap(e as Map<String, dynamic>))
    .toList() ?? [],
```

> **Catatan:** `VoiceItemModel` sangat mirip `OcrItemModel` — tapi tetap dipisah karena berada di feature berbeda (voice vs ocr). Bisa dipertimbangkan shared model tapi opsional.

#### E3. Flutter — Update `_applyVoicePrefill` di form page

**File:** `transaction_form_page.dart`

Saat ini `_applyVoicePrefill` hanya handle single-item. Perlu ditambah branching mirip OCR:

```dart
void _applyVoicePrefill(TransactionFormController ctrl) {
  final voiceResult = ref.read(pendingVoicePrefillProvider);
  if (voiceResult == null) return;
  ref.read(pendingVoicePrefillProvider.notifier).state = null;

  // ... existing: set type, debtLoanKind, merchant, note, date, wallet ...

  // NEW: Multi-item branching (expense/income only)
  if (voiceResult.items.isNotEmpty && voiceResult.items.length > 1) {
    // ── MULTI-ITEM MODE ──
    // Balance check: jika sum(items) ≠ amount, tambah item penyeimbang
    // (reuse logic mirip OcrRepository.balanceResult tapi untuk voice)
    final txItems = voiceResult.items.asMap().entries.map((e) {
      final item = e.value;
      final cat = item.categoryId != null
          ? categoryLookup[item.categoryId] : null;
      return TransactionItemModel(
        itemName: item.name,
        qty: item.qty,
        unitPrice: item.unitPrice,
        amount: item.subtotal,
        sortOrder: e.key,
        categoryId: cat?.id,
        categoryName: cat?.name,
        categoryIcon: cat?.icon,
        categoryColor: cat?.color,
      );
    }).toList();
    ctrl.prefillItems(txItems);
  } else if (voiceResult.items.length == 1) {
    // ── SINGLE ITEM from items array ──
    // Set amount from item, category from item
    final item = voiceResult.items.first;
    ctrl.setTotalAmount(item.subtotal.toDouble());
    // ... category from item.categoryId
  } else {
    // ── SINGLE-ITEM MODE (existing behavior) ──
    if (voiceResult.amount != null) ctrl.setTotalAmount(voiceResult.amount!);
    // ... existing category matching via categoryId / categoryKeyword
  }
}
```

**Catatan penting:** Ketika multi-item aktif:
- `amount` di top-level = grand total (sum of items) — tetap di-set
- `categoryId` di top-level = `null` (karena setiap item punya categoryId sendiri)
- `note` di top-level tetap bisa ada (misal deskripsi umum)
- Per-item `categoryId` di-lookup dari `CategoryModel` untuk dapat icon/name/color

#### E4. Balance Logic untuk Voice Multi-Item

Perlu fungsi balance mirip `OcrRepository.balanceResult()` tapi untuk voice:

**Opsi 1:** Buat static method di `VoiceRepository`
**Opsi 2:** Reuse/extract `balanceResult` ke shared utility

Logic:
```
if sum(items.subtotal) ≠ amount:
  diff = amount - sum(items.subtotal)
  if diff > 0 → tambah "Item lainnya" (selisih positif)
  if diff < 0 → tambah "Diskon/potongan" (selisih negatif)
```

Karena untuk text/voice, kemungkinan selisih kecil karena AI menghitung sendiri, tapi tetap perlu safety net.

> **Rekomendasi:** Extract `balanceResult` ke shared utility (misal `lib/core/utils/transaction_balance_utils.dart`) agar tidak duplikasi. Atau cukup taruh di `VoiceRepository` sebagai static method terpisah — lebih simple.

---

## Ringkasan Perubahan per File

### 1. Edge Function (`ai-parse/index.ts`) — MEDIUM-HIGH

| # | Perubahan |
|---|----------|
| 1 | Tambah `WalletInput` interface + `buildWalletMapping()` — short ID `w1,w2...` |
| 2 | Inject `Wallets: {...}` ke user prompt (text + OCR) |
| 3 | Rename `suggestedWallet` → `suggestedWalletId`, `destinationWallet` → `destinationWalletId` di output schema |
| 4 | Update system prompt: wallet matching rule (pilih dari list, null jika tidak cocok) |
| 5 | Update system prompt: amount wajib (0 jika kosong) |
| 6 | Update system prompt: category fallback rule (asterisk = default) |
| 7 | `buildIdMapping()`: tandai default categories dengan asterisk di prompt map |
| 8 | `reverseMapResponse()`: extend untuk reverse wallet short ID → UUID + items array |
| 9 | Update few-shot examples (wallet ID placeholder + multi-item example) |
| 10 | Validasi `MAX_WALLETS = 50` |
| 11 | **Tambah `items` ke text/voice output schema + multi-item rules di system prompt** |

### 2. Flutter Controllers (3 file) — LOW

- `voice_input_controller.dart`
- `text_input_controller.dart`
- `ocr_scan_controller.dart`

Perubahan per file:
- Ambil wallet list dari `walletListProvider`
- Format `[{id, name}]`
- Tambah `is_default` ke category maps
- Pass wallets ke repository call

### 3. Flutter Repositories (2 file) — LOW

- `voice_repository.dart`
- `ocr_repository.dart`

Perubahan: tambah param `List<Map<String, String>> wallets`, pass-through ke datasource.

### 4. Flutter Datasources (2 file) — LOW

- `voice_remote_data_source.dart`
- `ocr_remote_data_source.dart`

Perubahan: tambah `body['wallets'] = wallets;`

### 5. Flutter Models (2 file) — LOW-MEDIUM

- `voice_parse_result_model.dart`
- `ocr_parse_result_model.dart`

Perubahan:
- Rename `suggestedWallet` → `suggestedWalletId`
- Rename `destinationWallet` → `destinationWalletId`
- Update `fromEdgeFunctionMap()` parser
- **`voice_parse_result_model.dart`: tambah `items: List<VoiceItemModel>` + class `VoiceItemModel`**

### 6. Flutter Form Page (1 file) — MEDIUM-HIGH

- `transaction_form_page.dart`

Perubahan di `_applyVoicePrefill` + `_applyOcrPrefill`:
- Wallet matching: `name.toLowerCase()` → `w.id == result.suggestedWalletId`
- Jika null → skip (tidak prefill wallet)
- **`_applyVoicePrefill`: tambah multi-item branching** (items.length > 1 → balance + `ctrl.prefillItems()`, mirip `_applyOcrPrefill`)

### 7. Flutter Shared Utility (1 file, baru) — LOW

- `lib/core/utils/transaction_balance_utils.dart` (atau static method di `VoiceRepository`)

Extract balance logic dari `OcrRepository.balanceResult()` ke shared utility agar bisa dipakai oleh voice multi-item juga. Menghindari duplikasi kode.

---

## Urutan Eksekusi

| Step | Area | Detail |
|------|------|--------|
| 1 | Edge Function | Update prompt (wallet mapping + multi-item text + category default), deploy |
| 2 | Flutter Datasources | Tambah `wallets` ke body |
| 3 | Flutter Repositories | Pass-through `wallets` param |
| 4 | Flutter Controllers | Build wallet list + enriched categories |
| 5 | Flutter Models | Rename wallet fields + tambah `items` di voice model |
| 6 | Flutter Shared Utility | Extract balance logic (atau static method) |
| 7 | Flutter Form Page | Update wallet matching + multi-item voice prefill |
| 8 | Testing | Manual test voice, text, OCR — khususnya multi-item text |

**Total: 12 file** (1 edge function + 11 Flutter files, termasuk 1 file baru shared utility)
