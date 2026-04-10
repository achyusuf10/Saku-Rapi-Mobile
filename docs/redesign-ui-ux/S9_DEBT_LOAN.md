# S9 — Debt/Loan Module

**Dependency:** S2 (Global Widgets)
**Files:**
- `lib/features/debt_loan/view/ui/debt_loan_page.dart`
- `lib/features/debt_loan/view/ui/debt_loan_person_page.dart`
- `lib/features/debt_loan/view/ui/settlement_history_page.dart`
- `lib/features/debt_loan/view/widgets/` (4 files)

---

## Perubahan Utama

### Semantic Colors
- Debt (Hutang): `debt` color — Orange 600 (light) / Orange 400 (dark)
- Loan (Piutang): `loan` color — Purple 600 (light) / Purple 400 (dark)

### Debt/Loan Cards
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Card | Mungkin colored border | SakuCard + left accent border (debt/loan color) |
| Person name | textPrimary | `textPrimary` h7 w600 |
| Amount | Debt/loan color | Semantic color, b1 bold |
| Status badge | Mungkin chip | Subtle chip: semantic color bg 10% + text |

### Settlement Sheet (`debt_loan_settlement_sheet.dart`)
- Amount input: SakuCurrencyField
- Wallet picker: SakuWalletPickerTile
- Confirm button: SakuButton primary

### Shimmer files
- Otomatis ikut ShimmerWidget update

---

## Checklist S9

- [ ] Update `debt_loan_page.dart` — page layout, tab styling
- [ ] Update `debt_loan_person_page.dart` — person detail styling
- [ ] Update `settlement_history_page.dart` — history list styling
- [ ] Update `debt_loan_settlement_sheet.dart` — form styling
- [ ] Update shimmer files — colors
- [ ] Visual test light + dark
- [ ] Debt orange / Loan purple colors correct
- [ ] Semua informasi tetap ditampilkan
