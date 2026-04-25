# Plan: Perbaikan & Penambahan Kategori Default

> **Status:** Disetujui — siap implementasi
> **Tanggal:** 2026-04-19
> **Scope:** UPDATE + INSERT ke tabel `categories` (semua user existing) + update `seed_default_categories()`

---

## Kondisi Saat Ini

### Expense — 7 Parent + 21 Child (is_default = true)

| # | Parent | Color | Icon |
|---|--------|-------|------|
| 1 | Kebutuhan Rumah Tangga | `#F59E0B` | house |
| 2 | Kesehatan & Kebugaran | `#EF4444` | heartPulse |
| 3 | Transportasi | `#3B82F6` | car |
| 4 | Tagihan & Kewajiban | `#8B5CF6` | fileInvoiceDollar |
| 5 | Teknologi & Edukasi | `#06B6D4` | laptop |
| 6 | Keluarga & Sosial | `#EC4899` | peopleGroup |
| 7 | Lain-lain | `#6B7280` | ellipsis |

**Children per parent:**
- **Kebutuhan RT**: Belanja Dapur/Bahan Makanan, Perlengkapan Rumah, Makan di Luar/Jajan
- **Kesehatan**: Olahraga/Gym, Suplemen & Nutrisi, Medis/Dokter/Obat
- **Transportasi**: Bensin, Tol, Parkir, Transportasi Umum, Ojol, Servis Kendaraan
- **Tagihan**: Listrik & Air, Internet & Pulsa, Cicilan/Asuransi
- **Teknologi & Edukasi**: Langganan Digital, Kursus, Buku, Server & Hosting
- **Keluarga & Sosial**: Kebutuhan Pasangan, Kondangan/Donasi, Nongkrong/Hiburan
- **Lain-lain**: Biaya Admin/Pajak/Selisih, Pengeluaran Tak Terduga, Pengeluaran yang tidak diketahui

### Income — 3 Parent + 7 Child

| # | Parent | Color | Icon |
|---|--------|-------|------|
| 1 | Gaji & Pendapatan Utama | `#10B981` | briefcase |
| 2 | Pendapatan Tambahan | `#10B981` | circlePlus |
| 3 | Lain-lain | `#6B7280` | ellipsis |

**Children per parent:**
- **Gaji**: Gaji Bulanan, Bonus/THR
- **Pendapatan Tambahan**: Pekerjaan Sampingan/Freelance, Hasil Investasi/Dividen, Pencairan Dana
- **Lain-lain**: Hadiah/Pemberian

### System — 2 kategori
- Penyesuaian Saldo, Transfer ke Aset

---

## Masalah yang Ditemukan

### 1. Warna Duplikat

| Masalah | Detail |
|---------|--------|
| **Income: 2 parent warna identik** | `Gaji & Pendapatan Utama` dan `Pendapatan Tambahan` keduanya `#10B981` — di list picker terlihat sama persis |
| **Kesehatan vs Keluarga & Sosial mirip** | `#EF4444` (merah) vs `#EC4899` (pink gelap) — terlalu dekat satu sama lain |
| **Semua child income satu warna** | Semua 7 sub-kategori income warna `#10B981` identik — sulit dibedakan grupnya |

### 2. Kategori Penting yang Tidak Ada

| Kategori Hilang | Keterangan |
|-----------------|-----------|
| **Makanan & Minuman (parent)** | Pengeluaran terbesar rata-rata orang Indonesia. Sekarang hanya ada "Makan di Luar/Jajan" tersembunyi di bawah Kebutuhan RT |
| **Belanja & Fashion** | Tidak ada parent untuk pakaian, aksesori, sepatu — sangat umum dipakai |
| **Perawatan Diri / Kecantikan** | Salon, skincare, barbershop — tidak ada sama sekali |
| **Hiburan & Hobi** | "Nongkrong/Hiburan" tersembunyi di bawah Keluarga & Sosial. Tidak ada: bioskop, game, liburan, hobi |
| **Sewa / Kos / KPR** | Cicilan dan Asuransi digabung dalam satu item — padahal sewa kos/rumah sangat umum |
| **Cashback & Reward (income)** | Income umum dari e-wallet, kartu kredit — belum default |
| **Penjualan Barang / Aset (income)** | Belum ada default |

### 3. Naming yang Bisa Disempurnakan

| Sekarang | Masalah |
|----------|---------|
| "Pengeluaran yang tidak diketahui" | Terlalu panjang, mirip dengan "Pengeluaran Tak Terduga" yang ada di sebelahnya |

---

## Rencana Perubahan

### A. EDIT Warna (UPDATE — tidak mengubah nama, hanya warna)

**Tujuan:** Hilangkan duplikat warna di income

