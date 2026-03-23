# Prompt 05 — Category System and Seeding

Patuh penuh pada semua dokumen SakuRapi.

## Task
Implementasikan sistem kategori parent-child untuk income dan expense.

## Scope
- model kategori
- category repository
- load categories per type
- parent-child grouping max 2 level
- system/default categories bila relevan
- user categories CRUD dasar
- category picker foundation untuk form transaksi
- seed handling sesuai dokumen

## Yang harus kamu lakukan
1. Implementasikan flow baca kategori berdasarkan type.
2. Buat dukungan parent-child max 2 level.
3. Buat validasi agar struktur kategori tetap sesuai constraint.
4. Siapkan picker UI/component reusable.
5. Jika ada default/system category strategy, implementasikan sesuai dokumen.
6. Pisahkan category logic dari widget.

## Output
Berikan:
1. ringkasan rule kategori
2. daftar file
3. kode lengkap
4. SQL tambahan jika diperlukan
5. test minimum
6. edge case:
   - empty categories
   - hidden category
   - parent invalid
   - duplicate name per konteks yang relevan
