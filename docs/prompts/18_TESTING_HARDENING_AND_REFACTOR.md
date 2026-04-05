# Prompt 18 — Testing, Hardening, and Refactor

Patuh penuh pada semua dokumen SakuRapi.

## Task
Lakukan hardening implementasi project setelah modul utama selesai.

## Yang harus kamu lakukan
1. Review seluruh modul yang sudah dibuat terhadap:
   - `docs/prd/` (PRD per section)
   - `02_DATABASE.md`
   - `03_COPILOT_RULES.md`
2. Identifikasi:
   - pelanggaran rule finansial
   - business logic di widget
   - state management yang rawan
   - duplicate submit risk
   - invalid async handling
   - missing test
   - localization yang belum lengkap
   - performance issue yang jelas
3. Refactor seminimal mungkin tetapi efektif.
4. Tambahkan test minimum yang masih kurang.
5. Rapikan struktur file bila ada deviasi dari architecture rules.

## Output
Berikan:
1. daftar temuan prioritas tinggi/sedang/rendah
2. file yang diubah
3. kode hasil perbaikan
4. daftar test yang ditambahkan
5. checklist verifikasi manual
