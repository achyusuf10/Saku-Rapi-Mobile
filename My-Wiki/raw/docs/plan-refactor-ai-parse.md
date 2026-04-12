# Plan: Refactor AI Parse Edge Function

> Status: Draft
> Tanggal: 2026-04-12
> Scope: `supabase/functions/ai-parse/index.ts` + Flutter client error handling + Supabase migration (rate limit tables)

---

## Problem

Edge function `ai-parse` punya beberapa isu:

1. **Terlalu banyak provider fallback** — Gemini → Groq → OpenRouter chain bikin edge function kompleks dan sulit debug. User ingin Gemini only.
2. **Field `note` kurang tepat** — AI kadang mengisi `note` dengan amount, tanggal, atau info yang sudah tertangkap field lain (contoh: "Beli Degan 10K pakai Cash Kemarin" → note seharusnya "Beli Degan", bukan null atau mengandung "10K").
3. **Error message generic** — Hanya `AI_BUSY`, tidak informatif.
4. **Tidak ada rate limiting** — User bisa call AI parse tanpa batas, bikin usage cost tidak terkontrol.

---

## Approach

### A. Simplifikasi Provider (Gemini Only)

| Mode | Sebelum | Sesudah |
|------|---------|---------|
| Text (voice/text input) | `gemini-2.5-flash` → `groq (llama-3.3-70b)` | **`gemini-1.5-flash`** only |
| OCR (scan struk) | `gemini-2.5-flash-lite` → `groq (llama-4-scout)` → `openrouter (gemma-3-27b)` | **`gemini-2.5-flash`** only |

Yang dihapus:
- `callGroq()`, `callGroqVision()`, `callOpenRouterVision()` functions
- `GROQ_API_KEY`, `OPENROUTER_API_KEY` constants
- Semua timeout constants Groq/OpenRouter
- Fallback try-catch chains

### B. Perbaiki Rule `note`

