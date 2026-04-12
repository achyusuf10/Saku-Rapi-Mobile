---
title: "Budgeting"
type: entity
tags: [budgeting, anggaran, fitur, pg_cron, alert]
sources: [raw/docs/prd/14_BUDGETING.md, raw/docs/prd/04_ATURAN_KEUANGAN.md, raw/docs/02_DATABASE.md]
created: 2026-04-10
updated: 2026-04-10
---

# Budgeting

## Deskripsi

Budgeting adalah fitur anggaran di SakuRapi yang memungkinkan user menetapkan batas pengeluaran **per kategori expense**. Budget bisa bersifat **global** (semua wallet) atau **per-wallet** (spesifik satu wallet). Fitur ini mendukung 5 jenis periode, auto-renew otomatis, carry-forward sisa anggaran, dan alert bertingkat saat pengeluaran mendekati/melebihi batas.

## Fitur & Aturan Utama

### Scope Budget

| Scope | Deskripsi |
|-------|-----------|
| **Global** | Budget berlaku untuk pengeluaran dari semua wallet |
| **Per-wallet** | Budget hanya menghitung pengeluaran dari wallet tertentu |

### 5 Tipe Periode

| # | Periode | Deskripsi |
|---|---------|-----------|
| 1 | **Weekly** | Mingguan |
| 2 | **Monthly** | Bulanan |
| 3 | **Quarterly** | Per kuartal (3 bulan) |
| 4 | **Yearly** | Tahunan |
| 5 | **Custom** | Rentang tanggal yang ditentukan user |

### Auto-Renew

- Budget dengan periode non-custom (Weekly, Monthly, Quarterly, Yearly) di-renew secara otomatis oleh **pg_cron job `auto_renew_budgets`** di server.
- Saat periode berakhir, sistem membuat budget baru untuk periode berikutnya secara otomatis.

### Carry-Forward

- Jika budget periode sebelumnya memiliki **sisa positif** (pengeluaran < anggaran), sisa tersebut **ditambahkan** ke budget periode baru.
- Contoh: Budget bulanan Rp 1.000.000, terpakai Rp 800.000 → sisa Rp 200.000 ditambahkan ke budget bulan berikutnya (menjadi Rp 1.200.000).

### Duplicate Detection

- Sistem mendeteksi duplikasi budget secara **seragam** baik saat create maupun edit.
- Tidak boleh ada 2 budget aktif untuk kategori + scope + periode yang sama.

### Aturan Settlement

- Transaksi settlement (pelunasan hutang/piutang) **dikecualikan** dari perhitungan budget — tidak dihitung sebagai pengeluaran.

## UI Halaman Budget

### Halaman Utama Budget

| Komponen | Deskripsi |
|----------|-----------|
| **Arc Gauge (180°)** | Visualisasi total penggunaan budget dalam bentuk gauge setengah lingkaran |
| **Period Tabs** | Tab dinamis berdasarkan periode aktif (berpindah antar periode) |
| **Parent-Child Budgets** | Budget induk (global) dengan child budget (per-kategori) ditampilkan hierarkis |

### Halaman Detail Budget

| Komponen | Deskripsi |
|----------|-----------|
| **Progress Bar** | Bar horizontal dengan 4 level warna berdasarkan persentase penggunaan |
| **Stats** | 3 metrik: Daily Recommended, Projected Spending, Actual Daily Spending |
| **Daftar Transaksi** | Transaksi yang termasuk dalam budget ini |

### Warna Progress Bar

| Persentase | Warna | Arti |
|------------|-------|------|
| **< 60%** | 🟢 Hijau | Aman |
| **60% – 79%** | 🟡 Kuning | Perlu perhatian |
| **80% – 99%** | 🟠 Oranye | Hampir habis |
| **≥ 100%** | 🔴 Merah | Melebihi budget |

### Stats Detail

| Metrik | Deskripsi |
|--------|-----------|
| **Daily Recommended** | Sisa budget ÷ sisa hari dalam periode = berapa yang "boleh" dihabiskan per hari |
| **Projected** | Berdasarkan spending rate saat ini, proyeksi total pengeluaran akhir periode |
| **Actual Daily** | Rata-rata pengeluaran aktual per hari dalam periode ini |

