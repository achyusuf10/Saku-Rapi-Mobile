# Prompt 11 — Multi-Item and Split Bill

Patuh penuh pada semua dokumen SakuRapi.

## Task
Implementasikan fitur multi-item / split bill untuk transaksi.

## Scope
- add/edit/remove multiple transaction items
- item-level category
- total summary
- sync total items ke total transaksi
- reusable item editor UI
- support untuk dipakai oleh manual entry, voice prefill, dan OCR prefill

## Yang harus kamu lakukan
1. Implementasikan editor item yang aman dan nyaman.
2. Pastikan minimal ada 1 item.
3. Pastikan `sum(item.amount) == total transaction`.
4. Jika schema mendukung detail item OCR seperti `item_name`, `qty`, `unit_price`, gunakan dengan konsisten.
5. Buat validation dan UX yang jelas saat mismatch total.
6. Jangan simpan logic perhitungan di widget build.

## Output
Berikan:
1. rule item yang diterapkan
2. file dan kode lengkap
3. jika perlu perubahan DB/RPC, sertakan
4. test minimum
5. edge case:
   - item kosong
   - qty/price invalid
   - total mismatch
   - reorder item
