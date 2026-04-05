# 13. Categories

[← History](12_HISTORY.md) · [Index](00_INDEX.md) · [Budgeting →](14_BUDGETING.md)

---

## 13.1. Aturan
- Parent-child max 2 level
- `is_default = true` → tidak boleh hard delete
- Default category bisa di-hide (`is_hidden = true`)
- Form transaksi hanya tampilkan kategori sesuai type (expense → expense categories)
- Tipe debt/loan tidak pakai taxonomy kategori normal di MVP

### Flowchart: Category CRUD

```mermaid
flowchart TD
    A([Category\nManagement Page]) --> B{Action?}

    B -->|Tambah Parent| C["Input: Nama, Icon, Tipe\n(expense/income)"]
    B -->|Tambah Child| D["Pilih parent\n→ Input: Nama, Icon"]
    B -->|Edit| E["Edit: Nama, Icon"]
    B -->|Delete| F{is_default\n= true?}
    B -->|Hide/Show| G["Toggle is_hidden"]

    C --> H["INSERT category\n(parent_id = null)"]
    D --> I["INSERT category\n(parent_id = parent.id)"]
    E --> J["UPDATE category"]

    F -->|Ya| K["❌ DIBLOK:\nDefault tidak bisa\ndihapus"]
    F -->|Tidak| L{Ada transaksi\npakai kategori ini?}
    L -->|Ya| M["❌ DIBLOK:\nKategori masih\ndipakai"]
    L -->|Tidak| N["DELETE category"]

    G --> O["UPDATE is_hidden"]

    style K fill:#d32f2f,color:#fff
    style M fill:#d32f2f,color:#fff
```

### Flowchart: Category Hierarchy

```mermaid
flowchart TD
    subgraph Expense["Expense Categories"]
        direction TB
        EP1["Kebutuhan RT"]
        EP1C1["Belanja Dapur"]
        EP1C2["Perlengkapan Rumah"]
        EP1C3["Makan di Luar"]
        EP1 --> EP1C1
        EP1 --> EP1C2
        EP1 --> EP1C3

        EP2["Transportasi"]
        EP2C1["Bensin"]
        EP2C2["Tol"]
        EP2C3["Ojol"]
        EP2 --> EP2C1
        EP2 --> EP2C2
        EP2 --> EP2C3
    end

    subgraph Income["Income Categories"]
        direction TB
        IP1["Gaji"]
        IP1C1["Gaji Bulanan"]
        IP1C2["Bonus/THR"]
        IP1 --> IP1C1
        IP1 --> IP1C2
    end

    subgraph System["System (Internal)"]
        SP1["Penyesuaian Saldo"]
        SP2["Transfer ke Aset"]
    end

    style Expense fill:#d32f2f,color:#fff
    style Income fill:#2d6a4f,color:#fff
    style System fill:#455a64,color:#fff
```

---

[← History](12_HISTORY.md) · [Index](00_INDEX.md) · [Budgeting →](14_BUDGETING.md)
