# S4 — Wallet Module

**Dependency:** S2 (Global Widgets)
**Files:**
- `lib/features/wallet/view/ui/wallet_page.dart`
- `lib/features/wallet/view/widgets/` (5 files)

---

## Perubahan Utama

### Wallet Summary Card (`wallet_summary_card.dart`)
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Card style | Mungkin gradient/colored | Flat SakuCard, solid surface |
| Total balance | Mungkin primary-colored | `textPrimary` bold |
| Summary info | Coloured text | Muted textSecondary + semantic colors |

### Wallet Card Tile (`wallet_card_tile.dart`)
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Card bg | surface | surface via SakuCard |
| Wallet icon | Mungkin colored circle | Neutral icon circle (primaryLight bg) |
| Balance | Possibly emerald | `textPrimary` bold |
| Selected state | Emerald tint | `primaryLight` bg + `primary` border |

### Wallet Form Sheet (`wallet_form_sheet.dart`)
- Form fields: ikuti SakuTextField updates (S2)
- Save button: SakuButton primary (navy)
- Input labels: consistent typography

### Wallet Adjust Sheet (`wallet_adjust_sheet.dart`)
- Currency input: SakuCurrencyField (S2)
- Reason field: SakuTextField (S2)
- Confirm button: SakuButton primary

### Wallet Shimmer (`wallet_shimmer.dart`)
- Otomatis ikut ShimmerWidget update

---

## Checklist S4

- [ ] Update `wallet_summary_card.dart` — flat design
- [ ] Update `wallet_card_tile.dart` — neutral icon, clean balance
- [ ] Update `wallet_form_sheet.dart` — form styling
- [ ] Update `wallet_adjust_sheet.dart` — input styling
- [ ] Update `wallet_shimmer.dart` — shimmer colors
- [ ] Update `wallet_page.dart` — overall layout
- [ ] Visual test light + dark
- [ ] Semua informasi tetap ditampilkan