| Kategori | Warna Lama | Warna Baru | Alasan |
|----------|-----------|-----------|--------|
| `Pendapatan Tambahan` (parent) | `#10B981` | `#0EA5E9` | Beda dengan Gaji yang tetap hijau |
| `Pekerjaan Sampingan / Freelance` (child) | `#10B981` | `#0EA5E9` | Ikut parent baru |
| `Hasil Investasi / Dividen` (child) | `#10B981` | `#0EA5E9` | Ikut parent baru |
| `Pencairan Dana` (child) | `#10B981` | `#0EA5E9` | Ikut parent baru |
| `Kesehatan & Kebugaran` (parent) | `#EF4444` | `#F87171` | Sedikit lebih terang, beda dengan Keluarga & Sosial |
| `Olahraga / Gym` (child) | `#EF4444` | `#F87171` | Ikut parent baru |
| `Suplemen & Nutrisi` (child) | `#EF4444` | `#F87171` | Ikut parent baru |
| `Medis / Dokter / Obat` (child) | `#EF4444` | `#F87171` | Ikut parent baru |

> Catatan: `#F87171` adalah Red-400 (lebih terang dari EF4444 Red-500), tetap dibaca "merah kesehatan" tapi tidak confuse dengan pink EC4899.

### B. EDIT Nama (UPDATE)

| Kategori | Nama Lama | Nama Baru | Alasan |
|----------|-----------|-----------|--------|
| Lain-lain > expense child | "Pengeluaran yang tidak diketahui" | "Tidak Diketahui" | Lebih ringkas, tidak redundan |
| Keluarga & Sosial > child | "Nongkrong / Hiburan" | "Nongkrong & Sosial" | "Hiburan" pindah ke parent sendiri |

### C. TAMBAH Parent Baru (INSERT)

#### C1. Makanan & Minuman
- **Warna:** `#F97316` (Orange — berbeda dengan Amber `#F59E0B` Kebutuhan RT)
- **Icon:** `utensils`
- **Sort order:** `0` (ditampilkan paling awal — paling sering dipakai)

**Sub-kategori baru:**
| Nama | Icon | Sort |
|------|------|------|
| Kopi & Minuman | `mugHot` | 1 |
| Delivery / Pesan Antar | `cartShopping` | 2 |
| Restoran & Kafe | `store` | 3 |
| Jajan & Camilan | `cookieBite` | 4 |

#### C2. Belanja & Fashion
- **Warna:** `#D946EF` (Fuchsia — berbeda dari pink `#EC4899` Keluarga & Sosial)
- **Icon:** `bagShopping`
- **Sort order:** `8` (setelah Keluarga & Sosial, sebelum Lain-lain)

**Sub-kategori baru:**
| Nama | Icon | Sort |
|------|------|------|
| Pakaian & Aksesori | `shirt` | 1 |
| Sepatu & Tas | `shoePrints` | 2 |
| Kosmetik & Skincare | `spa` | 3 |
| Salon & Perawatan Diri | `scissors` | 4 |

#### C3. Hiburan & Hobi
- **Warna:** `#14B8A6` (Teal — berbeda dari Cyan `#06B6D4` Teknologi)
- **Icon:** `masksTheater`
- **Sort order:** `9`

**Sub-kategori baru:**
| Nama | Icon | Sort |
|------|------|------|
| Bioskop & Konser | `film` | 1 |
| Game & Gaming | `gamepad` | 2 |
| Hobi & Koleksi | `puzzlePiece` | 3 |
| Liburan & Wisata | `planeUp` | 4 |

### D. TAMBAH Child ke Parent yang Sudah Ada (INSERT)

#### D1. Tagihan & Kewajiban — tambah 2 child

| Nama | Icon | Color | Sort |
|------|------|-------|------|
| Sewa Rumah | `house` | `#8B5CF6` | 4 (setelah Cicilan/Asuransi) |
| KPR | `building` | `#8B5CF6` | 5 |

> Dipisah karena semantiknya beda: sewa/kontrak = pengeluaran rutin murni, KPR = cicilan aset. Keduanya tetap terpisah dari "Cicilan / Asuransi" yang lebih untuk cicilan barang & premi.

#### D2. Keluarga & Sosial — tambah 1 child

| Nama | Icon | Color | Sort |
|------|------|-------|------|
| Hewan Peliharaan | `paw` | `#EC4899` | 4 (setelah Nongkrong & Sosial) |

#### D3. Kesehatan & Kebugaran — tambah 1 child

| Nama | Icon | Color | Sort |
|------|------|-------|------|
| Kesehatan Mental / Terapi | `brain` | `#F87171` | 4 |

#### D4. Pendapatan Tambahan (income) — tambah 2 child

| Nama | Icon | Color | Sort |
|------|------|-------|------|
| Cashback & Reward | `percent` | `#0EA5E9` | 4 |
| Penjualan Barang / Aset | `tag` | `#0EA5E9` | 5 |

---

## Palette Warna Final (Setelah Perubahan)

