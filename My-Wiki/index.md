---
title: "Indeks Wiki"
updated: 2026-04-19
---

# 📚 Indeks Wiki SakuRapi

> Katalog semua halaman wiki. Diperbarui otomatis oleh LLM setiap kali ada perubahan.

## Statistik

| Metrik | Jumlah |
|--------|--------|
| Total halaman | 59 |
| Sumber diproses | 22 |
| Entitas | 22 |
| Konsep | 8 |
| Analisis | 5 |

---

## 🏷️ Entitas

<!-- Halaman tentang fitur, layanan, tools, komponen spesifik -->

- [[wiki/entities/sakurapi|SakuRapi]] — Aplikasi pencatat keuangan pribadi (Flutter + Supabase)
- [[wiki/entities/wallet|Wallet]] — Multi-wallet CRUD, saldo read-only via DB trigger
- [[wiki/entities/transaksi|Transaksi]] — Form 4-tab: Expense, Income, Transfer, Hutang/Piutang
- [[wiki/entities/dashboard|Dashboard]] — Ringkasan keuangan dan visualisasi chart
- [[wiki/entities/dashboard-charts|Dashboard Charts]] — Breakdown lengkap: Carousel, Comparison Chart, Trend Chart, Period Summary, Burn Rate insight
- [[wiki/entities/hutang-piutang|Hutang/Piutang]] — Manajemen pinjaman dan pelunasan per kontak
- [[wiki/entities/budgeting|Budgeting]] — Anggaran per kategori dengan auto-renew dan alert
- [[wiki/entities/investasi|Investasi]] — Portfolio investasi (gold, bitcoin, custom asset)
- [[wiki/entities/voice-input|Voice Input]] — Input transaksi via suara dengan AI parsing
- [[wiki/entities/text-input|Text Input]] — Input transaksi via teks dengan AI parsing
- [[wiki/entities/ocr-receipt|OCR Receipt]] — Scan struk belanja dengan OCR dan AI parsing
- [[wiki/entities/history|History]] — Riwayat transaksi dengan filter, period, dan pagination
- [[wiki/entities/settings|Settings]] — Pengaturan aplikasi, notifikasi, dan preferensi
- [[wiki/entities/user-report|User Report]] — Kirim laporan/feedback dari dalam app (fire-and-forget write ke Supabase)
- [[wiki/entities/database-schema|Database Schema]] — 17 tabel Supabase/Postgres, triggers, RPC, indexes, RLS
- [[wiki/entities/categories|Categories]] — Sistem kategori (expense, income, system) dengan hierarki 2-level
- [[wiki/entities/contacts|Contacts]] — Manajemen kontak untuk hutang/piutang
- [[wiki/entities/reports|Reports]] — Laporan keuangan (summary, pie chart, trend chart, per kategori)
- [[wiki/entities/edge-functions|Edge Functions]] — Supabase Edge Functions (ai-parse, gold-price, bitcoin-price) berbasis Deno + TypeScript
- [[wiki/entities/notifikasi|Notifikasi]] — Sistem notifikasi lokal (daily reminder, budget alert, pengingat piutang)
- [[wiki/entities/ads|Ads]] — Sistem iklan Google AdMob (banner, native, interstitial, eligibility gate via `show_ads`)
- [[wiki/entities/home-widget|Android Home Widget]] — Widget Android (XML RemoteViews, wallet display, balance privacy toggle, 4 quick actions)

## 💡 Konsep

<!-- Halaman tentang pola arsitektur, domain knowledge, prinsip -->

- [[wiki/concepts/aturan-keuangan|Aturan Keuangan Fundamental]] — Aturan emas, keputusan final, guardrails keuangan
- [[wiki/concepts/matrix-transaksi|Matrix Transaksi]] — 7 tipe transaksi, aturan settlement, validasi
- [[wiki/concepts/ai-pipeline|AI Pipeline]] — Voice/Text/OCR parsing, failover chain, parsing dictionary
- [[wiki/concepts/arsitektur-app|Arsitektur App]] — Tech stack, 3-file pattern, model/provider/UI conventions
- [[wiki/concepts/roadmap-status|Roadmap & Status]] — 12 fase development, DoD, testing, permission model
- [[wiki/concepts/coding-rules|Coding Rules]] — Aturan coding, formatting, UI conventions, testing, forbidden actions
- [[wiki/concepts/design-system|Design System]] — "Financial Trust" design system (Trust Navy, IBM Plex Sans, visual rules)
- [[wiki/concepts/keamanan|Keamanan & Security Posture]] — Security posture post-audit, RLS patterns, edge function auth, checklist deployment

## 📄 Sumber

<!-- Ringkasan sumber yang sudah diproses -->

