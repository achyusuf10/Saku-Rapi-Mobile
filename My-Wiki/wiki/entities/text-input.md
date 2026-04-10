---
title: "Text Input"
type: entity
tags: [text-input, ai-parse, gemini, groq, edge-function]
sources: [raw/docs/prd/17_VOICE_INPUT.md, raw/docs/prd/19_PARSING_DICTIONARY.md]
created: 2026-04-10
updated: 2026-04-10
---

# Text Input

## Deskripsi

Fitur text input adalah alternatif dari [[wiki/entities/voice-input|Voice Input]] yang memungkinkan pengguna mengetik deskripsi transaksi dalam bahasa natural. Teks langsung dikirim ke AI untuk diparsing — **tanpa step Speech-to-Text (STT)**. Tidak memerlukan izin mikrofon.

---

## Fitur & Aturan Utama

- **Tidak memerlukan mic permission** — murni input teks
- Menggunakan **`TextInputSheet`** dengan text field dan submit button
- Controller: **`TextInputController`** — lebih sederhana dari `VoiceInputController` karena tidak mengelola state rekaman audio
- Hasil parsing di-share melalui **`pendingVoicePrefillProvider`** (shared dengan [[wiki/entities/voice-input|Voice Input]])

---

## Cara Kerja

### Pipeline

```
User ketik teks → Edge Function ai-parse mode='text'
    → Gemini (primary)
    → Groq (failover)
    → VoiceLocalParser (regex + dictionary, fallback terakhir)
```

Pipeline identik dengan Voice Input kecuali tidak ada step rekam suara dan STT. Edge Function `ai-parse` dipanggil dengan `mode='text'` yang sama.

### Komponen UI

- **TextInputSheet** — Bottom sheet sederhana berisi:
  - Text field untuk mengetik deskripsi transaksi
  - Submit button untuk mengirim ke AI parsing
  - Loading state saat menunggu response

### Shared Provider

`pendingVoicePrefillProvider` digunakan bersama oleh Voice Input dan Text Input. Provider ini menyimpan hasil parsing AI yang akan di-consume oleh form transaksi untuk prefill field-field yang berhasil diparsing.

---

## Halaman Terkait

- [[wiki/entities/voice-input|Voice Input]]
- [[wiki/entities/ocr-receipt|OCR Receipt]]
- [[wiki/concepts/aturan-keuangan|Aturan Keuangan]]
- [[wiki/sources/prd-sakurapi-v7|PRD SakuRapi v7.0]]
