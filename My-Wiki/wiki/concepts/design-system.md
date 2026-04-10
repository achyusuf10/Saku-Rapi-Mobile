---
title: "Design System — Financial Trust"
type: concept
tags: [design-system, theme, color, typography, widget, financial-trust]
sources:
  - raw/docs/redesign-ui-ux/00_REDESIGN_OVERVIEW.md
  - raw/docs/redesign-ui-ux/S1_DESIGN_TOKENS.md
  - raw/docs/redesign-ui-ux/S2_GLOBAL_WIDGETS.md
  - raw/docs/redesign-ui-ux/S12_FINAL_REVIEW.md
created: 2026-04-10
updated: 2026-04-10
---

# Design System — Financial Trust

Referensi utama untuk seluruh aturan visual dan UI di SakuRapi setelah redesign. Design system ini bernama **"Financial Trust"** — terinspirasi dari palette banking/traditional finance.

---

## Filosofi Desain

**"Minimalism + Trust & Authority"**

Desain yang bersih, profesional, dan terpercaya — cocok untuk aplikasi keuangan. Menggunakan palette banking/traditional finance, bukan palette startup/tech yang terlalu playful.

### 4 Prinsip Utama

1. **Clean & Functional** — setiap elemen visual punya tujuan; tidak ada dekorasi tanpa fungsi
2. **Trust Through Restraint** — menahan diri dari warna mencolok; muted colors = trustworthy
3. **Hierarchy Matters** — hierarki visual jelas lewat ukuran, font weight, dan kontras warna
4. **Consistent Calm** — pengalaman visual tenang dan konsisten di seluruh layar

---

## Color Palette

### Light Mode — "Clean Authority"

| Token | Hex | Nama | Keterangan |
|-------|-----|------|------------|
| `primary` | `#0F172A` | Slate 900 | Trust Navy — main brand color |
| `primaryLight` | `#E2E8F0` | Slate 200 | Subtle background tint |
| `primaryDark` | `#020617` | Slate 950 | Deep press state |
| `onPrimary` | `#FFFFFF` | White | Text on primary |
| `accent` | `#CA8A04` | Yellow 600 | Premium Gold — highlight/CTA |
| `background` | `#F8FAFC` | Slate 50 | Clean off-white page bg |
| `surface` | `#FFFFFF` | Pure White | Card background |
| `surfaceVariant` | `#F1F5F9` | Slate 100 | Input field bg, secondary surface |
| `border` | `#E2E8F0` | Slate 200 | Soft border |
| `textPrimary` | `#0F172A` | Slate 900 | Maximum readability |
| `textSecondary` | `#64748B` | Slate 500 | Muted text, WCAG AA compliant |
| `income` | `#059669` | Emerald 600 | Muted green — pemasukan |
| `expense` | `#DC2626` | Red 600 | Solid red — pengeluaran |
| `transfer` | `#2563EB` | Blue 600 | Solid blue — transfer |
| `debt` | `#EA580C` | Orange 600 | Solid orange — hutang |
| `loan` | `#9333EA` | Purple 600 | Solid purple — piutang |
| `success` | Emerald 600 | | Semantic — berhasil |
| `warning` | Yellow 600 | | Semantic — peringatan |
| `error` | Red 600 | | Semantic — error |
| `info` | Blue 600 | | Semantic — informasi |

### Dark Mode — "Calm Depth"

| Token | Hex | Nama | Keterangan |
|-------|-----|------|------------|
| `primary` | `#E2E8F0` | Slate 200 | Light text on dark |
| `background` | `#0F172A` | Slate 900 | **Neutral** — tanpa green tint |
| `surface` | `#1E293B` | Slate 800 | Card background |
| `surfaceVariant` | `#334155` | Slate 700 | Input/secondary surface |
| `accent` | `#EAB308` | Yellow 500 | Brighter gold untuk dark mode |
| `textPrimary` | `#F1F5F9` | Slate 100 | High contrast text |
| `textSecondary` | `#94A3B8` | Slate 400 | Muted text |
| `income` | 400-level | Emerald 400 | Soft, not neon |
| `expense` | 400-level | Red 400 | Soft, not neon |
| `transfer` | 400-level | Blue 400 | Soft, not neon |
| `debt` | 400-level | Orange 400 | Soft, not neon |
| `loan` | 400-level | Purple 400 | Soft, not neon |

---

