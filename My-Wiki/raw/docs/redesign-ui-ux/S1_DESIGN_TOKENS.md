# S1 — Design Tokens & Theme Foundation

**Priority:** 🔴 Critical (semua section lain bergantung pada ini)
**Files:** 3 core files

---

## 1. Color Palette Baru: `app_colors.dart`

### Light Mode — "Clean Authority"

```
PRIMARY COLORS:
  primary:       #0F172A  (Slate 900 — Trust Navy)
  primaryLight:  #E2E8F0  (Slate 200 — Subtle bg tint)
  primaryDark:   #020617  (Slate 950 — Deep press state)
  onPrimary:     #FFFFFF  (White)

ACCENT:
  accent:        #CA8A04  (Yellow 600 — Premium Gold, restrained)

BACKGROUNDS & SURFACES:
  background:    #F8FAFC  (Slate 50 — Clean off-white)
  surface:       #FFFFFF  (Pure white cards)
  surfaceVariant:#F1F5F9  (Slate 100 — Input field bg)
  border:        #E2E8F0  (Slate 200 — Soft border)

TEXT:
  textPrimary:   #0F172A  (Slate 900 — Maximum readability)
  textSecondary: #64748B  (Slate 500 — Muted but readable, WCAG AA)

TRANSACTION/STATUS — Desaturated Professional:
  income:        #059669  (Emerald 600 — Muted green)
  expense:       #DC2626  (Red 600 — Solid red)
  transfer:      #2563EB  (Blue 600 — Solid blue)
  debt:          #EA580C  (Orange 600 — Solid orange)
  loan:          #9333EA  (Purple 600 — Solid purple)

SEMANTIC:
  success:       #059669  (Emerald 600)
  warning:       #CA8A04  (Yellow 600)
  error:         #DC2626  (Red 600)
  info:          #2563EB  (Blue 600)
```

### Dark Mode — "Calm Depth" (tanpa green-tint, tanpa neon)

```
PRIMARY COLORS:
  primary:       #E2E8F0  (Slate 200 — Light on dark)
  primaryLight:  #1E293B  (Slate 800 — Subtle dark tint)
  primaryDark:   #F8FAFC  (Slate 50 — Brighter press state)
  onPrimary:     #0F172A  (Dark text on light primary)

ACCENT:
  accent:        #EAB308  (Yellow 500 — Gold, slightly brighter for dark)

BACKGROUNDS & SURFACES:
  background:    #0F172A  (Slate 900 — True dark, NO green tint)
  surface:       #1E293B  (Slate 800 — Card surface)
  surfaceVariant:#334155  (Slate 700 — Input field bg)
  border:        #334155  (Slate 700)

TEXT:
  textPrimary:   #F1F5F9  (Slate 100 — High readability)
  textSecondary: #94A3B8  (Slate 400 — Muted)

TRANSACTION/STATUS — Slightly brighter, NOT neon:
  income:        #34D399  (Emerald 400 — Soft green, not neon)
  expense:       #F87171  (Red 400 — Soft red)
  transfer:      #60A5FA  (Blue 400 — Soft blue)
  debt:          #FB923C  (Orange 400 — Soft orange)
  loan:          #C084FC  (Purple 400 — Soft purple)

SEMANTIC:
  success:       #34D399  (Emerald 400)
  warning:       #EAB308  (Yellow 500)
  error:         #F87171  (Red 400)
  info:          #60A5FA  (Blue 400)
```

### Perbedaan Kunci vs Sekarang

| Aspek | Sekarang | Baru |
|-------|----------|------|
| Primary | Emerald #10B981 (both modes) | Navy #0F172A (light) / Slate #E2E8F0 (dark) |
| Dark BG | #0F1412 (green-tinted) | #0F172A (neutral slate) |
| Dark Surface | #1A2420 (green-tinted) | #1E293B (neutral slate) |
| Accent | Amber #F59E0B (bright) | Gold #CA8A04 (restrained) |
| Income | Same as primary | Separate: Emerald 600/400 |
| Neon issue | 400-level colors on dark bg | Same 400-level tapi bg neutral → less neon |

