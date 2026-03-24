# Prompt 12 — Voice Input AI Prefill

Patuh penuh pada semua dokumen SakuRapi.

## Task
Implementasikan fitur Voice Input AI sebagai prefill transaksi, bukan auto-save.

## Scope
- permission microphone
- record voice flow
- transcribe / kirim ke AI parser
- hasil parsing ke draft transaction form
- user review + edit sebelum save
- dictionary/cache bila sudah masuk fase yang sama
- error/loading state

## Yang harus kamu lakukan
1. Implementasikan alur voice sesuai PRD.
2. Pastikan AI hanya mengisi draft form, tidak pernah auto-commit transaksi.
3. Tampilkan hasil parsing yang mudah direview user.
4. Jika parser mengembalikan confidence/field kosong, tampilkan fallback UI yang aman.
5. Pisahkan audio/parsing/service dari widget.
6. Tambahkan permission handling dan edge case UX.
7. Buat UI yang elegan, modern, simpel, fancy dan mudah digunakan oleh user

## Output
Berikan:
1. flow voice end-to-end
2. kontrak data input/output voice parser
3. file dan kode lengkap
4. API/service abstraction yang dipakai
5. test minimum
6. edge case:
   - mic permission denied
   - transcription gagal
   - parser partial result
   - user cancel sebelum submit
