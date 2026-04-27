---
title: "Log Wiki"
updated: 2026-04-27
---

# 📋 Log Wiki SakuRapi

> Log kronologis semua operasi wiki. Append-only.

---

## [2026-04-10] setup | Inisialisasi Wiki

- Dibuat struktur direktori wiki
- Dibuat `SCHEMA.md` (panduan LLM)
- Dibuat `index.md` (katalog halaman)
- Dibuat `log.md` (file ini)
- Struktur: `raw/` (docs, articles, feedback, competitors, assets) + `wiki/` (entities, concepts, sources, analysis)
- Bahasa wiki: Bahasa Indonesia
- Domain: Proyek SakuRapi — aplikasi keuangan pribadi Flutter

## [2026-04-10] ingest | PRD SakuRapi v7.0

- Dibuat `wiki/sources/prd-sakurapi-v7.md` — ringkasan PRD v7.0 (27 file sumber)
- Cakupan: fitur P0/P1/P2, aturan keuangan fundamental, 7 keputusan final, status roadmap 12 phase, KPI target, AI pipeline
- Diperbarui `index.md` — tambah entry sumber baru (total halaman: 1)

## [2026-04-10] create | Batch pembuatan 6 halaman entitas (batch 1)

- Dibuat `wiki/entities/investasi.md` — Portfolio investasi (gold, bitcoin, custom asset)
- Dibuat `wiki/entities/voice-input.md` — Input transaksi via suara dengan AI parsing
- Dibuat `wiki/entities/text-input.md` — Input transaksi via teks dengan AI parsing
- Dibuat `wiki/entities/ocr-receipt.md` — Scan struk belanja dengan OCR dan AI parsing
- Dibuat `wiki/entities/history.md` — Riwayat transaksi dengan filter dan pagination
- Dibuat `wiki/entities/settings.md` — Pengaturan aplikasi, notifikasi, dan preferensi
- Diperbarui `index.md` — Ditambahkan 6 entitas baru

## [2026-04-10] create | Batch pembuatan 6 halaman entitas (batch 2)

- Dibuat `wiki/entities/sakurapi.md` — Overview aplikasi, prinsip desain, tech stack
- Dibuat `wiki/entities/wallet.md` — Multi-wallet, saldo read-only, adjustment
- Dibuat `wiki/entities/transaksi.md` — Form 4-tab, multi-item, contact picker, attachment
- Dibuat `wiki/entities/dashboard.md` — Layout, split controller, cache Hive
- Dibuat `wiki/entities/hutang-piutang.md` — 2 tab, settlement, 7 RPC functions
- Dibuat `wiki/entities/budgeting.md` — 5 period types, auto-renew, carry-forward, alert
- Diperbarui `index.md` — Ditambahkan 6 entitas baru (total: 12 entitas)

## [2026-04-10] create | Batch pembuatan 5 halaman konsep

- Dibuat `wiki/concepts/aturan-keuangan.md` — Aturan emas balance via trigger, 7 keputusan final, IDR/UTC rules
- Dibuat `wiki/concepts/matrix-transaksi.md` — 7 tipe transaksi, settlement rules, validasi guardrails
- Dibuat `wiki/concepts/ai-pipeline.md` — Edge Function ai-parse, voice/text/OCR alur, failover chain, parsing dictionary
- Dibuat `wiki/concepts/arsitektur-app.md` — Tech stack, 3-file data pattern, model/provider/UI conventions, global widgets
- Dibuat `wiki/concepts/roadmap-status.md` — 12 fase roadmap, Definition of Done, testing requirements, just-in-time permission
- Diperbarui `index.md` — Ditambahkan 5 konsep baru (total halaman: 5 konsep)

## [2026-04-10] ingest | Coding Rules, Database Schema, Copilot Rules

- **Sumber baru diproses**: 3 file
  - `raw/docs/00_SakuRapi_Coding_Rules.md` — Aturan coding & formatting Flutter
  - `raw/docs/02_DATABASE.md` — Database Final v6.4 (15 tabel, triggers, RPC, indexes)
  - `raw/docs/03_COPILOT_RULES.md` — Merged rules (coding rules + copilot guardrails)
- **Halaman baru dibuat**: 7
  - `wiki/sources/coding-rules.md` — Ringkasan coding rules
  - `wiki/sources/database-v6.md` — Ringkasan database schema
  - `wiki/sources/copilot-rules.md` — Ringkasan copilot rules
  - `wiki/entities/database-schema.md` — 15 tabel, triggers, RPC, indexes, RLS, accounting rules
  - `wiki/entities/categories.md` — Sistem kategori (seed defaults, hierarki)
  - `wiki/entities/contacts.md` — Manajemen kontak untuk hutang/piutang
  - `wiki/concepts/coding-rules.md` — Aturan coding lengkap, formatting, testing, forbidden actions
