---
title: "Plan: Refactor AI Parse (Gemini Only + Daily Quota)"
type: source
tags: [ai-parse, edge-function, gemini, rate-limiting, quota, ocr, voice-input, text-input]
sources: [raw/docs/plan-refactor-ai-parse.md]
created: 2026-04-19
updated: 2026-04-19
---

# Plan: Refactor AI Parse (Gemini Only + Daily Quota)

**Status:** ✅ Implemented (April 2026)
**Tanggal:** 2026-04-12
**Sumber:** `raw/docs/plan-refactor-ai-parse.md`

## Ringkasan

Refactor edge function `ai-parse` dengan tiga perubahan utama:
1. Hapus Groq + OpenRouter, pakai Gemini only
2. Perbaiki rule field `note` agar berisi deskripsi item (bukan amount/tanggal)
3. Tambah rate limiting (kuota harian) per user dengan dukungan tier

## Perubahan

### A. Simplifikasi AI Provider (Gemini Only)

| Mode | Sebelum | Sesudah |
|------|---------|---------|
| Text | `gemini-2.5-flash` → Groq → OpenRouter | `gemini-2.5-flash-lite` only |
| Voice | Same as text | `gemini-2.5-flash-lite` only |
| OCR | `gemini-2.5-flash-lite` → Groq Vision → OpenRouter Vision | `gemini-2.5-flash` only |

Yang dihapus: `callGroq()`, `callGroqVision()`, `callOpenRouterVision()`, `GROQ_API_KEY`, `OPENROUTER_API_KEY`

### B. Perbaikan Rule `note`

**Rule baru:** `note` harus berisi deskripsi item/jasa (misal "Beli Degan", "Makan siang di Warteg") dan **TIDAK boleh** berisi amount, tanggal, nama wallet, atau nama orang.

Contoh:
- `"Beli Degan 10K"` → `note: "Beli Degan"` (bukan null)
- `"makan 25rb"` → `note: null` (terlalu generic, cukup di categoryKeyword)

### C. Rate Limiting — 3 Mode Kuota

| Mode | Free Limit/Hari |
|------|----------------|
| `text` | 5x |
| `voice` | 5x |
| `ocr` | 3x |

### D. Error Messages Lebih Spesifik

| Kondisi | Error Code |
|---------|-----------|
| Timeout | `AI_TIMEOUT` |
| 429 rate limit | `AI_RATE_LIMIT` |
| 401/403 auth | `AI_AUTH_ERROR` |
| 404 / config invalid | `AI_CONFIG_ERROR` |
| Quota harian habis | `DAILY_QUOTA_EXCEEDED` |
| Lainnya | `AI_ERROR` |

## Database Changes

**Tabel baru:**
- `ai_usage_quotas` — konfigurasi limit per tier+mode
- `ai_usage_logs` — log setiap AI parse yang berhasil

**Kolom baru di `users`:**
- `tier text DEFAULT 'free'`
- `tier_expires_at timestamptz DEFAULT NULL` — auto-downgrade jika expired

**RPC baru:**
- `check_ai_quota(p_mode)` — cek kuota + auto-downgrade jika tier expired
- `log_ai_usage(p_mode, p_provider)` — catat setelah AI berhasil
- Satu RPC combined yang atomic: cek + call AI + log

## Tier System

| Tier | text/hari | voice/hari | ocr/hari |
|------|-----------|-----------|---------|
| free | 5 | 5 | 3 |
| premium | 20 | 20 | 10 |

Admin aktifkan premium via SQL: `UPDATE users SET tier='premium', tier_expires_at=now()+'30 days'`

## Scope File

- `supabase/functions/ai-parse/index.ts` — remove fallbacks, fix note rule, tambah quota check
- Migrations: `ai_usage_quotas`, `ai_usage_logs`, kolom `users.tier`, seed data, RPC functions

## Halaman Terkait

- [[wiki/analysis/refactor-ai-parse-gemini-quota|Analisis: Refactor AI Parse Gemini-Only + Quota]]
- [[wiki/sources/plan-fix-ai-parse-gemini-404|Plan: Fix AI Parse Gemini Model 404]]
- [[wiki/sources/plan-remove-manual-parsing|Plan: Hapus Manual Parsing]]
- [[wiki/entities/edge-functions|Edge Functions]]
- [[wiki/entities/voice-input|Voice Input]]
- [[wiki/entities/ocr-receipt|OCR Receipt]]
