---
title: "PRD SakuRapi v7.0 — Ringkasan"
type: source
tags: [prd, product-requirements, sakurapi, v7]
sources: [raw/docs/prd/00_INDEX.md, raw/docs/prd/01_TENTANG_SAKURAPI.md, raw/docs/prd/02_PRIORITAS_FITUR.md, raw/docs/prd/03_KPI_TARGET.md, raw/docs/prd/04_ATURAN_KEUANGAN.md, raw/docs/prd/05_USER_FLOWS.md, raw/docs/prd/06_AUTH_PROFIL.md, raw/docs/prd/07_DASHBOARD.md, raw/docs/prd/08_WALLETS.md, raw/docs/prd/09_TRANSAKSI.md, raw/docs/prd/10_TRANSACTION_DETAIL.md, raw/docs/prd/11_HUTANG_PIUTANG.md, raw/docs/prd/12_HISTORY.md, raw/docs/prd/13_CATEGORIES.md, raw/docs/prd/14_BUDGETING.md, raw/docs/prd/15_INVESTASI.md, raw/docs/prd/16_SETTINGS.md, raw/docs/prd/17_VOICE_INPUT.md, raw/docs/prd/18_OCR_RECEIPT.md, raw/docs/prd/19_PARSING_DICTIONARY.md, raw/docs/prd/20_EXTERNAL_API.md, raw/docs/prd/21_KATEGORI_DEFAULT.md, raw/docs/prd/22_EDGE_CASES.md, raw/docs/prd/23_PERMISSIONS.md, raw/docs/prd/24_TESTING.md, raw/docs/prd/25_ROADMAP.md, raw/docs/prd/26_KEPUTUSAN_FINAL.md]
created: 2026-04-10
updated: 2026-04-10
---

# PRD SakuRapi v7.0 — Ringkasan

**Jenis**: Dokumen internal — Product Requirements Document
**Tanggal sumber**: 2026-03-31
**Versi**: 7.0
**Cakupan**: 27 file di `docs/prd/`

## Ringkasan

SakuRapi adalah aplikasi pencatat keuangan pribadi untuk platform Android yang ditargetkan khusus untuk pasar Indonesia. Aplikasi ini dibangun menggunakan **Flutter** di sisi client dan **Supabase** (PostgreSQL + Edge Functions) di sisi backend. Mata uang yang didukung hanya **IDR** — tidak ada dukungan multi-currency. PRD v7.0 merupakan dokumen spesifikasi komprehensif yang dipecah ke dalam 27 file, masing-masing membahas aspek produk secara mendalam mulai dari autentikasi hingga roadmap pengembangan.

Fitur utama mencakup pencatatan transaksi manual, pengelolaan multi-wallet, sistem kategori parent-child, dashboard ringkasan keuangan, serta fitur hutang-piutang yang terintegrasi langsung ke dalam alur transaksi. Di luar fitur dasar, SakuRapi memiliki kemampuan input berbasis AI: voice input yang memanfaatkan speech-to-text lalu di-parse oleh Gemini (dengan failover ke Groq), OCR struk belanja, serta parsing dictionary untuk mengenali merchant dan kategori secara otomatis.

Aturan keuangan dalam aplikasi sangat ketat dan menjadi fondasi integritas data. Saldo wallet tidak pernah dihitung secara manual — selalu melalui database trigger berdasarkan ledger transaksi. Terdapat 7 tipe transaksi yang didefinisikan: income, expense, transfer, debt, loan, adjustment, dan transfer_to_asset. Settlement hutang/piutang secara eksplisit dikecualikan dari laporan dan budgeting agar tidak mengacaukan analisa keuangan pengguna.

PRD juga mendefinisikan roadmap 12 fase. Hingga versi ini, Phase 0–11 telah selesai, dan Phase 12 (Polish & QA) sedang aktif berjalan. Sistem budgeting hanya memperhitungkan expense, sementara laporan keuangan hanya menampilkan income dan expense non-settlement. Fitur AI berfungsi sebagai prefill — selalu membutuhkan konfirmasi pengguna sebelum data disimpan.

Target KPI utama yang ditetapkan meliputi: pencatatan transaksi manual harus selesai dalam waktu kurang dari 20 detik, input via voice/OCR kurang dari 45 detik, dan akurasi saldo harus 100% setiap saat. Metrik-metrik ini menjadi acuan utama dalam setiap keputusan desain UI dan arsitektur backend.

## Poin Kunci

- **Produk**: SakuRapi — pencatat keuangan pribadi, Android only, IDR only
- **Tech stack**: Flutter (client) + Supabase/PostgreSQL + Edge Functions (backend)
- **Autentikasi**: Google Sign-In sebagai satu-satunya metode login
- **7 tipe transaksi**: income, expense, transfer, debt, loan, adjustment, transfer_to_asset
- **Saldo via trigger**: Tidak ada perhitungan saldo manual; semua melalui database trigger pada ledger
- **AI hanya prefill**: Voice input, OCR, dan text parsing hanya mengisi form — pengguna selalu konfirmasi
- **AI pipeline**: STT → Edge Function `ai-parse` → Gemini → Groq failover → local parser
- **Settlement dikecualikan** dari laporan keuangan dan budgeting
- **Multi-item & split bill** menggunakan tabel `transaction_items`
- **Transfer bukan expense**: Transfer antar wallet tidak dihitung sebagai pengeluaran
- **KPI ketat**: Manual < 20 detik, voice/OCR < 45 detik, saldo akurat 100%
- **Roadmap**: 12 phase; Phase 0–11 done, Phase 12 (Polish QA) aktif

## Daftar Fitur

### P0 — Core (Harus Ada)

