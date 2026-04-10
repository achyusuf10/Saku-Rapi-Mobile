# S8 — Reports & Charts

**Dependency:** S2 (Global Widgets)
**Files:**
- `lib/features/reports/view/ui/report_page.dart`
- `lib/features/reports/view/ui/report_category_transactions_page.dart`
- `lib/features/reports/view/widgets/` (6 files)

---

## Perubahan Utama

### Report Summary Card (`report_summary_card.dart`)
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Card | Mungkin colored bg | Flat SakuCard |
| Income total | income color | `income` dari theme |
| Expense total | expense color | `expense` dari theme |
| Net | Mungkin primary | Semantic: positif → income, negatif → expense |

### Category Pie Chart (`report_category_pie_chart.dart`)
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Chart colors | Category colors | Category colors (tetap) — ini semantic |
| Center text | Mungkin primary | `textPrimary` |
| Legend text | Mungkin inconsistent | `textSecondary` for labels, `textPrimary` for values |
| Chart bg | surface | surface |

### Category Bar Chart (`report_category_chart.dart`)
- Bar colors: category semantic colors
- Axis labels: textSecondary
- Grid lines: border color with 30% alpha

### Trend Chart (`report_trend_chart.dart`)
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Line colors | income/expense | `income`/`expense` from theme |
| Grid | Mungkin hardcoded | `border.withValues(alpha: 0.3)` |
| Tooltip | Mungkin styled | Clean tooltip with surface bg + border |
| Dots | Mungkin primary | Same as line color |

### Report Sub Period Tabs (`report_sub_period_tabs.dart`)
- Ikut SakuSubPeriodTabs dari S2

### Report Shimmer (`report_shimmer.dart`)
- Otomatis ikut ShimmerWidget update

---

## Chart Color Guidelines

Charts tetap menggunakan warna semantic karena warna chart punya meaning khusus.
Yang berubah:
- Background: neutral surface
- Labels/axis: neutral text colors
- Grid: subtle border color
- Tooltip: clean surface + border

---

## Checklist S8

- [ ] Update `report_summary_card.dart` — flat design
- [ ] Update `report_category_pie_chart.dart` — neutral bg, legend styling
- [ ] Update `report_category_chart.dart` — bar/axis styling
- [ ] Update `report_trend_chart.dart` — line, grid, tooltip styling
- [ ] Update `report_sub_period_tabs.dart` — tab styling
- [ ] Update `report_shimmer.dart` — shimmer colors
- [ ] Update `report_page.dart` — page layout
- [ ] Update `report_category_transactions_page.dart` — list styling
- [ ] Visual test light + dark
- [ ] Chart warna semantic correct
- [ ] Semua informasi tetap ditampilkan
