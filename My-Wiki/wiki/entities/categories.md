---
title: "Categories"
type: entity
tags: [kategori, expense, income, system, hierarchy, seed, global, user_category_hidden, rpc]
sources: [raw/docs/02_DATABASE.md, raw/docs/plan-revamp-default-categories.md, supabase/migrations/]
created: 2026-04-10
updated: 2026-04-25
---

# Categories

> Halaman ini mendokumentasikan **sistem kategori** di SakuRapi: schema, hierarki, **katalog global** (`user_id` null), preferensi *hide* per user, RPC, file migrasi di repo, dan uji coba Flutter.

---

## Schema: Tabel `categories`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| user_id | uuid nullable FK | `null` = baris **katalog global** (dibagi semua user) |
| name | text not null | nama kategori |
| icon | text not null | fontawesome icon |
| color | text not null | hex color |
| type | text not null | `income`, `expense`, `system` |
| parent_id | uuid nullable FK self | referensi ke parent category |
| is_default | boolean not null default false | flag kategori default (global / milik user) |
| sort_order | integer not null default 0 | urutan tampil |
| created_at | timestamptz | |
| updated_at | timestamptz | |

> **2026-04-25 (migrasi katalog global):** kolom **`categories.is_hidden` di-drop**. Visibility “tersembunyi” untuk kategori bawaan tidak lagi disimpan di `categories`, melainkan lewat tabel `user_category_hidden` + proyeksi di RPC (lihat bawah). Kategori **milik user** tetap bisa disembunyikan lewat alur yang sama (baris di `user_category_hidden` / RPC).

### Tabel `user_category_hidden`

| Kolom | Tipe | Keterangan |
|---|---|---|
| user_id | uuid | pemilik (bagian dari UNIQUE) |
| category_id | uuid FK | kategori yang disembunyikan (UNIQUE berpasangan dengan `user_id`) |

*Hide* kategori **global** (satu `category_id` dipakai bersama) tanpa memutakhirkan baris global: satu baris per (user, category) bila disembunyi.

---

## Tipe Kategori

Sistem kategori SakuRapi terbagi menjadi **3 tipe** utama:

### 1. `expense` — Pengeluaran

Kategori untuk semua jenis transaksi pengeluaran. Digunakan di:
- **Transaction items**: setiap item transaksi expense mereferensi category ini
- **Budgeting**: budget **hanya** boleh terkait dengan category bertipe `expense`
- **Parsing dictionaries**: keyword mapping ke category expense

### 2. `income` — Pemasukan

Kategori untuk semua jenis transaksi pemasukan. Digunakan di:
- **Transaction items**: setiap item transaksi income mereferensi category ini

### 3. `system` — Sistem

Kategori internal yang **tidak bisa diedit/dihapus oleh user**. Hanya digunakan oleh sistem untuk tipe transaksi khusus:
- **Penyesuaian Saldo** — untuk transaksi `adjustment`
- **Transfer ke Aset** — untuk transaksi `transfer_to_asset`

---

## Hierarki Parent-Child

Kategori mendukung **maksimal 2 level** hierarki:

```
Parent Category (level 1)
├── Child Category A (level 2)
├── Child Category B (level 2)
└── Child Category C (level 2)
```

### Aturan Hierarki

1. **Parent dan child harus punya `type` yang sama.** Tidak boleh ada parent `expense` dengan child `income`.
2. **Maksimal 2 level.** Child category tidak boleh punya child lagi (tidak ada grandchild).
3. **Parent budget bisa terpakai oleh child expense.** Jika budget di-set pada parent category, transaksi expense di child category ikut dihitung.

---

## Kepemilikan & Visibility

### `user_id` nullable

- `user_id = NULL` → Kategori **global** (bawaan app, satu set baris bersama). Semua user terautentikasi membacanya (RLS). **Tidak** ada salinan per-user lewat *seed* otomatis; user baru membaca katalog global yang sama.
- `user_id = uuid` → Kategori **milik user** (dibuat/di-CRUD di app). Hanya owner yang mengelola.

### System Categories

- Kategori dengan `type = 'system'` **tidak bisa diedit** oleh user melalui UI maupun API
- Hanya digunakan oleh sistem internal (adjustment dan transfer_to_asset)
- Dilindungi oleh RLS policy

---

## Katalog default (baris global)

Tabel di bawah ini menggambarkan **isi katalog** (nama, warna, hierarki) yang di-*seed* sebagai baris **`user_id` null** — diperbarui pada **revamp 2026-04-19** ([[wiki/sources/plan-revamp-default-categories|Plan: Revamp Kategori Default]]). Setelah migrasi **katalog global 2026-04-25**, pendaftaran user baru **tidak** mem-*insert* salinan kategori per user; `seed_default_categories` dibuat *no-op* (trigger pendaftaran dihapus). *Hidden* bawaan di UI: preferensi per user lewat `user_category_hidden` + `get_user_categories` / `toggle_category_hidden`, bukan kolom `is_hidden` di `categories`.

### Expense (10 parent, 36 child)