## Budget Alert (Dihapus)

> ⚠️ Sistem Budget Alert (notifikasi lokal saat threshold 50%/80%/100%) **telah dihapus** dari app layer pada April 2026. Lihat [[wiki/analysis/keputusan-hapus-notifikasi|Keputusan: Hapus Notifikasi]] untuk detail.

Progress bar masih menampilkan warna berdasarkan threshold:
| Persentase | Warna | Arti |
|-----------|-------|------|
| < 60% | 🟢 Hijau | Aman |
| 60–79% | 🟡 Kuning | Perlu perhatian |
| 80–99% | 🟠 Oranye | Hampir habis |
| ≥ 100% | 🔴 Merah | Melebihi budget |

Field `notification_sent_50/80/100` masih ada di tabel `budgets` di DB (tidak dihapus).

## Database Schema (`budgets`)

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK | owner |
| category_id | uuid FK | category expense yang dibudget |
| wallet_id | uuid nullable FK | null = global |
| amount | numeric not null | budget limit, CHECK > 0 |
| used_amount | numeric not null default 0 | current usage |
| start_date | date not null | |
| end_date | date not null | CHECK >= start_date |
| is_recurring | boolean not null default false | auto clone |
| notification_sent_50 | boolean default false | flag alert threshold 50% |
| notification_sent_80 | boolean default false | flag alert threshold 80% |
| notification_sent_100 | boolean default false | flag alert threshold 100% |
| carry_forward | boolean not null default false | rollover sisa positif |
| period_type | text not null default 'monthly' | CHECK: weekly, monthly, quarterly, yearly, custom |
| created_at / updated_at | timestamptz | |

**Trigger:**
- `update_budget_usage` — recalc used_amount setelah insert/update/delete pada transaction_items
- `auto_renew_budgets` — pg_cron daily, clone recurring budgets dengan period-aware date calculation dan carry_forward support

**RPC:**
- `replace_budget(...)` → jsonb — atomic DELETE old + INSERT new untuk handle duplicate overlap

## Cara Kerja

```
┌────────────────────────────────────────┐
│  Buat Budget                           │
│  Kategori + Scope + Periode + Amount   │
│  → Duplicate detection                 │
└──────────────┬─────────────────────────┘
               │
               ▼
┌────────────────────────────────────────┐
│  Budget Aktif                          │
│  Arc Gauge + Period Tabs + Hierarchy   │
│  → Setiap transaksi expense dihitung   │
│  → Settlement dikecualikan             │
└──────────────┬─────────────────────────┘
               │
               ▼
┌────────────────────────────────────────┐
│  Periode Berakhir                      │
│  pg_cron: auto_renew_budgets           │
│  → Carry-forward sisa positif          │
│  → Budget baru otomatis                │
└────────────────────────────────────────┘
```

1. User membuat budget dengan memilih kategori, scope, periode, dan jumlah.
2. Setiap transaksi expense yang sesuai kategori & scope otomatis terhitung.
3. UI menampilkan progress (gauge, bar, stats) secara real-time.
4. Saat periode berakhir, pg_cron membuat budget baru (dengan carry-forward jika ada sisa).
5. ~~BudgetAlertChecker memeriksa threshold saat user membuka halaman budget.~~ *(Fitur notifikasi dihapus — lihat [Keputusan: Hapus Notifikasi](wiki/analysis/keputusan-hapus-notifikasi))*

## Halaman Terkait

- [[wiki/entities/sakurapi|SakuRapi]]
- [[wiki/entities/wallet|Wallet]]
- [[wiki/entities/transaksi|Transaksi]]
- [[wiki/entities/dashboard|Dashboard]]
- [[wiki/entities/hutang-piutang|Hutang/Piutang]]
- [[wiki/concepts/aturan-keuangan|Aturan Keuangan]]
- [[wiki/entities/database-schema|Database Schema]]
- [[wiki/entities/categories|Categories]]
- [[wiki/sources/prd-sakurapi-v7|PRD SakuRapi v7.0]]
- [[wiki/concepts/design-system|Design System]]
- [[wiki/sources/redesign-ui-ux|Redesign UI/UX (Sumber)]]
- [[wiki/analysis/keputusan-hapus-notifikasi|Keputusan: Hapus Notifikasi]]
