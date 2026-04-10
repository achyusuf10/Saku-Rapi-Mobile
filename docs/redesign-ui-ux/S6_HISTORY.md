# S6 — History Module

**Dependency:** S2 (Global Widgets)
**Files:**
- `lib/features/history/view/ui/history_page.dart`
- `lib/features/history/view/widgets/` (5 files)

---

## Perubahan Utama

### History Transaction Tile (`history_transaction_tile.dart`)
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Amount color | Semantic (income/expense) | Tetap semantic, pakai theme colors |
| Category icon | SakuCategoryIcon | Ikut S2 update |
| Date text | textSecondary | textSecondary |
| Divider | Mungkin hardcoded | `colors.border` |

### History Filter Sheet (`history_filter_sheet.dart`)
- Filter chips: `primaryLight` bg saat aktif, `surfaceVariant` saat inaktif
- Apply button: SakuButton primary (navy)
- Reset button: TextButton, textSecondary color

### History Period Selector (`history_period_selector.dart`)
- Ikut SakuPeriodSelector style dari S2

### History Sub Period Tabs (`history_sub_period_tabs.dart`)
- Ikut SakuSubPeriodTabs style dari S2

### History Shimmer (`history_shimmer.dart`)
- Otomatis ikut ShimmerWidget update

---

## Checklist S6

- [ ] Update `history_transaction_tile.dart` — colors, dividers
- [ ] Update `history_filter_sheet.dart` — chip/button styling
- [ ] Update `history_period_selector.dart` — selector styling
- [ ] Update `history_sub_period_tabs.dart` — tab styling
- [ ] Update `history_shimmer.dart` — shimmer colors
- [ ] Update `history_page.dart` — page layout
- [ ] Visual test light + dark
- [ ] Semua informasi tetap ditampilkan
