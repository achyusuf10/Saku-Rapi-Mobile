---
title: "Plan: Hapus Fitur Notifikasi"
type: source
tags: [plan, notification, budgeting, cleanup, refactor]
sources: [raw/docs/plan-remove-notification.md]
created: 2026-04-12
updated: 2026-04-12
---

# Plan: Hapus Fitur Notifikasi

Ringkasan dokumen perencanaan penghapusan seluruh fitur notifikasi lokal dari codebase SakuRapi.

---

## Latar Belakang & Alasan

Tiga alasan utama keputusan ini:

1. **Inkonsistensi trigger Budget Alert** — `BudgetAlertChecker` dipanggil di `budget_page.dart` saat `ref.listen()` mendeteksi budget state `loaded`, artinya saat halaman Budget dibuka dan data selesai di-fetch — **bukan** saat transaksi masuk. Ini bertentangan dengan ekspektasi user dan dokumentasi internal yang saling kontradiksi.

2. **Debt reminder setengah jadi** — Settings toggle dan `days_before` sudah ada di UI dan DB, tapi **logika pengirimannya belum diimplementasi sama sekali**. Fitur ini dirilis dalam kondisi tidak selesai.

3. **Kompleksitas vs nilai** — Menambah 4 dependencies besar (`flutter_local_notifications`, `workmanager`, `timezone`, `permission_handler`*), 7 file feature, integrasi di `main.dart` + budget page + router + settings — untuk sesuatu yang belum matang. Lebih baik hapus sekarang, desain ulang dengan benar di versi berikutnya.

> *`permission_handler` **tidak dihapus** karena dipakai fitur OCR, Voice, dan Contacts.

---

## Scope Perubahan

### ❌ Dihapus Sepenuhnya

| Area | Yang Dihapus |
|------|-------------|
| Feature folder | `lib/features/notification/` (seluruh folder, 7 file) |
| Budget model | Field `notificationSent50`, `notificationSent80`, `notificationSent100` di `BudgetModel` |
| Budget page | Method `_checkBudgetAlerts()` + referensi ke `budgetAlertCheckerProvider` |
| main.dart | `_workmanagerCallbackDispatcher()`, init `NotificationService`, init timezone |
| Router | Route `/notification-settings` + import `NotificationSettingsPage` |
| Settings page | Menu item "Notifications" |
| pubspec.yaml | `flutter_local_notifications`, `workmanager`, `timezone` |
| AndroidManifest.xml | `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`, `POST_NOTIFICATIONS` |
| Test | `test/features/notification/notification_test.dart` |

### ✅ Tetap Ada (Tidak Diubah)

| Area | Alasan |
|------|--------|
| Tabel `notification_settings` di DB | Bisa dipakai lagi nanti — jangan sentuh DB |
| Field `notification_sent_50/80/100` di tabel `budgets` | Tetap ada di DB; cukup hapus dari model Flutter |
| `BudgetModel.isHalfUsed`, `isNearLimit`, `isOverBudget` | Masih dipakai untuk warna progress bar UI |
| `budget_progress_bar.dart` | Warna threshold tetap ada (UI only, tanpa notif) |
| Trigger `auto_renew_budgets` (pg_cron) | Tetap jalan, reset flag di DB — aman |
| `permission_handler` dependency | Dipakai OCR (`Permission.camera`), Voice (`Permission.microphone`), Contacts (`Permission.contacts`) |

---

## File-by-File Changes

9 area perubahan yang perlu dikerjakan:

1. **Hapus `lib/features/notification/`** — seluruh folder (7 file: controllers, datasource, models, repositories, services, view/ui)
2. **`budget_model.dart`** — hapus 3 field + occurrences di constructor, `fromMap`, `toMap`, `copyWith`
3. **`budget_page.dart`** — hapus method `_checkBudgetAlerts()` + panggilan di `ref.listen()`
4. **`main.dart`** — hapus import workmanager, notification_service, timezone; hapus fungsi `_workmanagerCallbackDispatcher()`; hapus inisialisasi timezone dan NotificationService di `bootstrap()`
5. **`app_router.dart`** — hapus import `NotificationSettingsPage`, hapus constant `notificationSettings`, hapus `GoRoute` untuk `/notification-settings`
6. **`settings_page.dart`** — hapus menu item "Notifications"
7. **`pubspec.yaml`** — hapus `flutter_local_notifications`, `workmanager`, `timezone`
8. **`AndroidManifest.xml`** — hapus 3 `<uses-permission>`: `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`, `POST_NOTIFICATIONS`
9. **Test** — hapus/update `test/features/notification/notification_test.dart`

---

## Urutan Pengerjaan

Urutan ini penting untuk menghindari compile error:

1. Hapus folder `lib/features/notification/`
2. Update `budget_model.dart` — hapus 3 field notif
3. Update `budget_page.dart` — hapus `_checkBudgetAlerts` + listener-nya
4. Update `settings_page.dart` — hapus menu Notifications
5. Update `app_router.dart` — hapus route + import
6. Update `main.dart` — hapus WorkManager + NotificationService + timezone
7. Update `pubspec.yaml` — hapus 3 dependencies
8. Update `AndroidManifest.xml` — hapus 3 `<uses-permission>`
9. Jalankan `flutter pub get`
10. Jalankan `fvm flutter analyze` — pastikan 0 error baru
11. Jalankan `fvm flutter test` — pastikan tidak ada test yang break

---

## Catatan Penting

- **`permission_handler` TETAP** — digunakan oleh OCR, Voice, dan Contacts. **Jangan dihapus.**
- **DB tidak diubah** — tabel `notification_settings` dan kolom `notification_sent_*` di `budgets` tetap ada untuk memudahkan re-implementasi di masa depan.
- **iOS tidak perlu diubah** — tidak ada entri notification permission di `Info.plist`.
- Grep test folder untuk keyword `notification` sebelum commit untuk memastikan tidak ada test yang tertinggal.

---

## Halaman Terkait

- [[wiki/entities/budgeting|Budgeting]]
- [[wiki/entities/notifikasi|Notifikasi]]
- [[wiki/entities/settings|Settings]]
- [[wiki/concepts/arsitektur-app|Arsitektur App]]
- [[wiki/analysis/keputusan-hapus-notifikasi|Keputusan: Hapus Notifikasi]]
