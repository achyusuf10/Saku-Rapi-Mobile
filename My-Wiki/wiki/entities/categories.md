---
title: "Categories"
type: entity
tags: [kategori, expense, income, system, hierarchy, seed]
sources: [raw/docs/02_DATABASE.md]
created: 2026-04-10
updated: 2026-04-10
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

### Expense (7 parent, 25 child)

| Parent | Children |
|---|---|
| **Kebutuhan Rumah Tangga** | Belanja Dapur / Bahan Makanan, Perlengkapan Rumah, Makan di Luar / Jajan |
| **Kesehatan & Kebugaran** | Olahraga / Gym, Suplemen & Nutrisi, Medis / Dokter / Obat |
| **Transportasi** | Bensin, Tol, Parkir, Transportasi Umum, Ojol, Servis Kendaraan |
| **Tagihan & Kewajiban** | Listrik & Air, Internet & Pulsa, Cicilan / Asuransi |
| **Teknologi & Edukasi** | Langganan Digital, Kursus, Buku, Server & Hosting |
| **Keluarga & Sosial** | Kebutuhan Pasangan, Kondangan / Donasi, Nongkrong / Hiburan |
| **Lain-lain** | Biaya Admin / Pajak / Selisih, Pengeluaran Tak Terduga, Pengeluaran yang tidak diketahui |

### Income (3 parent, 6 child)

| Parent | Children |
|---|---|
| **Gaji & Pendapatan Utama** | Gaji Bulanan, Bonus / THR |
| **Pendapatan Tambahan** | Pekerjaan Sampingan / Freelance, Hasil Investasi / Dividen, Pencairan Dana |
| **Lain-lain** | Hadiah / Pemberian |

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

### Parsing Dictionaries
- Tabel `parsing_dictionaries` memetakan keyword ke `category_id`
- Digunakan oleh fitur AI/OCR untuk auto-suggest kategori
- Keyword disimpan lowercase

---

## Halaman Terkait

- [[wiki/entities/database-schema|Database Schema]]
- [[wiki/entities/transaksi|Transaksi]]
- [[wiki/entities/budgeting|Budgeting]]
- [[wiki/entities/settings|Settings]]
