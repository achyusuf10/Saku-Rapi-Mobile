# Refactor AI Parse: Gemini-Only + Daily Quota

**Tanggal:** 2026-04-12  
**Commit:** `f296c52`  
**Branch:** `feature/transaction`

## Ringkasan

Refactor besar pada sistem AI Parse (Input Text, Input Suara, Input OCR) dengan tiga perubahan utama:

1. **Simplifikasi provider** — Hapus Groq dan OpenRouter, hanya pakai Google Gemini
2. **Perbaikan kualitas catatan** — Prompt diperbaiki agar catatan berisi deskripsi item saja
3. **Sistem kuota harian** — Rate limiting per user dengan support tier (free/premium)

## Perubahan Detail

### 1. Simplifikasi AI Provider

| Sebelum | Sesudah |
|---------|---------|
| Text: Gemini 2.5 Flash → Groq fallback → OpenRouter fallback | Text: Gemini 2.5 Flash Lite saja |
| Voice: Same as text | Voice: Gemini 2.5 Flash Lite saja |
| OCR: Gemini 2.5 Flash Lite → Groq Vision → OpenRouter Vision | OCR: Gemini 2.5 Flash saja |

**Alasan:** Groq dan OpenRouter sering timeout, rate limit, dan kualitas parsing tidak konsisten. Gemini lebih stabil dan gratis untuk volume rendah.

### 2. Perbaikan Kualitas Catatan

**Masalah:** Catatan mengandung informasi yang seharusnya ada di field lain (amount, tanggal, wallet).

**Contoh perbaikan:**
- Input: "Beli Degan 10K" → Catatan sebelum: "Beli Degan 10K" → Catatan sesudah: "Beli Degan"
- Input: "Transfer ke BCA 500rb" → Catatan: "Transfer ke BCA" (bukan "Transfer ke BCA 500rb")

**Rule prompt baru:** Catatan HARUS berisi deskripsi item/layanan saja, TIDAK BOLEH mengandung jumlah uang, tanggal, nama dompet, atau nama orang.

### 3. Sistem Kuota Harian

#### Tabel Baru

**`ai_usage_quotas`** — Konfigurasi batas per tier per mode:

| Tier | Text | Voice | OCR |
|------|------|-------|-----|
| Free | 5/hari | 5/hari | 3/hari |
| Premium | 20/hari | 20/hari | 10/hari |

**`ai_usage_logs`** — Log setiap penggunaan AI yang berhasil (`user_id`, `mode`, `provider`, `created_at`, `usage_date`).

#### Kolom Baru di `users`

- `tier` (text, default 'free') — Tier langganan user
- `tier_expires_at` (timestamptz, nullable) — Kapan tier expired, auto-downgrade ke free

#### RPC Functions

1. **`check_ai_quota(p_mode, p_usage_date)`** — Cek apakah user masih punya kuota. Otomatis downgrade jika tier expired.
2. **`log_ai_usage(p_mode, p_provider, p_usage_date)`** — Catat penggunaan setelah AI parse berhasil.
3. **`get_all_ai_quotas(p_usage_date)`** — Ambil semua kuota user (text/voice/ocr) untuk ditampilkan di UI.

Semua RPC menggunakan `SECURITY DEFINER`; batas hari dihitung dari `usage_date` yang dikirim client (`localDate`), bukan lagi hardcoded `Asia/Jakarta`.

#### Auto-Downgrade

Ketika user premium dan `tier_expires_at < now()`:
- RPC otomatis set `tier = 'free'` dan `tier_expires_at = NULL`
- Terjadi saat check_ai_quota atau get_all_ai_quotas dipanggil
- Tidak perlu cron job

## Perubahan Edge Function

File: `supabase/functions/ai-parse/index.ts` (620 → 542 baris)

**Dihapus:**
- `GROQ_API_KEY`, `OPENROUTER_API_KEY` constants
- `callGroq()`, `callGroqVision()`, `callOpenRouterVision()` functions
- Fallback chain logic

**Ditambah:**
- `classifyError()` — Maps error ke kode spesifik (AI_TIMEOUT, AI_RATE_LIMIT, AI_AUTH_ERROR, AI_ERROR)
- Quota check sebelum AI call
- Log usage setelah AI berhasil
- Mode `voice` (sama pipeline dengan `text`, beda tracking kuota)
- Response success sekarang include `quota: {used, limit, remaining}`
- Error `DAILY_QUOTA_EXCEEDED` return HTTP 429

## Perubahan Flutter

### File Baru
- `lib/features/voice/controllers/ai_quota_provider.dart` — Provider fetch kuota via RPC
- `lib/features/voice/models/ai_quota_model.dart` — Model `AiQuotaModel` + `AllAiQuotasModel`
- `lib/features/voice/view/widgets/ai_quota_info_row.dart` — Widget tampilan kuota

### File Diubah
- `voice_remote_data_source.dart` — Tambah parameter `mode` (default 'text')
- `voice_repository.dart` — Pass `mode` ke remote data source
- `voice_input_controller.dart` — Kirim `mode: 'voice'` saat parse
- `text_input_sheet.dart` — Tambah `AiQuotaInfoRow`, handle `DAILY_QUOTA_EXCEEDED`
- `voice_input_sheet.dart` — Tambah `AiQuotaInfoRow`, handle `DAILY_QUOTA_EXCEEDED`
- `ocr_result_sheet.dart` — Tambah `AiQuotaInfoRow`, handle `DAILY_QUOTA_EXCEEDED`

### UI Quota
- Ditampilkan di atas setiap bottom sheet input (text/voice/OCR)
- Format: "⚡ Sisa X dari Y kali hari ini"
- Jika habis: "⚠ Batas harian tercapai"
- Auto-refresh setelah AI parse selesai (invalidate provider)

## Relasi

- [[voice-input]] — Mode voice sekarang dikirim sebagai parameter terpisah
- [[text-input]] — Sama dengan voice, tapi mode 'text'
- [[ocr-receipt]] — Mode 'ocr', model Gemini 2.5 Flash
- [[edge-functions]] — ai-parse di-refactor total
- [[database-schema]] — 2 tabel baru, 2 kolom baru di users, 3 RPC baru
- [[remove-manual-parsing]] — Prerequisite dari refactor ini
