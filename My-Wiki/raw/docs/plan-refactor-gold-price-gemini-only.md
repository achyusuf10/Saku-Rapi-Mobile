# Plan: Refactor Gold Price to Gemini Only

> Status: Draft for review
> Tanggal: 2026-04-12
> Scope: `supabase/functions/gold-price/index.ts` + wiki docs

---

## Problem

Edge function `gold-price` saat ini masih memakai fallback chain yang panjang:

- Gemini
- Groq
- OpenRouter

Ini bikin logic lebih rumit, harder to debug, dan tidak konsisten dengan arah backend AI yang mulai disederhanakan.

User ingin:

1. `gold-price` **pakai Gemini saja**
2. Model yang dipakai **Gemini 2.5 Flash**

---

## Current State Analysis

Flow sekarang:

1. Ambil harga dari **Antaremas** lewat WordPress API / HTML scraping
2. Jika parsing gagal, fallback ke **Gemini with Google Search grounding**
3. Jika masih gagal, fallback lagi ke chain **Gemini → Groq → OpenRouter**
4. Ulang pola serupa untuk **LogamMulia / harga-emas.org**
5. Jika dapat hasil valid, insert ke `gold_prices`

Masalah utama di code saat ini:

- masih ada `GROQ_API_KEY`
- masih ada `OPENROUTER_API_KEY`
- masih ada helper `callGroq()` dan `callOpenRouter()`
- fallback chain terlalu banyak
- source of truth wiki belum eksplisit bilang `gold-price` sudah/akan Gemini-only

---

## Proposed Direction

### A. Simplify to Gemini-only

Pertahankan urutan besar flow, tapi sederhanakan fallback:

#### Antaremas
1. WordPress API / HTML parsing
2. Gemini 2.5 Flash + Google Search grounding
3. Gemini 2.5 Flash plain prompt
4. Jika tetap gagal → return null

#### LogamMulia
1. harga-emas.org / HTML parsing
2. Gemini 2.5 Flash + Google Search grounding
3. Gemini 2.5 Flash plain prompt
4. Jika tetap gagal → return null

Jadi yang dihapus:

- `callGroq()`
- `callOpenRouter()`
- `GROQ_API_KEY`
- `OPENROUTER_API_KEY`
- loop fallback `for (const caller of [callGemini, callGroq, callOpenRouter])`

### B. Keep validation strict

Validasi yang sekarang sudah bagus dan perlu dipertahankan:

- harga harus di range wajar
- `sell > buy`
- output AI harus bisa di-parse jadi JSON `{ buy, sell }`

### C. Keep source scraping first

Gemini jangan dijadikan first path.

Tetap prioritaskan:

1. structured source / scrape
2. baru Gemini sebagai fallback

Ini lebih hemat, lebih stabil, dan lebih cocok untuk job terjadwal seperti `gold-price`.

---

## Implementation Plan

### Phase 1 — Remove non-Gemini providers

1. Hapus constants:
   - `GROQ_API_KEY`
   - `OPENROUTER_API_KEY`
2. Hapus helper:
   - `callGroq()`
   - `callOpenRouter()`
3. Hapus semua fallback chain yang memanggil provider selain Gemini

### Phase 2 — Standardize Gemini calls

1. Pakai **Gemini 2.5 Flash** untuk semua fallback AI di `gold-price`
2. Rapikan helper Gemini supaya:
   - plain prompt path tetap ada
   - Google Search grounding path tetap ada
3. Pertahankan timeout dan parsing JSON result

### Phase 3 — Verify per source

Pastikan dua sumber tetap aman:

1. `fetchAntaremas()`
2. `fetchLogamMulia()`

Yang diverifikasi:

- scrape path masih jalan
- Gemini fallback tetap bisa dipakai
- hasil validasi tidak meloloskan harga yang salah

### Phase 4 — Update docs/wiki

Update dokumentasi terkait:

1. `My-Wiki/wiki/entities/edge-functions.md`
2. Jika perlu, halaman raw/plan terkait AI provider simplification

---

## Files Likely Affected

- `supabase/functions/gold-price/index.ts`
- `My-Wiki/wiki/entities/edge-functions.md`

---

## Testing Plan

### Supabase side

1. Invoke `gold-price?debug=1`
2. Pastikan response tetap menampilkan hasil dari:
   - `antaremas`
   - `logammulia`
3. Pastikan tidak ada referensi Groq/OpenRouter lagi
4. Pastikan hasil insert ke `gold_prices` tetap benar saat debug off

### Validation focus

1. `buy` dan `sell` harus integer
2. `sell` harus lebih tinggi dari `buy`
3. Harga harus tetap masuk range valid
4. Jika source gagal total, function tetap return status yang jelas

---

## Open Decision

Ada satu keputusan implementasi yang masih perlu dikunci:

**Auth Gemini untuk `gold-price` mau tetap pakai `GEMINI_API_KEY`, atau ikut diseragamkan ke Vertex AI service auth seperti `ai-parse`?**

Secara fitur, keduanya bisa sama-sama memenuhi requirement “Gemini only”.
Bedanya ada di konfigurasi env dan URL request yang dipakai.

Kalau goal kamu cuma menyederhanakan provider dulu, opsi paling kecil risikonya adalah:

- tetap Gemini-only
- model `gemini-2.5-flash`
- auth tidak diubah dulu

Kalau goal kamu juga ingin konsisten backend AI, maka `gold-price` lebih bagus ikut Vertex AI.
Pakai ENV GCP_SERVICE_ACCOUNT_JSON, dan GCP_LOCATION
