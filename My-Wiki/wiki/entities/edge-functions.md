---
title: "Edge Functions"
type: entity
tags: [edge-functions, supabase, backend, deno, typescript, ai, api]
sources: [raw/docs/prd/20_EXTERNAL_API.md, raw/docs/03_COPILOT_RULES.md, raw/docs/prd/17_VOICE_INPUT.md, raw/docs/prd/18_OCR_RECEIPT.md, raw/docs/prd/15_INVESTASI.md]
created: 2026-04-10
updated: 2026-04-10
---

## Deskripsi

Edge Functions SakuRapi adalah server-side functions yang berjalan di atas **Deno + TypeScript** (bukan Node.js), di-host oleh Supabase. Bertugas sebagai middleware antara Flutter app dan external APIs (Gemini, Indodax, harga-emas.org) untuk menjaga API keys aman di server-side.

## Edge Functions yang Ada

| Nama | Tujuan | External API |
|------|--------|-------------|
| `ai-parse` | Parsing voice/text/OCR ke struktur transaksi + quota check | Gemini AI (1.5 Flash text, 2.5 Flash OCR) |
| `gold-price` | Harga emas Antam terkini | harga-emas.org → Gemini (parsing) |
| `bitcoin-price` | Harga Bitcoin/IDR terkini | Indodax API → CoinGecko |

Lokasi: `supabase/functions/`

## Aturan Wajib

### Environment Variables

```typescript
// ✅ BENAR — Deno style
Deno.env.get('GEMINI_API_KEY')

// ❌ SALAH — Node.js style
process.env.GEMINI_API_KEY
```

### API Key Security

- Flutter **TIDAK** boleh memanggil Gemini/AI API langsung
- Semua AI call melalui Edge Function `ai-parse`
- Edge Function hanya pakai Gemini (Groq/OpenRouter sudah dihapus)
- CoinGecko dipanggil langsung dari Flutter (tidak ada API key, di-cache Hive 12 jam)

## Detail: `ai-parse`

**Request dari Flutter:**
```json
{
  "mode": "text" | "voice" | "ocr",
  "content": "<teks>" | "<base64_image>",
  "dictionary": [...],
  "user_id": "<uuid>"
}
```

**Response ke Flutter (success):**
```json
{
  "data": {
    "type": "expense|income|transfer|hutang|piutang|...",
    "amount": 50000,
    "category_id": "<uuid>",
    "description": "Makan siang",
    "wallet_id": "<uuid>",
    "date": "2024-01-15T12:00:00Z"
  },
  "quota": { "used": 1, "limit": 5, "remaining": 4 }
}
```

**Quota & Error handling:**
- Cek kuota sebelum AI call (via `check_ai_quota` RPC)
- Jika kuota habis → HTTP 429 `DAILY_QUOTA_EXCEEDED`
- Jika AI gagal → error code: `AI_TIMEOUT`, `AI_RATE_LIMIT`, `AI_AUTH_ERROR`, `AI_ERROR`
- Catat usage setelah AI berhasil (via `log_ai_usage` RPC)

**Model yang dipakai:**
- Text/Voice: `gemini-1.5-flash` (timeout 10s)
- OCR: `gemini-2.5-flash` (timeout 20s)

**Dipanggil oleh:** Voice Input, Text Input, OCR Receipt

## Detail: `gold-price`

- Dipanggil oleh Flutter saat refresh harga emas
- Mengambil harga emas Antam dari harga-emas.org
- Mem-parse HTML/data menggunakan Gemini
- Cache hasil 1 hari di `gold_prices` table
- Juga dipicu oleh **cron job** (pg_cron) — berjalan terjadwal di server

## Detail: `bitcoin-price`

- Dipanggil oleh Flutter saat refresh harga Bitcoin
- Mengambil dari Indodax API (primary) → CoinGecko (fallback)
- Cache hasil di `bitcoin_prices` table
- Juga dipicu oleh **cron job** (pg_cron)

## Arsitektur Integrasi

```
Flutter App
  ├── Google Sign-In → Supabase Auth → Google OAuth
  ├── CoinGecko (langsung, cache Hive 12j)
  └── Supabase Client
        ├── Edge Function: ai-parse → Gemini (+ quota RPC)
        ├── Edge Function: gold-price → harga-emas.org
        └── Edge Function: bitcoin-price → Indodax/CoinGecko
```

## Halaman Terkait

- `[[wiki/entities/voice-input|Voice Input]]`
- `[[wiki/entities/text-input|Text Input]]`
- `[[wiki/entities/ocr-receipt|OCR Receipt]]`
- `[[wiki/entities/investasi|Investasi]]`
- `[[wiki/concepts/ai-pipeline|AI Pipeline]]`
- `[[wiki/concepts/arsitektur-app|Arsitektur App]]`
- `[[wiki/sources/copilot-rules|Copilot Rules (Sumber)]]`
