---
title: "UI/UX Redesign — Financial Trust"
type: source
tags: [redesign, ui-ux, design-system, theme, financial-trust]
updated: 2026-04-10
sources:
  - raw/docs/redesign-ui-ux/00_REDESIGN_OVERVIEW.md
  - raw/docs/redesign-ui-ux/S1_DESIGN_TOKENS.md
  - raw/docs/redesign-ui-ux/S2_GLOBAL_WIDGETS.md
  - raw/docs/redesign-ui-ux/S3_DASHBOARD.md
  - raw/docs/redesign-ui-ux/S4_WALLET.md
  - raw/docs/redesign-ui-ux/S5_TRANSACTION.md
  - raw/docs/redesign-ui-ux/S6_HISTORY.md
  - raw/docs/redesign-ui-ux/S7_BUDGET.md
  - raw/docs/redesign-ui-ux/S8_REPORTS.md
  - raw/docs/redesign-ui-ux/S9_DEBT_LOAN.md
  - raw/docs/redesign-ui-ux/S10_INVESTMENT.md
  - raw/docs/redesign-ui-ux/S11_AUTH_SETTINGS_MISC.md
  - raw/docs/redesign-ui-ux/S12_FINAL_REVIEW.md
created: 2026-04-10
updated: 2026-04-10
---

# UI/UX Redesign — Financial Trust

Rangkuman menyeluruh proyek redesign UI/UX SakuRapi. Proyek ini mengganti seluruh visual layer — tema warna, tipografi, dan komponen widget — tanpa mengubah logic layer (models, repositories, datasources, controllers, router, providers, services).

---

## Filosofi

**"Minimalism + Trust & Authority"** — desain bersih, profesional, cocok untuk aplikasi keuangan. Menggantikan tampilan lama yang terlalu playful dan saturated.

### 4 Prinsip Utama

1. **Clean & Functional** — setiap elemen punya tujuan, tidak ada dekorasi berlebih
2. **Trust Through Restraint** — warna muted, tipografi konsisten, memberikan kesan terpercaya
3. **Hierarchy Matters** — hierarki visual jelas lewat ukuran, weight, dan kontras warna
4. **Consistent Calm** — pengalaman visual tenang dan konsisten di seluruh aplikasi

---

## Masalah UI Lama

- **Emerald dominance** — `#10B981` terlalu saturated dan playful untuk app keuangan
- **Dark mode neon** — 400-level colors di atas green-tinted background
- **Green-tinted backgrounds** — `#0F1412`, `#1A2420` membuat dark mode terasa tidak netral
- **Gradient cards** — efek gradient emerald memberikan kesan vibe-coding, bukan profesional
- **Mixed typography** — Plus Jakarta Sans (heading) + Nunito Sans (body) membuat inkonsistensi visual

---

## Design System Baru: "Financial Trust"

### Color

- **Primary**: Trust Navy `#0F172A` (Slate 900) — menggantikan Emerald
- **Accent**: Premium Gold `#CA8A04` (Yellow 600) — restrained, bukan Amber terang
- **Dark background**: Pure neutral `#0F172A` (Slate 900) — tanpa green tint
- **Transaction colors**: Semantic, desaturated (600-level light, 400-level dark)

### Typography

- **Satu font family**: IBM Plex Sans (via `GoogleFonts.ibmPlexSans`)
- Menggantikan campuran Plus Jakarta Sans + Nunito Sans
- Weight hierarchy: 400 (body), 500 (emphasis), 600 (labels/buttons), 700 (headings)

### Visual

- **Flat cards** — tanpa gradient, hanya surface color + border
- **Neutral shadows** — `Colors.black.withValues(alpha: 0.06)`, blur 12
- **Border radius**: `12.r` (refined) — menggantikan 16-20.r yang terlalu bubbly
- **Status colors**: Desaturated (600-level) — bukan neon

---

## Scope

- **12 sections** (S1–S12)
- **~118 files** yang diubah:
  - 3 core theme files
  - ~23 global widget files
  - ~25 screen/page files
  - ~65 feature widget files
  - 2–3 extension files
- **TIDAK berubah**: Logic layer (models, repos, datasources, controllers), router, providers, services

---

## Section Plan

| Section | Nama | File Count |
|---------|------|-----------|
| S1 | Design Tokens & Theme Foundation | 3 files |
| S2 | Global Widgets Overhaul | ~23 files |
| S3 | Dashboard & Home | 11 files |
| S4 | Wallet Module | 6 files |
| S5 | Transaction Module | 16 files |
| S6 | History Module | 6 files |
| S7 | Budget Module | 9 files |
| S8 | Reports & Charts | 8 files |
| S9 | Debt/Loan Module | 7 files |
| S10 | Investment Module | 10 files |
| S11 | Auth, Settings & Misc | 11 files |
| S12 | Final Review & Polish | 2 files |

---

## Status

| Section | Status |
|---------|--------|
| S1–S9 | ⏳ Pending |
| S10 — Investment Module | ✅ Done |
| S11 — Auth, Settings & Misc | ✅ Done |
| S12 — Final Review & Polish | ✅ Done |

---

## Final Review (S12) Highlights

- **`fvm flutter analyze`** — 10 issues ditemukan, semua pre-existing (bukan dari redesign)
- **`fvm flutter test`** — 589 pass, 7 fail (semua pre-existing)
- Semua informasi tetap ditampilkan, navigation unchanged
- **Acceptable patterns** yang didokumentasikan:
  - `Colors.black.withValues(alpha:)` untuk shadow — correct, bukan hardcoded color
  - Chart library inline `TextStyle` — required oleh Syncfusion API
  - `LinearGradient` hanya di chart area fills dan category icon background
  - `Color(0xFF6B7280)` sebagai fallback saat hex parsing gagal

---

## Halaman Terkait

- [[wiki/concepts/design-system|Design System — Financial Trust]]
- [[wiki/concepts/arsitektur-app|Arsitektur Aplikasi]]
- [[wiki/entities/dashboard|Dashboard]]
- [[wiki/entities/wallet|Wallet]]
- [[wiki/entities/transaksi|Transaksi]]
- [[wiki/entities/history|History]]
- [[wiki/entities/budgeting|Budgeting]]
- [[wiki/entities/reports|Reports]]
- [[wiki/entities/hutang-piutang|Hutang Piutang]]
- [[wiki/entities/investasi|Investasi]]
- [[wiki/entities/settings|Settings]]
- [[wiki/concepts/coding-rules|Coding Rules]]
