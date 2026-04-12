---
title: "Analisis & Plan: Penghapusan Fitur Notifikasi"
type: analysis
tags: [notification, budget-alert, refactoring, technical-debt]
sources: [raw/docs/plan-remove-notification.md]
created: 2026-04-12
updated: 2026-04-12
---

# Analisis & Plan: Penghapusan Fitur Notifikasi

## Latar Belakang

Keputusan untuk menghapus fitur notifikasi lokal (daily reminder, budget alert, debt reminder) diambil setelah ditemukan beberapa masalah:

### Inkonsistensi Budget Alert
Budget Alert di-trigger saat **halaman Budget dibuka** (bukan saat transaksi masuk seperti yang tertulis di dokumen). Alurnya:
```
Halaman Budget dibuka
  → ref.listenManual(budgetControllerProvider)
  → state == loaded → _checkBudgetAlerts()
  → BudgetAlertChecker.checkBudgets()
  → NotificationRepository.checkAndSendBudgetAlerts()
  → flutter_local_notifications.show() + markBudgetNotificationSent() ke DB
```
Ini berbeda dari ekspektasi user (real-time saat transaksi) dan menyebabkan kebingungan.

### Fitur Setengah Jadi
Debt reminder: toggle dan settings-nya ada di UI dan DB, tapi **logika pengirimannya tidak pernah diimplementasi**.

### Kompleksitas Tidak Sebanding
4 dependencies besar untuk fitur yang belum matang:
- `flutter_local_notifications: ^18.0.0`
- `workmanager: ^0.9.0+3`
- `timezone: ^0.9.4`
- (+ `permission_handler` — tetap karena dipakai OCR/Voice/Contacts)

---

## Scope Perubahan

### Dihapus dari Flutter

| Area | Detail |
|------|--------|
| `lib/features/notification/` | Seluruh folder (7 file: controllers, datasource, models, repositories, services, view) |
| `BudgetModel` | Field `notificationSent50/80/100` dari constructor, fields, fromMap, toFullMap, copyWith |
| `budget_page.dart` | Method `_checkBudgetAlerts()` + `ref.listenManual` untuk alert |
| `settings_page.dart` | Menu item "Notifications" |
| `app_router.dart` | Route `/notification-settings` + import |
| `main.dart` | `_workmanagerCallbackDispatcher()`, `NotificationService.init()`, `tz.initializeTimeZones()` |
| `pubspec.yaml` | `flutter_local_notifications`, `workmanager`, `timezone` |
| `AndroidManifest.xml` | `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`, `POST_NOTIFICATIONS` |

### Tetap Ada

| Area | Alasan |
|------|--------|
| Tabel `notification_settings` di DB | Tidak menyentuh DB — bisa dipakai lagi nanti |
| Field `notification_sent_50/80/100` di tabel `budgets` (DB) | Tetap di DB, cukup hapus dari model Flutter |
| `BudgetModel.isHalfUsed`, `isNearLimit`, `isOverBudget` | Masih dipakai untuk warna progress bar UI |
| `permission_handler` | Dipakai di OCR (camera), Voice (microphone), Contacts |
| `iOS Info.plist` | Tidak ada notification permission entry — tidak perlu diubah |

---

## Catatan Implementasi

- `permission_handler` **tidak dihapus** dari pubspec karena masih dipakai di 3 tempat: `ocr_image_service.dart` (camera), `voice_input_service.dart` (microphone), `contact_controller.dart` (contacts)
- iOS tidak memerlukan perubahan native (tidak ada entri di Info.plist untuk notification)
- Android memerlukan hapus 3 `<uses-permission>` di `AndroidManifest.xml`
- DB `notification_settings` table dan kolom `notification_sent_*` di `budgets` tetap ada — akan berguna jika fitur didesain ulang

---

## Supabase Changes (Migration 015)

File: `supabase/migrations/20260412100000_015_remove_notification.sql`

### Dihapus dari Database

| Object | Type | Detail |
|--------|------|--------|
| `trg_seed_notification_settings` | TRIGGER | Trigger on `users` yang auto-seed notification settings saat user baru |
| `seed_notification_settings()` | FUNCTION | Function yang di-trigger di atas |
| `notification_settings` | TABLE | Tabel preferensi notifikasi per-user — CASCADE hapus trigger `trg_notification_settings_updated_at` dan semua RLS policies |
| `budgets.notification_sent_50` | COLUMN | Flag 50% budget terpakai |
| `budgets.notification_sent_80` | COLUMN | Flag 80% budget terpakai |
| `budgets.notification_sent_100` | COLUMN | Flag 100% budget terpakai |

### Catatan
- `DROP TABLE notification_settings CASCADE` otomatis menghapus: trigger `trg_notification_settings_updated_at`, policy `notification_settings_select_own`, policy `notification_settings_update_own`
- Migration dapat dijalankan via `supabase db push` atau langsung di Supabase dashboard SQL editor

---

## Halaman Terkait
- [[wiki/entities/budgeting|Budgeting]]
- [[wiki/entities/notifikasi|Notifikasi]]
- [[wiki/entities/settings|Settings]]
- [[wiki/concepts/arsitektur-app|Arsitektur App]]
- [[wiki/entities/database-schema|Database Schema]]
