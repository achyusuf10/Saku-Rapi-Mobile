---
title: "Keputusan: Hapus Fitur Notifikasi"
type: analysis
tags: [decision, notification, budgeting, technical-debt]
sources: [raw/docs/plan-remove-notification.md]
created: 2026-04-12
updated: 2026-04-12
---

# Keputusan: Hapus Fitur Notifikasi

## Konteks

Fitur notifikasi SakuRapi (budget alert + daily reminder + debt reminder) diputuskan untuk dihapus sementara dari codebase pada April 2026. Keputusan ini bersifat **app layer only** — skema database tidak diubah agar re-implementasi di masa depan lebih mudah.

---

## Masalah yang Ditemukan

1. **Inkonsistensi perilaku**: Budget alert hanya di-trigger saat halaman Budget dibuka (via `ref.listen` + `BudgetAlertChecker`), bukan saat transaksi masuk. Ini bertentangan dengan ekspektasi user dan dokumentasi internal (`budgeting.md` vs `notifikasi.md` saling kontradiksi tentang kapan alert di-trigger).

2. **Fitur setengah jadi**: Debt reminder settings ada di UI dan DB (toggle + `debt_reminder_days_before`), tapi logika pengiriman belum diimplementasi sama sekali. Fitur ini dirilis dalam kondisi tidak selesai.

3. **Overhead besar**: 4 dependencies besar (`flutter_local_notifications`, `workmanager`, `timezone`, `permission_handler`*) + 7 file feature + integrasi di `main.dart`, router, settings — untuk sesuatu yang belum matang dan membingungkan.

> *`permission_handler` tidak dihapus karena dipakai OCR, Voice, dan Contacts.

---

## Keputusan

Hapus seluruh fitur notifikasi dari Flutter (app layer) untuk mengurangi kompleksitas teknis. **DB tidak diubah** — tabel `notification_settings` dan kolom `notification_sent_*` di `budgets` tetap ada untuk memudahkan re-implementasi di masa depan.

---

## Yang Dihapus

- `lib/features/notification/` — seluruh folder (7 file: controllers, datasource, models, repositories, services, view/ui)
- 3 field di `BudgetModel`: `notificationSent50`, `notificationSent80`, `notificationSent100`
- `_checkBudgetAlerts()` di `budget_page.dart` + referensi ke `budgetAlertCheckerProvider`
- WorkManager + NotificationService + inisialisasi timezone di `main.dart`
- Route `/notification-settings` dan import `NotificationSettingsPage` di router
- Menu "Notifikasi" di settings page
- `test/features/notification/notification_test.dart`
- Dependencies di `pubspec.yaml`: `flutter_local_notifications`, `workmanager`, `timezone`
- Android permissions di `AndroidManifest.xml`: `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`, `POST_NOTIFICATIONS`

---

## Yang Tetap

| Yang Tetap | Alasan |
|-----------|--------|
| Tabel `notification_settings` di DB | Tidak sentuh DB — bisa dipakai lagi nanti |
| Field `notification_sent_50/80/100` di tabel `budgets` | Tetap ada di DB; cukup hapus dari model Flutter |
| `permission_handler` dependency | Dipakai OCR (`Permission.camera`), Voice (`Permission.microphone`), Contacts (`Permission.contacts`) |
| `BudgetModel.isHalfUsed`, `isNearLimit`, `isOverBudget` | Masih dipakai untuk warna progress bar di UI |
| `budget_progress_bar.dart` | Warna threshold (hijau/kuning/oranye/merah) tetap ada — UI only |
| Trigger `auto_renew_budgets` (pg_cron) | Tetap jalan, reset flag di DB — aman karena Flutter tidak baca flag lagi |

---

## Rencana Ke Depan

Jika notifikasi diimplementasi ulang di masa depan, desain yang benar:

- **Budget alert**: Trigger saat transaksi masuk — di repository layer (setelah `createTransaction` sukses), bukan saat page load
- **Debt reminder**: Implementasi logika pengiriman sebelum fitur di-release ke user
- **Pertimbangkan arsitektur**: Push notification via FCM (server-side trigger) vs local notification (client-side) — FCM lebih tepat untuk event berbasis data seperti budget alert

---

## Halaman Terkait

- [[wiki/entities/budgeting|Budgeting]]
- [[wiki/entities/notifikasi|Notifikasi]]
- [[wiki/entities/settings|Settings]]
- [[wiki/concepts/aturan-keuangan|Aturan Keuangan]]
- [[wiki/sources/plan-remove-notification|Plan: Hapus Fitur Notifikasi]]