## Perbedaan vs Design Lama

| Aspek | Lama | Baru |
|-------|------|------|
| Primary | Emerald `#10B981` | Navy `#0F172A` |
| Dark BG | `#0F1412` (green-tinted) | `#0F172A` (neutral) |
| Accent | Amber `#F59E0B` (bright) | Gold `#CA8A04` (restrained) |
| Cards | Gradient emerald | Flat surface + border |
| Shadows | Primary-tinted | Neutral black alpha |
| Typography | 2 font families | 1 — IBM Plex Sans |
| Border radius | 16–20.r (bubbly) | 12.r (refined) |

---

## Typography

### Satu Font: IBM Plex Sans

Seluruh aplikasi menggunakan **IBM Plex Sans** (via `GoogleFonts.ibmPlexSans`), menggantikan campuran Plus Jakarta Sans (heading) + Nunito Sans (body).

**Alasan**: IBM Plex Sans memberikan kesan trustworthy dan professional — cocok untuk konteks keuangan.

### Weight Hierarchy

| Weight | Penggunaan |
|--------|-----------|
| 400 (Regular) | Body text |
| 500 (Medium) | Emphasis, secondary headings |
| 600 (SemiBold) | Labels, buttons |
| 700 (Bold) | Headings |

### Type Scale

`h1` – `h7`, `b1` – `b2`, `caption`, `label1` – `label3`, `overline`

> Ukuran type scale tidak berubah dari sebelumnya — hanya font family yang diganti.

---

## Theme Config

| Config | Value |
|--------|-------|
| `useMaterial3` | `false` |
| AppBar elevation | 0 + subtle bottom border |
| Card radius | `12.r` (sebelumnya 16–20.r) |
| Shadow | Neutral `Colors.black.withValues(alpha: 0.06)`, blur 12 |
| Shadow lama | Primary-tinted, blur 16 |
| Balance card | Solid navy (light) / Solid slate-800 (dark) — **tanpa gradient** |

---

## Prinsip Widget Redesign

1. **Warna dari theme** — tidak boleh hardcoded colors, ambil dari `context.colors`
2. **Border radius `12.r`** — refined, konsisten di semua widget
3. **Shadow neutral** — `black alpha`, bukan primary-tinted
4. **Tipografi via `TextStyleConstants`** + `context.colors` — bukan inline TextStyle
5. **Spacing base unit 8** — padding standar `16.w`

---

## Widget Spesifik

| Widget | Perubahan Utama |
|--------|----------------|
| `SakuButton` | Primary: Navy (light) / Slate-200 (dark) |
| `SakuCard` | `12.r` radius, neutral shadow, full opacity border |
| `SakuTextField` | Slate fill, navy focus border |
| `SakuDialog` | `16.r` radius, neutral shadow |
| `ShimmerWidget` | surfaceVariant-based, visible di kedua mode |
| Calculator | surfaceVariant keys, accent (gold) equal key |
| Balance Card | Solid navy (tanpa gradient), `12.r` |

---

## WCAG Compliance

| Kombinasi | Ratio | Status |
|-----------|-------|--------|
| `textPrimary` on `background` | 15.4:1 | ✅ AAA |
| `textSecondary` on `background` | 4.6:1 | ✅ AA |

---

## Acceptable Patterns (Post-Audit)

Pattern-pattern berikut ditemukan saat final review dan dianggap acceptable:

| Pattern | Alasan |
|---------|--------|
| `Colors.black.withValues(alpha:)` | Correct untuk shadow — bukan hardcoded color |
| Chart library inline `TextStyle` | Required oleh Syncfusion API |
| `LinearGradient` di chart area fills | Hanya untuk chart visualization, bukan card |
| `LinearGradient` di category icon bg | Background dekoratif icon — acceptable |
| `Color(0xFF6B7280)` | Fallback saat hex parsing gagal — defensive coding |

---

## Halaman Terkait

- [[wiki/concepts/arsitektur-app|Arsitektur Aplikasi]]
- [[wiki/concepts/coding-rules|Coding Rules]]
- [[wiki/entities/dashboard|Dashboard]]
- [[wiki/entities/wallet|Wallet]]
- [[wiki/entities/transaksi|Transaksi]]
- [[wiki/entities/sakurapi|SakuRapi]]
- [[wiki/sources/redesign-ui-ux|Source: UI/UX Redesign]]
