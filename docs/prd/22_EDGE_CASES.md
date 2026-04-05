# 22. Edge Cases & Error Handling

[← Kategori Default](21_KATEGORI_DEFAULT.md) · [Index](00_INDEX.md) · [Permissions →](23_PERMISSIONS.md)

---

## 22.1. Voice/Text/OCR

| Skenario | Penanganan |
|---|---|
| Permission mic/kamera ditolak | Explainer + CTA buka settings |
| Permission ditolak permanen | `isPermanentlyDenied` → tombol "Buka Settings" |
| Gemini timeout | Failover ke Groq |
| Groq timeout / AI_BUSY | Fallback lokal parser |
| `isTransaction = false` | Error "bukan transaksi", jangan prefill |
| `hasUsableData = false` | Error `PARSE_FAILED` |
| JSON invalid | Tampilkan raw parse preview, jangan auto-save |
| Wallet/kategori AI tidak ditemukan | Form terbuka dengan field kosong parsial |
| OCR items_sum ≠ grandTotal | Auto-balance dengan item tambahan |
| Voice: tidak ada suara | `no_speech` error |

### Flowchart: Voice/Text/OCR Error Handling

```mermaid
flowchart TD
    A([Voice/Text/OCR\nrequest]) --> B{Permission\ngranted?\n(voice/OCR only)}
    B -->|Tidak| C{Permanently\ndenied?}
    C -->|Ya| D["Tombol:\n'Buka Settings'"]
    C -->|Tidak| E["Request\npermission"]

    B -->|Ya| F{AI berhasil?}
    F -->|Gemini OK| G["Parse result"]
    F -->|Gemini fail| H{Groq OK?}
    H -->|Ya| G
    H -->|Tidak| I["Local parser\nfallback"]
    I --> G

    G --> J{isTransaction?}
    J -->|Ya| K{hasUsableData?}
    K -->|Ya| L["Prefill form ✅"]
    K -->|Tidak| M["PARSE_FAILED"]
    J -->|Tidak| N["'Bukan transaksi'"]

    style L fill:#2d6a4f,color:#fff
    style M fill:#d32f2f,color:#fff
    style N fill:#d32f2f,color:#fff
    style D fill:#ff8f00,color:#000
```

## 22.2. Transaksi

| Skenario | Penanganan |
|---|---|
| Double tap submit | Request kedua diabaikan (flag `saving`) |
| Transfer ke wallet sama | Diblok |
| Total item ≠ total transaksi | Blok simpan |
| Delete wallet yang punya transaksi | Diblok |
| Settlement > outstanding | Diblok |

### Flowchart: Transaction Validation Guards

```mermaid
flowchart TD
    A([Submit\ntransaksi]) --> B{Flag saving\n= true?}
    B -->|Ya| C["🚫 Ignore\n(anti double-submit)"]
    B -->|Tidak| D["Set saving = true"]
    D --> E{Tipe?}

    E -->|Transfer| F{wallet_id =\ndestination?}
    F -->|Ya| G["🚫 Diblok:\nwallet sama"]

    E -->|Expense/Income\n+ items| H{SUM(items) =\ntotal_amount?}
    H -->|Tidak| I["🚫 Diblok:\nmismatch"]

    E -->|Settlement| J{amount >\noutstanding?}
    J -->|Ya| K["🚫 Diblok:\nmelebihi sisa"]

    F -->|Tidak| L["✅ Submit RPC"]
    H -->|Ya| L
    J -->|Tidak| L

    L --> M["Set saving = false"]

    style L fill:#2d6a4f,color:#fff
    style C fill:#455a64,color:#fff
    style G fill:#d32f2f,color:#fff
    style I fill:#d32f2f,color:#fff
    style K fill:#d32f2f,color:#fff
```

## 22.3. Notifikasi

| Skenario | Penanganan |
|---|---|
| Permission notifikasi ditolak | Reminder dianggap disabled di UI |
| Android OEM battery restriction | Info di settings jika perlu |

---

[← Kategori Default](21_KATEGORI_DEFAULT.md) · [Index](00_INDEX.md) · [Permissions →](23_PERMISSIONS.md)
