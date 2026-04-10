---
title: "Voice Input"
type: entity
tags: [voice-input, stt, ai-parse, gemini, groq, edge-function]
sources: [raw/docs/prd/17_VOICE_INPUT.md, raw/docs/prd/19_PARSING_DICTIONARY.md]
created: 2026-04-10
updated: 2026-04-10
---

# Voice Input

## Deskripsi

Fitur voice input memungkinkan pengguna mencatat transaksi dengan suara. Suara direkam, diubah menjadi teks secara lokal, lalu dikirim ke AI untuk diparsing menjadi field-field transaksi. Terdapat mekanisme failover berlapis: Gemini → Groq → local parser.

---

## Fitur & Aturan Utama

- Rekaman suara **maksimal 10 detik**
- STT dilakukan **secara lokal** menggunakan package `speech_to_text` dengan locale `id_ID`
- Hasil parsing di-share ke form transaksi melalui **`pendingVoicePrefillProvider`** (shared dengan [[wiki/entities/text-input|Text Input]])
- Tidak memerlukan koneksi internet untuk STT (tapi perlu untuk AI parsing)

---

## Cara Kerja

### Pipeline

```
Record (max 10s) → STT lokal (speech_to_text, id_ID)
    → Edge Function ai-parse mode='text'
        → Gemini (primary)
        → Groq (failover)
    → VoiceLocalParser (regex + dictionary, fallback terakhir)
```

### Request JSON

```json
{
  "mode": "text",
  "text": "transfer 50 ribu ke BCA kemarin untuk makan siang",
  "locale": "id_ID"
}
```

### Response JSON

```json
{
  "amount": 50000,
  "type": "transfer",
  "description": "makan siang",
  "walletName": "BCA",
  "date": "2026-04-09",
  "categoryHint": "Makanan"
}
```

### Mapping Response → Form Fields

| Field AI Response | Form Field |
|-------------------|------------|
| `amount` | Jumlah transaksi |
| `type` | Tipe (income/expense/transfer) |
| `description` | Deskripsi/catatan |
| `walletName` | Wallet tujuan/sumber |
| `date` | Tanggal transaksi |
| `categoryHint` | Saran kategori |

### VoiceLocalParser (Fallback Lokal)

Parser regex dan dictionary yang berjalan di device sebagai fallback terakhir. Pola-pola yang didukung:

| Input | Output | Keterangan |
|-------|--------|------------|
| `1.5jt`, `1,5jt` | `1.500.000` | Jutaan |
| `25rb` | `25.000` | Ribuan |
| `transfer`, `kirim` | type: `transfer` | Mapping kata ke tipe |
| `kemarin` | tanggal -1 hari | Relatif date parsing |

---

## Halaman Terkait

- [[wiki/entities/text-input|Text Input]]
- [[wiki/entities/ocr-receipt|OCR Receipt]]
- [[wiki/concepts/aturan-keuangan|Aturan Keuangan]]
- [[wiki/sources/prd-sakurapi-v7|PRD SakuRapi v7.0]]
