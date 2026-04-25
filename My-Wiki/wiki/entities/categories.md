---
title: "Categories"
type: entity
tags: [kategori, expense, income, system, hierarchy, seed]
sources: [raw/docs/02_DATABASE.md, raw/docs/plan-revamp-default-categories.md]
created: 2026-04-10
updated: 2026-04-19
---

# Categories

> Halaman ini mendokumentasikan **sistem kategori** di SakuRapi — mulai dari schema tabel, hierarki tipe, aturan parent-child, hingga daftar seed default yang otomatis diberikan ke user baru.

---

## Schema: Tabel `categories`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| user_id | uuid nullable FK | null = global/default category |
| name | text not null | nama kategori |
| icon | text not null | fontawesome icon |
| color | text not null | hex color |
| type | text not null | `income`, `expense`, `system` |
| parent_id | uuid nullable FK self | referensi ke parent category |
| is_default | boolean not null default false | flag kategori default |
| is_hidden | boolean not null default false | flag hidden dari UI |
| sort_order | integer not null default 0 | urutan tampil |
| created_at | timestamptz | |
| updated_at | timestamptz | |

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

- `user_id = NULL` → Kategori **global/default** yang bisa dibaca oleh semua user terautentikasi (via RLS). Ini adalah kategori seed bawaan.
- `user_id = uuid` → Kategori **milik user spesifik**. Hanya bisa diakses oleh owner.

### System Categories

- Kategori dengan `type = 'system'` **tidak bisa diedit** oleh user melalui UI maupun API
- Hanya digunakan oleh sistem internal (adjustment dan transfer_to_asset)
- Dilindungi oleh RLS policy

---

## Default Seed Categories

Ketika user baru mendaftar, trigger `seed_default_categories()` otomatis membuat kategori-kategori berikut:

> ⚠️ **Revamped 2026-04-19** — Lihat [[wiki/sources/plan-revamp-default-categories|Plan: Revamp Kategori Default]] untuk ringkasan perubahan.

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
