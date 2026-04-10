# 26. Keputusan Final

[← Roadmap](25_ROADMAP.md) · [Index](00_INDEX.md)

---

> Jika ada konflik antara implementasi lama, asumsi Copilot, atau prompt lain,
> keputusan berikut yang **MENANG**:

| # | Keputusan | Tidak Boleh Dilanggar |
|---|---|---|
| 1 | Saldo wallet berubah hanya dari ledger `transactions` | ❌ Bypass trigger |
| 2 | Report hanya menghitung income/expense non-settlement | ❌ Include settlement |
| 3 | Budget hanya menghitung expense | ❌ Include income/transfer |
| 4 | Multi-item selalu menggunakan `transaction_items` | ❌ Simpan di field JSON |
| 5 | Transfer dan transfer_to_asset bukan expense | ❌ Masukkan ke laporan |
| 6 | AI hanya prefill, user tetap review | ❌ Auto-save tanpa konfirmasi |
| 7 | Semua nominal MVP memakai IDR | ❌ Multi-currency |

### Flowchart: Decision Priority

```mermaid
flowchart TD
    A([Ada konflik\nimplementasi?]) --> B{Cek keputusan\nfinal \u00a726}
    B --> C{Keputusan\ntertulis?}
    C -->|Ya| D["Ikuti keputusan final\n(MENANG atas\nsemua sumber lain)"]
    C -->|Tidak| E{Cek PRD\ndetail fitur}
    E --> F{Tertulis\ndi PRD?}
    F -->|Ya| G["Ikuti PRD"]
    F -->|Tidak| H{Cek\n02_DATABASE.md}
    H --> I{Tertulis\ndi DB doc?}
    I -->|Ya| J["Ikuti DB doc"]
    I -->|Tidak| K["Diskusi dengan\nteam / stakeholder"]

    style D fill:#d32f2f,color:#fff
    style G fill:#2d6a4f,color:#fff
    style J fill:#1565c0,color:#fff
```

---

*Dokumen ini adalah sumber kebenaran utama untuk requirement produk SakuRapi.*  
*Last updated: 2026-03-31 — PRD v7.0*

---

[← Roadmap](25_ROADMAP.md) · [Index](00_INDEX.md)
