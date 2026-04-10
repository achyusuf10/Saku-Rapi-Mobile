# SakuRapi UI/UX Redesign — Minimalism + Trust & Authority

## Filosofi Desain

**Minimalism + Trust & Authority** — Desain bersih yang memancarkan kepercayaan dan profesionalisme,
cocok untuk aplikasi keuangan pribadi yang mengelola uang pengguna.

### Prinsip Utama
1. **Clean & Functional** — Setiap elemen punya tujuan, tidak ada dekorasi kosong
2. **Trust Through Restraint** — Warna netral, tipografi solid, tanpa efek neon/glow
3. **Hierarchy Matters** — Informasi penting menonjol secara alami via ukuran, berat, dan ruang
4. **Consistent Calm** — Dark mode yang tenang (bukan neon), light mode yang lapang

---

## Masalah UI/UX Saat Ini

| Masalah | Detail |
|---------|--------|
| **Emerald Dominance** | Hijau emerald (#10B981) terlalu saturated, terasa "playful" bukan "trustworthy" |
| **Dark Mode Neon** | Warna transaksi (#34D399, #F87171, #60A5FA, #FB923C, #C084FC) terlalu cerah di dark mode → kesan neon |
| **Green-tinted backgrounds** | Dark bg (#0F1412) dan surface (#1A2420) punya tint hijau → terasa quirky |
| **Gradient cards** | Balance card gradient (emerald dark → emerald) terasa vibe-coding |
| **Mixed typography** | Plus Jakarta Sans + Nunito Sans (theme default) → inconsistent |
| **Over-saturated status** | Semua status color terlalu saturated, kurang sophisticated |

---

## Design System Baru: "Financial Trust"

### Konsep Warna

**Banking/Traditional Finance palette** dari UI UX Pro Max:
- Trust Navy + Premium Gold — menyiratkan stabilitas, kepercayaan, dan kualitas

### Konsep Typography

**IBM Plex Sans** — Font yang dirancang IBM untuk fintech/banking.
Memancarkan: trustworthy, professional, serious, reliable.

### Konsep Visual

| Aspek | Sekarang | Baru |
|-------|----------|------|
| Primary | Emerald saturated | Navy (trust) |
| Accent | Amber random | Gold restrained (premium) |
| Dark BG | Hijau-tinted gelap | Pure dark neutral |
| Cards | Gradient emerald | Flat surface + subtle border |
| Status colors | Saturated neon | Muted/desaturated professional |
| Typography | 2 font families | 1 font family (IBM Plex Sans) |
| Shadows | Primary-tinted | Neutral black alpha |
| Border radius | 16-20r (bubbly) | 12r (refined) |

---

## Scope Perubahan

### Files yang Akan Berubah

| Category | Count | Description |
|----------|-------|-------------|
| Core Theme | 3 files | `app_colors.dart`, `app_themes.dart`, `text_style_constants.dart` |
| Global Widgets | ~23 files | Semua widget di `lib/global/widgets/` |
| Screen Pages | 25 files | Semua halaman di `*/view/ui/` |
| Feature Widgets | 65 files | Semua widget di `*/view/widgets/` |
| Extensions | 2-3 files | Currency/date formatting jika ada hardcoded style |

### Files yang TIDAK Berubah
- Models, repositories, datasources, controllers (logic layer)
- Router, providers, services
- Supabase functions
- Test files (akan di-update terpisah jika diperlukan)

---

## Section Plan (Urutan Pengerjaan)

| Section | Nama | Scope | Dependensi |
|---------|------|-------|------------|
| **S1** | Design Tokens & Theme Foundation | `app_colors.dart`, `text_style_constants.dart`, `app_themes.dart` | — |
| **S2** | Global Widgets Overhaul | 23 files di `lib/global/widgets/` | S1 |
| **S3** | Dashboard & Home | dashboard page + 10 widget files | S2 |
| **S4** | Wallet Module | wallet page + 4 widget files | S2 |
| **S5** | Transaction Module | transaction form/detail + 14 widget files | S2 |
| **S6** | History Module | history page + 5 widget files | S2 |
| **S7** | Budget Module | 3 pages + 6 widget files | S2 |
| **S8** | Reports & Charts | 2 pages + 6 widget files | S2 |
| **S9** | Debt/Loan Module | 3 pages + 4 widget files | S2 |
| **S10** | Investment Module | 4 pages + 6 widget files | S2 |
| **S11** | Auth, Settings & Misc | splash, login, settings, category, notification, voice, OCR | S2 |
| **S12** | Final Review & Polish | Cross-check semua halaman, accessibility audit | S3–S11 |

Setiap section punya dokumen detail tersendiri di `docs/redesign-ui-ux/`.
