# Prompt 19 — Final Review and Release Checklist

Patuh penuh pada semua dokumen SakuRapi.

## Task
Lakukan final review sebelum release internal / demo build.

## Yang harus kamu lakukan
1. Audit seluruh project terhadap:
   - PRD
   - database spec
   - copilot rules
2. Buat checklist final untuk:
   - feature completeness P0
   - feature completeness P1 yang sudah dikerjakan
   - database readiness
   - auth readiness
   - wallet/transaction/report correctness
   - localization completeness
   - loading/empty/error coverage
   - test coverage minimum
   - Android permission readiness
   - release build readiness
3. Identifikasi gap yang masih tersisa.
4. Jika ada kode yang masih menyimpang, berikan patch perbaikannya.
5. Buat ringkasan “siap demo” vs “belum siap production”.

## Output
Berikan:
1. checklist final yang bisa saya centang
2. daftar gap/bloker
3. patch code terakhir bila perlu
4. rekomendasi prioritas next steps setelah fase ini
