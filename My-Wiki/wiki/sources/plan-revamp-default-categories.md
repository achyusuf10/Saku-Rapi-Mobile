---
title: "Plan: Revamp Kategori Default"
type: source
tags: [kategori, seed, expense, income, migration, warna, revamp]
sources: [raw/docs/plan-revamp-default-categories.md]
created: 2026-04-19
updated: 2026-04-25
---

# Plan: Revamp Kategori Default

> **Status:** ✅ Implemented — Dev & Prod (2026-04-19)
> **Migration:** `revamp_default_categories` applied ke kedua environment
> **Scope (per run 2026-04-19):** UPDATE/INSERT ke baris `categories` + *update* fungsi `seed_default_categories()` (waktu itu rencananya: user baru **mendapat** *copy* lewat *seed* — sebelum *katalog global* menyederhanakan alur)

> **Pasca katalog global (2026-04-25):** satu set baris **global** (`user_id` null), `seed_default_categories` *no-op*, trigger pendaftaran dihapun, *hide* lewat `user_category_hidden` + RPC. Lihat [[wiki/entities/categories|Categories]].

## Masalah yang Diperbaiki

1. **Warna duplikat income** — `Gaji & Pendapatan Utama` dan `Pendapatan Tambahan` keduanya `#10B981`, tidak bisa dibedakan di list picker
2. **Kategori penting tidak ada** — Makanan & Minuman, Belanja & Fashion, Hiburan & Hobi tidak punya parent sendiri
3. **Naming tidak konsisten** — "Pengeluaran yang tidak diketahui" terlalu panjang dan redundan dengan "Pengeluaran Tak Terduga"
4. **Sewa/KPR tidak ada** — "Cicilan / Asuransi" tidak cukup mewakili biaya tempat tinggal

---

## Perubahan yang Dilakukan

### A. UPDATE Warna

| Kategori | Lama | Baru | Alasan |
|---|---|---|---|
| `Pendapatan Tambahan` (parent + 3 child) | `#10B981` | `#0EA5E9` | Beda dari Gaji yang tetap hijau |
| `Kesehatan & Kebugaran` (parent + 3 child) | `#EF4444` | `#F87171` | Red-400, beda dari pink `#EC4899` Keluarga & Sosial |

### B. UPDATE Nama

| Nama Lama | Nama Baru | Alasan |
|---|---|---|
| "Pengeluaran yang tidak diketahui" | "Tidak Diketahui" | Lebih ringkas |
| "Nongkrong / Hiburan" | "Nongkrong & Sosial" | Hiburan pindah ke parent baru |

### C. INSERT Parent Baru (3 parent)

| Parent | Warna | Icon | Sort |
|---|---|---|---|
| **Makanan & Minuman** | `#F97316` 🟠 | `utensils` | 0 (tampil pertama) |
| **Belanja & Fashion** | `#D946EF` 💜 | `bagShopping` | 8 |
| **Hiburan & Hobi** | `#14B8A6` 🟢 | `masksTheater` | 9 |

### D. INSERT Children Baru (12 child)

**Makanan & Minuman (4 child):**
- Kopi & Minuman (`mugHot`, sort 1)
- Delivery / Pesan Antar (`cartShopping`, sort 2)
- Restoran & Kafe (`store`, sort 3)
- Jajan & Camilan (`cookieBite`, sort 4)

**Belanja & Fashion (4 child):**
- Pakaian & Aksesori (`shirt`, sort 1)
- Sepatu & Tas (`shoePrints`, sort 2)
- Kosmetik & Skincare (`spa`, sort 3)
- Salon & Perawatan Diri (`scissors`, sort 4)

**Hiburan & Hobi (4 child):**
- Bioskop & Konser (`film`, sort 1)
- Game & Gaming (`gamepad`, sort 2)
- Hobi & Koleksi (`puzzlePiece`, sort 3)
- Liburan & Wisata (`planeUp`, sort 4)

**Tagihan & Kewajiban (2 child baru, sort 4–5):**
- Sewa Rumah (`house`, sort 4, `#8B5CF6`)
- KPR (`building`, sort 5, `#8B5CF6`)

