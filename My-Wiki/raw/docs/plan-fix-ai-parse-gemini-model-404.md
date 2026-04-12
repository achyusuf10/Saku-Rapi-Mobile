# Plan: Fix AI Parse Gemini Model 404

> Status: Draft for discussion
> Tanggal: 2026-04-12
> Scope: `supabase/functions/ai-parse/index.ts`, Flutter error surface, wiki docs

---

## Problem

AI Parse untuk input text sekarang gagal sebelum parsing berjalan. Error utamanya:

- Edge function memanggil `v1beta/models/gemini-1.5-flash:generateContent`
- Google membalas `404 model not found`
- Akibatnya Flutter menerima `FunctionException(status: 503, error: AI_ERROR)`

Jadi bug ini bukan dari controller Flutter, melainkan dari konfigurasi model di edge function.

---

## Root Cause

Model `gemini-1.5-flash` yang sekarang di-hardcode di `ai-parse` sudah tidak tersedia / tidak valid lagi untuk endpoint `generateContent` yang dipakai.

Implikasinya:

1. Semua parse mode `text` gagal.
2. `voice` berisiko ikut gagal karena pipeline parse-nya tetap lewat text AI setelah STT.
3. Dokumentasi wiki sekarang menyebut model yang sudah tidak valid, jadi source of truth ikut meleset.

---

## Chosen Direction

User sudah mengunci arah model:

- **Text / Voice:** `gemini-2.5-flash-lite`
- **OCR / Struk:** `gemini-2.5-flash`

Alasan arah ini masuk akal:

- text/voice parsing butuh model ringan dan cepat
- OCR tetap pakai model yang lebih kuat untuk vision
- output JSON tidak perlu diubah

Catatan penting:

- Untuk mencegah bug serupa, implementasi sebaiknya tetap memakai constant terpusat untuk nama model.
- Jika endpoint Google saat ini mengharuskan variant tertentu seperti `-latest`, itu perlu divalidasi saat implementasi.

### Auth direction locked

User sudah mengunci auth ke **Vertex AI di GCP dengan project-based service auth**.

Artinya:

- tidak lagi memakai env `GEMINI_API_KEY`
- edge function harus pindah ke pola auth Vertex
- config minimal yang perlu disiapkan:
  - `GCP_LOCATION`
  - `GCP_SERVICE_ACCOUNT_JSON`

Konsekuensinya, URL dan header request ke model juga harus pindah mengikuti format Vertex AI, bukan Gemini Developer API lama.

---

## Implementation Plan

### Phase 1 — Fix Edge Function model config

1. Ganti constant / URL model text dari `gemini-1.5-flash` ke `gemini-2.5-flash-lite`.
2. Pastikan OCR memakai `gemini-2.5-flash`.
3. Rapikan supaya model name tidak hardcoded di banyak tempat:
   - `TEXT_MODEL`
   - `VISION_MODEL`
4. Refactor config env supaya pindah ke config Vertex AI:
   - `GCP_LOCATION`
   - `GCP_SERVICE_ACCOUNT_JSON`
5. Pertahankan prompt, JSON schema, dan error contract yang sekarang.

### Phase 2 — Make failures clearer

1. Saat Google / Vertex mengembalikan model/config error, map ke pesan internal yang lebih jelas.
2. Bedakan:
   - config/model error
   - timeout
   - rate limit
   - generic AI error
3. Tujuannya supaya kalau model retired lagi, log langsung menunjukkan masalah konfigurasi, bukan terlihat seperti AI lagi sibuk biasa.

### Phase 3 — Validate all AI parse modes

Validasi alur:

1. Text input
2. Voice input
3. OCR input

Yang dicek:

- response JSON tetap sesuai shape lama
- `note` tetap bersih
- quota hanya bertambah saat parse berhasil
- error ke Flutter tetap jelas

### Phase 4 — Update docs / wiki

Update raw + wiki supaya model yang tertulis sama dengan implementasi baru:

1. `My-Wiki/raw/docs/plan-refactor-ai-parse.md`
2. `My-Wiki/wiki/entities/edge-functions.md`
3. Jika perlu, `My-Wiki/wiki/entities/database-schema.md` untuk contoh provider name

---

## Files Likely Affected

- `supabase/functions/ai-parse/index.ts`
- `lib/features/voice/datasource/voice_remote_data_source.dart` (hanya jika perlu improve mapping message)
- `lib/features/voice/repositories/voice_repository.dart` (hanya jika perlu improve surfaced error)
- `My-Wiki/raw/docs/plan-refactor-ai-parse.md`
- `My-Wiki/wiki/entities/edge-functions.md`

---

## Testing Plan

### Supabase side

1. Invoke edge function mode `text` dengan contoh `"Beli Degan 10K"`
2. Invoke edge function mode `voice` dengan hasil transkrip sederhana
3. Invoke edge function mode `ocr` dengan sample receipt
4. Pastikan response sukses dan tidak ada `404 model not found`
5. Pastikan env/config Vertex AI baru benar-benar terbaca oleh edge function

### Flutter side

1. Test Text Input dari bottom sheet
2. Test Voice Input end-to-end setelah STT menghasilkan text
3. Test OCR result parse
4. Pastikan UI quota tetap refresh sesudah sukses
5. Pastikan error text tetap ramah kalau AI gagal

---

## Notes / Guardrails

- Jangan ubah format JSON hasil parse.
- Jangan kembalikan manual parser fallback.
- Jangan ubah logic quota increment: tetap hanya bertambah kalau parse sukses.
- Kalau variant model yang dipilih user perlu suffix berbeda agar valid di API Google, prioritasnya adalah menjaga perilaku produk yang dimaksud user, bukan memaksa nama literal yang ternyata retired.

---

## Locked decisions

1. Text / Voice memakai `gemini-2.5-flash-lite`
2. OCR memakai `gemini-2.5-flash`
3. Auth pindah ke **Vertex AI di GCP dengan project-based service auth**
