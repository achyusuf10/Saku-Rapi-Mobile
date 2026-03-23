# Prompt 14 — Budgeting Module

Patuh penuh pada semua dokumen SakuRapi.

## Task
Implementasikan modul budgeting.

## Scope
- budget per kategori expense sesuai PRD
- parent-child budget behavior
- period budget
- budget progress UI
- budget alert state dasar
- create/edit/delete budget
- penggunaan budget berdasarkan transaksi yang eligible

## Rule penting
- budget hanya menghitung expense non-settlement
- jangan masukkan transfer atau transfer_to_asset sebagai usage budget

## Yang harus kamu lakukan
1. Implementasikan model, query, dan UI budgeting.
2. Tegaskan aturan kategori expense yang eligible.
3. Hitung usage dengan benar berdasarkan rule ledger/report.
4. Sediakan komponen progress/ringkasan budget yang reusable.
5. Pastikan perubahan transaksi tercermin pada budget state saat refresh.

## Output
Berikan:
1. rule budgeting yang diterapkan
2. file dan kode lengkap
3. SQL/query/RPC tambahan bila perlu
4. test minimum
5. edge case:
   - over budget
   - no budget
   - hidden category
   - settlement transaction tidak boleh ikut usage
