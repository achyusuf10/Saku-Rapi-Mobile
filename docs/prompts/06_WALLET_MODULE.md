# Prompt 06 — Wallet Module

Patuh penuh pada semua dokumen SakuRapi.

## Task
Implementasikan modul Wallet.

## Scope
- wallet list
- wallet create
- wallet edit
- wallet delete dengan guard yang aman
- exclude_from_total toggle
- sort order
- wallet summary card
- empty/loading/error state

## Rule penting
- `wallets.balance` tidak boleh diubah langsung dari Flutter untuk perubahan operasional
- `initial_balance` hanya bagian dari setup awal sesuai rule
- currency MVP hanya IDR

## Yang harus kamu lakukan
1. Implementasikan CRUD wallet sesuai schema.
2. Buat validasi form wallet.
3. Sediakan UI list dan form yang clean.
4. Pastikan delete wallet aman terhadap relasi/transaksi existing sesuai dokumen.
5. Sediakan komponen reusable untuk wallet chip/card/selector.
6. Tambahkan localization.

## Output
Berikan:
1. ringkasan rule wallet
2. rencana implementasi
3. file dan kode lengkap
4. test minimum
5. catatan edge case
