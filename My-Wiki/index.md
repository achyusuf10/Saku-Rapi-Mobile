---
title: "Indeks Wiki"
updated: 2026-04-12
---

# 📚 Indeks Wiki SakuRapi

> Katalog semua halaman wiki. Diperbarui otomatis oleh LLM setiap kali ada perubahan.

## Statistik

| Metrik | Jumlah |
|--------|--------|
| Total halaman | 35 |
| Sumber diproses | 6 |
| Entitas | 18 |
| Konsep | 7 |
| Analisis | 4 |

---

## 🏷️ Entitas

<!-- Halaman tentang fitur, layanan, tools, komponen spesifik -->

- [[wiki/entities/sakurapi|SakuRapi]] — Aplikasi pencatat keuangan pribadi (Flutter + Supabase)
- [[wiki/entities/wallet|Wallet]] — Multi-wallet CRUD, saldo read-only via DB trigger
- [[wiki/entities/transaksi|Transaksi]] — Form 4-tab: Expense, Income, Transfer, Hutang/Piutang
- [[wiki/entities/dashboard|Dashboard]] — Ringkasan keuangan dan visualisasi chart
- [[wiki/entities/hutang-piutang|Hutang/Piutang]] — Manajemen pinjaman dan pelunasan per kontak
- [[wiki/entities/budgeting|Budgeting]] — Anggaran per kategori dengan auto-renew dan alert
- [[wiki/entities/investasi|Investasi]] — Portfolio investasi (gold, bitcoin, custom asset)
- [[wiki/entities/voice-input|Voice Input]] — Input transaksi via suara dengan AI parsing
- [[wiki/entities/text-input|Text Input]] — Input transaksi via teks dengan AI parsing
- [[wiki/entities/ocr-receipt|OCR Receipt]] — Scan struk belanja dengan OCR dan AI parsing
- [[wiki/entities/history|History]] — Riwayat transaksi dengan filter, period, dan pagination
- [[wiki/entities/settings|Settings]] — Pengaturan aplikasi, notifikasi, dan preferensi
- [[wiki/entities/database-schema|Database Schema]] — 17 tabel Supabase/Postgres, triggers, RPC, indexes, RLS
- [[wiki/entities/categories|Categories]] — Sistem kategori (expense, income, system) dengan hierarki 2-level
- [[wiki/entities/contacts|Contacts]] — Manajemen kontak untuk hutang/piutang
- [[wiki/entities/reports|Reports]] — Laporan keuangan (summary, pie chart, trend chart, per kategori)
- [[wiki/entities/edge-functions|Edge Functions]] — Supabase Edge Functions (ai-parse, gold-price, bitcoin-price) berbasis Deno + TypeScript
- [[wiki/entities/notifikasi|Notifikasi]] — Sistem notifikasi lokal (daily reminder, budget alert, pengingat piutang)

## 💡 Konsep

<!-- Halaman tentang pola arsitektur, domain knowledge, prinsip -->

- [[wiki/concepts/aturan-keuangan|Aturan Keuangan Fundamental]] — Aturan emas, keputusan final, guardrails keuangan
- [[wiki/concepts/matrix-transaksi|Matrix Transaksi]] — 7 tipe transaksi, aturan settlement, validasi
- [[wiki/concepts/ai-pipeline|AI Pipeline]] — Voice/Text/OCR parsing, failover chain, parsing dictionary
- [[wiki/concepts/arsitektur-app|Arsitektur App]] — Tech stack, 3-file pattern, model/provider/UI conventions
- [[wiki/concepts/roadmap-status|Roadmap & Status]] — 12 fase development, DoD, testing, permission model
- [[wiki/concepts/coding-rules|Coding Rules]] — Aturan coding, formatting, UI conventions, testing, forbidden actions
- [[wiki/concepts/design-system|Design System]] — "Financial Trust" design system (Trust Navy, IBM Plex Sans, visual rules)

## 📄 Sumber

<!-- Ringkasan sumber yang sudah diproses -->

- [[wiki/sources/prd-sakurapi-v7|PRD SakuRapi v7.0 — Ringkasan]] — Ringkasan komprehensif PRD v7.0 (27 file, fitur P0–P2, aturan keuangan, roadmap, keputusan final)
- [[wiki/sources/coding-rules|Coding Rules (Sumber)]] — Ringkasan 00_SakuRapi_Coding_Rules.md
- [[wiki/sources/database-v6|Database v6.4 (Sumber)]] — Ringkasan 02_DATABASE.md (15 tabel, triggers, RPC, indexes)
- [[wiki/sources/copilot-rules|Copilot Rules (Sumber)]] — Ringkasan 03_COPILOT_RULES.md (guardrails, conventions, testing)
- [[wiki/sources/redesign-ui-ux|Redesign UI/UX (Sumber)]] — Ringkasan 13 file redesign (S1-S12, design tokens, widget overhaul, per-module specs)
- [[wiki/sources/plan-remove-notification|Plan: Hapus Fitur Notifikasi]] — Rencana dan dokumentasi penghapusan fitur notifikasi lokal (April 2026)

## 🔬 Analisis

<!-- Perbandingan, evaluasi, sintesis -->

- [[wiki/analysis/remove-notification|Penghapusan Fitur Notifikasi]] — Analisis keputusan, scope perubahan, dan catatan implementasi penghapusan fitur notifikasi lokal
- [[wiki/analysis/keputusan-hapus-notifikasi|Keputusan: Hapus Notifikasi]] — Analisis keputusan menghapus budget alert, daily reminder, dan debt reminder dari app layer
- [[wiki/analysis/remove-manual-parsing|Penghapusan Manual Parsing Fallback]] — Refactor OCR + Voice + Text Input: fallback lokal (regex + parsing_dictionaries) dihapus, AI fail → error + retry
- [[wiki/analysis/refactor-ai-parse-gemini-quota|Refactor AI Parse: Gemini-Only + Quota]] — Simplifikasi ke Gemini saja, perbaikan note quality, daily quota system (free/premium tier), auto-downgrade
