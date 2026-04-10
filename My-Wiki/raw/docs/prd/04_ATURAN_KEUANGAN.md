# 4. Aturan Keuangan Fundamental

[← KPI Target](03_KPI_TARGET.md) · [Index](00_INDEX.md) · [User Flows →](05_USER_FLOWS.md)

---

> **Bagian ini WAJIB dipahami oleh semua developer.**
> Aturan ini berlaku di seluruh aplikasi dan tidak boleh dilanggar.

## 4.1. Sumber Kebenaran Saldo Wallet

```
┌───────────────────────────────────────────────────────┐
│  ATURAN EMAS: Wallet balance HANYA berubah melalui    │
│  tabel `transactions` via database trigger.            │
│                                                       │
│  ❌ DILARANG mengubah balance langsung dari Flutter    │
│  ❌ DILARANG ada trigger lain di luar ledger          │
│  ✅ Semua mutasi saldo harus tercatat di transactions │
└───────────────────────────────────────────────────────┘
```

### Flowchart: Alur Perubahan Saldo Wallet

```mermaid
flowchart TD
    A([Aksi User]) --> B{Tipe aksi?}

    B -->|Expense / Income| C["RPC create transaction\n(type, amount, wallet_id)"]
    B -->|Transfer| D["RPC create transaction\n(wallet_id + destination_wallet_id)"]
    B -->|Debt / Loan| E["RPC create transaction\n(with_person, wallet_id)"]
    B -->|Adjustment| F["RPC create_adjustment\n(target balance)"]
    B -->|Beli Investasi| G["RPC create_investment_asset\n(deduct_wallet = true)"]

    C --> H["INSERT INTO transactions"]
    D --> H
    E --> H
    F --> H
    G --> H

    H --> I["DB Trigger:\nupdate_wallet_balance"]
    I --> J["wallet.balance\nterupdate otomatis"]

    style J fill:#2d6a4f,color:#fff
    style I fill:#1565c0,color:#fff
```

## 4.2. Matrix Tipe Transaksi

Tabel ini menjelaskan apa yang terjadi untuk setiap tipe transaksi:

| `type` | Arah Kas Wallet | Masuk Laporan? | Masuk Budget? | Butuh Wallet Tujuan? | Butuh `with_person`? |
|---|:---:|:---:|:---:|:---:|:---:|
| `income` | + (masuk) | ✅ Ya | ❌ Tidak | ❌ | ❌ |
| `expense` | - (keluar) | ✅ Ya | ✅ Ya | ❌ | ❌ |
| `transfer` | - asal, + tujuan | ❌ Tidak | ❌ Tidak | ✅ Wajib | ❌ |
| `debt` | + (pinjaman masuk) | ❌ Tidak | ❌ Tidak | ❌ | ✅ Wajib |
| `loan` | - (pinjamkan keluar) | ❌ Tidak | ❌ Tidak | ❌ | ✅ Wajib |
| `adjustment` | +/- (koreksi) | ❌ Tidak | ❌ Tidak | ❌ | ❌ |
| `transfer_to_asset` | - (beli aset) | ❌ Tidak | ❌ Tidak | ❌ | ❌ |

> **Ringkasan Sederhana:**
> - **Laporan** hanya menghitung `income` dan `expense` (bukan settlement).
> - **Budget** hanya menghitung `expense` (bukan settlement).
> - **Transfer, debt, loan, adjustment, transfer_to_asset** TIDAK masuk laporan maupun budget.

### Flowchart: Aliran Uang per Tipe

```mermaid
flowchart LR
    subgraph Masuk_Laporan["📊 Masuk Laporan"]
        INC["income\n+ wallet"]
        EXP["expense\n- wallet"]
    end

    subgraph Tidak_Laporan["🚫 Tidak Masuk Laporan"]
        TRF["transfer\n- asal, + tujuan"]
        DEBT["debt\n+ wallet (pinjam)"]
        LOAN["loan\n- wallet (pinjamkan)"]
        ADJ["adjustment\n+/- koreksi"]
        TTA["transfer_to_asset\n- wallet (beli aset)"]
    end

    subgraph Masuk_Budget["📊 Masuk Budget"]
        EXP2["expense saja"]
    end

    EXP -.->|"juga"| EXP2

    style Masuk_Laporan fill:#2d6a4f,color:#fff
    style Tidak_Laporan fill:#455a64,color:#fff
    style Masuk_Budget fill:#1565c0,color:#fff
```

## 4.3. Aturan Settlement (Pelunasan Hutang/Piutang)

| Jenis Settlement | `settlement_kind` | `type` transaksi | Penjelasan |
|---|---|---|---|
| Bayar hutang | `debt_payment` | `expense` | User membayar hutangnya |
| Terima piutang | `loan_collection` | `income` | User menerima pembayaran piutang |

**Aturan penting:**
- Settlement **DIKECUALIKAN** dari laporan dan budget (meskipun type-nya income/expense)
- Setiap settlement wajib punya `reference_transaction_id` ke transaksi asal
- Amount settlement ≤ sisa outstanding

### Flowchart: Alur Settlement

```mermaid
flowchart TD
    A([User punya\nhutang/piutang]) --> B{Jenis?}

    B -->|Hutang| C["Bayar hutang\nsettlement_kind = debt_payment\ntype = expense"]
    B -->|Piutang| D["Terima piutang\nsettlement_kind = loan_collection\ntype = income"]

    C --> E["reference_transaction_id\n→ transaksi hutang asal"]
    D --> E

    E --> F{amount ≤\nsisa outstanding?}
    F -->|❌ Tidak| G["⚠️ DIBLOK\nAmount terlalu besar"]
    F -->|✅ Ya| H["INSERT settlement\ntransaksi"]
    H --> I{Sisa = 0?}
    I -->|Ya| J["Status → PAID ✅"]
    I -->|Tidak| K["Status → PARTIAL ⏳"]

    style J fill:#2d6a4f,color:#fff
    style K fill:#ff8f00,color:#000
    style G fill:#d32f2f,color:#fff
```

## 4.4. Aturan Hutang/Piutang

```mermaid
flowchart LR
    subgraph Hutang["🔴 HUTANG (debt)"]
        D1["User MEMINJAM uang\ndari orang lain"]
        D2["Uang MASUK ke wallet user"]
        D3["Pelunasan: user MEMBAYAR"]
        D1 --> D2 --> D3
    end
    subgraph Piutang["🟢 PIUTANG (loan)"]
        L1["User MEMINJAMKAN uang\nke orang lain"]
        L2["Uang KELUAR dari wallet user"]
        L3["Pelunasan: user MENERIMA\npembayaran"]
        L1 --> L2 --> L3
    end
```

- `with_person` (teks) **wajib** diisi untuk identifikasi pihak terkait
- `contact_id` (FK ke `contacts`) **opsional** — diisi jika user pilih dari phonebook
- Status: `unpaid` → `partial` → `paid` (dihitung dari total settlement)

## 4.5. Currency & Timezone

| Aturan | Nilai |
|---|---|
| Currency MVP | IDR only |
| Default `wallet.currency` | `'IDR'` |
| Timezone rendering | `Asia/Jakarta` |
| Penyimpanan tanggal | UTC di database |

---

[← KPI Target](03_KPI_TARGET.md) · [Index](00_INDEX.md) · [User Flows →](05_USER_FLOWS.md)
