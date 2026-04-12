---
title: "Notifikasi"
type: entity
tags: [notification, local-notification, budget-alert, reminder, settings, hive]
sources: [raw/docs/prd/16_SETTINGS.md, raw/docs/prd/14_BUDGETING.md, raw/docs/02_DATABASE.md]
created: 2026-04-10
updated: 2026-04-10
---

## Deskripsi

Sistem notifikasi lokal SakuRapi. Menggunakan `flutter_local_notifications` dengan `timezone` package untuk penjadwalan. Semua notifikasi adalah **lokal** (bukan push/FCM). Settings disimpan di server (`notification_settings` table) dan dibackup di Hive.

## Jenis Notifikasi

| Jenis | Channel | Kapan | Default |
|-------|---------|-------|---------|
| **Pengingat Harian** | `saku_rapi_reminder` (HIGH) | Setiap hari jam yang ditentukan | OFF, 20:00 |
| **Alert Anggaran 100%** | `saku_rapi_budget` (HIGH) | Budget melampaui batas | ON |
| **Alert Anggaran 80%** | `saku_rapi_budget` (HIGH) | Budget mencapai 80% | ON |
| **Alert Anggaran 50%** | `saku_rapi_budget` (HIGH) | Budget mencapai 50% | OFF |
| **Pengingat Piutang** | — | N hari sebelum jatuh tempo | ON, 3 hari |

## Notification Channels

| Channel ID | Nama | Importance |
|-----------|------|-----------|
| `saku_rapi_reminder` | Pengingat Harian | HIGH |
| `saku_rapi_budget` | Alert Anggaran | HIGH |

## Database: `notification_settings`

| Kolom | Tipe | Default | Keterangan |
|-------|------|---------|-----------|
| `id` | uuid PK | gen_random_uuid() | |
| `user_id` | uuid FK | — | 1 row per user |
| `reminder_enabled` | boolean | false | Daily reminder toggle |
| `reminder_time` | time | null | Jam pengingat |
| `budget_alert_enabled` | boolean | true | Master toggle budget alert |
| `budget_alert_50_enabled` | boolean | false | Alert di 50% |
| `debt_reminder_enabled` | boolean | true | Pengingat piutang |
| `debt_reminder_days_before` | integer | 3 | Berapa hari sebelum jatuh tempo |

Trigger `seed_notification_settings()` otomatis membuat row default saat user baru dibuat.

## Alur Budget Alert

1. Setiap kali ada transaksi masuk, Flutter menghitung persentase budget terpakai
2. Cek prioritas: 100% → 80% → 50% (hanya satu alert per threshold)
3. Cek flag `notification_sent_100/80/50` — jika sudah dikirim, skip
4. Kirim notifikasi lokal via `flutter_local_notifications`
5. Update flag di server agar tidak dikirim lagi di periode yang sama
6. Saat budget auto-renew (pg_cron), flag di-reset

**Prioritas:** Hanya alert tertinggi yang belum terkirim yang dikirim. (100% > 80% > 50%)

## Alur Daily Reminder

```
User set reminder ON + pilih jam
  → Save ke server (notification_settings)
  → Schedule via zonedSchedule (Asia/Jakarta timezone)
  → DateTimeComponents.time → repeat harian

Device restart:
  → WorkManager re-sync jadwal dari cache Hive
```

## Permissions

| Status | Tampilan |
|--------|----------|
| Belum diminta | Banner: "Izinkan notifikasi" |
| Granted | Semua settings tampil |
| Denied permanently | Banner: "Buka App Settings" |

## Aturan Penting

- Semua notifikasi **lokal** — bukan push/FCM
- Timezone wajib `Asia/Jakarta`
- Settings di-save ke server, bukan hanya Hive
- Debt reminder logic **belum diimplementasi** (settings tersimpan, pengiriman belum ada)
- Budget alert cek dilakukan di Flutter side (bukan trigger DB)

## Halaman Terkait

- `[[wiki/entities/settings|Settings]]`
- `[[wiki/entities/budgeting|Budgeting]]`
- `[[wiki/entities/hutang-piutang|Hutang/Piutang]]`
- `[[wiki/entities/database-schema|Database Schema]]`
- `[[wiki/concepts/aturan-keuangan|Aturan Keuangan Fundamental]]`
