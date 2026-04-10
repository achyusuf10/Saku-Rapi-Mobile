# S7 — Budget Module

**Dependency:** S2 (Global Widgets)
**Files:**
- `lib/features/budget/view/ui/budget_page.dart`
- `lib/features/budget/view/ui/budget_detail_page.dart`
- `lib/features/budget/view/ui/completed_budgets_page.dart`
- `lib/features/budget/view/widgets/` (6 files)

---

## Perubahan Utama

### Budget Summary Card (`budget_summary_card.dart`)
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Card style | Mungkin colored | Flat SakuCard |
| Total budget | Mungkin primary | `textPrimary` bold |
| Used/remaining | Colored bars | Semantic: green (under), gold (warning 80%), red (over 100%) |

### Budget Progress Bar (`budget_progress_bar.dart`)
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Track | surfaceVariant | surfaceVariant (slate) |
| Fill < 80% | income/success color | `success` (emerald 600/400) |
| Fill 80-99% | warning color | `warning` (gold) |
| Fill ≥ 100% | error color | `error` (red) |
| Height | ?? | 8.h (consistent) |
| Radius | ?? | 4.r |

### Budget Card Tile (`budget_card_tile.dart`)
- Card: SakuCard style
- Category icon: SakuCategoryIcon
- Budget amount: textPrimary
- Spent amount: semantic color based on threshold

### Budget Group Card (`budget_group_card.dart`)
- Header: h7 w600, textPrimary
- Group border: colors.border
- Collapse/expand icon: textSecondary

### Budget Form Sheet (`budget_form_sheet.dart`)
- Form fields: SakuTextField + SakuCurrencyField (S2)
- Category picker: SakuCategoryIcon
- Save button: SakuButton primary

### Budget Shimmer (`budget_shimmer.dart`)
- Otomatis ikut ShimmerWidget update

---

## Checklist S7

- [ ] Update `budget_summary_card.dart` — flat design, semantic colors
- [ ] Update `budget_progress_bar.dart` — track, fill colors
- [ ] Update `budget_card_tile.dart` — card, icon, amount styling
- [ ] Update `budget_group_card.dart` — header, border
- [ ] Update `budget_form_sheet.dart` — form fields
- [ ] Update `budget_shimmer.dart` — shimmer colors
- [ ] Update `budget_page.dart` — page layout
- [ ] Update `budget_detail_page.dart` — detail layout
- [ ] Update `completed_budgets_page.dart` — completed state styling
- [ ] Visual test light + dark
- [ ] Budget threshold colors correct (green < 80%, gold 80-99%, red ≥ 100%)
- [ ] Semua informasi tetap ditampilkan
