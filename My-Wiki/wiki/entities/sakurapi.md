---
title: "SakuRapi"
type: entity
tags: [app, overview, flutter, supabase]
sources: [raw/docs/prd/01_TENTANG_SAKURAPI.md, raw/docs/prd/02_PRIORITAS_FITUR.md, raw/docs/prd/25_ROADMAP.md]
created: 2026-04-10
updated: 2026-04-12
---

# SakuRapi

## Deskripsi

SakuRapi adalah aplikasi pencatat keuangan pribadi untuk platform Android, dibangun menggunakan **Flutter** sebagai framework UI dan **Supabase** sebagai backend (auth, database PostgreSQL, storage, edge functions). Aplikasi ini ditargetkan secara eksklusif untuk **pasar Indonesia** — hanya mendukung mata uang **IDR**; timestamp disimpan UTC dan dirender mengikuti local device user.

Versi dokumen saat ini: **PRD v7.0**. Status pengembangan: **Phase 12 — Polish & QA** (aktif).

## Prinsip Desain

SakuRapi dibangun berdasarkan 5 prinsip desain utama:

| # | Prinsip | Penjelasan |
|---|---------|------------|
| 1 | **Fast Capture First** | Input transaksi harus secepat mungkin — minimal tap, maksimal efisiensi. |
| 2 | **Auditability** | Setiap perubahan saldo harus bisa ditelusuri ke transaksi yang memicunya. Tidak ada perubahan saldo "diam-diam". |
| 3 | **Consistent Money Model** | Semua operasi uang berjalan di server (DB trigger/RPC) untuk menjamin konsistensi. Client bersifat read-only untuk saldo. |
| 4 | **AI = Assistant** | Fitur AI (voice input, OCR) membantu dan menyarankan, tapi user selalu punya kontrol final sebelum submit. |
| 5 | **Low Ambiguity** | UI dan flow dirancang agar user tidak bingung — satu aksi punya satu makna yang jelas. |

## Yang TIDAK Termasuk MVP

Fitur-fitur berikut secara eksplisit **dikecualikan** dari scope MVP:

- ❌ Multi-currency (hanya IDR)
- ❌ Sinkronisasi bank / open banking
- ❌ Shared wallet / multi-user
- ❌ Export / import data
- ❌ Dukungan iOS

## Tech Stack

| Layer | Teknologi |
|-------|-----------|
| Frontend | Flutter (Android) |
| Backend | Supabase (PostgreSQL, Auth, Storage, Edge Functions) |
| State Management | Riverpod |
| Local Cache | Hive |
| AI Features | Voice input, OCR receipt scanning |

## Fitur Utama

- [[wiki/entities/wallet|Wallet]] — Multi-wallet dengan saldo read-only
- [[wiki/entities/transaksi|Transaksi]] — Pencatatan expense, income, transfer, hutang/piutang
- [[wiki/entities/dashboard|Dashboard]] — Ringkasan keuangan dan visualisasi
- [[wiki/entities/hutang-piutang|Hutang/Piutang]] — Manajemen pinjaman dan penagihan
- [[wiki/entities/budgeting|Budgeting]] — Anggaran per kategori dengan auto-renew

## Halaman Terkait

- [[wiki/entities/wallet|Wallet]]
- [[wiki/entities/transaksi|Transaksi]]
- [[wiki/entities/dashboard|Dashboard]]
- [[wiki/entities/hutang-piutang|Hutang/Piutang]]
- [[wiki/entities/budgeting|Budgeting]]
- [[wiki/sources/prd-sakurapi-v7|PRD SakuRapi v7.0]]
- [[wiki/concepts/aturan-keuangan|Aturan Keuangan]]
