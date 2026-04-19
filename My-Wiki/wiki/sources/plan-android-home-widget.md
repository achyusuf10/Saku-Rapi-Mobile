---
title: "Plan: Android Home Widget"
type: source
tags: [home-widget, android, deep-link, riverpod, wallet, quick-actions]
sources: [raw/plan-android-home-widget.md]
created: 2026-04-19
updated: 2026-04-19
---

# Plan: Android Home Widget

**Status:** Draft v2.1 — Belum diimplementasi
**Dibuat:** 2026-04-15
**Package:** `home_widget: ^0.9.1`
**Sumber:** `raw/plan-android-home-widget.md`

## Ringkasan

Membangun 1 Android Home Widget untuk SakuRapi dengan fitur:

| Bagian | Deskripsi |
|--------|-----------|
| **Wallet Display + Arrows** | Layout statis 1 wallet aktif + tombol `<` `>` untuk navigasi antar wallet |
| **Balance Privacy Toggle** | Icon mata show/hide saldo — default: tersembunyi (`Rp •••••••`) |
| **Quick Actions** | 4 tombol: Manual, Voice, OCR, Text — deep link ke app |
| **Config Activity** | Popup saat widget ditambahkan untuk pilih wallet |

## Keputusan Teknis Kunci

### Approach: XML RemoteViews (bukan Jetpack Glance)
- Stabilitas lebih terjamin — battle-tested
- Horizontal swipe tidak didukung RemoteViews → pakai static layout + arrow buttons
- `home_widget 0.9.1` masih support XML via `HomeWidgetProvider`

### Cold Start Fix — Dual-Path di Dashboard
`ref.listen` hanya fire pada **perubahan** state. Saat cold start dari widget, provider sudah diisi sebelum DashboardPage mount → listener tidak fire.

**Fix:**
1. `ref.listen` untuk warm start
2. `_coldStartHandled` flag + `addPostFrameCallback` initial check untuk cold start

### Privacy Toggle
- State disimpan di `SharedPreferences` (bukan Hive, karena native layer butuh akses)
- Default: saldo tersembunyi

## Revisi Krusial (v2)

| # | Masalah | Solusi |
|---|---------|--------|
| R1 | `AdapterViewFlipper` tidak support swipe mulus | Static + arrow buttons via `PendingIntent` |
| R2 | `Future.delayed` di deep link = race condition | State-based: `pendingWidgetActionProvider` (Riverpod) |
| R3 | Saldo terbuka di home screen = celah privasi | Eye toggle, default hidden, state di SharedPreferences |
| R4 | Config Activity crash jika SharedPreferences kosong | Empty state + tombol "Buka App" |

## Deep Link / Quick Actions

4 quick actions sebagai deep link ke app:
- **Manual** → `AppRouter.transactionForm`
- **Voice** → set `pendingVoicePrefillProvider` + push form
- **OCR** → set `pendingOcrPrefillProvider` + push form
- **Text** → set `pendingVoicePrefillProvider` (text mode) + push form

**Belum ada URI scheme handler** di `app_router.dart` — perlu ditambah.

## Scope File

**Android Native:**
- `android/app/src/main/res/layout/saku_home_widget.xml`
- `android/app/src/main/res/xml/saku_home_widget_info.xml`
- `android/app/src/main/kotlin/.../SakuHomeWidgetProvider.kt`
- `android/app/src/main/kotlin/.../SakuWidgetConfigActivity.kt`
- `android/app/src/main/AndroidManifest.xml`

**Flutter:**
- `lib/core/router/app_router.dart` — tambah deep link handler
- `lib/features/dashboard/controllers/dashboard_controller.dart` — cold start dual-path
- `lib/core/providers/widget_action_provider.dart` (BARU) — `pendingWidgetActionProvider`

## Halaman Terkait

- [[wiki/entities/wallet|Wallet]]
- [[wiki/entities/dashboard|Dashboard]]
- [[wiki/entities/voice-input|Voice Input]]
- [[wiki/entities/ocr-receipt|OCR Receipt]]
