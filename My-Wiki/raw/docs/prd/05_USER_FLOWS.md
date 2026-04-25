# 5. Flow Utama Aplikasi

[← Aturan Keuangan](04_ATURAN_KEUANGAN.md) · [Index](00_INDEX.md) · [Auth & Profil →](06_AUTH_PROFIL.md)

> **Katalog kategori 2026-04:** pasca-login kategori bawaan lewat **baris global** + `get_user_categories` (bukan *trigger* *seed* per pendaftaran). Lihat `My-Wiki/wiki/entities/categories.md`.

---

> **Panduan membaca flowchart:**
> - Kotak persegi = aksi/halaman
> - Diamond (belah ketupat) = keputusan/kondisi
> - Panah = alur proses
> - Warna hijau = happy path, merah = error path

## 5.1. Overview — Alur Navigasi Utama

```mermaid
flowchart TD
    START([App Dibuka]) --> AUTH{Session\nvalid?}
    AUTH -->|Ya| DASH[🏠 Dashboard]
    AUTH -->|Tidak| LOGIN[🔐 Login Screen]
    LOGIN --> DASH

    DASH --> WALLET[💼 Wallet Page]
    DASH --> HISTORY[📋 History Page]
    DASH --> BUDGET[📊 Budget Page]
    DASH --> INVEST[📈 Investment Page]
    DASH --> SETTINGS[⚙️ Settings Page]

    DASH -->|Quick Action| TXN_FORM[📝 Transaction Form]
    DASH -->|Quick Action| VOICE[🎤 Voice Input]
    DASH -->|Quick Action| OCR[📷 Scan Struk]
    DASH -->|Quick Action| TEXTINPUT[⌨️ Text Input]

    VOICE --> TXN_FORM
    OCR --> TXN_FORM
    TEXTINPUT --> TXN_FORM

    TXN_FORM -->|Simpan| DASH
```

## 5.2. Authentication Flow

```mermaid
flowchart TD
    A([App Launch]) --> B{Session\nSupabase ada?}

    B -->|✅ Ya| C[Load profile +\nbootstrap app]
    C --> D[🏠 Dashboard]

    B -->|❌ Tidak| E[🔐 Login Screen]
    E --> F["Tap 'Masuk dengan Google'"]
    F --> G[Supabase Google OAuth]
    G --> H{Login\nberhasil?}

    H -->|✅ Ya| I["Trigger: handle_new_user\n→ public.users"]
    I --> D

    H -->|❌ Gagal| L[Tampilkan error]
    L --> E

    style D fill:#2d6a4f,color:#fff
    style L fill:#d32f2f,color:#fff
```

**Catatan penting:**
- Flutter **TIDAK** insert manual ke `public.users` — `handle_new_user` mengisi profil
- Kategori: katalog **global** + RPC (bukan *insert* *seed* per pendaftaran, Apr 2026)
- *Notification settings* DB (baseline) sudah di-drop; notifikasi lokal di app dihapun
- Logout membersihkan session lokal + cache Hive → navigasi ke login

## 5.3. Manual Transaction Flow

```mermaid
flowchart TD
    A([User tap\nTambah Transaksi]) --> B[📝 Transaction Form]
    B --> C{Pilih tab\ntipe transaksi}

    C -->|Expense / Income| D["Isi:\n• Amount\n• Kategori\n• Wallet\n• Tanggal\n• Merchant (opsional)\n• Note (opsional)"]
    C -->|Transfer| E["Isi:\n• Wallet asal\n• Wallet tujuan\n• Amount"]
    C -->|Hutang / Piutang| F{Sub-selector}

    F -->|Hutang / Piutang| G["Isi:\n• Wallet\n• Amount\n• Contact/Person\n• Due date (opsional)"]
    F -->|Pelunasan / Terima| H["Isi:\n• Transaksi referensi\n• Amount ≤ sisa\n• Wallet"]

    D --> I{Validasi\ndomain}
    E --> I
    G --> I
    H --> I

    I -->|✅ Valid| J["Submit via RPC\n(atomik)"]
    J --> K["Trigger update_wallet_balance\n(DB otomatis)"]
    K --> L[Refresh: Dashboard,\nHistory, Wallet]

    I -->|❌ Invalid| M[Tampilkan error\ndi form]

    style L fill:#2d6a4f,color:#fff
    style M fill:#d32f2f,color:#fff
```

> **Catatan:** Tipe `adjustment` **TIDAK** ditampilkan di form transaksi manual.
> Adjustment hanya bisa dibuat dari fitur koreksi saldo wallet.

## 5.4. Multi-item Transaction Flow

