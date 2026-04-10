# S2 — Global Widgets Overhaul

**Priority:** 🔴 Critical (semua feature screens bergantung pada global widgets)
**Dependency:** S1 (Design Tokens)
**Files:** ~23 files di `lib/global/widgets/`

---

## Prinsip Redesign Widgets

1. **Gunakan warna dari theme** — Tidak ada hardcoded color
2. **Kurangi border radius** — Dari 16-20r ke 12r (lebih refined)
3. **Shadow neutral** — `Colors.black` alpha, bukan primary-tinted
4. **Tipografi konsisten** — Semua pakai `TextStyleConstants` + `context.colors`
5. **Spacing konsisten** — Base unit 8, padding 16.w standar

---

## Widget-by-Widget Plan

### SakuButton (`saku_button.dart`)
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Primary bg | Emerald | Navy (light) / Slate-200 (dark) |
| Border radius | 12.r | 12.r (tetap) |
| Outlined style | Emerald border | Navy border (light) / Slate-200 border (dark) |
| Disabled | Opacity | Grayed out + opacity |
| Height | 48.h | 48.h (tetap) |
| Font weight | w600 | w600 (tetap) |

### SakuCard (`saku_card.dart`)
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Default radius | 16.r | 12.r |
| Shadow | Possible primary-tinted | Neutral black alpha: 0.04 (light) / 0.15 (dark) |
| Border | `colors.border.withValues(alpha: 0.5)` | `colors.border` (full opacity, subtle) |
| Padding default | 16.w | 16.w (tetap) |

### SakuTextField (`saku_text_field.dart`)
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Fill color | surfaceVariant (emerald-50) | surfaceVariant (slate-100/700) |
| Focus border | Emerald | Navy (light) / Slate-200 (dark) |
| Label style | label1 | label1 w/ textSecondary color |
| Error style | Red | Same (error color from theme) |
| Radius | 12.r | 12.r (tetap) |

### SakuCurrencyField (`saku_currency_field.dart`)
- Ikuti perubahan SakuTextField
- Calculator keyboard: update warna tombol sesuai theme baru

### SakuDialog (`saku_dialog.dart`)
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Icon circle bg | primary 15% alpha | primary 10% alpha |
| Radius | 20.r | 16.r |
| Shadow | black 15% | black 8% |
| Positive btn | Primary (emerald) | Primary (navy/slate) |
| Title | h6 bold | h6 w600 |

### SakuEmptyState (`saku_empty_state.dart`)
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Icon color | textSecondary 40% alpha | textSecondary 50% alpha |
| Icon size | 48.w | 48.w (tetap) |
| Title style | h7 w600 | h7 w600 (tetap) |
| Action button | TextButton.icon | TextButton.icon dengan primary color |

### SakuErrorState (`saku_error_state.dart`)
- Mirip dengan EmptyState
- Retry button: primary color (navy)

### SakuDropdown (`saku_dropdown.dart`)
- Border dan fill color ikuti theme baru
- Selected indicator: primary color

### SakuBottomSheet (`saku_bottom_sheet.dart`)
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Handle bar | Mungkin hardcoded | `colors.border` atau `textSecondary.withValues(alpha: 0.3)` |
| Radius | 20.r (top) | 16.r (top) |
| Background | surface | surface |

### SakuPeriodSelector (`saku_period_selector.dart`)
- Active tab: primary bg (navy) + onPrimary text
- Inactive tab: surface + textSecondary

### SakuSubPeriodTabs (`saku_sub_period_tabs.dart`)
- Sama dengan PeriodSelector

### SakuWalletFilterButton, SakuWalletPickerSheet, SakuWalletPickerTile
- Icon colors: primary (navy)
- Selected state: primaryLight bg + primary text
- Border: `colors.border`

### SakuCategoryIcon (`saku_category_icon.dart`)
- Container bg: category color with 10-15% alpha
- Icon color: category color (full)
- Border radius: 10.r (lebih kecil, refined)

### ShimmerWidget
- Base color: `surfaceVariant` (slate-100/700)
- Highlight color: `surface` (white/slate-800)
- Pastikan visible di kedua mode

### Calculator Widgets
- Key bg: `surfaceVariant`
- Key text: `textPrimary`
- Operator keys: `primary` bg
- Equal key: `accent` (gold) bg

### SakuLoadingIndicator
- Color: `primary` (navy/slate-200)
- Track: `surfaceVariant`

---

## Checklist S2

- [ ] Update SakuButton — colors, states
- [ ] Update SakuCard — radius, shadow, border
- [ ] Update SakuTextField — fill, focus, label colors
- [ ] Update SakuCurrencyField — inherit TextField changes
- [ ] Update SakuDialog — icon, radius, shadow, buttons
- [ ] Update SakuEmptyState — icon, button colors
- [ ] Update SakuErrorState — icon, button colors
- [ ] Update SakuDropdown — border, selection color
- [ ] Update SakuBottomSheet — handle, radius
- [ ] Update SakuPeriodSelector — tab colors
- [ ] Update SakuSubPeriodTabs — tab colors
- [ ] Update SakuWalletFilterButton — icon, selection
- [ ] Update SakuWalletPickerSheet — selection state
- [ ] Update SakuWalletPickerTile — selected indicator
- [ ] Update SakuCategoryIcon — bg alpha, radius
- [ ] Update ShimmerWidget — base/highlight colors
- [ ] Update Calculator widgets — key colors
- [ ] Update SakuLoadingIndicator — color, track
- [ ] Update remaining global widgets
- [ ] `fvm flutter analyze` clean
- [ ] Visual test light mode
- [ ] Visual test dark mode
