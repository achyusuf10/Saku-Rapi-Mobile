# S11 — Auth, Settings & Misc Modules

**Dependency:** S2 (Global Widgets)
**Files:**
- `lib/features/auth/view/ui/splash_page.dart`
- `lib/features/auth/view/ui/login_page.dart`
- `lib/features/auth/view/widgets/profile_header_widget.dart`
- `lib/features/settings/view/ui/settings_page.dart`
- `lib/features/settings/view/widgets/settings_tile.dart`
- `lib/features/category/view/ui/category_management_page.dart`
- `lib/features/category/view/widgets/` (5 files)
- `lib/features/notification/view/ui/notification_settings_page.dart`
- `lib/features/voice/view/ui/voice_input_sheet.dart`
- `lib/features/voice/view/ui/text_input_sheet.dart`
- `lib/features/ocr/view/ui/ocr_result_sheet.dart`

---

## Auth

### Splash Page
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Background | Mungkin primary/gradient | Clean: background color + centered logo |
| Logo | Mungkin emerald | Navy logo (light) / White logo (dark) |
| Loading | Mungkin primary spinner | Subtle loading bar, primary color |

### Login Page
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Form fields | SakuTextField | Ikut S2 update |
| Login button | Primary (emerald) | Primary (navy) |
| Social login | Mungkin styled | Clean outlined buttons |
| Error state | Red text | Error color from theme |

### Profile Header
- Avatar circle: neutral bg
- Name: h6 bold, textPrimary
- Email: b2, textSecondary

---

## Settings

### Settings Page & Tile
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Tile icon | Mungkin colored | `textSecondary` icons |
| Tile text | textPrimary | textPrimary |
| Subtitle | textSecondary | textSecondary |
| Switch | Emerald | Primary color (navy/slate) |
| Divider | Mungkin hardcoded | `colors.border` |
| Arrow/chevron | Mungkin primary | textSecondary |

---

## Category Management

### Category List & Form
- Category icons: SakuCategoryIcon (S2)
- Color picker: clean grid
- Icon picker: clean grid
- Form: SakuTextField + SakuButton

---

## Voice & OCR

### Voice Input Sheet
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Mic button | Mungkin primary circle | Navy circle (light) / Slate circle (dark) |
| Waveform | Mungkin primary | Primary color |
| Results | Card style | Clean SakuCard |

### Text Input Sheet
- Input field: SakuTextField
- Send button: primary color

### OCR Result Sheet
- Scanned items: clean list with dividers
- Edit fields: SakuTextField
- Save button: SakuButton primary

---

## Checklist S11

- [ ] Update `splash_page.dart` — clean bg, logo
- [ ] Update `login_page.dart` — form, button, error styling
- [ ] Update `profile_header_widget.dart` — avatar, text styling
- [ ] Update `settings_page.dart` — tile styling
- [ ] Update `settings_tile.dart` — icon, text, switch colors
- [ ] Update `category_management_page.dart` — list styling
- [ ] Update category widgets (5 files) — picker, form, tile styling
- [ ] Update `notification_settings_page.dart` — toggle styling
- [ ] Update `voice_input_sheet.dart` — mic button, waveform
- [ ] Update `text_input_sheet.dart` — input styling
- [ ] Update `ocr_result_sheet.dart` — list, edit, save styling
- [ ] Visual test light + dark
- [ ] Semua informasi tetap ditampilkan
