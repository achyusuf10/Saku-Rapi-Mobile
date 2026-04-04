# Prompt 16 — Local Notifications and Reminders

Patuh penuh pada semua dokumen SakuRapi.

## Task
Implementasikan local notifications/reminders.

## Scope
- reminder catat transaksi
- budget alert local
- permission flow Android
- settings on/off
- local scheduling abstraction

## Yang harus kamu lakukan
1. Implementasikan notifikasi lokal sesuai PRD.
2. Tambahkan permission flow Android 13+.
3. Buat abstraction yang mudah dites.
4. Pastikan notifikasi budget hanya berdasarkan data yang benar.
5. Sediakan settings UI dasar untuk reminder.

## Output
Berikan:
1. flow permission dan scheduling
2. file dan kode lengkap
3. konfigurasi Android yang diperlukan
4. test minimum
5. edge case:
   - permission denied
   - schedule duplikat
   - timezone/perubahan jam
   - budget alert stale
