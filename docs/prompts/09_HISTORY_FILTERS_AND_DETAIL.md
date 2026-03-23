# Prompt 09 — History, Filters, and Detail

Patuh penuh pada semua dokumen SakuRapi.

## Task
Implementasikan histori transaksi.

## Scope
- transaction history list
- filter periode: harian/mingguan/bulanan/range sesuai PRD
- filter wallet
- filter type
- grouping list
- pagination/infinite scroll bila relevan
- detail transaction page
- delete/edit action entry
- empty/loading/error state

## Yang harus kamu lakukan
1. Implementasikan query histori yang scalable.
2. Terapkan grouping dan filter sesuai dokumen.
3. Pastikan boundary tanggal aman dengan UTC storage + Asia/Jakarta render.
4. Buat detail page yang menjelaskan data transaksi dengan jelas.
5. Siapkan refresh flow setelah create/update/delete.

## Output
Berikan:
1. strategi query/filter/grouping
2. file dan kode lengkap
3. test minimum
4. edge case:
   - no data
   - filter result empty
   - timezone boundary
   - stale list setelah edit/delete
