# 8. Wallets

[← Dashboard](07_DASHBOARD.md) · [Index](00_INDEX.md) · [Transaksi →](09_TRANSAKSI.md)

---

## 8.1. Deskripsi
Manajemen multi-dompet. Setiap wallet punya nama, icon, warna, dan saldo. Balance hanya berubah melalui ledger transaksi.

## 8.2. UI Layout

```
┌─────────────────────────────────────┐
│  Dompet                    [+ FAB] │  ← AppBar
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐    │
│  │  TOTAL SALDO               │    │  ← WalletSummaryCard
│  │  Rp 12.500.000  (3 dompet) │    │     (gradient card)
│  └─────────────────────────────┘    │
├─────────────────────────────────────┤
│  📂 Termasuk dalam total            │  ← Section header
│  ┌─ 💰 Cash         Rp 5.000.000 ┐ │
│  ├─ 📱 Dana         Rp 4.500.000 ┤ │  ← WalletTile + popup menu
│  └─ 📱 OVO          Rp 3.000.000 ┘ │     (Edit, Adjust, Delete)
├─────────────────────────────────────┤
│  📂 Dikecualikan dari total         │  ← Section header
│  └─ 🏦 Tabungan     Rp 50.000.000┘ │
└─────────────────────────────────────┘
```

## 8.3. Forms

**WalletFormSheet (Bottom Sheet):**

| Mode | Fields yang Tampil |
|---|---|
| **Create** | Name, Initial Balance, Icon Picker, Color Picker, Exclude Toggle |
| **Edit** | Name, Icon Picker, Color Picker, Exclude Toggle (**tanpa** Initial Balance) |

Validasi:
- Name required, trimmed, unique per user (case-insensitive)
- Initial balance ≥ 0 (hanya saat create)

**WalletAdjustSheet (Bottom Sheet) — Koreksi Saldo:**
- Tampilkan: nama wallet, saldo saat ini
- Input: target balance (saldo aktual sekarang)
- Tampilkan selisih: +/- berwarna (hijau/merah)
- Validasi: target ≠ saldo saat ini
- Save → RPC `create_adjustment_transaction`

### Flowchart: Wallet CRUD Flow

```mermaid
flowchart TD
    A([Wallet Page]) --> B{User action?}

    B -->|FAB +| C[WalletFormSheet\nmode: Create]
    B -->|Popup: Edit| D[WalletFormSheet\nmode: Edit]
    B -->|Popup: Adjust| E[WalletAdjustSheet]
    B -->|Popup: Delete| F{Wallet punya\ntransaksi?}

    C --> G["Isi: Name, Initial Balance,\nIcon, Color, Exclude"]
    G --> H{Validasi}
    H -->|Name duplicate| I["⚠️ Error:\nnama sudah ada"]
    H -->|✅ Valid| J["RPC create wallet"]
    J --> K["Refresh wallet list"]

    D --> L["Edit: Name,\nIcon, Color, Exclude"]
    L --> H

    E --> M["Input target balance\nTampilkan selisih"]
    M --> N{target ≠\nsaldo saat ini?}
    N -->|❌ Sama| O["⚠️ Tidak ada\nperubahan"]
    N -->|✅ Berbeda| P["RPC create_adjustment_transaction\ntype = adjustment"]
    P --> K

    F -->|Ya| Q["⚠️ DIBLOK:\nHapus tidak bisa"]
    F -->|Tidak| R["Konfirmasi delete"]
    R --> S["DELETE wallet"]
    S --> K

    style K fill:#2d6a4f,color:#fff
    style I fill:#d32f2f,color:#fff
    style Q fill:#d32f2f,color:#fff
```

### Flowchart: Balance Adjustment Flow

```mermaid
flowchart TD
    A([User pilih\nAdjust Saldo]) --> B["WalletAdjustSheet\nSaldo saat ini: Rp X"]
    B --> C["Input: Target Balance\n(saldo aktual)"]
    C --> D["Hitung selisih:\ntarget - current"]
    D --> E{Selisih?}

    E -->|"> 0 (Surplus)"| F["Tampilkan\n+Rp Y (hijau)"]
    E -->|"< 0 (Deficit)"| G["Tampilkan\n-Rp Y (merah)"]
    E -->|"= 0"| H["⚠️ Tombol\nsave disabled"]

    F --> I["Submit RPC\ncreate_adjustment_transaction"]
    G --> I
    I --> J["DB Trigger:\nupdate_wallet_balance"]
    J --> K["Saldo wallet\nterupdate"]

    style K fill:#2d6a4f,color:#fff
    style H fill:#ff8f00,color:#000
```

## 8.4. Aturan Bisnis
- `balance` adalah **READ-ONLY** di client — hanya berubah via trigger
- Transfer antar dompet = 1 record `type='transfer'` + `destination_wallet_id`
- Ordering: `sort_order ASC`, `created_at ASC`
- Caching: list wallet di-cache ke Hive

## 8.5. Acceptance Criteria
- [x] Transfer ke wallet sama → diblok
- [x] Delete wallet yang punya transaksi → diblok
- [x] Dashboard total hanya wallet `exclude_from_total = false`
- [x] Name duplicate (case-insensitive) → diblok di create & update
- [x] Balance adjustment → buat transaksi `type = adjustment` via RPC

---

[← Dashboard](07_DASHBOARD.md) · [Index](00_INDEX.md) · [Transaksi →](09_TRANSAKSI.md)