**Keluarga & Sosial (1 child baru, sort 4):**
- Hewan Peliharaan (`paw`, sort 4, `#EC4899`)

**Kesehatan & Kebugaran (1 child baru, sort 4):**
- Kesehatan Mental / Terapi (`brain`, sort 4, `#F87171`)

**Pendapatan Tambahan / income (2 child baru, sort 4–5):**
- Cashback & Reward (`percent`, sort 4, `#0EA5E9`)
- Penjualan Barang / Aset (`tag`, sort 5, `#0EA5E9`)

---

## Palette Warna Final

### Expense Parents (10 warna unik)

| Sort | Parent | Warna |
|---|---|---|
| 0 | Makanan & Minuman | `#F97316` 🟠 |
| 1 | Kebutuhan Rumah Tangga | `#F59E0B` 🟡 |
| 2 | Kesehatan & Kebugaran | `#F87171` 🔴 |
| 3 | Transportasi | `#3B82F6` 🔵 |
| 4 | Tagihan & Kewajiban | `#8B5CF6` 🟣 |
| 5 | Teknologi & Edukasi | `#06B6D4` 🩵 |
| 6 | Keluarga & Sosial | `#EC4899` 🩷 |
| 7 | Lain-lain | `#6B7280` ⬜ |
| 8 | Belanja & Fashion | `#D946EF` 💜 |
| 9 | Hiburan & Hobi | `#14B8A6` 🟢 |

### Income Parents (3 warna unik)

| Sort | Parent | Warna |
|---|---|---|
| 1 | Gaji & Pendapatan Utama | `#10B981` 🟢 |
| 2 | Pendapatan Tambahan | `#0EA5E9` 🔵 |
| 3 | Lain-lain | `#6B7280` ⬜ |

---

## Ringkasan Jumlah

| | Sebelum | Sesudah |
|---|---|---|
| Expense parent | 7 | 10 |
| Expense child | 21 | 36 |
| Income parent | 3 | 3 |
| Income child | 6 | 9 |
| System | 2 | 2 |

---

## Implementasi Teknis

### SQL Migration
- Pattern UPDATE: `WHERE name = '...' AND type = '...' AND is_default = true` (berlaku ke semua user)
- Pattern INSERT parent baru: CTE `WITH inserted AS (INSERT ... RETURNING id, user_id)` → CROSS JOIN untuk children
- Pattern INSERT child ke parent lama: `SELECT p.user_id ... FROM categories p CROSS JOIN (VALUES ...) sub WHERE p.name = '...' AND NOT EXISTS (...)` — idempotent
- Semua INSERT memiliki guard `NOT EXISTS` sehingga bisa dijalankan ulang tanpa duplikasi

### Seed Function (perilaku saat migrasi 2026-04-19)

- `seed_default_categories()` di-*replace* agar isi fungsi selaras **60** kategori bawaan (struktur parent/child & variabel `v_makanan` / `v_belanja` / `v_hiburan`).

**Setelah migrasi katalog global (2026-04-25):** fungsi dijadikan *no-op*; **tidak** ada lagi *insert* 60 baris per pendaftaran. Isi tabel bawaan = **katalog** di `categories` (baris global); lihat entitas *Categories*.

### AI Parse Impact
- **Tidak ada perubahan ke `ai-parse/index.ts`** — mapping kategori bersifat dynamic (dikirim dari Flutter per request)
- Dengan `Makanan & Minuman` di sort_order=0, ia menjadi `e1` di short ID mapping — sesuai dengan few-shot examples yang sudah ada
- `MAX_CATEGORIES = 200` masih cukup: daftar pilihan berasal dari katalog (bukan 60 *salinan* per *user*).

---

## Halaman Terkait

- [[wiki/entities/categories|Categories]] — daftar lengkap kategori default terbaru
- [[wiki/entities/budgeting|Budgeting]] — kategori expense dipakai sebagai filter budget
- [[wiki/entities/transaksi|Transaksi]] — category_id di transaction_items
