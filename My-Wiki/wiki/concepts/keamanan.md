---
title: "Keamanan & Security Posture"
type: concept
tags: [security, rls, edge-functions, android, ios, hive, supabase, audit]
sources: [raw/security-audit.md]
created: 2026-04-14
updated: 2026-04-14
---

# Keamanan & Security Posture

> Halaman ini mendokumentasikan postur keamanan SakuRapi setelah audit April 2026, beserta aturan dan praktik yang harus dipertahankan ke depannya.

**Security score (post-audit):** 8.5/10 🟢
**Audit terakhir:** April 2026 — lihat [[wiki/sources/security-audit|Security Audit Report]]

---

## Layer Keamanan

### 1. Supabase Database (RLS)

**Status:** ✅ Aman

- Semua 16 tabel bisnis RLS ON
- Semua 44 RLS policy sudah dioptimasi dengan pattern `(SELECT auth.uid())` — mencegah re-evaluate per row saat query tabel besar
- INSERT ke `gold_prices` hanya bisa dilakukan service_role (via edge function) — policy publik dihapus
- Avatars listing dibatasi ke folder milik user sendiri (`(storage.foldername(name))[1] = auth.uid()::text`)

**Aturan wajib:**
```sql
-- ✅ Pattern yang benar (evaluate sekali per query)
CREATE POLICY "select_own" ON table
  FOR SELECT USING (user_id = (SELECT auth.uid()));

-- ❌ Jangan (evaluate per row — lambat untuk tabel besar)
CREATE POLICY "select_own" ON table
  FOR SELECT USING (user_id = auth.uid());
```

### 2. Supabase Functions

**Status:** ✅ Aman

- Semua 33 RPC function pakai `SECURITY DEFINER` dengan `SET search_path = public`
- Tanpa `search_path` eksplisit, function rentan **schema hijacking attack**

**Aturan wajib:** Setiap function baru harus menyertakan:
```sql
CREATE OR REPLACE FUNCTION public.nama_function(...)
  RETURNS ...
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public
AS $$
...
$$;
```

### 3. Edge Functions

**Status:** ✅ Aman

| Function | verify_jwt | Auth |
|----------|-----------|------|
| `gold-price` | ✅ true | JWT validated by Supabase |
| `bitcoin-price` | ✅ true | JWT validated by Supabase |
| `ai-parse` | ❌ false | Custom JWT check via `supabase.auth.getUser()` |

**Aturan wajib:**
- Setiap function baru harus `verify_jwt: true` kecuali ada alasan kuat (seperti `ai-parse` yang perlu raw JWT untuk custom validation)
- Error responses **tidak boleh** mengekspos detail internal: gunakan pesan generik
- Input validation wajib: batasi ukuran text, image, dan array dari client

**Cron jobs memanggil edge function:**
```sql
-- Wajib sertakan Authorization header
headers := jsonb_build_object(
  'Content-Type', 'application/json',
  'Authorization', 'Bearer <anon_key>'
)
```

### 4. Flutter Client — Platform Security

**Status:** ✅ Aman

**Android (`AndroidManifest.xml`):**
- `android:allowBackup="false"` — mencegah backup Hive database via ADB
- `android:networkSecurityConfig="@xml/network_security_config"` — block cleartext HTTP

**iOS (`Info.plist`):**
- `NSAppTransportSecurity` dengan `NSAllowsArbitraryLoads=false` — enforce HTTPS

### 5. Flutter Client — Data Protection

**Status:** ✅ Aman

- **Hive encryption**: Key di-generate via `Hive.generateSecureKey()` satu kali per device install, disimpan di `FlutterSecureStorage`
- **Credentials**: Tidak ada hardcoded API key di source code — semua via `--dart-define` saat build
- **No service role key**: Service role key tidak pernah ada di Flutter client

### 6. Storage

**Status:** ✅ Aman

| Bucket | Akses | Limit |
|--------|-------|-------|
| `avatars` | Public URL, listing dibatasi per user | 2 MB, jpeg/png/webp |
| `attachments` | Private, hanya pemilik | 5 MB, jpeg/png/webp/pdf |

---

## Action Manual yang Tersisa

> ⚠️ **Perlu dilakukan manual di Supabase Dashboard sebelum launch production:**

1. **Leaked Password Protection** — Dashboard → Authentication → Settings → Password → Enable "Leaked Password Protection" dan set minimum length 12 karakter

---

## Items Deferred (Untuk Sprint Berikutnya)

| Item | Deskripsi |
|------|-----------|
| **SSL Pinning** | Integrasikan `ssl_pinning_client.dart` ke Supabase initialization — perlu Supabase SDK support untuk custom HTTP client |
| **Form Bounds Checking** | Tambahkan max amount validation (>999B rejected) dan max text length pada form transaksi |
| **Deep Link Guard** | Siapkan validasi parameter saat menambahkan deep link di masa depan |

---

## Checklist untuk Deployment Production

Sebelum launch ke production project (`geehwokpxfqldssozqvq`), pastikan:

- [ ] Apply semua migrations dari dev ke prod
- [ ] Deploy semua edge functions ke prod dengan `verify_jwt: true`
- [ ] Update cron job commands di prod dengan anon key prod
- [ ] Aktifkan Leaked Password Protection di Dashboard prod
- [ ] Jalankan Supabase Security & Performance Advisor di prod
- [ ] `fvm flutter pub outdated` — update dependency yang sudah ketinggalan

---

## Monitoring Berkelanjutan

- Jalankan **Supabase Security Advisor** setelah setiap DDL change
- Jalankan **Supabase Performance Advisor** setelah menambah tabel/index baru
- `fvm flutter pub outdated` — bulanan
- Cek **`ai_usage_logs`** growth — pertimbangkan retention policy (hapus log > 90 hari)
- Cek **`gold_prices`** growth — append-only, akan terus bertambah (1 row/hari)

---

## Halaman Terkait

- `[[wiki/sources/security-audit|Security Audit Report (April 2026)]]`
- `[[wiki/entities/edge-functions|Edge Functions]]`
- `[[wiki/entities/database-schema|Database Schema]]`
- `[[wiki/concepts/aturan-keuangan|Aturan Keuangan Fundamental]]`
- `[[wiki/concepts/arsitektur-app|Arsitektur App]]`
