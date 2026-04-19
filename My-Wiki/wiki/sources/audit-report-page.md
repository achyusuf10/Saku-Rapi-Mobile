---
title: "Audit: Report Page (April 2026)"
type: source
tags: [reports, audit, bug, tooltip, trend-chart, smart-insight, gap-fill]
sources: [raw/audit-report-page.md]
created: 2026-04-19
updated: 2026-04-19
---

# Audit: Report Page (April 2026)

**Status:** Audit findings — Smart Insight sudah diimplementasi
**Sumber:** `raw/audit-report-page.md`

## Ringkasan

Audit terhadap `ReportPage` menemukan beberapa isu di trend chart tooltip, gap fill untuk hari tanpa transaksi, dan hardcoded string. Smart Insight juga diaudit.

## Bug / Improvement Ditemukan

### 1. Tooltip Trend Chart — Hanya 1 Series
**Problem:** Tooltip pada trend chart hanya menampilkan 1 series (misalnya hanya income, atau hanya expense).
**Fix:** Tooltip harus menampilkan kedua series (income + expense) di titik yang sama.

### 2. Gap Fill — Hari Tanpa Transaksi
**Problem:** Jika tidak ada transaksi di tanggal tertentu, titik tersebut hilang dari chart (tidak ada `0` fill).
**Fix:** Frontend atau query harus mengisi gap dengan nilai `0` untuk semua hari dalam range periode.

### 3. Hardcoded "Income" / "Expense" di Tooltip
**Problem:** Label series di tooltip menggunakan string hardcoded `"Income"` dan `"Expense"` (English), bukan dari l10n.
**Fix:** Pakai `context.l10n.income` / `context.l10n.expense` atau ARB key yang sesuai.

### 4. Smart Insight — Audit
Smart Insight diaudit untuk memastikan logic peringatan dan saran keuangan yang ditampilkan akurat dan relevan. Status: diimplementasi.

## Scope Fix

- `lib/features/reports/view/ui/report_page.dart`
- `lib/features/reports/view/widgets/trend_chart_widget.dart` (atau sejenisnya)
- `lib/l10n/app_id.arb` + `app_en.arb` (jika ada key yang perlu ditambah)

## Halaman Terkait

- [[wiki/entities/reports|Reports]]
- [[wiki/sources/audit-dashboard-charts|Audit: Dashboard Charts]]