```mermaid
flowchart TD
    A([Form Expense/Income]) --> B["User tap\n'Tambah Item'"]
    B --> C[Switch ke\nmode multi-item]
    C --> D["Isi per item:\n• Nama item\n• Qty × Harga satuan\n• Atau langsung amount\n• Kategori"]
    D --> E[Grand total =\nSUM semua item]
    E --> F{Total item =\nTotal transaksi?}

    F -->|❌ Tidak cocok| G["⚠️ Warning mismatch\nTombol simpan DIBLOK"]
    G --> D

    F -->|✅ Cocok| H[Pilih wallet\n& tanggal]
    H --> I[Submit via RPC]
    I --> J["Insert transaction +\nmultiple transaction_items"]
    J --> K["Trigger update_wallet_balance"]

    style K fill:#2d6a4f,color:#fff
    style G fill:#ff8f00,color:#000
```

**Aturan perhitungan amount item:**
1. Jika `qty` dan `unit_price` terisi → `amount = qty × unit_price` (otomatis, read-only)
2. Jika tidak → user isi `amount` manual
3. Single-item tetap simpan 1 row di `transaction_items`

## 5.5. Voice Input Flow

```mermaid
flowchart TD
    A([User tap\ntombol mic 🎤]) --> B["Record suara\n(max 10 detik,\ncountdown timer)"]
    B --> C["speech_to_text lokal\n→ raw transcript"]
    C --> D["Kirim ke Edge Function\nai-parse mode='text'"]

    D --> E{AI berhasil?\nGemini → Groq failover}
    E -->|✅ Ya| F["Return JSON +\nprovider info"]
    E -->|❌ Gagal / Timeout| G["Fallback lokal:\nVoiceLocalParser\n(regex + dictionary)"]
    G --> F

    F --> H{isTransaction\n= true?}
    H -->|✅ Ya| I["Set pendingVoicePrefill"]
    I --> J[Navigate ke\nTransaction Form]
    J --> K["Prefill form:\ntype, amount, wallet,\ncategory, merchant, date"]
    K --> L["User review &\nedit jika perlu"]
    L --> M[Save transaksi]

    H -->|❌ Tidak| N["Tampilkan error:\n'Bukan transaksi'"]

    style M fill:#2d6a4f,color:#fff
    style N fill:#d32f2f,color:#fff
```

**Pipeline AI:**
1. STT lokal (`speech_to_text`, locale `id_ID`) → teks
2. Edge Function `ai-parse` mode `text` → Gemini
3. Failover ke Groq (bukan Grok)
4. Fallback lokal: regex amount + keyword type + dictionary category

**Contoh parsing lokal:**
- `"1.5jt"` → 1.500.000
- `"25rb"` → 25.000
- `"transfer/kirim uang"` → type transfer
- `"kemarin"` → tanggal -1 hari

## 5.6. Text Input Flow

```mermaid
flowchart TD
    A([User tap\ntombol ⌨️]) --> B["Tampilkan TextInputSheet\n(text field + submit)"]
    B --> C["User ketik teks\ntransaksi"]
    C --> D["Submit teks"]
    D --> E["Kirim ke Edge Function\nai-parse mode='text'"]

    E --> F{AI berhasil?\nGemini → Groq failover}
    F -->|✅ Ya| G["Return JSON +\nprovider info"]
    F -->|❌ Gagal / Timeout| H["Fallback lokal:\nVoiceLocalParser\n(regex + dictionary)"]
    H --> G

    G --> I{isTransaction\n= true?}
    I -->|✅ Ya| J["Set pendingVoicePrefill"]
    J --> K[Navigate ke\nTransaction Form]
    K --> L["Prefill form:\ntype, amount, wallet,\ncategory, merchant, date"]
    L --> M["User review &\nedit jika perlu"]
    M --> N[Save transaksi]

    I -->|❌ Tidak| O["Tampilkan error:\n'Bukan transaksi'"]

    style N fill:#2d6a4f,color:#fff
    style O fill:#d32f2f,color:#fff
```

**Pipeline AI (sama dengan Voice, tanpa STT):**
1. User ketik teks langsung → tidak perlu mic permission / STT
2. Edge Function `ai-parse` mode `text` → Gemini
3. Failover ke Groq
4. Fallback lokal: regex amount + keyword type + dictionary category

## 5.7. OCR Receipt Flow

