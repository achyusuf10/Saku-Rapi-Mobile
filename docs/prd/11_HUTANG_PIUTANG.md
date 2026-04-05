# 11. Debt/Loan Management

[← Transaction Detail](10_TRANSACTION_DETAIL.md) · [Index](00_INDEX.md) · [History →](12_HISTORY.md)

---

## 11.1. Halaman Utama — 2 Tab

| Tab | Konten | Data dari |
|---|---|---|
| Untuk Dibayar | Daftar hutang user | RPC `get_debt_loan_summary` type=debt |
| Untuk Diterima | Daftar piutang user | RPC `get_debt_loan_summary` type=loan |

Setiap tab menampilkan:
- **Section Unpaid:** Kontak dengan sisa hutang/piutang + total remaining
- **Section Paid:** Kontak yang sudah lunas + total principal
- **Wallet filter** di AppBar

### Flowchart: Navigasi Hutang/Piutang

```mermaid
flowchart TD
    A([Halaman\nHutang/Piutang]) --> B["2 Tab:\n• Untuk Dibayar\n• Untuk Diterima"]
    B --> C["RPC get_debt_loan_summary\ngrouped by contact"]
    C --> D["Section Unpaid:\nkontak belum lunas"]
    C --> E["Section Paid:\nkontak sudah lunas"]

    D --> F[Tap person tile]
    E --> F
    F --> G[Halaman Per-Orang]

    G --> H["Summary card +\nList transaksi"]
    H --> I{Action?}

    I -->|Tap transaksi\n(belum lunas)| J[Settlement Sheet]
    I -->|Tap transaksi\n(ada settlement)| K[Settlement History]
    I -->|FAB| L["New Settlement\n(hidden jika semua paid)"]

    style G fill:#1565c0,color:#fff
```

## 11.2. Halaman Per-Orang
- Summary card: total principal vs settled vs remaining
- List transaksi grouped by date
- Status badge per transaksi: Paid (hijau), Partial (oranye), Unpaid (abu)
- FAB settlement (hidden jika semua sudah paid)

## 11.3. Settlement Sheet

| Mode | Fitur |
|---|---|
| **Create** | Pilih referensi, info sisa, input amount + MAX, wallet ChoiceChips, note |
| **Edit** | Pre-filled amount + note, tombol delete (konfirmasi) |

Validasi: amount > 0, amount ≤ remaining, wallet dipilih.

### Flowchart: Settlement Create/Edit Flow

```mermaid
flowchart TD
    A([Settlement Sheet]) --> B{Mode?}

    B -->|Create| C["Pilih transaksi referensi\nInfo sisa: Rp X"]
    B -->|Edit| D["Pre-filled amount +\nnote dari existing"]

    C --> E["Input:\n• Amount (> 0, ≤ sisa)\n• Wallet (ChoiceChips)\n• Note (opsional)"]
    D --> E

    E --> F{Validasi}
    F -->|amount = 0| G["⚠️ Error"]
    F -->|amount > sisa| H["⚠️ Error:\nmelebihi sisa"]
    F -->|wallet kosong| I["⚠️ Error:\npilih wallet"]
    F -->|✅ Valid| J{Mode?}

    J -->|Create| K["RPC settle_debt_or_loan"]
    J -->|Edit| L["RPC update_settlement"]

    K --> M{Sisa setelah\nsettlement?}
    L --> M
    M -->|= 0| N["Status → PAID ✅"]
    M -->|> 0| O["Status → PARTIAL ⏳"]

    B -->|Edit + Delete| P["Dialog konfirmasi\nhapus settlement"]
    P --> Q["RPC delete_settlement\n+ recalc status"]

    style N fill:#2d6a4f,color:#fff
    style O fill:#ff8f00,color:#000
    style G fill:#d32f2f,color:#fff
    style H fill:#d32f2f,color:#fff
```

## 11.4. RPC Terkait

| RPC | Kegunaan |
|---|---|
| `get_debt_loan_summary` | Summary grouped by contact per type |
| `get_debt_loan_transactions_by_person` | Semua transaksi dengan satu orang |
| `get_all_unpaid_debt_loan` | Semua transaksi belum lunas (untuk picker) |
| `get_settlement_history` | Riwayat pelunasan untuk satu referensi |
| `settle_debt_or_loan` | Buat transaksi pelunasan |
| `update_settlement` | Edit pelunasan |
| `delete_settlement` | Hapus pelunasan + recalc status |

---

[← Transaction Detail](10_TRANSACTION_DETAIL.md) · [Index](00_INDEX.md) · [History →](12_HISTORY.md)
