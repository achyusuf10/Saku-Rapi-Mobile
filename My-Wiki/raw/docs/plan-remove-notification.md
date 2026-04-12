# Plan: Remove Fitur Notifikasi & Budget Alert

> **Status:** Draft  
> **Tujuan:** Menghapus seluruh fitur notifikasi lokal (daily reminder, budget alert, debt reminder) dan semua kode terkait dari codebase SakuRapi.

---

## Latar Belakang & Alasan

Fitur notifikasi saat ini memiliki beberapa masalah:

1. **Inkonsistensi perilaku Budget Alert** — `budgeting.md` menyebut alert di-trigger *saat page load*, sedangkan `notifikasi.md` menyebut *saat transaksi masuk*. Kenyataannya: alert dipanggil di `budget_page.dart` saat `ref.listen()` mendeteksi budget state `loaded` → artinya saat halaman Budget dibuka dan data selesai di-fetch. Bukan saat transaksi masuk. Ini membingungkan dan tidak sesuai ekspektasi user.

2. **Debt reminder belum diimplementasi** — settings-nya ada (toggle, days before), tapi logika pengirimannya belum ada sama sekali. Fitur setengah jadi.

3. **Kompleksitas vs nilai** — Menambah 4 dependencies besar (`flutter_local_notifications`, `workmanager`, `timezone`, `permission_handler`), 7 file feature, dan integrasi di `main.dart` + budget + router — untuk sesuatu yang belum matang dan membingungkan.

4. **Keputusan:** Lebih baik hapus sekarang secara bersih, lalu desain ulang dengan benar di versi berikutnya jika diperlukan.

---

## Scope Perubahan

### ❌ Dihapus Sepenuhnya

| Area | File / Hal yang Dihapus |
|------|------------------------|
| **Feature folder** | `lib/features/notification/` (seluruh folder, 7 file) |
| **Budget model** | Field `notificationSent50`, `notificationSent80`, `notificationSent100` di `BudgetModel` |
| **Budget page** | Method `_checkBudgetAlerts()` + semua referensi ke `budgetAlertCheckerProvider` |
| **main.dart** | `_workmanagerCallbackDispatcher()`, init `NotificationService`, init timezone (`tz.*`) |
| **Router** | Route `/notification-settings` + import `NotificationSettingsPage` |
| **Settings page** | Menu item "Notifications" (navigasi ke `/notification-settings`) |
| **pubspec.yaml** | `flutter_local_notifications`, `workmanager`, `timezone` (**bukan** `permission_handler`) |
| **AndroidManifest.xml** | `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`, `POST_NOTIFICATIONS` |

### ✅ Tetap Ada (Tidak Diubah)

| Area | Alasan |
|------|--------|
| Tabel `notification_settings` di DB | Jangan sentuh DB — bisa dipakai lagi nanti |
| Field `notification_sent_50/80/100` di tabel `budgets` | Tetap ada di DB, cukup hapus dari model Flutter |
| `BudgetModel.isHalfUsed`, `isNearLimit`, `isOverBudget` | Masih dipakai untuk warna progress bar di UI |
| `budget_progress_bar.dart` | Warna threshold tetap ada (UI only, tanpa notif) |
| Trigger `auto_renew_budgets` (pg_cron) | Tetap jalan, reset flag di DB — aman karena Flutter tidak baca flag lagi |

---

## File-by-File Detail

### 1. Hapus seluruh folder
```
lib/features/notification/   ← DELETE seluruh folder
├── controllers/
│   ├── budget_alert_checker.dart
│   └── notification_controller.dart
├── datasource/
│   ├── notification_local_data_source.dart
│   └── notification_remote_data_source.dart
├── models/
│   └── notification_settings_model.dart
├── repositories/
│   └── notification_repository.dart
├── services/
│   └── notification_service.dart
└── view/ui/
    └── notification_settings_page.dart
```

### 2. `lib/features/budget/models/budget_model.dart`
Hapus 3 field + occurrences di constructor, fromMap, toMap, copyWith:
- `notificationSent50`
- `notificationSent80`  
- `notificationSent100`

### 3. `lib/features/budget/view/ui/budget_page.dart`
Hapus:
- Import `budget_alert_checker.dart` dan `notification_controller.dart`
- Method `_checkBudgetAlerts(BudgetState budgetState)`
- Panggilan `_checkBudgetAlerts(next)` di dalam `ref.listen()`