**Rule baru (menggantikan rule #11 text & #12 OCR):**

```
"note": Descriptive name of the item or service being transacted.
MUST contain the item/service description (e.g. "Beli Degan", "Makan siang di Warteg", "Bayar listrik").
MUST NOT contain: amount/angka, date/tanggal, wallet name, person name — these are already in their own fields.
If the input is just a category keyword with amount (e.g. "makan 25rb"), note can be null.
```

**Few-shot examples baru:**
- `"Beli Degan 10K"` → `note: "Beli Degan"` ← bukan null, bukan "Beli Degan 10K"
- `"Beli nasi goreng di warteg kemarin 15rb"` → `note: "Beli nasi goreng di warteg"` ← tanpa tanggal & amount
- `"makan 25rb"` → `note: null` ← terlalu generic, sudah cukup ada di categoryKeyword

### C. Error Messages Lebih Spesifik

| HTTP Status dari Gemini | Error code ke client |
|-------------------------|---------------------|
| Timeout (AbortController) | `AI_TIMEOUT` |
| 429 (rate limit) | `AI_RATE_LIMIT` |
| 401/403 (auth) | `AI_AUTH_ERROR` |
| Other errors | `AI_ERROR` + detail message |
| Quota exceeded (daily limit) | `DAILY_QUOTA_EXCEEDED` + remaining info |

### D. Rate Limiting (Scalable, Supabase-side)

**3 Mode terpisah** (update dari sebelumnya 2 mode):

| Mode | Deskripsi | Free Limit |
|------|-----------|------------|
| `text` | Input Teks (manual ketik) | 5x/hari |
| `voice` | Input Suara (STT → AI) | 5x/hari |
| `ocr` | Scan Struk (Vision AI) | 3x/hari |

> Edge function `ai-parse` akan accept mode `text`, `voice`, `ocr`. Mode `text` dan `voice` pakai pipeline yang sama (text parse), tapi kuota dihitung terpisah.

**Desain tabel:**

#### Tabel 1: `ai_usage_quotas` — Konfigurasi limit per tier

```sql
CREATE TABLE public.ai_usage_quotas (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  tier text NOT NULL DEFAULT 'free',          -- 'free', 'premium', 'unlimited', dst
  mode text NOT NULL,                          -- 'text' | 'voice' | 'ocr'
  daily_limit integer NOT NULL,                -- max per hari
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(tier, mode)
);

-- Seed data (default free tier):
INSERT INTO public.ai_usage_quotas (tier, mode, daily_limit) VALUES
  ('free', 'text', 5),     -- Input Teks: 5x/hari
  ('free', 'voice', 5),    -- Input Suara: 5x/hari
  ('free', 'ocr', 3);      -- Input Struk: 3x/hari
```

Kenapa scalable:
- Tinggal `INSERT ('premium', 'text', 50)` untuk tier premium
- Tinggal `INSERT ('unlimited', 'text', 9999)` untuk unlimited
- Bisa diubah kapan saja tanpa deploy ulang

#### Tabel 2: `ai_usage_logs` — Log setiap AI parse yang berhasil

```sql
CREATE TABLE public.ai_usage_logs (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  mode text NOT NULL,                          -- 'text' | 'ocr'
  provider text,                               -- 'gemini'
  created_at timestamptz DEFAULT now()
);

-- Index untuk query count harian yang cepat:
CREATE INDEX idx_ai_usage_logs_user_date
  ON public.ai_usage_logs (user_id, mode, created_at);
```

#### Kolom subscription di `users` table

```sql
ALTER TABLE public.users
  ADD COLUMN tier text NOT NULL DEFAULT 'free',
  ADD COLUMN tier_expires_at timestamptz DEFAULT NULL;
```

- `tier`: `'free'` atau `'premium'` (nanti bisa tambah tier lain)
- `tier_expires_at`: kapan subscription habis. `NULL` = permanent (free tier). Contoh: admin set `tier = 'premium'`, `tier_expires_at = now() + interval '30 days'`
- **Auto-downgrade**: RPC `check_ai_quota()` cek `tier_expires_at` — kalau sudah lewat, otomatis UPDATE tier ke `'free'` + clear `tier_expires_at`. Jadi user langsung kena limit free tanpa cron job.

**Seed data quota (2 tier):**

```sql
INSERT INTO public.ai_usage_quotas (tier, mode, daily_limit) VALUES
  ('free', 'text', 5),
  ('free', 'voice', 5),
  ('free', 'ocr', 3),
  ('premium', 'text', 20),
  ('premium', 'voice', 20),
  ('premium', 'ocr', 10);
```

**Admin workflow (via Supabase Dashboard):**
```sql
-- Aktifkan premium 30 hari:
UPDATE public.users SET tier = 'premium', tier_expires_at = now() + interval '30 days' WHERE email = 'user@email.com';

-- Cabut premium manual:
UPDATE public.users SET tier = 'free', tier_expires_at = NULL WHERE email = 'user@email.com';
```

#### RPC Function: 3 fungsi

**1. `check_ai_quota(p_mode)` — cek kuota sebelum call AI (+ auto-downgrade jika expired)**

```sql
CREATE OR REPLACE FUNCTION public.check_ai_quota(p_mode text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_tier text;
  v_expires_at timestamptz;
  v_daily_limit integer;
  v_today_count integer;
BEGIN
  SELECT tier, tier_expires_at INTO v_tier, v_expires_at
  FROM public.users WHERE id = v_user_id;
  IF v_tier IS NULL THEN v_tier := 'free'; END IF;

  -- Auto-downgrade: jika tier bukan free DAN sudah expired → downgrade
  IF v_tier <> 'free' AND v_expires_at IS NOT NULL AND v_expires_at < now() THEN
    UPDATE public.users SET tier = 'free', tier_expires_at = NULL WHERE id = v_user_id;
    v_tier := 'free';
  END IF;

  SELECT daily_limit INTO v_daily_limit
  FROM public.ai_usage_quotas WHERE tier = v_tier AND mode = p_mode;
  IF v_daily_limit IS NULL THEN v_daily_limit := 0; END IF;

  SELECT COUNT(*) INTO v_today_count FROM public.ai_usage_logs
  WHERE user_id = v_user_id AND mode = p_mode
    AND created_at >= date_trunc('day', now() AT TIME ZONE 'Asia/Jakarta') AT TIME ZONE 'Asia/Jakarta'
    AND created_at < (date_trunc('day', now() AT TIME ZONE 'Asia/Jakarta') + interval '1 day') AT TIME ZONE 'Asia/Jakarta';

  RETURN jsonb_build_object(
    'allowed', v_today_count < v_daily_limit,
    'used', v_today_count,
    'limit', v_daily_limit,
    'remaining', GREATEST(v_daily_limit - v_today_count, 0),
    'tier', v_tier
  );
END; $$;
```

**2. `log_ai_usage(p_mode, p_provider)` — catat setelah AI berhasil**

```sql
CREATE OR REPLACE FUNCTION public.log_ai_usage(p_mode text, p_provider text DEFAULT 'gemini')
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_tier text;
  v_daily_limit integer;
  v_today_count integer;
BEGIN
  INSERT INTO public.ai_usage_logs (user_id, mode, provider)
  VALUES (v_user_id, p_mode, p_provider);

  SELECT tier INTO v_tier FROM public.users WHERE id = v_user_id;
  IF v_tier IS NULL THEN v_tier := 'free'; END IF;

  SELECT daily_limit INTO v_daily_limit
  FROM public.ai_usage_quotas WHERE tier = v_tier AND mode = p_mode;
  IF v_daily_limit IS NULL THEN v_daily_limit := 0; END IF;

  SELECT COUNT(*) INTO v_today_count FROM public.ai_usage_logs
  WHERE user_id = v_user_id AND mode = p_mode
    AND created_at >= date_trunc('day', now() AT TIME ZONE 'Asia/Jakarta') AT TIME ZONE 'Asia/Jakarta'
    AND created_at < (date_trunc('day', now() AT TIME ZONE 'Asia/Jakarta') + interval '1 day') AT TIME ZONE 'Asia/Jakarta';

  RETURN jsonb_build_object(
    'used', v_today_count,
    'limit', v_daily_limit,
    'remaining', GREATEST(v_daily_limit - v_today_count, 0)
  );
END; $$;
```

**3. `get_all_ai_quotas()` — fetch semua kuota user sekaligus (untuk UI, + auto-downgrade)**

```sql
CREATE OR REPLACE FUNCTION public.get_all_ai_quotas()
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_tier text;
  v_expires_at timestamptz;
  v_result jsonb := '{}';
  v_mode text;
  v_daily_limit integer;
  v_today_count integer;
BEGIN
  SELECT tier, tier_expires_at INTO v_tier, v_expires_at
  FROM public.users WHERE id = v_user_id;
  IF v_tier IS NULL THEN v_tier := 'free'; END IF;

  -- Auto-downgrade
  IF v_tier <> 'free' AND v_expires_at IS NOT NULL AND v_expires_at < now() THEN
    UPDATE public.users SET tier = 'free', tier_expires_at = NULL WHERE id = v_user_id;
    v_tier := 'free';
  END IF;

  FOR v_mode, v_daily_limit IN
    SELECT q.mode, q.daily_limit FROM public.ai_usage_quotas q WHERE q.tier = v_tier
  LOOP
    SELECT COUNT(*) INTO v_today_count FROM public.ai_usage_logs
    WHERE user_id = v_user_id AND mode = v_mode
      AND created_at >= date_trunc('day', now() AT TIME ZONE 'Asia/Jakarta') AT TIME ZONE 'Asia/Jakarta'
      AND created_at < (date_trunc('day', now() AT TIME ZONE 'Asia/Jakarta') + interval '1 day') AT TIME ZONE 'Asia/Jakarta';

    v_result := v_result || jsonb_build_object(
      v_mode, jsonb_build_object(
        'used', v_today_count,
        'limit', v_daily_limit,
        'remaining', GREATEST(v_daily_limit - v_today_count, 0)
      )
    );
  END LOOP;

  -- Tambah info tier + expiry
  v_result := v_result || jsonb_build_object('tier', v_tier);

  RETURN v_result;
END; $$;
```

Contoh response `get_all_ai_quotas()`:
```json
{
  "text": { "used": 2, "limit": 5, "remaining": 3 },
  "voice": { "used": 1, "limit": 5, "remaining": 4 },
  "ocr": { "used": 0, "limit": 3, "remaining": 3 },
  "tier": "free"
}
```

#### Flow di Edge Function

```
1. Receive request (mode: text/voice/ocr)
2. Auth check (JWT)
3. Check quota → RPC `check_ai_quota(mode)` (read-only)
   - Jika quota habis → return 429 DAILY_QUOTA_EXCEEDED + {used, limit, remaining: 0}
   - Jika masih ada → lanjut
4. Call AI (text/voice pakai Gemini text, ocr pakai Gemini vision)
5. AI berhasil → RPC `log_ai_usage(mode, provider)` → return success + {remaining}
6. AI gagal → TIDAK log usage (quota tidak berkurang)
```

#### RLS Policies

```sql
ALTER TABLE public.ai_usage_quotas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ai_usage_quotas_select_all" ON public.ai_usage_quotas
  FOR SELECT TO authenticated USING (true);

ALTER TABLE public.ai_usage_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ai_usage_logs_select_own" ON public.ai_usage_logs
  FOR SELECT TO authenticated USING (user_id = auth.uid());
-- INSERT/UPDATE/DELETE hanya via SECURITY DEFINER RPC
```

### E. Flutter Client Changes

#### 1. Bottom sheet — tampilkan sisa kuota SEBELUM input

Setiap kali user membuka bottom sheet input (Voice/Text/OCR), fetch `get_all_ai_quotas()` lalu tampilkan:
- **Sisa kuota hari ini** — e.g. "Sisa 3 dari 5 kali hari ini"
- **Jika kuota habis** — disable button input, tampilkan pesan "Batas harian tercapai. Coba lagi besok."

#### 2. Hasil review — tampilkan sisa kuota SETELAH berhasil

Setelah AI parse berhasil, response dari edge function akan berisi `remaining`.
Tampilkan di halaman review: "Sisa kuota: 4/5 hari ini"
Ini auto update karena `remaining` langsung dari response (tidak perlu fetch lagi).

#### 3. Handle error `DAILY_QUOTA_EXCEEDED`

Di OCR + Voice remote data sources: detect error code, tampilkan user-friendly message.

#### 4. L10n keys baru

```
aiQuotaRemaining: "Sisa {remaining} dari {limit} kali hari ini"
aiQuotaExhausted: "Batas harian tercapai. Coba lagi besok."
aiQuotaText: "Input Teks"
aiQuotaVoice: "Input Suara"
aiQuotaOcr: "Scan Struk"
```

---

## Todos (Urutan Eksekusi)

### Phase 1: Supabase Migration (Rate Limit Tables)
1. `ap-migration-tables` — Buat migration SQL: `ai_usage_quotas`, `ai_usage_logs`, ALTER users ADD tier + tier_expires_at, RLS policies, seed free+premium tiers
2. `ap-migration-rpcs` — Buat 3 RPC functions: `check_ai_quota()`, `log_ai_usage()`, `get_all_ai_quotas()` — semua include auto-downgrade logic

### Phase 2: Edge Function Refactor
3. `ap-remove-fallbacks` — Hapus Groq + OpenRouter functions, constants, dan fallback chains
4. `ap-update-models` — Ganti model: text=`gemini-1.5-flash`, OCR=`gemini-2.5-flash`
5. `ap-fix-note-prompt` — Perbaiki rule `note` di system prompt text + OCR, tambah few-shot examples
6. `ap-improve-errors` — Error messages spesifik (AI_TIMEOUT, AI_RATE_LIMIT, AI_ERROR)
7. `ap-add-quota-check` — Tambah quota check (before AI) + log usage (after AI success) + accept mode text/voice/ocr

### Phase 3: Flutter Client
8. `ap-flutter-quota-error` — Handle `DAILY_QUOTA_EXCEEDED` error di OCR + Voice remote data sources
9. `ap-flutter-l10n` — Tambah l10n keys untuk pesan quota
10. `ap-flutter-quota-ui` — Tampilkan sisa kuota di bottom sheet (fetch `get_all_ai_quotas()`) + di halaman review hasil (dari response `remaining`)
11. `ap-flutter-update-mode` — Update Voice remote data source kirim mode `voice` (bukan `text`) ke edge function

### Phase 4: Testing
12. `ap-test-supabase` — Test Supabase RPCs: quota check, log usage, auto-downgrade, day boundary
13. `ap-test-flutter` — Test Flutter: `fvm flutter analyze` + `fvm flutter test` — pastikan 0 new errors

### Phase 5: Finalize
14. `ap-commit-wiki` — Commit, ingest wiki

---

## Keputusan Teknis

| Keputusan | Pilihan | Alasan |
|-----------|---------|--------|
| Provider | Gemini only | User request, simplifikasi |
| Text model | `gemini-1.5-flash` | User request |
| Vision model | `gemini-2.5-flash` | User request |
| Quota check | SEBELUM call AI | Hemat cost, UX lebih cepat |
| Log usage | SETELAH AI berhasil | AI gagal = quota tidak berkurang |
| Tier storage | `tier` + `tier_expires_at` di `users` | Simple, auto-downgrade tanpa cron |
| Subscription expiry | Auto-downgrade di RPC | Dicek saat `check_ai_quota()` atau `get_all_ai_quotas()` — expired → instant downgrade |
| Admin activate | Manual via Supabase Dashboard | Belum ada in-app purchase untuk MVP |
| Free tier | text=5, voice=5, ocr=3 /hari | Default semua user |
| Premium tier | text=20, voice=20, ocr=10 /hari | Admin set manual + durasi |
| Quota config | Tabel `ai_usage_quotas` | Bisa diubah tanpa deploy, scalable per tier |
| Day boundary | Asia/Jakarta timezone | Sesuai target market Indonesia |
| RPC approach | 3 RPC (check + log + get_all) | check sebelum AI, log setelah berhasil, get_all untuk UI |
| Mode | 3 mode (text, voice, ocr) | Kuota terpisah per fitur input |
| Quota UI fetch | Fetch dari server tiap buka bottom sheet | Selalu akurat, meski pakai 2 device |

---

## Yang TIDAK Berubah

- JSON output format / contract ke Flutter client (field names, types)
- `reverseMapResponse()`, `buildIdMapping()` logic
- Category ID mapping (UUID ↔ short ID)
- CORS headers
- Flutter model parsing (`VoiceParseResultModel`, `OcrParseResultModel`)

---

## Testing Plan

### Supabase-side Testing

Test RPC functions via SQL (di Supabase SQL Editor atau local pgTAP):

**1. Quota check basic:**
```sql
-- User free tier, belum pakai → should return allowed=true, remaining=5
SELECT check_ai_quota('text');

-- Insert 5 fake logs → should return allowed=false, remaining=0
INSERT INTO ai_usage_logs (user_id, mode, provider)
  SELECT auth.uid(), 'text', 'gemini' FROM generate_series(1,5);
SELECT check_ai_quota('text');
```

**2. Auto-downgrade:**
```sql
-- Set user premium, expired kemarin
UPDATE users SET tier = 'premium', tier_expires_at = now() - interval '1 day' WHERE id = auth.uid();

-- Call quota check → should auto-downgrade to free and return free limits
SELECT check_ai_quota('text');
-- Verify: tier should now be 'free', tier_expires_at NULL
SELECT tier, tier_expires_at FROM users WHERE id = auth.uid();
```

**3. Premium active (belum expired):**
```sql
UPDATE users SET tier = 'premium', tier_expires_at = now() + interval '29 days' WHERE id = auth.uid();
SELECT check_ai_quota('text');  -- should return limit=20
```

**4. Day boundary:**
```sql
-- Insert log with yesterday timestamp → should NOT count toward today
INSERT INTO ai_usage_logs (user_id, mode, provider, created_at)
  VALUES (auth.uid(), 'text', 'gemini', now() - interval '1 day');
SELECT check_ai_quota('text');  -- yesterday log should not reduce today's quota
```

**5. get_all_ai_quotas:**
```sql
SELECT get_all_ai_quotas();  -- should return {text:{...}, voice:{...}, ocr:{...}, tier:"free"}
```

**6. log_ai_usage:**
```sql
SELECT log_ai_usage('text', 'gemini');  -- should insert + return remaining
SELECT COUNT(*) FROM ai_usage_logs WHERE user_id = auth.uid() AND mode = 'text';
```

### Flutter-side Testing

**1. Static analysis:**
```bash
fvm flutter analyze --no-fatal-infos
```
Target: 0 new errors (hanya pre-existing warnings).

**2. Existing test suite:**
```bash
fvm flutter test
```
Target: sama atau lebih baik dari baseline (505+ pass, 7 pre-existing fails).

**3. Manual test checklist:**
- [ ] Buka bottom sheet Input Suara → kuota terlihat
- [ ] Buka bottom sheet Input Teks → kuota terlihat
- [ ] Buka bottom sheet Scan Struk → kuota terlihat
- [ ] AI parse berhasil → kuota remaining update di review page
- [ ] AI parse ke-5 (text) → berhasil, remaining=0
- [ ] AI parse ke-6 (text) → ditolak, pesan "Batas harian tercapai"
- [ ] AI parse gagal (AI error) → kuota TIDAK berkurang
- [ ] Ganti hari (atau reset logs) → kuota kembali full
