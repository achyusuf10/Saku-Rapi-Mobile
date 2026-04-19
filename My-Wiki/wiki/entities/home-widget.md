---
title: "Android Home Widget"
type: entity
tags: [home-widget, android, deep-link, remote-views, quick-actions, wallet]
sources: [raw/plan-android-home-widget.md]
created: 2026-04-19
updated: 2026-04-19
---

# Android Home Widget

## Ringkasan

Widget Android berukuran 4×2 yang menampilkan saldo wallet aktif dan memberikan akses cepat ke 4 aksi transaksi. Dibangun dengan XML RemoteViews (bukan Jetpack Glance) untuk stabilitas maksimal.

**Status implementasi:** Draft v2.1 — Belum diimplementasi (April 2026)
**Package:** `home_widget: ^0.9.1`

---

## Layout & Fitur

```
┌──────────────────────────────────────┐
│  < [Nama Wallet]  >   👁  [Rp •••••] │
├──────────────────────────────────────┤
│  [Manual]  [Voice]  [OCR]  [Text]    │
└──────────────────────────────────────┘
```

| Bagian | Deskripsi |
|--------|-----------|
| Wallet Display | Nama wallet aktif + navigasi `<` `>` (bukan swipe) |
| Balance Privacy | Toggle 👁 — default tersembunyi. State di SharedPreferences |
| Quick Actions | 4 tombol deep link ke app: Manual / Voice / OCR / Text |
| Config Activity | Popup saat widget ditambahkan → pilih wallet default |

---

## Keputusan Arsitektur

### XML RemoteViews (bukan Jetpack Glance)
- Horizontal swipe tidak didukung stabil oleh Glance
- XML RemoteViews battle-tested untuk kasus ini
- Navigation wallet via static layout + `PendingIntent` arrow buttons

### Cold Start Fix — Dual Path di Dashboard

`ref.listen` hanya fire saat state **berubah**. Pada cold start, `pendingWidgetActionProvider` sudah diisi sebelum `DashboardPage` mount → listener tidak fire → user stuck.

**Solusi — Dual Path:**
```dart
// Warm start: ref.listen (perubahan state)
ref.listen(pendingWidgetActionProvider, (_, action) {
  if (action != null) _handleWidgetAction(action);
});

// Cold start: initial check via addPostFrameCallback
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (_coldStartHandled) return;
  _coldStartHandled = true;
  final action = ref.read(pendingWidgetActionProvider);
  if (action != null) _handleWidgetAction(action);
});
```

### Privacy Toggle
- Default: **saldo tersembunyi** (`Rp •••••••`)
- State di `SharedPreferences` (native layer butuh akses)
- Tidak menggunakan Hive karena Hive bukan platform channel

---

## Deep Link / Quick Actions Flow

| Tombol | Flow |
|--------|------|
| Manual | Launch app → Dashboard → push `transactionForm` |
| Voice | Launch app → Dashboard → set `pendingVoicePrefillProvider` → VoiceInputSheet |
| OCR | Launch app → Dashboard → set `pendingOcrPrefillProvider` → OcrResultSheet |
| Text | Launch app → Dashboard → set `pendingVoicePrefillProvider` (text mode) → TextInputSheet |

**Belum ada URI scheme handler** di `app_router.dart` — perlu ditambah.

---

## Scope File

### Android Native (Baru)
- `android/app/src/main/res/layout/saku_home_widget.xml`
- `android/app/src/main/res/xml/saku_home_widget_info.xml`
- `android/app/src/main/kotlin/.../SakuHomeWidgetProvider.kt`
- `android/app/src/main/kotlin/.../SakuWidgetConfigActivity.kt`
- `android/app/src/main/AndroidManifest.xml` — tambah widget + config activity

### Flutter (Baru/Ubah)
- **BARU**: `lib/core/providers/widget_action_provider.dart` — `pendingWidgetActionProvider`
- `lib/core/router/app_router.dart` — tambah deep link URI handler
- `lib/features/dashboard/controllers/dashboard_controller.dart` — cold start dual-path

---

## Data yang Disimpan di SharedPreferences (Native)

| Key | Tipe | Keterangan |
|-----|------|-----------|
| `widget_active_wallet_index` | int | Index wallet aktif di list |
| `widget_balance_hidden` | bool | Privacy toggle state |
| `widget_wallet_names` | String (JSON) | Serialized wallet names |
| `widget_wallet_balances` | String (JSON) | Serialized wallet balances |

Widget update saat: app foreground, transaksi disimpan, saldo berubah.

---

## Halaman Terkait

- [[wiki/sources/plan-android-home-widget|Plan: Android Home Widget]]
- [[wiki/entities/wallet|Wallet]]
- [[wiki/entities/dashboard|Dashboard]]
- [[wiki/entities/voice-input|Voice Input]]
- [[wiki/entities/ocr-receipt|OCR Receipt]]