- [[wiki/sources/prd-sakurapi-v7|PRD SakuRapi v7.0 — Ringkasan]] — Ringkasan komprehensif PRD v7.0 (27 file, fitur P0–P2, aturan keuangan, roadmap, keputusan final)
- [[wiki/sources/coding-rules|Coding Rules (Sumber)]] — Ringkasan 00_SakuRapi_Coding_Rules.md
- [[wiki/sources/database-v6|Database v6.4 (Sumber)]] — Ringkasan 02_DATABASE.md (15 tabel, triggers, RPC, indexes)
- [[wiki/sources/copilot-rules|Copilot Rules (Sumber)]] — Ringkasan 03_COPILOT_RULES.md (guardrails, conventions, testing)
- [[wiki/sources/redesign-ui-ux|Redesign UI/UX (Sumber)]] — Ringkasan 13 file redesign (S1-S12, design tokens, widget overhaul, per-module specs)
- [[wiki/sources/plan-remove-notification|Plan: Hapus Fitur Notifikasi]] — Rencana dan dokumentasi penghapusan fitur notifikasi lokal (April 2026)
- [[wiki/sources/plan-fitur-kirim-laporan|Plan: Fitur Kirim Laporan]] — Rencana dan implementasi fitur user report/feedback (April 2026)
- [[wiki/sources/plan-history-search-category-pagination|Plan: History Search + Category Pagination]] — Rencana dan implementasi search server-side + category-level pagination di History (April 2026)
- [[wiki/sources/plan-refactor-report-category-breakdown|Plan: Refactor Breakdown Kategori Reports]] — Refactor breakdown kategori Reports: pie chart + linear list digabung, top 5 + Lainnya, mode toggle dihapus (April 2026)
- [[wiki/sources/plan-sentry-integration|Plan: Sentry Integration]] — Integrasi Sentry error monitoring: flavor-based config, noise filtering, SentryContext per event (April 2026)
- [[wiki/sources/plan-ads-integration|Plan: Integrasi Google AdMob]] — Rencana monetisasi iklan: Banner (dashboard+history), Native (every 10), Interstitial (per 5 simpan), eligibility gate `show_ads` (April 2026)
- [[wiki/sources/audit-dashboard-charts|Audit: Dashboard Charts]] — 8 bug ditemukan: loading state, stale flash, tooltip single-series, label "kemarin" salah (April 2026)
- [[wiki/sources/audit-report-page|Audit: Report Page]] — Bug tooltip single-series, gap fill hari kosong, hardcoded "Income"/"Expense" di tooltip (April 2026)
- [[wiki/sources/plan-image-upload-edge-fn|Plan: Edge Function image-upload]] — Edge function upload gambar: Supabase Storage primary, GCS fallback jika over limit (April 2026)
- [[wiki/sources/plan-ai-parse-enhancement|Plan: Enhancement AI Parse (Wallet + Category)]] — Kirim wallet list ke AI, short ID mapping, multi-item text/voice, rename `suggestedWalletId` (April 2026)
- [[wiki/sources/plan-android-home-widget|Plan: Android Home Widget]] — XML RemoteViews, wallet navigation arrows, balance privacy toggle, 4 quick action deep links, cold start fix (April 2026)
- [[wiki/sources/plan-fix-ai-parse-gemini-404|Plan: Fix AI Parse Gemini Model 404]] — Root cause + fix model 404: `gemini-1.5-flash` → `gemini-2.5-flash-lite`, pindah ke Vertex AI auth (April 2026)
- [[wiki/sources/plan-normalize-date-iso8601|Plan: Normalisasi Date ISO 8601]] — Kontrak akhir timestamp vs date-only, `SakuDateUtils`, migration 021 restore timestamptz — ✅ Implemented (April 2026)
- [[wiki/sources/plan-refactor-ai-parse|Plan: Refactor AI Parse (Gemini Only + Daily Quota)]] — Gemini-only, perbaikan note quality, rate limiting per mode, tier free/premium — ✅ Implemented (April 2026)
- [[wiki/sources/plan-refactor-gold-price|Plan: Refactor Gold Price ke Gemini Only]] — Hapus Groq/OpenRouter, Vertex AI Gemini 2.5 Flash saja — ✅ Implemented (April 2026)
- [[wiki/sources/plan-remove-manual-parsing|Plan: Hapus Manual Parsing]] — Hapus regex fallback + parsing_dictionaries; AI fail → error + retry, bukan silent fallback — ✅ Implemented (April 2026)
- [[wiki/sources/plan-ui-grouping-attachment|Plan: UI Grouping + Attachment + Transaction Detail]] — Group-by-date di BudgetDetail+ReportCategory, fix wallet/kategori alias bug, tampilkan lampiran di TransactionDetail (April 2026)

## 🔬 Analisis

<!-- Perbandingan, evaluasi, sintesis -->

- [[wiki/analysis/remove-notification|Penghapusan Fitur Notifikasi]] — Analisis keputusan, scope perubahan, dan catatan implementasi penghapusan fitur notifikasi lokal
- [[wiki/analysis/keputusan-hapus-notifikasi|Keputusan: Hapus Notifikasi]] — Analisis keputusan menghapus budget alert, daily reminder, dan debt reminder dari app layer
- [[wiki/analysis/remove-manual-parsing|Penghapusan Manual Parsing Fallback]] — Refactor OCR + Voice + Text Input: fallback lokal (regex + parsing_dictionaries) dihapus, AI fail → error + retry
- [[wiki/analysis/refactor-ai-parse-gemini-quota|Refactor AI Parse: Gemini-Only + Quota]] — Simplifikasi ke Gemini saja, perbaikan note quality, daily quota system (free/premium tier), auto-downgrade
- [[wiki/analysis/refactor-gold-price-gemini-only|Refactor Gold Price: Vertex Gemini-Only]] — Penyederhanaan gold-price ke Vertex AI Gemini 2.5 Flash saja, scrape-first tetap dipertahankan, Groq/OpenRouter dihapus