| Sort | Parent | Warna | Children |
|---|---|---|---|
| 0 | **Makanan & Minuman** | `#F97316` | Kopi & Minuman, Delivery / Pesan Antar, Restoran & Kafe, Jajan & Camilan |
| 1 | **Kebutuhan Rumah Tangga** | `#F59E0B` | Belanja Dapur / Bahan Makanan, Perlengkapan Rumah, Makan di Luar / Jajan |
| 2 | **Kesehatan & Kebugaran** | `#F87171` | Olahraga / Gym, Suplemen & Nutrisi, Medis / Dokter / Obat, Kesehatan Mental / Terapi |
| 3 | **Transportasi** | `#3B82F6` | Bensin, Tol, Parkir, Transportasi Umum, Ojol, Servis Kendaraan |
| 4 | **Tagihan & Kewajiban** | `#8B5CF6` | Listrik & Air, Internet & Pulsa, Cicilan / Asuransi, Sewa Rumah, KPR |
| 5 | **Teknologi & Edukasi** | `#06B6D4` | Langganan Digital, Kursus, Buku, Server & Hosting |
| 6 | **Keluarga & Sosial** | `#EC4899` | Kebutuhan Pasangan, Kondangan / Donasi, Nongkrong & Sosial, Hewan Peliharaan |
| 7 | **Lain-lain** | `#6B7280` | Biaya Admin / Pajak / Selisih, Pengeluaran Tak Terduga, Tidak Diketahui |
| 8 | **Belanja & Fashion** | `#D946EF` | Pakaian & Aksesori, Sepatu & Tas, Kosmetik & Skincare, Salon & Perawatan Diri |
| 9 | **Hiburan & Hobi** | `#14B8A6` | Bioskop & Konser, Game & Gaming, Hobi & Koleksi, Liburan & Wisata |

### Income (3 parent, 9 child)

| Sort | Parent | Warna | Children |
|---|---|---|---|
| 1 | **Gaji & Pendapatan Utama** | `#10B981` | Gaji Bulanan, Bonus / THR |
| 2 | **Pendapatan Tambahan** | `#0EA5E9` | Pekerjaan Sampingan / Freelance, Hasil Investasi / Dividen, Pencairan Dana, Cashback & Reward, Penjualan Barang / Aset |
| 3 | **Lain-lain** | `#6B7280` | Hadiah / Pemberian |

### System (2 kategori, tanpa child)

| Kategori | Kegunaan |
|---|---|
| **Penyesuaian Saldo** | Digunakan untuk transaksi `adjustment` |
| **Transfer ke Aset** | Digunakan untuk transaksi `transfer_to_asset` (investasi) |

---

## RPC & perilaku API (ringkas)

- **`get_user_categories()`** — mengembalikan kategori yang relevan untuk user saat ini: katalog global + kategori milik user, dengan **`is_hidden`** di JSON hasil **gabungan** `user_category_hidden` + aturan bisnis (bukan kolom `categories.is_hidden`).
- **`toggle_category_hidden(p_category_id, p_is_hidden)`** — mengubah preferensi *hide*; memakai `p_uid := auth.uid()` di PL/pgSQL agar parameter/alias tidak bentrok dengan nama kolom `user_id` (perbaikan migrasi `20260425220000`).

*Parsing dictionary / tabel opsional:* jika tabel terkait parsing tidak ada di lingkungan tertentu, kode server dapat melewati langkah itu (*no-op*) agar migrasi tetap aman.

---

## File migrasi (repo `supabase/migrations/`)

Urutan **katalog global** + perbaikan (April 2026):

| File | Isi singkat |
|------|-------------|
| `20260425092604_category_globalize_is_hidden_v1.sql` | *No-op* (placeholder; rantai penuh di 01–03) |
| `20260425092813_category_globalize_01_seed_remap.sql` | Remap *seed* ke baris global, konsolidasi duplikat per user |
| `20260425092819_category_globalize_02_fk_hidden.sql` | FK & `user_category_hidden` |
| `20260425092826_category_globalize_03_cleanup_rpc.sql` | RPC, drop kolom `categories.is_hidden`, pembersihan trigger *seed* |
| `20260425220000_fix_toggle_category_hidden_plpgsql_user_id.sql` | Perbaiki ambiguitas `user_id` / `p_uid` di `toggle_category_hidden` |
| `20260425230000_category_globalize_03_prod_retry.sql` | **Prod:** *retry* bagian migrasi 03 (di prod skrip sebelumnya gagal karena bug `format` dengan alias relasi; diperbaiki memakai **`r.relname`**) |

Skrip operasional (opsional, di luar migrasi): `supabase/ops/apply_production_category_migrations.sql`, `supabase/ops/prod_category_state_audit.sql` — bantu audit/urutan penerapan manual jika perlu.

---

## Pengujian (Flutter)

```text
flutter test test/features/category/
```

(*Dari root repositori app.*)

Suite fitur kategori (hingga 2026-04) mencakup m.a. *parsing* respons `toggle_category_hidden` (bentuk `List` vs `Map`), dan asumsi `user_id` null pada baris global. Jalankan pula `dart analyze` bila mengubah kontrak RPC/model.

---

## Verifikasi DB (MCP / dashboard)

- **Dev** — *project* default untuk alat `mcp_supabase_*` (lihat `.cursor/mcp.json`).
- **Produksi** — gunakan alat **`mcp_supabase-prod_*`** (bukan *default*); *ref* prod berbeda dari dev.

Hindari *merge* hasil uji dev ke asumsi prod tanpa cek skema/urutan migrasi.

---

## Penggunaan di Fitur Lain

### Budgeting
- Budget **hanya** boleh mereferensi category bertipe `expense`
- Parent budget mencakup expense dari child categories
- Lihat: [[wiki/entities/budgeting|Budgeting]]

### Transaction Items
- Setiap `transaction_items` memiliki `category_id` (nullable FK)
- Wajib diisi untuk transaksi income/expense biasa
- Lihat: [[wiki/entities/transaksi|Transaksi]]

---

## Halaman Terkait

- [[wiki/entities/database-schema|Database Schema]]
- [[wiki/entities/transaksi|Transaksi]]
- [[wiki/entities/budgeting|Budgeting]]
- [[wiki/entities/settings|Settings]]
- [[wiki/sources/plan-revamp-default-categories|Plan: Revamp Kategori Default]] (konten nama/warna *seed* 2026-04-19)
