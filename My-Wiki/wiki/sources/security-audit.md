---
title: "Security Audit — SakuRapi (April 2026)"
type: source
tags: [security, audit, supabase, flutter, rls, edge-functions, android, ios]
sources: [raw/security-audit.md]
created: 2026-04-14
updated: 2026-04-14
---

# Security Audit — SakuRapi (April 2026)

**Jenis**: Laporan audit keamanan internal
**Tanggal sumber**: 14 April 2026
**Status**: ✅ Semua CRITICAL & HIGH sudah di-fix

## Ringkasan

Audit keamanan menyeluruh yang mencakup Flutter client, Supabase database (RLS, functions, storage), dan Edge Functions. Audit mengidentifikasi 5 temuan CRITICAL, 5 HIGH, 7 MEDIUM, dan 3 LOW. Setelah implementasi, skor keamanan naik dari **5.5/10 → 8.5/10**.

Metodologi: Automated scan via Supabase Security & Performance Advisor, code review manual, dan analisis konfigurasi platform (Android/iOS). Hasil fix diimplementasikan langsung di codebase dan database via migrations.

Dua temuan CRITICAL ternyata **false positive** setelah investigasi mendalam: `.env` tidak pernah di-commit ke git, dan `'thisIsRandomKeyForEncryption'` adalah nama key FlutterSecureStorage bukan encryption key itu sendiri.

## Poin Kunci

### Temuan CRITICAL (5)
- **C1 FALSE POSITIVE**: `.env*` di `.gitignore`, tidak tracked di git
- **C2 FALSE POSITIVE**: Hive encryption key dikelola benar via `Hive.generateSecureKey()` + FlutterSecureStorage
- **C3 FIXED**: `gold-price` dan `bitcoin-price` edge functions tidak punya auth → di-fix dengan `verify_jwt: true` + cron jobs pakai anon key sebagai Bearer token
- **C4 FIXED**: RLS policy `gold_prices_insert_all` (WITH CHECK true) → dihapus, INSERT sekarang hanya via service_role
- **C5 DASHBOARD ONLY**: Leaked password protection — tidak bisa di-set via API, harus manual di Supabase Dashboard

### Temuan HIGH (5 — semua FIXED)
- **H1**: `android:allowBackup="false"` + `network_security_config.xml` (block cleartext HTTP)
- **H2**: `NSAppTransportSecurity` dengan `NSAllowsArbitraryLoads=false` di iOS
- **H3**: Error responses di `gold-price` dan `bitcoin-price` di-sanitize (hapus debug logs & raw errors)
- **H4**: Cron jobs `fetch-gold-prices` dan `fetch-bitcoin-prices` ditambah Authorization Bearer header
- **H5**: Policy `avatars_select_public` diganti `avatars_select_own` (hanya akses folder milik sendiri)

### Temuan MEDIUM (4 FIXED, 3 deferred)
- **M1 FIXED**: `search_path=public` di-set pada 5 function yang rentan schema hijacking
- **M2 FIXED**: 7 FK indexes ditambahkan (6 missing + 1 ditemukan saat recheck)
- **M3 FIXED**: 41 RLS policy dioptimasi ke pattern `(SELECT auth.uid())` — cegah re-evaluate per row
- **M6 FIXED**: `ai-parse` edge function ditambah input validation (MAX_TEXT=10K, MAX_IMAGE=10MB, MAX_CATEGORIES=200)
- **M4 Deferred**: SSL pinning ke Supabase client — perlu Supabase SDK support
- **M5 Deferred**: Bounds checking form input (amount/text length) — UI change
- **M7 Deferred**: Session refresh behavior — ditangani otomatis SDK

### Verified Strengths (Hal yang Sudah Baik)
1. RLS ON di semua 16 tabel bisnis
2. Semua URL pakai HTTPS
3. `flutter_secure_storage` sudah digunakan
4. Production logging hanya saat `kDebugMode`
5. Google Sign-In token validation + auto refresh
6. AI quota system via `check_ai_quota` RPC
7. 28/33 function sudah SECURITY DEFINER + search_path benar
8. Supabase call selalu via `SupabaseHandler.call()` wrapper
9. Service role key tidak ada di Flutter client
10. Storage bucket punya size limit & MIME restriction

## Relevansi untuk SakuRapi

Laporan ini menjadi baseline keamanan untuk deployment ke production. Semua fix sudah diimplementasikan di dev project (`oqdtrmkipnkweguaagig`) dan perlu di-apply ke prod project saat siap launch. Satu action manual tersisa: aktifkan "Leaked Password Protection" di Supabase Dashboard Authentication settings.

## Halaman Terkait

- `[[wiki/concepts/keamanan|Keamanan & Security Posture]]`
- `[[wiki/entities/edge-functions|Edge Functions]]`
- `[[wiki/entities/database-schema|Database Schema]]`
