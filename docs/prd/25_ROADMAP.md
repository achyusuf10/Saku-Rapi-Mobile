# 25. Roadmap Pengembangan

[← Testing](24_TESTING.md) · [Index](00_INDEX.md) · [Keputusan Final →](26_KEPUTUSAN_FINAL.md)

---

## Phase Pengembangan

```mermaid
gantt
    title SakuRapi Development Phases
    dateFormat YYYY-MM-DD
    axisFormat %b

    section Foundation
    Phase 0 - Setup, theme, l10n, widgets     :done, p0, 2026-01-01, 14d
    Phase 1 - DB schema, RLS, triggers, RPC   :done, p1, after p0, 14d
    Phase 2 - Auth & bootstrap                :done, p2, after p1, 7d

    section Core Features
    Phase 3 - Wallets                         :done, p3, after p2, 10d
    Phase 4 - Manual transactions             :done, p4, after p3, 14d
    Phase 5 - History & dashboard             :done, p5, after p4, 14d
    Phase 6 - Categories                      :done, p6, after p5, 7d

    section Enhanced Features
    Phase 7 - Budgeting                       :done, p7, after p6, 14d
    Phase 8 - Voice parser                    :done, p8, after p7, 10d
    Phase 9 - OCR parser                      :done, p9, after p8, 10d
    Phase 10 - Notifications                  :done, p10, after p9, 7d

    section Advanced
    Phase 11 - Investments                    :done, p11, after p10, 14d
    Phase 12 - Polish, QA, performance        :active, p12, after p11, 14d
```

### Flowchart: Phase Dependencies

```mermaid
flowchart LR
    subgraph Foundation["Foundation"]
        P0["Phase 0\nSetup"]
        P1["Phase 1\nDB Schema"]
        P2["Phase 2\nAuth"]
        P0 --> P1 --> P2
    end

    subgraph Core["Core Features"]
        P3["Phase 3\nWallets"]
        P4["Phase 4\nTransactions"]
        P5["Phase 5\nHistory + Dash"]
        P6["Phase 6\nCategories"]
        P3 --> P4 --> P5 --> P6
    end

    subgraph Enhanced["Enhanced"]
        P7["Phase 7\nBudgeting"]
        P8["Phase 8\nVoice"]
        P9["Phase 9\nOCR"]
        P10["Phase 10\nNotifications"]
        P7 --> P8 --> P9 --> P10
    end

    subgraph Advanced["Advanced"]
        P11["Phase 11\nInvestments"]
        P12["Phase 12\nPolish QA"]
        P11 --> P12
    end

    Foundation --> Core --> Enhanced --> Advanced

    style Foundation fill:#455a64,color:#fff
    style Core fill:#2d6a4f,color:#fff
    style Enhanced fill:#1565c0,color:#fff
    style Advanced fill:#6a1b9a,color:#fff
```

---

[← Testing](24_TESTING.md) · [Index](00_INDEX.md) · [Keputusan Final →](26_KEPUTUSAN_FINAL.md)
