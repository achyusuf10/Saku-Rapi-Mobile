# Prompt 17 — Investment and Wealth

Patuh penuh pada semua dokumen SakuRapi.

## Task
Implementasikan modul investasi / wealth management dasar.

## Scope
- asset list
- create/edit investment
- buy/add position flow sesuai PRD
- integrasi dengan transaksi `transfer_to_asset` bila relevan
- portfolio summary dasar
- valuation refresh abstraction
- chart/summary ringan bila diminta PRD

## Rule penting
- hindari double deduction saldo
- perubahan saldo wallet yang terkait investasi harus tetap audit-able dari ledger transaksi
- jangan melanggar rule report/budget

## Yang harus kamu lakukan
1. Implementasikan model dan UI investasi.
2. Pastikan flow potong dari wallet mengikuti rule ledger tunggal.
3. Jika ada market price fetch, buat abstraction aman melalui backend/service sesuai rule.
4. Jelaskan dengan tegas bagaimana kaitan investasi dengan transaksi ledger.

## Output
Berikan:
1. accounting flow investasi yang diterapkan
2. file dan kode lengkap
3. SQL/RPC tambahan bila perlu
4. test minimum
5. edge case:
   - double submit
   - edit data investasi
   - wallet balance insufficient
   - valuation fetch gagal
