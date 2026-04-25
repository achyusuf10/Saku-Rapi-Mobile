# SakuRapi — Product Requirements Document (PRD)

**Versi:** 7.0  
**Tanggal:** 2026-03-31  
**Platform:** Android Only  
**Bahasa UI default:** Bahasa Indonesia  
**Timezone:** Asia/Jakarta  
**Currency MVP:** IDR only  
**Status:** Final for implementation  

> **Dokumen terkait:**
> - Skema **aktual** (Supabase) → `supabase/migrations/` (repo) + `My-Wiki/wiki/entities/database-schema.md` + kategori: `My-Wiki/wiki/entities/categories.md`
> - *Baseline* lama: [`02_DATABASE.md`](../02_DATABASE.md) (bisa usang soal kategori/*seed*)
> - Coding & Copilot → [`03_COPILOT_RULES.md`](../03_COPILOT_RULES.md)

---

## DAFTAR ISI

### BAGIAN I — RINGKASAN PRODUK
| # | Dokumen | Deskripsi |
|---|---|---|
| 1 | [Tentang SakuRapi](01_TENTANG_SAKURAPI.md) | Visi produk, masalah yang diselesaikan, prinsip desain, batasan MVP |
| 2 | [Prioritas Fitur](02_PRIORITAS_FITUR.md) | Matrix prioritas P0/P1/P2 |
| 3 | [KPI Target & Definition of Done](03_KPI_TARGET.md) | Metrik produk dan kriteria "selesai" |

### BAGIAN II — ATURAN BISNIS
| # | Dokumen | Deskripsi |
|---|---|---|
| 4 | [Aturan Keuangan Fundamental](04_ATURAN_KEUANGAN.md) | Saldo wallet, matrix transaksi, settlement, hutang/piutang, currency |

### BAGIAN III — USER FLOWS
| # | Dokumen | Deskripsi |
|---|---|---|
| 5 | [Flow Utama Aplikasi](05_USER_FLOWS.md) | Semua flowchart navigasi & proses utama |

### BAGIAN IV — DETAIL FITUR
| # | Dokumen | Deskripsi |
|---|---|---|
| 6 | [Auth & Profil](06_AUTH_PROFIL.md) | Login Google OAuth, profil user |
| 7 | [Dashboard](07_DASHBOARD.md) | Halaman utama, rangkuman, chart, quick actions |
| 8 | [Wallets](08_WALLETS.md) | Multi-wallet CRUD, balance adjustment |
| 9 | [Transaksi](09_TRANSAKSI.md) | Form 4-tab, multi-item, attachment, validasi |
| 10 | [Transaction Detail](10_TRANSACTION_DETAIL.md) | Detail view, edit/delete, debt progress |
| 11 | [Hutang / Piutang](11_HUTANG_PIUTANG.md) | Debt/Loan management, settlement |
| 12 | [History](12_HISTORY.md) | Riwayat transaksi, filter, pagination |
| 13 | [Categories](13_CATEGORIES.md) | Kategori parent-child 2 level |
| 14 | [Budgeting](14_BUDGETING.md) | Anggaran per kategori, alert, auto-renew |
| 15 | [Investasi](15_INVESTASI.md) | Portfolio gold/bitcoin/custom, harga live |
| 16 | [Settings](16_SETTINGS.md) | Preferensi, notifikasi, profil |

### BAGIAN V — DATA & TEKNIS
| # | Dokumen | Deskripsi |
|---|---|---|
| 17 | [Voice & Text Input — Detail Teknis](17_VOICE_INPUT.md) | Edge Function format, mapping, local parser |
| 18 | [OCR Receipt — Detail Teknis](18_OCR_RECEIPT.md) | Edge Function format, image pipeline, local parser |
| 19 | [Parsing Dictionary](19_PARSING_DICTIONARY.md) | Cache keyword-kategori |
| 20 | [External API & Integration](20_EXTERNAL_API.md) | CoinGecko, Edge Functions, Google Sign-In |

### BAGIAN VI — DEFAULT CATEGORIES
| # | Dokumen | Deskripsi |
|---|---|---|
| 21 | [Kategori Default](21_KATEGORI_DEFAULT.md) | Expense, Income, System categories |

### BAGIAN VII — EDGE CASES & ERROR HANDLING
| # | Dokumen | Deskripsi |
|---|---|---|
| 22 | [Edge Cases](22_EDGE_CASES.md) | Voice/Text/OCR, transaksi, notifikasi |

### BAGIAN VIII — PERMISSION & TESTING
| # | Dokumen | Deskripsi |
|---|---|---|
| 23 | [Permission Requirements](23_PERMISSIONS.md) | Just-in-time permissions |
| 24 | [Testing Requirements](24_TESTING.md) | Unit/widget/integration tests |

### BAGIAN IX — ROADMAP PENGEMBANGAN
| # | Dokumen | Deskripsi |
|---|---|---|
| 25 | [Roadmap](25_ROADMAP.md) | 12 phase development plan |

### BAGIAN X — FINAL DECISION SUMMARY
| # | Dokumen | Deskripsi |
|---|---|---|
| 26 | [Keputusan Final](26_KEPUTUSAN_FINAL.md) | 7 keputusan yang tidak boleh dilanggar |

---

*Dokumen ini adalah sumber kebenaran utama untuk requirement produk SakuRapi.*  
*Last updated: 2026-03-31 — PRD v7.0*
