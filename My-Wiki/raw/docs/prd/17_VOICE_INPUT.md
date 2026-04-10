# 17. Voice & Text Input — Detail Teknis

[← Settings](16_SETTINGS.md) · [Index](00_INDEX.md) · [OCR Receipt →](18_OCR_RECEIPT.md)

---

> **Catatan:** Voice input dan text input menggunakan Edge Function yang sama (`ai-parse`, mode `text`).
> Voice flow menambahkan tahap Speech-to-Text (STT) sebelum mengirim teks ke AI.
> Text input mengirim teks langsung ke AI tanpa STT.

## 17.1. Request ke Edge Function

```json
{
  "mode": "text",
  "text": "beli kopi kenangan 20 ribu pakai gopay",
  "categories": [
    { "id": "uuid", "name": "Makanan & Minuman", "type": "expense" }
  ]
}
```

## 17.2. Response dari Edge Function

```json
{
  "success": true,
  "mode": "text",
  "provider": "gemini",
  "data": {
    "isTransaction": true,
    "type": "expense",
    "amount": 20000,
    "categoryId": "uuid-kategori",
    "categoryKeyword": "kopi",
    "note": "Beli kopi kenangan",
    "suggestedWallet": "GoPay",
    "destinationWallet": null,
    "withPerson": null,
    "merchantName": "Kopi Kenangan",
    "date": "2026-03-29"
  }
}
```

## 17.3. Mapping Response → Form

| AI Field | Form Field | Matching Logic |
|---|---|---|
| `type` | Tab selection | Direct enum match |
| `amount` | `totalAmount` + single item | Direct |
| `suggestedWallet` | `wallet` | Case-insensitive name match |
| `destinationWallet` | `destinationWallet` | Case-insensitive name match |
| `categoryId` | Item category | Direct UUID |
| `categoryKeyword` | Item category | Fallback: dictionary lookup |
| `merchantName` | `merchantName` | Direct |
| `note` | `note` | Direct |
| `date` | `date` | Parse yyyy-MM-dd |
| `withPerson` | `withPerson` | Direct (debt/loan) |

## 17.4. Voice Input Flow

### Flowchart: Voice Processing Pipeline

```mermaid
flowchart TD
    A([User tap 🎤]) --> B["Record suara\n(max 10 detik)"]
    B --> C["speech_to_text\nlocale: id_ID"]
    C --> D{Transcript\nada?}

    D -->|Tidak / no_speech| E["⚠️ Error:\nTidak ada suara"]
    D -->|Ya| F["Kirim ke Edge Function\nai-parse mode='text'"]

    F --> G{Gemini\nberhasil?}
    G -->|Ya| H["Return JSON\nprovider: gemini"]
    G -->|Tidak| I{Groq\nberhasil?}
    I -->|Ya| J["Return JSON\nprovider: groq"]
    I -->|Tidak| K["VoiceLocalParser\n(regex + dictionary)"]

    H --> L{isTransaction?}
    J --> L
    K --> L

    L -->|Ya| M["Prefill form:\ntype, amount, wallet,\ncategory, merchant, date"]
    L -->|Tidak| N["⚠️ Error:\n'Bukan transaksi'"]

    style M fill:#2d6a4f,color:#fff
    style E fill:#d32f2f,color:#fff
    style N fill:#d32f2f,color:#fff
```

**Pipeline:**
1. STT lokal (`speech_to_text`, locale `id_ID`) → teks
2. Edge Function `ai-parse` mode `text` → Gemini
3. Failover ke Groq
4. Fallback lokal: regex amount + keyword type + dictionary category

## 17.5. Text Input Flow

### Flowchart: Text Input Pipeline

```mermaid
flowchart TD
    A([User tap ⌨️]) --> B["Tampilkan TextInputSheet\n(text field + submit)"]
    B --> C["User ketik teks\ntransaksi"]
    C --> D["Submit teks"]
    D --> E["Kirim ke Edge Function\nai-parse mode='text'"]

    E --> F{Gemini\nberhasil?}
    F -->|Ya| G["Return JSON\nprovider: gemini"]
    F -->|Tidak| H{Groq\nberhasil?}
    H -->|Ya| I["Return JSON\nprovider: groq"]
    H -->|Tidak| J["VoiceLocalParser\n(regex + dictionary)"]

    G --> K{isTransaction?}
    I --> K
    J --> K

    K -->|Ya| L["Set pendingVoicePrefill"]
    L --> M["Navigate ke\nTransaction Form"]
    M --> N["Prefill form:\ntype, amount, wallet,\ncategory, merchant, date"]
    K -->|Tidak| O["⚠️ Error:\n'Bukan transaksi'"]

    style N fill:#2d6a4f,color:#fff
    style O fill:#d32f2f,color:#fff
```

**Pipeline:**
1. User ketik teks langsung (tidak perlu mic permission / STT)
2. Edge Function `ai-parse` mode `text` → Gemini
3. Failover ke Groq
4. Fallback lokal: regex amount + keyword type + dictionary category

> **Perbedaan dengan Voice Input:**
> - Tidak ada STT → langsung kirim teks ke AI
> - Tidak perlu mic permission
> - Tidak ada countdown timer
> - Menggunakan `TextInputController` (lebih sederhana dari `VoiceInputController`)
> - Hasil tetap masuk ke `pendingVoicePrefillProvider` (shared dengan voice)

## 17.6. Local Fallback Parser Patterns

| Pola | Contoh | Hasil |
|---|---|---|
| Amount | `"1.5jt"` | 1.500.000 |
| Amount | `"25rb"` | 25.000 |
| Amount | `"150.000"` | 150.000 |
| Type keyword | `"transfer/kirim uang"` | transfer |
| Type keyword | `"hutang/ngutang"` | debt |
| Type keyword | `"piutang/kasih pinjam"` | loan |
| Type keyword | `"gaji/terima uang"` | income |
| Type keyword | (default) | expense |
| Date | `"kemarin"` | -1 hari |
| Date | `"tadi/hari ini"` | today |
| Date | `"X hari lalu"` | dynamic |

### Flowchart: Local Parser Fallback Logic

```mermaid
flowchart TD
    A([VoiceLocalParser]) --> B["Input: raw text"]
    B --> C["Step 1: Extract amount\n(regex: jt/rb/ribu/juta/k)"]
    C --> D["Step 2: Detect type\n(keyword matching)"]
    D --> E["Step 3: Match category\n(parsing_dictionaries cache)"]
    E --> F["Step 4: Parse date\n(kemarin/hari ini/X hari lalu)"]
    F --> G["Step 5: Extract wallet name\n(keyword: pakai/dari/ke)"]
    G --> H["Return parsed result\n(partial data OK)"]

    style H fill:#2d6a4f,color:#fff
```

---

[← Settings](16_SETTINGS.md) · [Index](00_INDEX.md) · [OCR Receipt →](18_OCR_RECEIPT.md)
