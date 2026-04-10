# 24. Testing Requirements

[← Permissions](23_PERMISSIONS.md) · [Index](00_INDEX.md) · [Roadmap →](25_ROADMAP.md)

---

## 24.1. Minimum Test Coverage

| Layer | Yang Ditest |
|---|---|
| Unit test | Repository: transaction create/update/delete |
| Unit test | Controller: history filter/grouping |
| Unit test | Local parser: voice & OCR fallback |
| Widget test | Form transaksi |
| Integration test | Login → dashboard |
| Integration test | Create expense, create transfer |
| Integration test | Multi-item save |
| Integration test | Budget usage update |

## 24.2. Assertion Penting
- Saldo wallet berubah sesuai matrix tipe transaksi
- Budget **TIDAK** menghitung transfer/settlement
- Settlement **TIDAK** masuk laporan
- Investment deduction **TIDAK** double count

### Flowchart: Test Pyramid

```mermaid
flowchart TD
    subgraph Unit["🔬 Unit Tests (Terbanyak)"]
        U1["Repository CRUD"]
        U2["Controller logic\n(filter, grouping)"]
        U3["Local parser\n(voice + OCR)"]
        U4["Model serialization\n(fromJson/toJson)"]
    end

    subgraph Widget["🧩 Widget Tests"]
        W1["Form transaksi\n(validasi, field visibility)"]
        W2["Budget progress bar\n(color coding)"]
    end

    subgraph Integration["🔗 Integration Tests (Termahal)"]
        I1["Login → Dashboard"]
        I2["Create expense → wallet balance"]
        I3["Multi-item save → items table"]
        I4["Budget usage update → trigger"]
    end

    Integration --> Widget --> Unit

    style Unit fill:#2d6a4f,color:#fff
    style Widget fill:#1565c0,color:#fff
    style Integration fill:#6a1b9a,color:#fff
```

### Flowchart: Key Test Assertions

```mermaid
flowchart LR
    subgraph Wallet["Wallet Balance"]
        WA["income → +balance"]
        WB["expense → -balance"]
        WC["transfer → -asal, +tujuan"]
        WD["adjustment → ±balance"]
    end

    subgraph Budget["Budget Scope"]
        BA["expense → masuk budget ✅"]
        BB["transfer → TIDAK masuk ❌"]
        BC["settlement → TIDAK masuk ❌"]
    end

    subgraph Report["Report Scope"]
        RA["income/expense → masuk ✅"]
        RB["settlement → TIDAK masuk ❌"]
    end

    subgraph Investment["Investment"]
        IA["transfer_to_asset → -wallet"]
        IB["income (sell) → +wallet"]
        IC["NO double count\ndi total saldo"]
    end
```

---

[← Permissions](23_PERMISSIONS.md) · [Index](00_INDEX.md) · [Roadmap →](25_ROADMAP.md)