- **Halaman diperbarui**: 7
  - `wiki/entities/wallet.md` — Ditambah schema kolom database
  - `wiki/entities/transaksi.md` — Ditambah schema transactions + transaction_items
  - `wiki/entities/budgeting.md` — Ditambah schema budgets, trigger detail
  - `wiki/entities/investasi.md` — Ditambah RPC detail lengkap + aturan edit/delete
  - `wiki/entities/hutang-piutang.md` — Dikoreksi nama RPC sesuai 02_DATABASE.md
  - `wiki/concepts/aturan-keuangan.md` — Ditambah accounting checklist + copilot guardrails
  - `wiki/concepts/arsitektur-app.md` — Ditambah layering rules + testing requirements + DoD
- **Total halaman wiki**: 25 (15 entitas, 6 konsep, 4 sumber, 0 analisis)

## [2026-04-10] ingest | Redesign UI/UX — Minimalism + Trust & Authority

- **Sumber baru diproses**: 13 file di `raw/docs/redesign-ui-ux/`
  - `00_REDESIGN_OVERVIEW.md` — Filosofi, masalah UI lama, design system baru, scope 12 section
  - `S1_DESIGN_TOKENS.md` — Color palette (Trust Navy + Premium Gold), IBM Plex Sans, theme config
  - `S2_GLOBAL_WIDGETS.md` — 23 widget overhaul (radius 12r, neutral shadow, theme colors)
  - `S3_DASHBOARD.md` — Balance card solid flat, quick actions muted, chart neutral bg
  - `S4_WALLET.md` — Wallet cards flat, summary neutral, form styling
  - `S5_TRANSACTION.md` — Semantic tab colors, form fields, contact picker, detail page
  - `S6_HISTORY.md` — Transaction tiles, filter sheet, period selector
  - `S7_BUDGET.md` — Progress bar semantic (green/gold/red), summary flat, form fields
  - `S8_REPORTS.md` — Summary card, pie/bar/trend charts, neutral bg
  - `S9_DEBT_LOAN.md` — Debt orange / loan purple, left accent border cards
  - `S10_INVESTMENT.md` — Portfolio card flat, gain/loss semantic, smart form ✅ DONE
  - `S11_AUTH_SETTINGS_MISC.md` — Splash, login, settings, category, voice, OCR ✅ DONE
  - `S12_FINAL_REVIEW.md` — Visual audit, WCAG compliance, acceptable patterns ✅ DONE
- **Halaman baru dibuat**: 3
  - `wiki/sources/redesign-ui-ux.md` — Ringkasan komprehensif redesign (13 file, 12 section)
  - `wiki/concepts/design-system.md` — "Financial Trust" design system (colors, typography, widget rules)
  - `wiki/entities/reports.md` — Fitur laporan keuangan (summary, charts, trend)
- **Total halaman wiki**: 28 (16 entitas, 7 konsep, 5 sumber, 0 analisis)

## [2026-04-10] lint | Wiki health check — 3 fixes, 4 suggestions implemented

- **Issues diperbaiki (dari lint scan):**
  - Broken link `wiki/concepts/database-schema` → `wiki/entities/database-schema` di 2 file (copilot-rules, database-v6)
  - Missing `updated:` frontmatter di `sources/redesign-ui-ux.md`
- **Saran diimplementasi:**
  - **Halaman baru**: `wiki/entities/edge-functions.md` (Deno, ai-parse, gold-price, bitcoin-price)
  - **Halaman baru**: `wiki/entities/notifikasi.md` (local notifications, budget alert, daily reminder)
  - **Konektivitas sumber**: `redesign-ui-ux` source link ditambah ke 9 entity pages
  - **SCHEMA.md**: Placeholder wikilinks `xxx`/`yyy` dibungkus backtick agar tidak muncul di Obsidian graph
- **Total halaman wiki**: 30 (18 entitas, 7 konsep, 5 sumber, 0 analisis)

## [2026-04-12] refactor | Penghapusan Fitur Notifikasi & Budget Alert

