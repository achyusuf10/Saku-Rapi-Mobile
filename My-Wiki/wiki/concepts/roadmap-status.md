---
title: "Roadmap & Status Development"
type: concept
tags: [roadmap, fase, status, dod, testing, permission, qa]
sources: [raw/docs/prd/02_PRIORITAS_FITUR.md, raw/docs/prd/03_KPI_TARGET.md, raw/docs/prd/23_PERMISSIONS.md]
created: 2026-04-10
updated: 2026-04-10
---

# Roadmap & Status Development

> Halaman ini mendokumentasikan roadmap pengembangan SakuRapi, status setiap fase, Definition of Done, dan kebijakan testing.

---

## Roadmap: 12 Fase + 1 Aktif

SakuRapi dikembangkan dalam 13 fase (Phase 0–12). Saat ini fase terakhir sedang aktif.

| Phase | Nama | Status |
|---|---|---|
| **Phase 0** | Setup, theme, l10n, widgets | ✅ Done |
| **Phase 1** | DB schema, RLS, triggers, RPC | ✅ Done |
| **Phase 2** | Auth & bootstrap | ✅ Done |
| **Phase 3** | Wallets | ✅ Done |
| **Phase 4** | Manual transactions | ✅ Done |
| **Phase 5** | History & dashboard | ✅ Done |
| **Phase 6** | Categories | ✅ Done |
| **Phase 7** | Budgeting | ✅ Done |
| **Phase 8** | Voice parser | ✅ Done |
| **Phase 9** | OCR parser | ✅ Done |
| **Phase 10** | Notifications | ✅ Done |
| **Phase 11** | Investments | ✅ Done |
| **Phase 12** | Polish, QA, performance | 🔵 **ACTIVE** |

---

## Detail per Fase

### Phase 0 — Setup & Fondasi
- Inisialisasi project Flutter via FVM
- Konfigurasi theme dan design system (`TextStyleConstants`, `context.colors`)
- Setup localization (`.arb` files, Bahasa Indonesia sebagai bahasa utama)
- Pembuatan global widgets (`SakuButton`, `SakuTextField`, `ShimmerWidget`, dll)

### Phase 1 — Database & Backend
- Desain database schema di Supabase
- Row Level Security (RLS) policies
- Database triggers (termasuk `update_wallet_balance`)
- RPC functions untuk operasi kompleks

### Phase 2 — Auth & Bootstrap
- Login, register, forgot password
- Bootstrap flow saat app launch
- Session management via Supabase Auth

### Phase 3 — Wallets
- CRUD wallet (buat, lihat, edit, hapus)
- Tampilan balance per wallet dan total
- Wallet sebagai fondasi transaksi

### Phase 4 — Manual Transactions
- Form input transaksi manual (7 tipe)
- Validasi berdasarkan [[wiki/concepts/matrix-transaksi|Matrix Transaksi]]
- RPC-based insert yang mentrigger update balance

### Phase 5 — History & Dashboard
- Dashboard ringkasan keuangan
- History transaksi dengan filter dan pencarian
- Grafik dan statistik

### Phase 6 — Categories
- Manajemen kategori transaksi
- Kategori default yang sudah disediakan
- Custom category oleh user

### Phase 7 — Budgeting
- Budget per kategori per periode
- Tracking usage vs limit
- Notifikasi mendekati/melebihi budget

### Phase 8 — Voice Parser
- Input transaksi via suara
- STT lokal (`speech_to_text`, `id_ID`)
- Integrasi dengan [[wiki/concepts/ai-pipeline|AI Pipeline]]

### Phase 9 — OCR Parser
- Input transaksi via foto struk
- Crop, compress, Base64 encode
- Integrasi dengan [[wiki/concepts/ai-pipeline|AI Pipeline]]

### Phase 10 — Notifications
- Notifikasi reminder dan alert
- Budget warning notifications
- Scheduled notifications

### Phase 11 — Investments
- Tracking investasi/aset
- Transfer to asset transaction type
- Portofolio view