### Catatan: Income vs Primary

Di design lama, `income == primary` (keduanya Emerald 500). Di design baru:
- `primary` = Navy (untuk buttons, nav, emphasis)
- `income` = Emerald (tetap hijau untuk semantic "uang masuk")
- Ini memisahkan brand identity dari semantic meaning

---

## 2. Typography Baru: `text_style_constants.dart`

### Font Family

```
SINGLE FAMILY: IBM Plex Sans
- Headers: IBM Plex Sans (weight 600-700)
- Body: IBM Plex Sans (weight 400-500)
- Labels: IBM Plex Sans (weight 500-600)
```

**Hapus**: Plus Jakarta Sans (heading), Nunito Sans (theme default)
**Ganti semua** ke IBM Plex Sans via `GoogleFonts.nunitoSans()`

### Type Scale (tetap sama ukurannya, hanya font berubah)

```
h1: 80sp → tetap (rarely used)
h2: 61sp → tetap
h3: 47sp → tetap
h4: 36sp → tetap
h5: 27sp → tetap
h6: 21sp → tetap
h7: 18sp → tetap

b1: 16sp → tetap
b2: 14sp → tetap
caption: min(13sp, 20) → tetap

label1: 14sp → tetap
label2: 12sp → tetap
label3: 10sp → tetap
overline: 9sp → tetap
```

---

## 3. Theme Config: `app_themes.dart`

### Perubahan di lightTheme & darkTheme

| Aspek | Sekarang | Baru |
|-------|----------|------|
| `useMaterial3` | `false` | Tetap `false` (avoid breaking change) |
| `textTheme` | `nunitoSansTextTheme` | `nunitoSansTextTheme` |
| AppBar bg | `#FAFAFC` | `surface` color (white/slate-800) |
| AppBar elevation | 4 | 0 (flat minimalist) + subtle bottom border |
| Button radius | 12.r | 12.r (tetap) |
| Card radius default | 16.r | 12.r (more refined) |
| Shadow style | Primary-tinted | Neutral `Colors.black.withValues(alpha: 0.06-0.10)` |
| BottomNav selected | Emerald | Navy (light) / Slate-200 (dark) |

### Perubahan Shadow Strategy

```dart
// SEKARANG (primary-tinted, vibe-coding feel):
BoxShadow(
  color: colors.primary.withValues(alpha: 0.25),
  blurRadius: 16,
  offset: Offset(0, 6),
)

// BARU (neutral, professional):
BoxShadow(
  color: Colors.black.withValues(alpha: 0.06),
  blurRadius: 12,
  offset: Offset(0, 2),
)
```

### Perubahan Balance Card Strategy

```dart
// SEKARANG (gradient emerald):
gradient: LinearGradient(
  colors: [colors.primaryDark, colors.primary],  // emerald gradient
)

// BARU (solid navy + gold accent):
// Light: Solid Navy (#0F172A) dengan teks putih + gold accent untuk amount
// Dark: Solid Slate-800 (#1E293B) dengan border subtle
// TANPA gradient
```

---

## Checklist S1

- [ ] Update `AppColorScheme.light` dengan palette baru
- [ ] Update `AppColorScheme.dark` dengan palette baru
- [ ] Ganti semua `GoogleFonts.plusJakartaSans` → `GoogleFonts.nunitoSans`
- [ ] Ganti `GoogleFonts.nunitoSansTextTheme` → `GoogleFonts.nunitoSansTextTheme`
- [ ] Update `app_themes.dart`: AppBar, button, input, nav, shadow styles
- [ ] Pastikan `fvm flutter analyze` clean
- [ ] Test visual light mode
- [ ] Test visual dark mode
- [ ] Verify WCAG contrast ratios (textPrimary on background, textSecondary on surface)
