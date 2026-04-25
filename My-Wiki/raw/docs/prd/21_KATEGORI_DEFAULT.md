# 21. Kategori Default

[← External API](20_EXTERNAL_API.md) · [Index](00_INDEX.md) · [Edge Cases →](22_EDGE_CASES.md)

> **2026-04 (katalog global):** isi tabel bawaan = **baris global**; pendaftaran user **tidak** mem-*trigger* *insert* kategori; *hide* lewat `user_category_hidden` + RPC. Rincian: `My-Wiki/wiki/entities/categories.md`.

---

## 21.1. Expense (Pengeluaran)

| Parent | Children |
|---|---|
| Kebutuhan Rumah Tangga | Belanja Dapur / Bahan Makanan, Perlengkapan Rumah, Makan di Luar / Jajan |
| Kesehatan & Kebugaran | Olahraga / Gym, Suplemen & Nutrisi, Medis / Dokter / Obat |
| Transportasi | Bensin, Tol, Parkir, Transportasi Umum, Ojol, Servis Kendaraan |
| Tagihan & Kewajiban | Listrik & Air, Internet & Pulsa, Cicilan / Asuransi |
| Teknologi & Edukasi | Langganan Digital, Kursus, Buku, Server & Hosting |
| Keluarga & Sosial | Kebutuhan Pasangan, Kondangan / Donasi, Nongkrong / Hiburan |
| Lain-lain | Biaya Admin / Pajak / Selisih, Pengeluaran Tak Terduga, Pengeluaran yang tidak diketahui |

## 21.2. Income (Pemasukan)

| Parent | Children |
|---|---|
| Gaji & Pendapatan Utama | Gaji Bulanan, Bonus / THR |
| Pendapatan Tambahan | Pekerjaan Sampingan / Freelance, Hasil Investasi / Dividen, Pencairan Dana |
| Lain-lain | Hadiah / Pemberian |

## 21.3. System (Internal)

| Kategori | Kegunaan |
|---|---|
| Penyesuaian Saldo | Untuk transaksi `adjustment` |
| Transfer ke Aset | Untuk transaksi `transfer_to_asset` |

### Flowchart: Default Category Seeding

```mermaid
flowchart TD
    A([User terautentikasi]) --> B["Baca katalog (get_user_categories)\nbaris user_id = null"]
    B --> C["Kategori tampil + is_hidden (proyeksi)"]
    C --> D["User bisa:\n• Tambah custom\n• Sembunyi bawaan (user_category_hidden + toggle RPC)\n• Default tidak hard-delete"]

    style C fill:#2d6a4f,color:#fff
```
> *Diagram lama* per *trigger* *seed* + *insert* per user disederhanakan pada *katalog global* (Apr 2026).

---

[← External API](20_EXTERNAL_API.md) · [Index](00_INDEX.md) · [Edge Cases →](22_EDGE_CASES.md)