### Phase 12 — Polish, QA, Performance (🔵 ACTIVE)
- Performance optimization
- Bug fixes dan edge cases
- QA menyeluruh
- Final polish UI/UX

---

## Definition of Done (DoD)

Sebuah fitur dianggap **selesai** hanya jika memenuhi semua kriteria berikut:

| # | Kriteria | Detail |
|---|---|---|
| 1 | **Business rules per PRD** | Semua aturan bisnis dari PRD terimplementasi dengan benar |
| 2 | **Loading state** | Menggunakan `ShimmerWidget` (bukan CircularProgressIndicator) |
| 3 | **Error state** | Menampilkan `SakuErrorState` dengan pesan yang jelas |
| 4 | **Empty state** | Menampilkan `SakuEmptyState` saat data kosong |
| 5 | **Form validasi** | Semua input form tervalidasi (required, format, range) |
| 6 | **Test minimal** | Minimal unit test untuk logic kritis |
| 7 | **`.arb` strings** | Semua string UI ada di file `.arb`, tidak ada hardcoded text |
| 8 | **No hardcoded styles** | Semua styling via `TextStyleConstants`, `context.colors`, `ScreenUtil` |
| 9 | **Happy path** | Alur normal berfungsi end-to-end |
| 10 | **Failure path** | Error handling untuk kegagalan network, validasi, edge cases |

---

## Kebijakan Testing

### Unit Tests

| Target | Contoh |
|---|---|
| **Repository** | Test orchestration logic, cache vs remote, error handling |
| **Controller/Notifier** | Test state transitions, validasi, side effects |
| **Parser** | Test VoiceLocalParser dan OcrLocalParser dengan berbagai input |

### Widget Tests

| Target | Contoh |
|---|---|
| **Form** | Test validasi form, field interaction, submit behavior |
| **Custom widget** | Test SakuCurrencyField formatting, SakuButton states |

### Integration Tests

| Skenario | Cakupan |
|---|---|
| **Login → Dashboard** | Auth flow lengkap sampai tampilan dashboard |
| **Create expense** | Buat transaksi pengeluaran dari form sampai tersimpan |
| **Multi-item transaction** | Transaksi OCR dengan beberapa item |
| **Budget usage** | Buat expense → cek budget berkurang sesuai |

---

## Model Permission: Just-in-Time

SakuRapi menggunakan pendekatan **just-in-time** untuk permission, bukan meminta semua permission saat app launch.

| Permission | Diminta Saat |
|---|---|
| **Mikrofon** | User pertama kali tap tombol voice input |
| **Kamera** | User pertama kali pilih ambil foto untuk OCR |
| **Gallery/Photos** | User pertama kali pilih foto dari galeri |
| **Notification** | User pertama kali mengaktifkan fitur notifikasi |

### Alasan Just-in-Time

- **UX lebih baik**: User mengerti konteks kenapa permission diminta
- **Conversion rate lebih tinggi**: User lebih mungkin mengizinkan saat memahami manfaatnya
- **Compliance**: Mengikuti best practice platform (Apple App Store, Google Play)

---

## Halaman Terkait

- [[wiki/concepts/arsitektur-app|Arsitektur App]] — Tech stack dan arsitektur
- [[wiki/concepts/aturan-keuangan|Aturan Keuangan Fundamental]] — Aturan yang harus dipenuhi
- [[wiki/concepts/matrix-transaksi|Matrix Transaksi]] — Referensi tipe transaksi
- [[wiki/concepts/ai-pipeline|AI Pipeline]] — Pipeline AI (Phase 8 & 9)
- [[wiki/entities/wallet|Wallet]] — Entitas wallet (Phase 3)
- [[wiki/entities/transaksi|Transaksi]] — Entitas transaksi (Phase 4)
- [[wiki/sources/prd-sakurapi-v7|PRD SakuRapi v7.0]] — Dokumen sumber roadmap
