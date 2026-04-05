# Prompt 03 — Database Schema, RLS, Trigger, RPC

Patuh penuh pada:
- `docs/prd/` (PRD per section — lihat `prd/00_INDEX.md`)
- `02_DATABASE.md`
- `03_COPILOT_RULES.md`
- `01_MASTER_SESSION_PROMPT.md`

## Task
Implementasikan fondasi database Supabase/Postgres untuk SakuRapi berdasarkan `02_DATABASE.md`.

## Tujuan
Saya ingin migration SQL yang siap dijalankan untuk:
- schema tabel utama
- enum/check constraints
- index
- trigger update timestamp
- trigger ledger balance dari transactions
- RLS policy
- RPC atomik untuk create/update/delete transaksi bila diperlukan
- seed category dasar bila memang didefinisikan di dokumen

## Yang harus kamu lakukan
1. Cocokkan schema dengan `02_DATABASE.md`.
2. Hasilkan migration SQL yang berurutan dan rapi.
3. Pastikan ledger rule aman:
   - saldo wallet hanya berubah dari transaksi
   - total transaction items konsisten
4. Implementasikan atau siapkan RPC atomik minimal untuk transaksi core.
5. Buat RLS untuk semua tabel business.
6. Buat index yang penting untuk dashboard, history, budget, dan report query.
7. Jika ada bagian yang lebih aman dijadikan trigger vs RPC, jelaskan singkat.
8. Beri contoh payload untuk RPC penting.

## Output
Berikan:
1. daftar migration file
2. isi SQL lengkap per migration
3. penjelasan constraint penting
4. daftar RPC penting dan kapan dipakai
5. checklist validasi setelah migration dijalankan

## Batasan
- Jangan menambah field yang tidak justified oleh dokumen
- Jangan membuat saldo wallet bisa diubah manual dari client
- Jangan membuat model multi-currency