### Expense
| Parent | Warna |
|--------|-------|
| **Makanan & Minuman** *(baru)* | `#F97316` 🟠 |
| Kebutuhan Rumah Tangga | `#F59E0B` 🟡 |
| **Kesehatan & Kebugaran** *(edit)* | `#F87171` 🔴 |
| Transportasi | `#3B82F6` 🔵 |
| Tagihan & Kewajiban | `#8B5CF6` 🟣 |
| Teknologi & Edukasi | `#06B6D4` 🩵 |
| Keluarga & Sosial | `#EC4899` 🩷 |
| **Belanja & Fashion** *(baru)* | `#D946EF` 💜 |
| **Hiburan & Hobi** *(baru)* | `#14B8A6` 🟢 |
| Lain-lain | `#6B7280` ⬜ |

→ 10 warna unik, tidak ada yang duplikat atau terlalu mirip.

### Income
| Parent | Warna |
|--------|-------|
| Gaji & Pendapatan Utama | `#10B981` 🟢 (tetap) |
| **Pendapatan Tambahan** *(edit)* | `#0EA5E9` 🔵 |
| Lain-lain | `#6B7280` ⬜ |

---

## Ringkasan Jumlah Perubahan

| Tipe | Jumlah |
|------|--------|
| UPDATE warna | 8 rows per user |
| UPDATE nama | 2 rows per user |
| INSERT parent baru | 3 rows per user |
| INSERT child baru | 4+4+4+2+1+1+2+2 = **12 rows per user** |
| **Total INSERT** | **15 rows per user** |
| Update `seed_default_categories()` | 1 fungsi Supabase |

> Breakdown child baru: Makanan(4) + Belanja&Fashion(4) + Hiburan&Hobi(4) + Sewa Rumah+KPR(2) + Hewan Peliharaan(1) + Kesehatan Mental(1) + Cashback+Penjualan(2)

### Expense setelah perubahan: **10 parent, 36 child**
### Income setelah perubahan: **3 parent, 9 child**

---

## Catatan Implementasi

### Cara UPDATE ke existing users
Karena setiap user punya copy kategori sendiri, UPDATE dan INSERT harus dilakukan untuk semua user yang punya `is_default = true`:

```sql
-- Contoh UPDATE warna
UPDATE public.categories
SET color = '#0EA5E9'
WHERE name = 'Pendapatan Tambahan'
  AND type = 'income'
  AND is_default = true;
```

### Cara INSERT untuk semua existing users
INSERT harus loop per user yang sudah punya set default:

```sql
-- Contoh: insert parent baru untuk semua user yang sudah punya default categories
INSERT INTO public.categories (user_id, name, icon, color, type, is_default, sort_order, parent_id)
SELECT DISTINCT c.user_id, 'Makanan & Minuman', 'utensils', '#F97316', 'expense', true, 0, NULL
FROM public.categories c
WHERE c.is_default = true AND c.type = 'expense';
```

Child harus di-insert dengan referensi `parent_id` yang baru dibuat — perlu `WITH` CTE atau loop per user.

### Update seed function
Fungsi `seed_default_categories()` harus diupdate agar user baru dapat semua kategori baru. Ini adalah perubahan DDL (CREATE OR REPLACE FUNCTION).

---

## Analisis Dampak ke AI Parse Edge Function

**File:** `supabase/functions/ai-parse/index.ts`

### Kesimpulan: Tidak perlu perubahan kode

AI Parse sudah menggunakan **dynamic category mapping** — Flutter kirim daftar kategori user ke edge function, lalu di-mapping ke short ID (`e1`, `e2`, ..., `i1`, `i2`, ...) secara runtime. Kategori baru otomatis muncul di mapping begitu user punya data kategori baru di DB.

### Detail analisis

| Area | Status | Alasan |
|------|--------|--------|
| `buildIdMapping()` | ✅ Tidak perlu diubah | Dynamic — mapping dibangun dari array categories yang dikirim Flutter |
| `buildTextSystemPrompt()` few-shot examples | ✅ Makin akurat | Contoh `e1` untuk makan — setelah perubahan, "Makanan & Minuman" (sort_order=0) jadi `e1` sehingga contoh kode makin sesuai |
| `buildOcrSystemPrompt()` few-shot examples | ✅ Makin akurat | Contoh `e1` untuk item di Indomaret (makanan) — sama seperti di atas |
| `categoryKeyword` fallback values | ✅ Tidak perlu diubah | Free-text field ("makan", "belanja", dll) — tidak bergantung daftar kategori |
| `reverseMapResponse()` | ✅ Tidak perlu diubah | Reverse map berdasarkan mapping yang dibangun runtime |
| `MAX_CATEGORIES = 200` | ✅ Cukup | Setelah penambahan: max ~46 expense + 9 income + 2 system = ~57 kategori per user. Jauh di bawah 200. |

### Catatan untuk Flutter side

Flutter sudah mengirim categories dinamis ke AI Parse. Pastikan saat mengambil kategori untuk dikirim ke AI Parse, query-nya include `is_default = true` dan kategori baru (insert baru) — ini sudah otomatis karena mengambil dari DB per user, bukan hardcoded.
