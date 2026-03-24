# Prompt 13 — OCR Receipt AI Prefill

Patuh penuh pada semua dokumen SakuRapi.

## Task
Implementasikan fitur OCR struk AI sebagai prefill transaksi multi-item.

## Scope
- camera/gallery pick
- image preprocess basic bila relevan
- kirim ke OCR/parser service
- hasil parsing masuk ke draft transaction + transaction_items
- user review sebelum save
- retry/edit manual flow
- attachment preview dasar bila sesuai PRD

## Yang harus kamu lakukan
1. Implementasikan flow OCR sesuai PRD.
2. Pastikan hasil OCR hanya prefill.
3. Mapping hasil OCR ke schema item harus konsisten.
4. Jika OCR gagal parsial, user tetap bisa edit manual.
5. Tambahkan permission handling kamera/storage sesuai kebutuhan Android.
6. Sediakan UI preview hasil scan yang jelas.
7. Buat UI yang elegan, modern, simpel, fancy dan mudah digunakan oleh user

## Output
Berikan:
1. flow OCR end-to-end
2. kontrak data OCR parser
3. file dan kode lengkap
4. service abstraction
5. test minimum
6. edge case:
   - permission denied
   - gambar blur/tidak terbaca
   - parser hanya mengembalikan sebagian item
   - subtotal dan total tidak sinkron
