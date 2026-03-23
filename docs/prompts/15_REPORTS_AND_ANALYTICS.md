# Prompt 15 — Reports and Analytics

Patuh penuh pada semua dokumen SakuRapi.

## Task
Implementasikan visual reports dan analytics dasar.

## Scope
- ringkasan income vs expense
- breakdown kategori
- period selector
- chart data adapter
- daftar insight ringan sesuai PRD
- empty/loading/error state

## Rule penting
- transfer bukan expense
- transfer_to_asset bukan expense
- settlement hutang/piutang bukan income/expense operasional report

## Yang harus kamu lakukan
1. Implementasikan layer query/agregasi report.
2. Pastikan semua rule exclusion report diterapkan.
3. Siapkan adapter data untuk chart/widget.
4. Buat UI report yang modular dan mudah dibaca.
5. Jangan letakkan kalkulasi report di widget.

## Output
Berikan:
1. rule report inclusion/exclusion yang kamu pakai
2. file dan kode lengkap
3. test minimum
4. edge case:
   - period kosong
   - data sangat sedikit
   - category deleted/hidden
   - mismatch karena transaction type exclusion
