---
title: "Plan: Fix AI Parse Gemini Model 404"
type: source
tags: [ai-parse, edge-function, gemini, vertex-ai, bug-fix]
sources: [raw/docs/plan-fix-ai-parse-gemini-model-404.md]
created: 2026-04-19
updated: 2026-04-19
---

# Plan: Fix AI Parse Gemini Model 404

**Status:** Superseded — diselesaikan oleh refactor AI Parse (Gemini-Only)
**Tanggal:** 2026-04-12
**Sumber:** `raw/docs/plan-fix-ai-parse-gemini-model-404.md`

## Masalah

Edge function `ai-parse` memanggil `v1beta/models/gemini-1.5-flash:generateContent` → Google merespons `404 model not found`.

Akibat:
- Semua parse mode `text` gagal
- `voice` berisiko ikut gagal (pipeline text parse setelah STT)
- Flutter menerima `FunctionException(status: 503, error: AI_ERROR)`

**Root Cause:** `gemini-1.5-flash` tidak lagi tersedia di endpoint yang dipakai.

## Keputusan (Locked)

| Mode | Model Baru |
|------|-----------|
| Text / Voice | `gemini-2.5-flash-lite` |
| OCR / Struk | `gemini-2.5-flash` |

### Auth Direction (Locked)

Pindah ke **Vertex AI di GCP dengan project-based service auth**:
- Tidak lagi memakai `GEMINI_API_KEY`
- Env yang dibutuhkan: `GCP_LOCATION`, `GCP_SERVICE_ACCOUNT_JSON`
- URL dan header request mengikuti format Vertex AI (bukan Gemini Developer API)

## Implementation Plan

1. Ganti model constant text: `gemini-1.5-flash` → `gemini-2.5-flash-lite`
2. OCR tetap pakai `gemini-2.5-flash`
3. Sentralisasi nama model (`TEXT_MODEL`, `VISION_MODEL` constants)
4. Refactor env config ke Vertex AI auth pattern
5. Pertahankan prompt, JSON schema, dan error contract

## Catatan

Plan ini kemudian di-merge ke dalam [[wiki/sources/plan-refactor-ai-parse|Plan: Refactor AI Parse (Gemini Only)]] yang lebih komprehensif, termasuk rate limiting dan perbaikan kualitas catatan.

## Halaman Terkait

- [[wiki/sources/plan-refactor-ai-parse|Plan: Refactor AI Parse (Gemini Only)]]
- [[wiki/analysis/refactor-ai-parse-gemini-quota|Analisis: Refactor AI Parse Gemini-Only + Quota]]
- [[wiki/entities/edge-functions|Edge Functions]]
