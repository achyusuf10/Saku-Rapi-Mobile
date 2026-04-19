---
title: "Plan: Enhancement AI Parse (Wallet + Category + Multi-Item)"
type: source
tags: [ai-parse, voice-input, ocr, text-input, edge-function, wallet, category]
sources: [raw/plan-ai-parse-enhancement.md]
created: 2026-04-19
updated: 2026-04-19
---

# Plan: Enhancement AI Parse (Wallet + Category + Multi-Item)

**Status:** Draft v3 — In Progress (April 2026)
**Sumber:** `raw/plan-ai-parse-enhancement.md`

## Ringkasan

Enhance edge function `ai-parse` agar AI bisa memilih wallet dan kategori dengan tepat:
- Kirim daftar wallet + kategori dari Flutter ke edge function
- AI memilih berdasarkan short ID mapping (bukan free text)
- Tambah dukungan multi-item untuk text/voice (jika user menyebut harga per item)
- Rename `suggestedWallet` → `suggestedWalletId`

## Masalah Saat Ini

- `suggestedWallet` adalah free text → form matching sering gagal jika nama tidak persis cocok
- AI tidak tahu daftar wallet user → menebak nama → mismatch dengan data aktual
- Text/voice hanya menghasilkan 1 item per parse — tidak bisa handle "beli nasi 15rb + es teh 5rb"

## Perubahan Utama

### A. Wallet Short ID Mapping

Flutter mengirim daftar wallet ke edge function:
```json
{ "wallets": [{"id": "uuid", "name": "Kas"}, {"id": "uuid", "name": "GoPay"}] }
```

Edge function membuat mapping `w1` → `uuid-kas`, `w2` → `uuid-gopay`.

AI merespons dengan short ID: `"suggestedWalletId": "w1"` → Flutter resolve ke UUID aktual.

### B. Kategori — Short ID Mapping (sudah ada, dipertahankan)

Pola identik dengan wallet — sudah ada sejak sebelumnya, tinggal diperkuat.

Default fallback categories di-mark dengan `*` di prompt agar AI tidak asal memilih.

### C. Multi-Item Text/Voice

Jika user menyebut beberapa item dengan harga berbeda, AI menghasilkan array `items[]` daripada satu `amount`. Contoh: "beli nasi goreng 15rb sama es teh 5rb" → 2 items.

### D. Rename Field

`suggestedWallet` (free text) → `suggestedWalletId` (short ID yang resolve ke UUID)

## Scope File

**Flutter:**
- 3 controller (voice, text, ocr) — tambah wallet list dari provider
- 2 repository + 2 datasource — pass wallet list ke request body

**Edge Function:**
- `supabase/functions/ai-parse/index.ts` — `buildWalletMapping()`, update prompt, response mapping

## Halaman Terkait

- [[wiki/entities/voice-input|Voice Input]]
- [[wiki/entities/ocr-receipt|OCR Receipt]]
- [[wiki/entities/text-input|Text Input]]
- [[wiki/entities/edge-functions|Edge Functions]]
- [[wiki/sources/plan-refactor-ai-parse|Plan: Refactor AI Parse (Gemini Only)]]
