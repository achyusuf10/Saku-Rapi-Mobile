# Prompt 02 — Repo Foundation and Architecture

Patuh penuh pada:
- `01_PRD.md`
- `02_DATABASE.md`
- `03_COPILOT_RULES.md`
- `01_MASTER_SESSION_PROMPT.md`

## Task
Bangun fondasi project Flutter SakuRapi agar siap dikembangkan modul per modul.

## Tujuan
Saya ingin fondasi repo yang rapi, scalable, dan konsisten dengan rules:
- struktur folder feature-based
- router dasar
- theme dasar
- localization dasar
- shared widgets/utilities dasar
- Hive bootstrap
- Supabase bootstrap
- Riverpod provider foundation
- error handling foundation
- formatter/parsers uang dan tanggal
- base page/loading/error widgets

## Yang harus kamu lakukan
1. Analisis struktur repo saat ini.
2. Jika struktur belum sesuai, usulkan dan implementasikan struktur folder yang paling cocok.
3. Buat fondasi untuk:
   - `app/`
   - `core/`
   - `features/`
   - `l10n/`
4. Setup:
   - app entrypoint
   - env/config bootstrap
   - Supabase init
   - Hive init
   - GoRouter shell dasar
   - ThemeData light/dark
   - context extensions
   - formatter helper IDR
   - UTC <-> Asia/Jakarta date helper
5. Sediakan placeholder route/page untuk:
   - auth
   - dashboard
   - wallet
   - transaction
   - history
   - settings
6. Jangan implementasi fitur bisnis penuh dulu; fokus ke fondasi.
7. Tambahkan file-file dasar untuk state/error/result pattern bila diperlukan.
8. Tambahkan `.arb` baseline untuk string umum.

## Output
Berikan:
1. struktur folder final
2. daftar dependency yang perlu dipakai
3. file yang dibuat/diubah
4. kode lengkap per file
5. alasan desain singkat
6. command verify yang harus saya jalankan (`flutter pub get`, `flutter analyze`, dst.)

## Batasan
- Jangan implementasi logic transaksi dulu
- Jangan ubah schema database
- Jangan gunakan code generation model
- Jangan gunakan `double` untuk util money domain
