---
title: "Plan: Edge Function image-upload"
type: source
tags: [edge-function, storage, gcs, supabase-storage, image-upload]
sources: [raw/image-upload-edge-fn-plan.md]
created: 2026-04-19
updated: 2026-04-19
---

# Plan: Edge Function image-upload

**Status:** Draft — belum diimplementasi
**Sumber:** `raw/image-upload-edge-fn-plan.md`

## Ringkasan

Edge function baru `image-upload` untuk menangani upload gambar (lampiran transaksi, struk OCR). Menggunakan Supabase Storage sebagai primary dan Google Cloud Storage (GCS) sebagai fallback jika usage mendekati limit.

## Alur Upload

```
Client → POST /functions/v1/image-upload (multipart/form-data)
       ↓
       Cek usage Supabase Storage
       ↓
       usage < STORAGE_LIMIT_MB?
         YES → upload ke Supabase Storage → return URL
         NO  → upload ke GCS (fallback) → return GCS URL
```

## Konfigurasi

| Env Var | Keterangan |
|---------|-----------|
| `STORAGE_LIMIT_MB` | Threshold sebelum fallback ke GCS |
| `GCS_SERVICE_ACCOUNT_JSON` | Service account JSON untuk autentikasi GCS |

## Keamanan

- `verify_jwt: true` — harus ada valid Supabase JWT
- User hanya bisa upload untuk dirinya sendiri (path di-enforce di server)

## Format Response

```json
{ "url": "https://..." }
```

URL yang dikembalikan bisa berupa Supabase Storage URL atau GCS URL — client tidak perlu tahu bedanya.

## Scope File

- **BARU**: `supabase/functions/image-upload/index.ts`

## Halaman Terkait

- [[wiki/entities/edge-functions|Edge Functions]]
- [[wiki/entities/transaksi|Transaksi]]
