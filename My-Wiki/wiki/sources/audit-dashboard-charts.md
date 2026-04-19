---
title: "Audit: Dashboard Charts (April 2026)"
type: source
tags: [dashboard, charts, audit, bug, loading-state, tooltip, trend-chart]
sources: [raw/audit-dashboard-charts.md]
created: 2026-04-19
updated: 2026-04-19
---

# Audit: Dashboard Charts (April 2026)

**Status:** Audit findings — sebagian sudah diperbaiki
**Sumber:** `raw/audit-dashboard-charts.md`

## Ringkasan

Audit terhadap komponen chart di Dashboard menemukan 8 bug yang berbeda, meliputi loading state, stale data, tooltip, dan label yang salah.

## Bug Ditemukan

| # | Bug | Komponen |
|---|-----|---------|
| 1 | Tidak ada loading indicator saat mode chart diganti | `ChartModeSelector` + parent |
| 2 | `selectChartMode()` tidak handle loading/error state | `DashboardController` |
| 3 | Stale data flash — data lama tampil sekilas sebelum data baru muncul | State management |
| 4 | Label "kemarin" di PeriodSummary salah pada mode daily | `PeriodSummaryWidget` |
| 5 | Tooltip comparison chart hanya tampil 1 series | `ComparisonChartWidget` |
| 6 | Tooltip trend chart hanya tampil 1 series | `TrendChartWidget` |
| 7 | Shimmer stuck — tidak berhenti meski data sudah ada | Loading state logic |
| 8 | Tooltip hanya tampil 1 data series (general issue across charts) | Multiple chart widgets |

## Detail Bug Kritis

### Bug 3 — Stale Data Flash
Saat user pindah periode, data lama masih di-render selama loading. Perlu set state ke loading/null dulu sebelum fetch.

### Bug 4 — Label "Kemarin"
Pada mode `daily`, label period summary menampilkan "kemarin" padahal harusnya nama hari spesifik. Logic label perlu disesuaikan dengan mode aktif.

### Bug 5 & 6 — Tooltip Single Series
Tooltip chart hanya menampilkan 1 data point. Fix: tooltip harus menampilkan semua series yang ada di titik tersebut (income + expense atau periode perbandingan A + B).

## Scope Fix

- `lib/features/dashboard/view/ui/dashboard_page.dart`
- `lib/features/dashboard/controllers/dashboard_controller.dart`
- Chart widget files di `lib/features/dashboard/view/widgets/`

## Halaman Terkait

- [[wiki/entities/dashboard|Dashboard]]
- [[wiki/sources/audit-report-page|Audit: Report Page]]
