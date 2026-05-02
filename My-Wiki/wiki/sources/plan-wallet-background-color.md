---
title: "Rencana: Background color dompet (wallet)"
type: source
tags: [wallet, database, ui, supabase, dev]
env: dev-first
created: 2026-05-02
updated: 2026-05-02
---

# Rencana: Background color pada wallet

Dokumen ini merencanakan penambahan **warna latar (background)** khusus untuk area icon dompet, terpisah dari **warna icon** (`color`) yang sudah ada. **Implementasi Flutter dilakukan setelah dokumen ini disetujui**; tahap database untuk **environment dev** dapat diterapkan lebih dulu lewat MCP Supabase.

## Lingkungan

| Lingkungan | Keterangan |
|------------|------------|
| **Dev (Supabase MCP: `supabase`)** | Migrasi kolom `background_color` diterapkan di sini terlebih dahulu. |
| **Prod** | Terapkan migrasi setara setelah QA di dev; gunakan MCP `supabase-prod` atau pipeline rilis yang dipakai tim. |

## Keputusan produk & UI

1. **Form tambah / edit dompet** (`wallet_form_sheet.dart`): di samping kontrol **pick warna icon** (yang sudah ada), tambah **pick warna background**.
2. **Default** saat buka form **baru** maupun bila data tidak ada: **abu-abu netral** — disepakati **`#E5E7EB`** (selaras dengan default DB, tailwind gray-200).
3. **Sheet warna**: lanjut memakai `SakuColorPickerSheet`, dengan perluasan agar tab **Kustom / wheel** mendukung **transparansi** (`isSupportTransparent: true` pada `SakuColorWheelPicker` di dalam sheet). Tab preset dapat tetap hanya warna opak (tanpa alpha) kecuali nanti ingin ditambah preset transparan.
4. **Format penyimpanan**: string hex seperti kolom `color` — dukung **6 digit (`RRGGBB`)** dan **8 digit (`AARRGGBB`)** agar selaras dengan Flutter `Color` dan picker transparan.

## Database (`public.wallets`)

### Kolom baru

| Kolom | Tipe | Nullable | Default | Keterangan |
|-------|------|----------|---------|------------|
| `background_color` | `text` | NOT NULL | `'#E5E7EB'` | Hex untuk latar icon; 6 atau 8 karakter. |

### Dev — status migrasi

- **Nama migrasi:** `add_wallet_background_color`
- **Isi:** `ALTER TABLE ... ADD COLUMN background_color text NOT NULL DEFAULT '#E5E7EB';` + komentar kolom.

**Backfill:** tidak perlu baris demi baris jika `NOT NULL DEFAULT` dipakai saat `ADD COLUMN` — Postgres mengisi baris lama dengan default.

**RLS / policy:** tidak berubah (policy per baris tetap mengikat `user_id`).

**Trigger `updated_at`:** jika ada trigger generik pada `wallets` untuk `updated_at`, pastikan `UPDATE` dari klien yang menyentuh `background_color` ikut memperbarui timestamp (biasanya sudah otomatis).

## Layer data & aplikasi (rencana implementasi Flutter — belum dieksekusi di repo saat dokumen ini ditulis)

1. **`WalletModel`**  
   - Field `backgroundColor` (atau `background_color` di map) + `fromMap` / `toInsertMap` / `toUpdateMap` / `toFullMap` / `copyWith`.
2. **`wallet_repository` / remote / local (Hive)**  
   - Create & update mengirim `background_color`.
3. **`parseHexColor` (`color_utils.dart`)**  
   - Perluas agar **8 digit** `[0-9A-Fa-f]{8}` di-parse sebagai `Color(int.parse(hex, radix: 16))` (AARRGGBB). Tetap dukung 6 digit dengan prefiks `FF`.
4. **`SakuColorPickerSheet`**  
   - Parameter opsional mis. `customTabSupportsTransparency` (default `false`) agar tidak mengubah perilaku kategori lain.  
   - Untuk wallet: panggil `show(..., customTabSupportsTransparency: true)` (nama final mengikuti konvensi tim).
