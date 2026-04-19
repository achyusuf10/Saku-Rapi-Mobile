---
title: "Plan: Refactor Gold Price ke Gemini Only"
type: source
tags: [gold-price, edge-function, gemini, vertex-ai, refactoring]
sources: [raw/docs/plan-refactor-gold-price-gemini-only.md]
created: 2026-04-19
updated: 2026-04-19
---

# Plan: Refactor Gold Price ke Gemini Only

**Status:** ✅ Implemented (April 2026)
**Tanggal:** 2026-04-12
**Sumber:** `raw/docs/plan-refactor-gold-price-gemini-only.md`

## Masalah

Edge function `gold-price` menggunakan fallback chain panjang: Gemini → Groq → OpenRouter.

Ini menyebabkan:
- Logic kompleks dan sulit di-debug
- Tidak konsisten dengan arah AI backend (Gemini only)
- Provider fallback (Groq, OpenRouter) sering timeout atau tidak stabil

## Keputusan

Sederhanakan `gold-price` agar hanya memakai **Gemini 2.5 Flash via Vertex AI**.

## Flow Baru

### Antaremas
1. WordPress API / HTML parsing (sumber primer)
2. Gemini 2.5 Flash + Google Search grounding (fallback parsing)
3. Gemini 2.5 Flash plain prompt (fallback ke-2)
4. Jika semua gagal → return null

### LogamMulia
1. harga-emas.org / HTML parsing (sumber primer)
2. Gemini 2.5 Flash + Google Search grounding (fallback parsing)
3. Gemini 2.5 Flash plain prompt (fallback ke-2)
4. Jika semua gagal → return null

## Yang Dihapus

- `callGroq()`
- `callOpenRouter()`
- `GROQ_API_KEY`
- `OPENROUTER_API_KEY`
- Loop fallback `for (const caller of [callGemini, callGroq, callOpenRouter])`

## Yang Dipertahankan

- Validasi harga (range wajar, `sell > buy`)
- Output AI harus bisa di-parse ke JSON `{ buy, sell }`
- Scraping sumber pertama (Antaremas + LogamMulia) tetap jadi jalur utama

## Auth

Diseragamkan ke Vertex AI: `GCP_SERVICE_ACCOUNT_JSON`, `GCP_LOCATION` — sama dengan `ai-parse`.

## Halaman Terkait

- [[wiki/analysis/refactor-gold-price-gemini-only|Analisis: Refactor Gold Price Vertex Gemini-Only]]
- [[wiki/entities/edge-functions|Edge Functions]]
- [[wiki/entities/investasi|Investasi]]
