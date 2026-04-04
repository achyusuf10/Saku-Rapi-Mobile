# Prompt 07 — Transaction Core Ledger

Patuh penuh pada semua dokumen SakuRapi.

## Task
Implementasikan modul transaksi inti SakuRapi.

## Scope
- transaction form manual
- type: `income`, `expense`, `transfer`, `debt`, `loan`, `adjustment`
- minimal 1 transaction_item
- create/update/delete transaction via jalur aman (RPC jika perlu)
- validation sesuai type
- transaction detail page
- reusable transaction form sections
- attachment field placeholder jika memang belum penuh

## Yang harus kamu lakukan
1. Implementasikan model dan flow transaksi inti.
2. Pisahkan form behavior berdasarkan `transaction.type`.
3. Terapkan rule:
   - transfer perlu source dan destination wallet
   - debt/loan perlu person info jika dokumen mensyaratkan
   - settlement/report rules harus tetap aman
4. Pastikan submit anti double-submit.
5. Gunakan jalur atomik untuk write kompleks.
6. Pastikan `sum(items) == total`.
7. Buat UI yang elegan, modern, simpel, fancy dan mudah digunakan oleh user

## Output
Berikan:
1. matrix rule per transaction type yang kamu terapkan
2. file yang dibuat/diubah
3. kode lengkap per file
4. SQL/RPC tambahan jika diperlukan
5. test minimum
6. edge case:
   - invalid category
   - destination wallet sama dengan source
   - item total mismatch
   - duplicate submit
   - edit/delete transaction yang memengaruhi saldo
