# 18. OCR Receipt — Detail Teknis

[← Voice & Text Input](17_VOICE_INPUT.md) · [Index](00_INDEX.md) · [Parsing Dictionary →](19_PARSING_DICTIONARY.md)

---

## 18.1. Request ke Edge Function

```json
{
  "mode": "ocr",
  "image": "<base64-encoded-jpeg>",
  "mimeType": "image/jpeg",
  "categories": [
    { "id": "uuid", "name": "Kebutuhan Harian" }
  ]
}
```

## 18.2. Response dari Edge Function

```json
{
  "success": true,
  "mode": "ocr",
  "provider": "gemini",
  "data": {
    "isTransaction": true,
    "type": "expense",
    "merchantName": "Indomaret",
    "date": "2026-03-29",
    "grandTotal": 45000,
    "categoryId": null,
    "categoryKeyword": null,
    "suggestedWallet": null,
    "destinationWallet": null,
    "withPerson": null,
    "note": null,
    "items": [
      {
        "name": "Kopi Kenangan Mantan",
        "qty": 2,
        "unitPrice": 15000,
        "subtotal": 30000,
        "categoryId": "uuid-kategori"
      },
      {
        "name": "Roti Sobek Coklat",
        "qty": 1,
        "unitPrice": 15000,
        "subtotal": 15000,
        "categoryId": "uuid-kategori"
      }
    ]
  }
}
```

## 18.3. OCR Error States

| Error Code | Arti | Aksi UI |
|---|---|---|
| `NO_TEXT` | ML Kit tidak menemukan teks | Pesan + rescan |
| `NOT_TRANSACTION` | `isTransaction = false` | Pesan: "bukan struk/nota" |
| `PARSE_FAILED` | Tidak ada data berguna | Pesan + rescan |

## 18.4. Local OCR Parser Patterns

| Target | Teknik |
|---|---|
| Grand total | Cari "GRAND TOTAL" dari bawah, fallback "TOTAL" (skip SUBTOTAL) |
| Items | Extract nama + harga, detect qty ("2x", "2 x"), unit price ("@15.000") |
| Skip lines | TOTAL, SUBTOTAL, TUNAI, CASH, KEMBALIAN, CHANGE, DISKON, TAX, PPN |
| Amount format | "15.000" → 15000 (dot=thousands), strip "Rp" |
| Date | dd/MM/yyyy, dd-MM-yyyy, dd.MM.yyyy |
| Merchant | 3 baris pertama non-numerik, skip "STRUK"/"RECEIPT"/"NOTA" |

### Flowchart: OCR Image Processing Pipeline

```mermaid
flowchart TD
    A([User pilih sumber]) --> B{Camera atau\nGallery?}

    B -->|Camera| C["Capture foto"]
    B -->|Gallery| D["Pick gambar"]

    C --> E["Crop image\n(croppy)"]
    D --> E
    E --> F["Compress ≤ 500KB\n(JPEG quality)"]
    F --> G["Base64 encode"]
    G --> H["Kirim ke Edge Function\nai-parse mode='ocr'"]

    H --> I{Vision AI\nberhasil?}
    I -->|Gemini OK| J["Parse structured JSON"]
    I -->|Gemini fail| K{Groq\nberhasil?}
    K -->|Ya| J
    K -->|Tidak / AI_BUSY| L["ML Kit on-device OCR"]
    L --> M["OcrLocalParser\n(regex extraction)"]
    M --> J

    J --> N{isTransaction &\nhasUsableData?}
    N -->|Ya| O["Prefill form +\nset attachment"]
    N -->|Tidak| P["Error:\nNO_TEXT / NOT_TRANSACTION\n/ PARSE_FAILED"]

    style O fill:#2d6a4f,color:#fff
    style P fill:#d32f2f,color:#fff
```

### Flowchart: Auto-Balance Items Logic

```mermaid
flowchart TD
    A([Items parsed\ndari OCR]) --> B["Hitung:\nitemsSum = SUM(item.subtotal)"]
    B --> C{itemsSum =\ngrandTotal?}

    C -->|✅ Match| D["Langsung prefill\nke form"]

    C -->|❌ Diff > 0| E["grandTotal > itemsSum\nAda item tidak terbaca"]
    E --> F["Tambah:\n'Item lainnya'\namount = diff"]

    C -->|❌ Diff < 0| G["itemsSum > grandTotal\nAda diskon/potongan"]
    G --> H["Tambah:\n'Diskon/potongan'\namount = -|diff|"]

    F --> I["Prefill ke form\nUser bisa edit"]
    H --> I
    D --> I

    style I fill:#2d6a4f,color:#fff
```

### Flowchart: Local OCR Parser

```mermaid
flowchart TD
    A([OcrLocalParser]) --> B["Input: raw text\ndari ML Kit"]
    B --> C["Step 1: Extract merchant\n(3 baris pertama non-numerik\nskip STRUK/RECEIPT/NOTA)"]
    C --> D["Step 2: Extract grand total\n(cari GRAND TOTAL dari bawah\nfallback TOTAL, skip SUBTOTAL)"]
    D --> E["Step 3: Extract items\n(nama + harga per baris\ndetect qty: 2x, @15.000)"]
    E --> F["Step 4: Extract date\n(dd/MM/yyyy, dd-MM-yyyy)"]
    F --> G["Step 5: Skip noise lines\n(TUNAI, CASH, KEMBALIAN,\nCHANGE, DISKON, TAX, PPN)"]
    G --> H["Return parsed result"]

    style H fill:#2d6a4f,color:#fff
```

---

[← Voice & Text Input](17_VOICE_INPUT.md) · [Index](00_INDEX.md) · [Parsing Dictionary →](19_PARSING_DICTIONARY.md)