```mermaid
flowchart TD
    A([User pilih sumber:\nCamera / Gallery]) --> B[Capture / Pick image]
    B --> C["Crop image\n(croppy)"]
    C --> D["Compress ≤ 500KB\n(JPEG)"]
    D --> E["Base64 encode +\nKirim ke Edge Function\nai-parse mode='ocr'"]

    E --> F{Vision AI berhasil?\nGemini → Groq failover}
    F -->|✅ Ya| G["Return structured JSON\n+ provider"]
    F -->|❌ Gagal / AI_BUSY| H["ML Kit on-device OCR\n→ raw text"]
    H --> I["OcrLocalParser\n(regex extraction)"]
    I --> G

    G --> J{isTransaction &\nhasUsableData?}
    J -->|✅ Ya| K["Set pendingOcrPrefill +\nSet pendingOcrImageFile"]
    K --> L[Navigate ke\nTransaction Form]
    L --> M["Prefill form:\ntype, merchant, date,\nwallet, items, total"]
    M --> N["Set lampiran dari\npendingOcrImageFile"]
    N --> O{Items sum =\ngrand total?}
    O -->|❌ Tidak| P["Auto-balance:\n• Diff > 0: tambah 'Item lainnya'\n• Diff < 0: tambah 'Diskon/potongan'"]
    P --> Q[User review &\nedit item list]
    O -->|✅ Ya| Q
    Q --> R[Save + upload\nlampiran]

    J -->|❌ Tidak| S["Tampilkan error:\n• NO_TEXT: tidak ada teks\n• NOT_TRANSACTION: bukan struk\n• PARSE_FAILED: data tidak valid"]

    style R fill:#2d6a4f,color:#fff
    style S fill:#d32f2f,color:#fff
```

## 5.8. Debt/Loan Management Flow

```mermaid
flowchart TD
    A([Halaman\nHutang/Piutang]) --> B["2 Tab:\n• Untuk Dibayar (debt)\n• Untuk Diterima (loan)"]
    B --> C["RPC get_debt_loan_summary\ngrouped by contact"]
    C --> D["Tampilkan:\n• Section Unpaid (belum lunas)\n• Section Paid (sudah lunas)"]
    D --> E[Tap person tile]
    E --> F[Halaman Per-Orang]
    F --> G["Summary card:\n• Total pinjaman\n• Total terbayar\n• Sisa"]
    G --> H[List transaksi\ngrouped by date]
    H --> I{Tap transaksi}

    I -->|Ada settlement| J[Settlement\nHistory Page]
    I -->|Belum lunas| K[Settlement\nSheet]

    J --> L[List semua\npembayaran]
    L --> M[Tap → Edit\nSettlement Sheet]

    K --> N["Isi:\n• Amount ≤ sisa\n• Wallet\n• Note (opsional)"]
    N --> O[Submit via RPC\nsettle_debt_or_loan]
    O --> P{Sisa = 0?}
    P -->|Ya| Q["Status → PAID ✅"]
    P -->|Tidak| R["Status → PARTIAL ⏳"]

    style Q fill:#2d6a4f,color:#fff
    style R fill:#ff8f00,color:#000
```

## 5.9. Budget Usage Update Flow (Otomatis)

```mermaid
flowchart TD
    A([Transaksi expense\ndisimpan]) --> B["DB Trigger:\nupdate_budget_usage"]
    B --> C["Match kategori expense\n(termasuk parent category)"]
    C --> D["Filter budget aktif:\n• Dalam rentang tanggal\n• Scope wallet cocok"]
    D --> E["Recalculate used_amount\ndari semua expense terkait"]
    E --> F["✅ Budget usage\nterupdate otomatis"]

    style F fill:#2d6a4f,color:#fff
```

> **Penting:** Notifikasi alert budget (50%/80%/100%) bukan bagian dari trigger database.
> Alert dicek saat halaman budget dibuka oleh `BudgetAlertChecker` di Flutter.

## 5.10. Investment Buy Flow

```mermaid
flowchart TD
    A([Halaman Investasi]) --> B[Fetch harga live\ndari cache/API]
    B --> C[Tap Tambah Investasi]
    C --> D["Isi:\n• Tipe aset\n• Nama\n• Amount (unit)\n• Harga beli per unit"]
    D --> E{Potong dari\nwallet?}

    E -->|❌ Tidak| F[Save investment only]
    E -->|✅ Ya| G["Create transaction\ntype = transfer_to_asset"]
    G --> H[Save investment]
    H --> I["Trigger update_wallet_balance\n(saldo wallet berkurang)"]

    F --> J[Refresh portfolio]
    I --> J

    style J fill:#2d6a4f,color:#fff
```

---

[← Aturan Keuangan](04_ATURAN_KEUANGAN.md) · [Index](00_INDEX.md) · [Auth & Profil →](06_AUTH_PROFIL.md)
