---
title: "Refactor Gold Price: Vertex Gemini-Only"
type: analysis
tags: [analysis, gold-price, edge-function, vertex-ai, gemini]
created: 2026-04-12
updated: 2026-04-12
---

## Ringkasan

Edge function `gold-price` direfactor agar hanya memakai **Vertex AI Gemini 2.5 Flash** sebagai fallback AI.

Provider yang dihapus:

- Groq
- OpenRouter

## Perubahan Teknis

### 1. Auth AI diseragamkan

`gold-price` sekarang mengikuti pola auth yang sama dengan `ai-parse`:

- `GCP_SERVICE_ACCOUNT_JSON`
- `GCP_LOCATION`

`project_id`, `client_email`, dan `private_key` dibaca langsung dari JSON service account.

### 2. Fallback chain disederhanakan

#### Antaremas
1. WordPress API / HTML parsing
2. Vertex AI Gemini 2.5 Flash + Google Search grounding
3. Vertex AI Gemini 2.5 Flash plain prompt

#### LogamMulia
1. HTML parsing dari `harga-emas.org`
2. Vertex AI Gemini 2.5 Flash + Google Search grounding
3. Vertex AI Gemini 2.5 Flash plain prompt

### 3. Scrape-first tetap dipertahankan

AI tidak dijadikan jalur utama.

Jalur utama tetap:

1. fetch data mentah dari source
2. parse regex / HTML
3. baru fallback ke AI jika source parsing gagal

Ini menjaga cost, stabilitas, dan determinisme untuk job terjadwal.

## Hasil Validasi

Invoke `gold-price?debug=1` berhasil setelah deploy:

- `antaremas` → sukses via fallback AI
- `logammulia` → sukses via HTML parsing

Contoh hasil:

- `antaremas`: buy `2727000`, sell `3163000`
- `logammulia`: buy `2709000`, sell `3010000`

Debug log juga menunjukkan:

- source Antaremas scrape kena `403`
- function otomatis jatuh ke Vertex AI fallback
- validation harga tetap lolos (`sell > buy`, range valid)

## Dampak

- konfigurasi AI backend lebih konsisten
- surface area error lebih kecil
- lebih mudah debug karena hanya ada satu provider AI
- wiki sekarang sinkron dengan implementasi terbaru