5. **`SakuCategoryIcon`**  
   - Parameter opsional mis. `backgroundFill` / `backgroundColor`: jika non-null, gunakan sebagai isi `BoxDecoration` (termasuk alpha); jika null, pertahankan perilaku sekarang (`color.withValues(alpha: 0.15)` / gradient).  
   - Untuk alpha &lt; 1 pada latar: pertimbangkan lapisan **checkerboard** kecil (sama pola seperti color wheel) agar transparansi terbaca di semua theme.
6. **`WalletFormSheet`**  
   - State `_selectedBackgroundColor`, default `#E5E7EB`; baris UI **dua swatch** berdampingan (icon color | background color); simpan ke model saat submit.

## Inventarisasi: semua lokasi yang menampilkan icon wallet

Berikut referensi dari codebase (per 2026-05-02). Setiap pemanggilan `SakuCategoryIcon` dengan `wallet.icon` / `WalletModel` harus menerima **warna latar** dari `wallet.backgroundColor` (setelah field ada).

| File | Konteks |
|------|---------|
| `lib/features/wallet/view/widgets/wallet_form_sheet.dart` | Preview icon di form — harus mencerminkan icon + **background** baru. |
| `lib/features/wallet/view/widgets/wallet_card_tile.dart` | Daftar dompet utama — icon + latar. |
| `lib/features/dashboard/view/widgets/dashboard_wallet_section.dart` | Chip / kartu ringkas dompet di dashboard. |
| `lib/global/widgets/saku_wallet_picker_sheet.dart` | List pemilih wallet (row icon). |
| `lib/global/widgets/saku_wallet_filter_button.dart` | Chip filter + leading icon wallet. |
| `lib/global/widgets/saku_wallet_picker_tile.dart` | Tile pemilih wallet di form (transaksi, investasi, settlement, dll.). |
| `lib/features/budget/view/widgets/budget_card_tile.dart` | Icon wallet jika anggaran per-dompet. |
| `lib/features/budget/view/widgets/budget_group_card.dart` | Sama. |
| `lib/features/budget/view/ui/budget_detail_page.dart` | Header/detail anggaran dengan wallet. |
| `lib/features/transaction/view/ui/transaction_detail_page.dart` | Icon dompet sumber/tujuan jika ditampilkan. |
| `lib/features/history/view/widgets/history_transaction_tile.dart` | Icon dompet pada riwayat. |
| `lib/features/history/view/ui/history_page.dart` | Varian tampilan riwayat dengan icon wallet. |

**Catatan:**

- **`SakuCategoryIcon` untuk kategori** (bukan wallet): tidak wajib berubah.
- **`HomeWidgetService.syncWalletData`**: serialisasi JSON ke Android widget — tambahkan key `backgroundColor` / `background_color` agar **native** bisa memakainya jika nanti layout widget menampilkan icon berlatar (saat ini banyak layout hanya nama + saldo; tetap siapkan data).
- **Android (`SakuRapiWidgetProvider`, layout XML)**: jika akan menampilkan latar icon, perlu parse hex di Kotlin dan set background view; masukkan sebagai fase opsional setelah Flutter mengirim field baru.

## Urutan kerja yang disarankan

1. Pastikan migrasi **dev** `background_color` sudah ada (MCP / Dashboard).
2. Regenerate atau perbarui **Supabase types** Dart jika dipakai.
3. Perbarui `WalletModel` + repository + Hive.
4. Perbarui `parseHexColor` untuk 8 digit.
5. Perluas `SakuColorPickerSheet` + integrasi form wallet (dua picker).
6. Perluas `SakuCategoryIcon` + sunting satu per satu pemanggilan pada tabel inventaris di atas.
7. Uji: create/edit wallet, daftar, dashboard, picker, budget, transaksi, history, filter.
8. Deploy migrasi **prod** + rilis aplikasi.

## Risiko & mitigasi

| Risiko | Mitigasi |
|--------|----------|
| Cache Hive berisi map tanpa `background_color` | `fromMap` fallback ke `'#E5E7EB'`. |
| `parseHexColor` gagal pada 8 digit | Implementasi eksplisit cabang 6 vs 8; uji regresi path kategori (`color` tetap 6 digit). |
| Theme gelap vs abu default terlalu terang | Opsional fase 2: default tema-adaptif (di luar cakupan awal). |

## Referensi wiki terkait

- [[wiki/entities/wallet|Wallet entity]]
- [[wiki/entities/database-schema|Database schema]]
