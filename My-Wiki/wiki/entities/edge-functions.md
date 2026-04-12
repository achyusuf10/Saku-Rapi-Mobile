---
title: "Edge Functions"
type: entity
tags: [edge-functions, supabase, backend, deno, typescript, ai, api]
sources: [raw/docs/prd/20_EXTERNAL_API.md, raw/docs/03_COPILOT_RULES.md, raw/docs/prd/17_VOICE_INPUT.md, raw/docs/prd/18_OCR_RECEIPT.md, raw/docs/prd/15_INVESTASI.md]
created: 2026-04-10
updated: 2026-04-12
---

## Deskripsi

Edge Functions SakuRapi adalah server-side functions yang berjalan di atas **Deno + TypeScript** (bukan Node.js), di-host oleh Supabase. Bertugas sebagai middleware antara Flutter app dan external APIs (Vertex AI Gemini, Indodax, harga-emas.org) untuk menjaga kredensial tetap aman di server-side.

## Edge Functions yang Ada

| Nama | Tujuan | External API |
|------|--------|-------------|
| `ai-parse` | Parsing voice/text/OCR ke struktur transaksi + quota check | Vertex AI Gemini (2.5 Flash Lite text/voice, 2.5 Flash OCR) |
| `gold-price` | Harga emas Antam terkini | harga-emas.org / antaremas.com → Vertex AI Gemini 2.5 Flash |
| `bitcoin-price` | Harga Bitcoin/IDR terkini | Indodax API → CoinGecko |

Lokasi: `supabase/functions/`

## Aturan Wajib

### Environment Variables

```typescript
// ✅ BENAR — Deno style
Deno.env.get('GCP_SERVICE_ACCOUNT_JSON')

// ❌ SALAH — Node.js style
process.env.GCP_SERVICE_ACCOUNT_JSON
```

### API Key Security

- Flutter **TIDAK** boleh memanggil Vertex AI / Gemini API langsung
- Semua AI call melalui Edge Function `ai-parse`
- Edge Function hanya pakai Vertex AI Gemini (Groq/OpenRouter sudah dihapus)
- CoinGecko dipanggil langsung dari Flutter (tidak ada API key, di-cache Hive 12 jam)

## Detail: `ai-parse`

**Request dari Flutter:**
```json
{
  "mode": "text" | "voice" | "ocr",
  "text": "<teks>",
  "image": "<base64_image>",
  "mimeType": "image/jpeg",
  "categories": [
    { "id": "<uuid>", "name": "Makan", "type": "expense" }
  ],
  "localDate": "2026-04-12"
}
```

**Response ke Flutter (success):**
```json
{
  "success": true,
  "mode": "text",
  "provider": "gemini-2.5-flash-lite",
  "data": {
    "type": "expense|income|transfer|debt|loan",
    "amount": 50000,
    "categoryId": "<uuid>",
    "note": "Makan siang",
    "suggestedWallet": "GoPay",
    "date": "2026-04-12"
  },
  "quota": { "used": 1, "limit": 5, "remaining": 4 }
}
```

**Quota & Error handling:**
- Cek kuota sebelum AI call (via `check_ai_quota` RPC)
- Jika kuota habis → HTTP 429 `DAILY_QUOTA_EXCEEDED`
- Jika AI gagal → error code: `AI_TIMEOUT`, `AI_RATE_LIMIT`, `AI_AUTH_ERROR`, `AI_CONFIG_ERROR`, `AI_ERROR`
- Catat usage setelah AI berhasil (via `log_ai_usage` RPC)
- `localDate` dari Flutter dipakai untuk relative-date prompt (`hari ini`, `kemarin`) dan untuk menghitung kuota harian via `ai_usage_logs.usage_date`

**Model yang dipakai:**
- Text/Voice: `gemini-2.5-flash-lite` (timeout 10s)
- OCR: `gemini-2.5-flash` (timeout 20s)

**Auth yang dipakai:**
- `ai-parse` tidak lagi memakai `GEMINI_API_KEY`
- Menggunakan Vertex AI service-based auth via env:
  - `GCP_LOCATION`
  - `GCP_SERVICE_ACCOUNT_JSON`
- `project_id`, `client_email`, dan `private_key` dibaca langsung dari JSON service account

**Dipanggil oleh:** Voice Input, Text Input, OCR Receipt

## Detail: `gold-price`

- Dipanggil oleh Flutter saat refresh harga emas
- Mengambil harga emas Antam dari `antaremas.com` dan `harga-emas.org`
- Prioritas utama: scrape / parse source langsung
- Fallback AI: **Vertex AI Gemini 2.5 Flash** saja
- Groq dan OpenRouter sudah dihapus dari fallback chain
- Cache hasil 1 hari di `gold_prices` table
- `fetched_at` tetap disimpan sebagai timestamp UTC; UI Flutter menampilkannya dalam local device user
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
        ├── Edge Function: ai-parse → Vertex AI Gemini (+ quota RPC)
        ├── Edge Function: gold-price → antaremas.com / harga-emas.org → Vertex AI Gemini
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
