# Prompt 04 — Auth and Profile

Patuh penuh pada semua dokumen SakuRapi.

## Task
Implementasikan fitur Auth dan Profile dasar.

## Scope
- Google Sign-In
- sinkronisasi user profile ke tabel `users`
- splash / session restore flow
- auth guard routing
- logout
- profile read basic
- error handling auth

## Yang harus kamu lakukan
1. Implementasi auth flow sesuai PRD.
2. Buat data source, repository, controller/notifier, dan page terkait.
3. Pastikan app bisa:
   - cek session existing
   - redirect ke auth jika belum login
   - redirect ke dashboard jika sudah login
4. Setelah login sukses, sinkronkan/mirror data user ke tabel `users`.
5. Buat profile header/basic profile section yang bisa dipakai ulang di Settings nanti.
6. Tambahkan localization string yang dibutuhkan.

## Output
Berikan:
1. flow auth yang diterapkan
2. file yang dibuat/diubah
3. kode lengkap
4. konfigurasi platform/package yang perlu dicek
5. test minimum
6. edge case:
   - user cancel sign-in
   - network/auth failure
   - session expired
