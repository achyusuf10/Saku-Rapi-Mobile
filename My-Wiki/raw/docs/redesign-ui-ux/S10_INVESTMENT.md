# S10 — Investment Module

**Dependency:** S2 (Global Widgets)
**Files:**
- `lib/features/investment/view/ui/investment_page.dart`
- `lib/features/investment/view/ui/investment_inactive_page.dart`
- `lib/features/investment/view/ui/investment_smart_form_page.dart`
- `lib/features/investment/view/ui/investment_detail_page.dart`
- `lib/features/investment/view/widgets/` (6 files)

---

## Perubahan Utama

### Investment Page
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Portfolio card | Mungkin styled | Flat SakuCard, total value in textPrimary bold |
| Gain/loss | Green/red | `income`/`expense` semantic colors |
| Asset list | Cards | Clean SakuCard tiles |

### Investment Detail
- Chart: neutral bg, semantic gain/loss colors
- Transaction list: clean dividers
- Buy/sell buttons: primary (navy) / outlined

### Investment Smart Form
- Form fields: SakuTextField + SakuCurrencyField
- Gold type / category pickers: clean sheet/dialog styling

### Custom Dialogs (`custom_asset_category_dialog.dart`, `custom_gold_type_dialog.dart`)
- Dialog: ikut SakuDialog style (S2)

### Sell Sheet (`investment_sell_sheet.dart`)
- Amount input: SakuCurrencyField
- Confirm: SakuButton primary

### Settings Sheet (`investment_settings_sheet.dart`)
- Toggle tiles: clean switch, textPrimary label
- Section headers: h7 w600

### Shimmer files
- Otomatis ikut ShimmerWidget update

---

## Checklist S10

- [x] Update `investment_page.dart` — portfolio card, asset list
- [x] Update `investment_inactive_page.dart` — inactive state
- [x] Update `investment_smart_form_page.dart` — form styling
- [x] Update `investment_detail_page.dart` — chart, detail, actions
- [x] Update `custom_asset_category_dialog.dart` — dialog style
- [x] Update `custom_gold_type_dialog.dart` — dialog style
- [x] Update `investment_sell_sheet.dart` — form styling
- [x] Update `investment_settings_sheet.dart` — settings styling
- [x] Update shimmer files — colors
- [x] Visual test light + dark
- [x] Gain/loss colors correct
- [x] Semua informasi tetap ditampilkan
