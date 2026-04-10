# S5 — Transaction Module

**Dependency:** S2 (Global Widgets)
**Files:**
- `lib/features/transaction/view/ui/transaction_form_page.dart`
- `lib/features/transaction/view/ui/transaction_detail_page.dart`
- `lib/features/transaction/view/widgets/` (14 files)

---

## Perubahan Utama

### Transaction Type Selector (`transaction_type_selector.dart`, `transaction_type_tabs.dart`)
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Active tab | Mungkin emerald bg | Tab color = semantic color (income→emerald, expense→red, transfer→blue) |
| Inactive tab | Muted | `surfaceVariant` bg + `textSecondary` text |
| Tab style | Mungkin pill/chip | Clean pill tabs, 8.r radius |

### Transaction Amount Section (`transaction_amount_section.dart`)
- Currency input: SakuCurrencyField (ikut S2)
- Amount color: semantic transaction type color

### Category Picker (`transaction_category_picker_tile.dart`)
- Category icon: SakuCategoryIcon (ikut S2)
- Selected state: `primaryLight` bg

### Date Picker (`transaction_date_picker_tile.dart`)
- Icon: `textSecondary` color
- Date text: `textPrimary`
- Picker theme: ikut `app_themes.dart` date picker config

### Wallet Picker (in form)
- Ikuti SakuWalletPickerTile updates

### Transfer Arrow (`transaction_transfer_arrow.dart`)
- Arrow icon: `transfer` color
- Circle bg: `transfer.withValues(alpha: 0.1)`

### Transaction Items (`transaction_item_row.dart`, `transaction_multi_item_section.dart`)
- Item rows: subtle border bottom, 16.w padding
- Add button: outline style, primary color

### Optional Details Section (`transaction_optional_details_section.dart`)
- Expandable section: clean divider
- Fields: SakuTextField style

### Debt/Loan Pickers (`debt_loan_kind_selector.dart`, etc.)
- Semantic colors untuk debt (orange) dan loan (purple)

### Contact Picker (`contact_picker_sheet.dart`, `contact_picker_tile.dart`)
- Avatar: neutral circle bg
- Name: textPrimary
- Phone: textSecondary

### Form Save Bar (`transaction_form_save_bar.dart`)
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Save button | Primary (emerald) | Primary (navy) |
| Bar bg | surface | surface + top border |

### Transaction Detail Page (`transaction_detail_page.dart`)
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Amount display | Mungkin colored large | Semantic color, h5 bold |
| Detail rows | Mungkin inconsistent | Clean label-value rows, dividers |
| Action buttons | Emerald-themed | Primary (navy) |

---

## Checklist S5

- [ ] Update `transaction_type_selector.dart` — semantic tab colors
- [ ] Update `transaction_type_tabs.dart` — tab styling
- [ ] Update `transaction_amount_section.dart` — currency field
- [ ] Update `transaction_category_picker_tile.dart` — icon, selection
- [ ] Update `transaction_date_picker_tile.dart` — icon, text colors
- [ ] Update `transaction_transfer_arrow.dart` — arrow styling
- [ ] Update `transaction_item_row.dart` — row styling
- [ ] Update `transaction_multi_item_section.dart` — section styling
- [ ] Update `transaction_optional_details_section.dart` — field styling
- [ ] Update `debt_loan_kind_selector.dart` — semantic colors
- [ ] Update `debt_loan_transaction_picker_tile.dart` — tile styling
- [ ] Update `contact_picker_sheet.dart` — sheet styling
- [ ] Update `contact_picker_tile.dart` — tile styling
- [ ] Update `transaction_form_save_bar.dart` — bar/button
- [ ] Update `transaction_form_page.dart` — page layout
- [ ] Update `transaction_detail_page.dart` — detail layout
- [ ] Update `unpaid_transaction_picker_sheet.dart` — sheet styling
- [ ] Visual test light + dark
- [ ] Semua informasi tetap ditampilkan