- **Alasan**: Inkonsistensi behavior (alert di-trigger saat page load, bukan transaksi masuk), debt reminder belum terimplementasi, 4 deps besar untuk fitur yang belum matang
- **Flutter — dihapus**:
  - `lib/features/notification/` (seluruh folder, 7 file)
  - `BudgetModel`: field `notificationSent50/80/100` + fromMap/toFullMap/copyWith
  - `budget_page.dart`: `_checkBudgetAlerts()` + listener
  - `settings_page.dart`: menu item Notifications
  - `app_router.dart`: route `/notification-settings`
  - `main.dart`: WorkManager, NotificationService.init(), timezone init
  - `pubspec.yaml`: `flutter_local_notifications`, `workmanager`, `timezone`
  - `AndroidManifest.xml`: `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`, `POST_NOTIFICATIONS`
- **Tetap ada**: `permission_handler` (OCR/Voice/Contacts), DB table `notification_settings`, kolom `notification_sent_*` di `budgets`
- **Wiki baru**: `wiki/analysis/remove-notification.md`

## [2026-04-12] ingest | Plan: Hapus Fitur Notifikasi

- **Sumber diproses**: `raw/docs/plan-remove-notification.md`
- **Halaman dibuat**: 
  - `wiki/sources/plan-remove-notification.md` — ringkasan plan penghapusan
  - `wiki/analysis/keputusan-hapus-notifikasi.md` — analisis keputusan teknis
- **Halaman diupdate**:
  - `wiki/entities/budgeting.md` — section Budget Alert diubah menjadi "Dihapus"
  - `wiki/entities/notifikasi.md` — ditambah warning banner status "Dihapus"
  - `wiki/entities/settings.md` — referensi Notification Settings diupdate
  - `index.md` — 33 halaman (18 entitas, 7 konsep, 6 sumber, 2 analisis)
- **Konteks**: Fitur notifikasi dihapus karena inkonsistensi trigger, debt reminder setengah jadi, dan overhead dependencies besar vs nilai yang dihasilkan

## [2026-04-12] refactor | Remove Notification dari Supabase (Migration 015)

- **Migration**: `20260412100000_015_remove_notification.sql`
- **Dihapus**:
  - TRIGGER `trg_seed_notification_settings` + FUNCTION `seed_notification_settings()`
  - TABLE `notification_settings` (CASCADE: trigger updated_at + 2 RLS policies)
  - COLUMNS `notification_sent_50/80/100` dari tabel `budgets`
- **Wiki diperbarui**: `wiki/analysis/remove-notification.md` (section Supabase Changes ditambahkan)

## [2026-04-14] ingest | Security Audit Report (April 2026)

- **Sumber diproses**: `raw/security-audit.md` (766 baris — laporan audit keamanan menyeluruh)
- **Cakupan audit**: Flutter client, Supabase DB (16 tabel, 44 RLS policies, 33 functions), 3 Edge Functions, Storage, Cron jobs
- **Temuan**: 5 CRITICAL, 5 HIGH, 7 MEDIUM, 3 LOW — skor awal 5.5/10
- **Semua CRITICAL & HIGH sudah di-fix** — skor akhir 8.5/10
- **Halaman baru dibuat**: 2
  - `wiki/sources/security-audit.md` — ringkasan laporan audit
  - `wiki/concepts/keamanan.md` — security posture, RLS patterns, edge function auth, checklist deployment
- **Halaman diperbarui**: 2
  - `wiki/entities/edge-functions.md` — tambah kolom JWT verify di tabel, section Authentication & Error Handling, link ke keamanan
  - `wiki/entities/database-schema.md` — RLS optimization pattern, 7 FK indexes baru, gold_prices security note, link ke keamanan
- **Total halaman wiki**: 44 (20 entitas, 8 konsep, 10 sumber, 5 analisis)
- **Action manual tersisa**: Aktifkan Leaked Password Protection di Supabase Dashboard (prod)

## [2026-04-19] ingest | Batch 12 sumber + 2 entitas + 1 fix frontmatter

- **Sumber diproses**: 12 raw docs yang belum di-ingest (7 dari `raw/` root + 5 dari `raw/docs/`)
- **Halaman baru dibuat**: 14

