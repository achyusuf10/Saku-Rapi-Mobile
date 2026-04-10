# S3 — Dashboard & Home

**Dependency:** S2 (Global Widgets)
**Files:**
- `lib/features/dashboard/view/ui/dashboard_page.dart`
- `lib/features/dashboard/view/widgets/` (10 files)

---

## Perubahan Utama

### Dashboard Balance Card (`dashboard_balance_card.dart`)
**Ini perubahan visual terbesar — menghilangkan kesan vibe-coding.**

| Aspek | Sekarang | Baru |
|-------|----------|------|
| Style | Gradient emerald + primary shadow | Solid flat card |
| Light mode | Emerald gradient (#059669 → #10B981) | Solid Navy (#0F172A) + white text |
| Dark mode | Dark emerald gradient (#065F46 → #047857) | Solid Slate-800 (#1E293B) + subtle border |
| Balance text | White on gradient | White on navy (light) / Slate-100 on Slate-800 (dark) |
| Total amount | Possibly accent/gold | White bold (light) / Gold accent (dark) |
| Shadow | primary 25% alpha, blur 16 | black 8% alpha, blur 8 (light) / none (dark) |
| Radius | 20.r | 12.r |

### Dashboard Quick Actions (`dashboard_quick_actions.dart`)
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Icon bg | Mungkin primary-tinted | `primaryLight` (slate-200/800) with icon in `primary` |
| Icon radius | Mungkin bulat | 10.r rounded square |
| Label | b2 atau caption | caption w/ textSecondary |

### Dashboard Wallet Section (`dashboard_wallet_section.dart`)
- Wallet cards: `SakuCard` style (otomatis ikut S2)
- Balance display: `textPrimary` + b1 bold
- Wallet icon/name: consistent dengan theme baru

### Dashboard Period Summary (`dashboard_period_summary.dart`)
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Income amount | Green (income color) | `income` color dari theme |
| Expense amount | Red (expense color) | `expense` color dari theme |
| Card bg | surface | surface (otomatis ikut S1) |

### Dashboard Charts (`dashboard_chart_carousel.dart`, `dashboard_expense_report_chart.dart`, etc.)
| Aspek | Sekarang | Baru |
|-------|----------|------|
| Chart colors | Mungkin hardcoded | Gunakan theme transaction colors |
| Chart bg | surface | surface |
| Axis labels | textSecondary | textSecondary |
| Grid lines | border color | border color |

### Dashboard Recent Transactions (`dashboard_recent_transactions.dart`)
- Transaction tiles: gunakan SakuCard + proper spacing
- Amount colors: income/expense dari theme
- Category icons: ikuti SakuCategoryIcon updates

### Dashboard Shimmer (`dashboard_shimmer.dart`)
- Otomatis ikut ShimmerWidget update dari S2

### Chart Fullscreen Dialog (`chart_fullscreen_dialog.dart`)
- Dialog bg: surface
- Chart render: same as inline charts

---

## Visual Direction

```
Light Mode Dashboard:
┌────────────────────────────────┐
│  ◄ AppBar (flat, no shadow)    │
├────────────────────────────────┤
│  ┌──────────────────────────┐  │
│  │   TOTAL BALANCE          │  │  ← Solid navy card
│  │   Rp 12.500.000         │  │  ← White bold text
│  │   +Rp 2.1jt  -Rp 800rb  │  │  ← Subtle white 70%
│  └──────────────────────────┘  │
│                                │
│  Quick Actions                 │
│  [💰] [📊] [💳] [📋]         │  ← Muted icons, slate bg
│                                │
│  Period Summary                │
│  Income  +Rp 2.100.000  ■     │  ← Emerald 600
│  Expense -Rp 800.000    ■     │  ← Red 600
│                                │
│  Recent Transactions           │
│  ┌──────────────────────────┐  │
│  │ 🛒 Groceries   -Rp 150k │  │  ← Clean card, 12.r
│  └──────────────────────────┘  │
└────────────────────────────────┘

Dark Mode Dashboard:
- Background: #0F172A (neutral dark)
- Balance card: #1E293B + subtle border
- Cards: #1E293B + border #334155
- Text: Slate-100 primary, Slate-400 secondary
- NO neon, NO glow effects
```

---

## Checklist S3

- [ ] Redesign `dashboard_balance_card.dart` — solid flat design
- [ ] Update `dashboard_quick_actions.dart` — muted icon style
- [ ] Update `dashboard_wallet_section.dart` — card style
- [ ] Update `dashboard_period_summary.dart` — amount colors
- [ ] Update `dashboard_chart_carousel.dart` — chart colors
- [ ] Update `dashboard_expense_report_chart.dart` — chart styling
- [ ] Update `dashboard_comparison_chart.dart` — chart styling
- [ ] Update `dashboard_trend_report_chart.dart` — chart styling
- [ ] Update `dashboard_recent_transactions.dart` — tile style
- [ ] Update `dashboard_shimmer.dart` — shimmer colors
- [ ] Update `chart_fullscreen_dialog.dart` — dialog style
- [ ] Update `dashboard_page.dart` — overall page styling
- [ ] Visual test light + dark mode
- [ ] Semua informasi yang ada sekarang tetap ditampilkan