| Fitur | Deskripsi |
|-------|-----------|
| Google Sign-In | Autentikasi tunggal via Google OAuth |
| Multi-Wallet | Kelola beberapa dompet/rekening |
| Dashboard | Ringkasan saldo, pengeluaran bulan ini, grafik mini |
| Transaksi Manual | Input income, expense, transfer, dll. |
| History + Filter | Riwayat transaksi dengan filter tanggal, kategori, wallet |
| Kategori Parent-Child | Hierarki kategori dua level |
| Settings | Pengaturan profil, wallet, kategori, dan preferensi |

### P1 — Enhanced

| Fitur | Deskripsi |
|-------|-----------|
| Multi-item / Split Bill | Catat beberapa item per transaksi, bagi tagihan |
| Voice Input AI | Input transaksi via suara, diproses AI |
| Text Input AI | Input transaksi via teks bebas, di-parse AI |
| OCR Struk | Scan struk belanja, ekstrak data otomatis |
| Parsing Dictionary | Kamus merchant ↔ kategori untuk AI parsing |
| Budgeting + Alert | Budget per kategori dengan notifikasi threshold |
| Visual Reports | Laporan grafis: pie chart, bar chart, tren |
| Local Notifications | Reminder dan alert via notifikasi lokal |

### P2 — Future

| Fitur | Deskripsi |
|-------|-----------|
| Investasi | Pencatatan aset investasi (emas, saham, dll.) |
| Lampiran Lanjutan | Attachment foto/dokumen per transaksi |
| Export/Import | Ekspor dan impor data (CSV, dll.) |
| Analytics | Analisis lanjutan dan insight keuangan |

## Aturan Keuangan Kunci

1. **Balance hanya via database trigger** — Saldo wallet dihitung otomatis dari ledger menggunakan trigger PostgreSQL. Tidak ada kode aplikasi yang menghitung saldo secara langsung.
2. **7 tipe transaksi** — `income`, `expense`, `transfer`, `debt`, `loan`, `adjustment`, `transfer_to_asset`. Setiap tipe memiliki efek berbeda terhadap saldo wallet.
3. **Settlement dikecualikan** — Pembayaran hutang/piutang (settlement) tidak masuk ke dalam laporan keuangan maupun perhitungan budget.
4. **Report hanya income & expense non-settlement** — Laporan keuangan hanya menghitung transaksi income dan expense yang bukan settlement.
5. **Budget hanya expense** — Budgeting hanya berlaku untuk tipe transaksi expense (non-settlement).
6. **Transfer ≠ expense** — Transfer antar wallet adalah perpindahan dana, bukan pengeluaran.
7. **AI hanya prefill** — Semua input AI (voice, OCR, text) mengisi form sebagai saran; pengguna wajib mengonfirmasi sebelum tersimpan.

## Status Roadmap

| Phase | Nama | Status |
|-------|------|--------|
| 0 | Foundation & Auth | ✅ Done |
| 1 | Wallet Management | ✅ Done |
| 2 | Kategori & Dashboard | ✅ Done |
| 3 | Transaksi Manual | ✅ Done |
| 4 | History & Filter | ✅ Done |
| 5 | Hutang Piutang | ✅ Done |
| 6 | Budgeting & Reports | ✅ Done |
| 7 | Voice Input AI | ✅ Done |
| 8 | OCR Receipt | ✅ Done |
| 9 | Multi-item & Split Bill | ✅ Done |
| 10 | Settings & Notifications | ✅ Done |
| 11 | Investasi & Export | ✅ Done |
| 12 | Polish & QA | 🔄 Active |

## Keputusan Final

Tujuh keputusan arsitektural final yang ditetapkan dalam PRD:

1. **Saldo via ledger only** — Saldo wallet selalu dihitung melalui trigger database dari tabel ledger, bukan dari kode aplikasi. Ini menjamin konsistensi data 100%.
2. **Report hanya income/expense non-settlement** — Laporan keuangan hanya menampilkan transaksi income dan expense yang bukan merupakan settlement hutang/piutang, agar analisa pengeluaran tetap akurat.
3. **Budget hanya expense** — Fitur budgeting hanya memperhitungkan transaksi bertipe expense (non-settlement), karena budget adalah kontrol pengeluaran.
4. **Multi-item pakai `transaction_items`** — Transaksi dengan banyak item (split bill, belanja multi-item) menggunakan tabel terpisah `transaction_items` yang berelasi ke transaksi induk.
5. **Transfer bukan expense** — Transfer antar wallet tidak dihitung sebagai expense dalam laporan maupun budget, karena secara finansial hanya perpindahan dana.
6. **AI hanya prefill** — Semua fitur AI (voice, OCR, text parsing) hanya berfungsi mengisi form secara otomatis. Pengguna wajib mereview dan mengonfirmasi sebelum data tersimpan.
7. **IDR only** — Aplikasi hanya mendukung mata uang Rupiah Indonesia. Tidak ada rencana multi-currency di versi ini.

## Halaman Terkait

- [[wiki/entities/wallet|Wallet]]
- [[wiki/entities/transaksi|Transaksi]]
- [[wiki/entities/dashboard|Dashboard]]
- [[wiki/entities/hutang-piutang|Hutang Piutang]]
- [[wiki/entities/budgeting|Budgeting]]
- [[wiki/entities/investasi|Investasi]]
- [[wiki/entities/voice-input|Voice Input]]
- [[wiki/entities/ocr-receipt|OCR Receipt]]
- [[wiki/concepts/aturan-keuangan|Aturan Keuangan Fundamental]]
- [[wiki/concepts/matrix-transaksi|Matrix Tipe Transaksi]]
- [[wiki/concepts/ai-pipeline|AI Pipeline]]