### wiki/sources/ (12 halaman baru)
  - `wiki/sources/plan-ads-integration.md` — Plan integrasi Google AdMob (banner, native, interstitial, eligibility gate `show_ads`)
  - `wiki/sources/audit-dashboard-charts.md` — Audit dashboard charts: 8 bug (loading state, stale flash, tooltip single-series, label)
  - `wiki/sources/audit-report-page.md` — Audit report page: tooltip single-series, gap fill, hardcoded string
  - `wiki/sources/plan-image-upload-edge-fn.md` — Plan edge function `image-upload` (Supabase Storage + GCS fallback)
  - `wiki/sources/plan-ai-parse-enhancement.md` — Enhancement AI Parse: wallet short ID mapping, multi-item, rename `suggestedWalletId`
  - `wiki/sources/plan-android-home-widget.md` — Plan Android Home Widget (XML RemoteViews, cold start fix, 4 quick actions)
  - `wiki/sources/plan-fix-ai-parse-gemini-404.md` — Plan fix model 404: `gemini-1.5-flash` → `gemini-2.5-flash-lite`, pindah ke Vertex AI
  - `wiki/sources/plan-normalize-date-iso8601.md` — Plan normalisasi date ISO 8601: kontrak final timestamp vs date-only, `SakuDateUtils`, migration 021 ✅
  - `wiki/sources/plan-refactor-ai-parse.md` — Plan refactor AI Parse: Gemini-only, note quality fix, rate limiting tier ✅
  - `wiki/sources/plan-refactor-gold-price.md` — Plan refactor gold-price: Vertex Gemini saja, hapus Groq/OpenRouter ✅
  - `wiki/sources/plan-remove-manual-parsing.md` — Plan hapus manual parsing fallback: regex + parsing_dictionaries ✅
  - `wiki/sources/plan-ui-grouping-attachment.md` — Plan UI grouping by date + fix wallet/category alias + lampiran TransactionDetail

### wiki/entities/ (2 halaman baru)
  - `wiki/entities/ads.md` — Entitas Ads: AdMob integration, eligibility gate, UserModel.showAds, 3 tipe iklan
  - `wiki/entities/home-widget.md` — Entitas Android Home Widget: XML RemoteViews, cold start dual-path, deep links

### wiki/analysis/ (1 fix frontmatter)
  - `wiki/analysis/refactor-ai-parse-gemini-quota.md` — Tambah YAML frontmatter (sebelumnya tidak ada)

- **index.md diperbarui**: tambah 14 entry, total halaman 59 (22 entitas, 8 konsep, 22 sumber, 5 analisis)

- **Tujuan**: Hapus semua jalur fallback parsing lokal (regex + `parsing_dictionaries`) dari ketiga fitur AI input
- **File dihapus**: `ocr_local_parser.dart`, `voice_local_parser.dart`, `parsing_dictionary_model.dart`, `voice_local_data_source.dart`, dan test-test terkait
- **Packages dihapus**: `google_mlkit_text_recognition`, `sqflite`
- **Flutter diubah**: `OcrImageService` (hapus ML Kit), `OcrRepository` (hapus `parseTextLocally`), `OcrScanController` (hapus status `extractingText`), `VoiceRepository` (disederhanakan, hapus `_localFallback()`), `AppConstants` (hapus `cacheTtlDictionary`), ARB (hapus `ocrExtractingText`)
- **Supabase Migration 016**: Drop tabel `parsing_dictionaries` (CASCADE)
- **Error handling baru**: AI fail → `DataState.error` → UI error state + retry button (tidak ada silent fallback)
- **Test**: 505 passed, 7 pre-existing failures
- **Wiki baru**: `wiki/analysis/remove-manual-parsing.md`

## [2026-04-19] ingest | Plan: Revamp Kategori Default

- **Sumber diproses**: `raw/docs/plan-revamp-default-categories.md`
- **Halaman baru dibuat**: 1
  - `wiki/sources/plan-revamp-default-categories.md` — ringkasan plan revamp kategori: 3 parent baru, 15 children baru, fix warna, fix nama
- **Halaman diperbarui**: 2
  - `wiki/entities/categories.md` — tabel seed default diperbarui (10 parent expense, 36 child, 3 parent income, 9 child), tambah link ke plan source, hapus referensi `parsing_dictionaries` (sudah dihapus)
  - `index.md` — tambah entry sumber baru, total halaman 60 (22 entitas, 8 konsep, 23 sumber, 5 analisis)
- **Migration applied**: `revamp_default_categories` → Dev ✅ + Prod ✅
  - UPDATE warna: Pendapatan Tambahan group `#10B981` → `#0EA5E9`, Kesehatan group `#EF4444` → `#F87171`
  - UPDATE nama: "Pengeluaran yang tidak diketahui" → "Tidak Diketahui", "Nongkrong / Hiburan" → "Nongkrong & Sosial"
  - INSERT 3 parent baru expense: Makanan & Minuman, Belanja & Fashion, Hiburan & Hobi
  - INSERT 12 child untuk 3 parent baru
  - INSERT Sewa Rumah + KPR di bawah Tagihan & Kewajiban
  - INSERT Hewan Peliharaan di bawah Keluarga & Sosial
  - INSERT Kesehatan Mental / Terapi di bawah Kesehatan & Kebugaran
  - INSERT Cashback & Reward + Penjualan Barang / Aset di bawah Pendapatan Tambahan
  - CREATE OR REPLACE FUNCTION `seed_default_categories()` — user baru mendapat 60 kategori default