### 4. `lib/main.dart`
Hapus:
- Import `workmanager`
- Import `notification_service.dart`
- Import `timezone` (`tz` dan `tzLocal`)
- Fungsi top-level `_workmanagerCallbackDispatcher()`
- `tz.initializeTimeZones()` + `tzLocal.setLocalLocation(...)` di `bootstrap()`
- `await NotificationService.instance.init()` di `bootstrap()`
- WorkManager init (jika ada di bootstrap)

### 5. `lib/core/router/app_router.dart`
Hapus:
- Import `notification_settings_page.dart`
- Constant `notificationSettings = '/notification-settings'`
- GoRoute untuk `/notification-settings`

### 6. `lib/features/settings/view/ui/settings_page.dart`
Hapus:
- Menu item "Notifications" (tile yang navigate ke `AppRouter.notificationSettings`)
- Import terkait jika tidak dipakai lagi

### 7. `pubspec.yaml`
Hapus 3 dependencies (bukan 4):
```yaml
flutter_local_notifications: ^18.0.0   # ← HAPUS
workmanager: ^0.9.0+3                   # ← HAPUS
timezone: ^0.9.4                        # ← HAPUS
permission_handler: ^12.0.1             # ← TETAP — dipakai OCR, Voice, Contacts
```

> ✅ **`permission_handler` TIDAK boleh dihapus** — digunakan di:
> - `lib/features/ocr/services/ocr_image_service.dart` → `Permission.camera`
> - `lib/features/voice/services/voice_input_service.dart` → `Permission.microphone`
> - `lib/features/transaction/controllers/contact_controller.dart` → `Permission.contacts`

### 8. Android — `android/app/src/main/AndroidManifest.xml`
Hapus 3 baris `<uses-permission>` ini:
```xml
<!-- HAPUS — WorkManager re-schedule after reboot -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

<!-- HAPUS — flutter_local_notifications exact scheduling -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>

<!-- HAPUS — flutter_local_notifications POST_NOTIFICATIONS (Android 13+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

Pertahankan (diperlukan fitur lain):
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />   <!-- OCR -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>   <!-- OCR -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />            <!-- Voice -->
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />   <!-- Voice -->
<uses-permission android:name="android.permission.READ_CONTACTS" />            <!-- Contacts -->
```

### 9. iOS — `ios/Runner/Info.plist`
Tidak ada perubahan. Dicek dan tidak ada entri notification permission di Info.plist
(DarwinInitializationSettings sudah menggunakan `requestAlertPermission: false`).

---

## Urutan Pengerjaan

Ikuti urutan ini untuk menghindari compile error:

1. **Hapus folder `lib/features/notification/`**
2. **Update `budget_model.dart`** — hapus 3 field notif
3. **Update `budget_page.dart`** — hapus `_checkBudgetAlerts` + listener-nya
4. **Update `settings_page.dart`** — hapus menu Notifications
5. **Update `app_router.dart`** — hapus route + import
6. **Update `main.dart`** — hapus WorkManager + NotificationService + timezone
7. **Update `pubspec.yaml`** — hapus 3 dependencies (`flutter_local_notifications`, `workmanager`, `timezone`)
8. **Update `AndroidManifest.xml`** — hapus 3 `<uses-permission>` (BOOT, SCHEDULE_EXACT_ALARM, POST_NOTIFICATIONS)
9. **Jalankan `flutter pub get`**
10. **Jalankan `fvm flutter analyze`** — pastikan 0 error baru
11. **Jalankan `fvm flutter test`** — pastikan tidak ada test yang break

---

## Risiko & Catatan

| Risiko | Mitigasi |
|--------|----------|
| Test yang mock `NotificationController` | Grep test folder untuk `notification`, hapus/update test yang terdampak |
| `timezone` dipakai untuk hal lain | Hanya dipakai di `main.dart` untuk notif — aman dihapus |
| DB tetap punya `notification_settings` table | Tidak masalah — tabel di DB tetap ada, Flutter tidak baca/tulis lagi |
| `permission_handler` — sudah dikonfirmasi tetap | Dipakai OCR (`Permission.camera`), Voice (`Permission.microphone`), Contacts (`Permission.contacts`) |

---

## Setelah Selesai: Update Wiki

- Update `wiki/entities/budgeting.md` — hapus section "Budget Alert" / "BudgetAlertChecker"
- Update `wiki/entities/notifikasi.md` — tambahkan note "Fitur ini dihapus di vX.X, akan didesain ulang di masa mendatang"
- Update `wiki/entities/settings.md` — hapus referensi ke Notification Settings page
- Append ke `My-Wiki/log.md`