## [2026-04-25] cleanup + ingest | Katalog kategori global (migrasi, raw docs)

- **Raw dihapus** (duplikat / usang, isi sudah digabung ke entitas): `migrasi-kategori-dev-execution-log.md`, `summary-rencana-is-hidden-categories-satu-sumber.md`, `plan-migrasi-kategori-global-tanpa-per-user-seed.md`, `audit-category-management-flutter-supabase.md`
- **Halaman diperbarui**: `wiki/entities/categories.md` — katalog global (`user_id` null), tabel `user_category_hidden`, drop `categories.is_hidden`, RPC `get_user_categories` / `toggle_category_hidden` (perbaikan `p_uid` / `r.relname`), daftar file migrasi `2026042509*` + `2026042522*` + `2026042523*`, uji `flutter test test/features/category/`, catatan MCP dev vs `mcp_supabase-prod_*`, *retry* migrasi 03 di prod; *seed* referensi (revamp 2026-04-19) tetap sebagai isi katalog, bukan *copy* per pendaftaran

## [2026-04-25] update | `database-schema.md` selaraskan kategori global

- **Entitas** `wiki/entities/database-schema.md` — 19 tabel: heading `### 1. users` diperbaiki, `categories` tanpa `is_hidden`, tabel `user_category_hidden`, semua entitas di-renomor, trigger `trg_seed_default_categories` + *no-op* `seed_default_categories` sesuai migrasi Apr 2026, RLS 17 tabel, RPC *Category* `get_user_categories` / `toggle_category_hidden`, indeks UNIQUE *hidden*, catatan `parsing_dictionaries` + intro cross-link ke [[wiki/entities/categories|Categories]]

## [2026-04-25] update | Otoritas skema + sisa selarasan kategori

- **Prioritas konflik** diselaraskan di `wiki/sources/copilot-rules.md`, `wiki/concepts/coding-rules.md`, `raw/docs/03_COPILOT_RULES.md` — *skema aktual* = `supabase/migrations/` + `wiki/entities/database-schema` + (kategori) `wiki/entities/categories`; `02_DATABASE` sebagai *baseline*
- **`SCHEMA.md`**: arah rujukan ke entitas *database-schema* / *categories* / migrasi
- **`raw/docs/prd/00_INDEX.md`**, **`raw/docs/plan-revamp-default-categories.md`**: catatan pasca *katalog global* + fungsi *seed* *no-op*
- **Konsep** `aturan-keuangan`, `arsitektur-app` — *updated*, checklist & link sumber *database* disesuaikan
- **`wiki/concepts/ai-pipeline.md`** — katalog kategori + catatan `parsing_dictionaries` opsional

## [2026-04-25] update | PRD ringkas + AI pipeline (tanpa Groq / tanpa parser lokal)

- **`wiki/sources/prd-sakurapi-v7.md`** — teks AI: Vertex/Gemini saja, error + *retry*; *bullet* *pipeline*; P1: baris *Local Notifications* + penyesuaian *Budgeting*; `updated` 2026-04-25
- **`wiki/concepts/ai-pipeline.md`** — diagram & section: singel provider, hapus Groq + *local parser*; `parsing_dictionaries` disingkat; link ke *remove manual parsing* + *refactor AI quota*

## [2026-04-27] ingest | Multi transaksi manual — UX + wiki

- **Raw diperbarui**: `raw/docs/MULTI_MANUAL_TRANSACTION_PLAN.md` — UX per entry selaras tab tunggal (`TransactionAmountSection` + chip multi-item), `setManualEntryTotalAmount`, batas batch 10 & pesan sukses + count, tabel referensi file Flutter, bagian testing
- **Sumber wiki baru**: `wiki/sources/plan-multi-manual-transaction.md` — ringkasan + tautan ke raw
- **Entitas** `wiki/entities/transaksi.md` — subsection *Mode multi transaksi (manual)*, RPC `create_transactions_batch`, `sources` + `updated`
- **`index.md`** — statistik 61 halaman / 24 sumber; entri sumber baru; deskripsi *Transaksi* diperjelas
- **Implementasi app (konteks)**: `TransactionManualMultiEntryCard`, `TransactionMultiItemSection`, `TransactionFormMultiManualCoordinator` + `setManualMultiEntryTotalAmount`, tes controller & widget terkait
