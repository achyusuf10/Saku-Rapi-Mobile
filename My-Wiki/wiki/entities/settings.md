---
title: "Settings"
type: entity
tags: [settings, notification, preferences, theme, logout, hive]
sources: [raw/docs/prd/16_SETTINGS.md]
created: 2026-04-10
updated: 2026-04-13
---

# Settings

## Deskripsi

Halaman settings adalah pusat pengaturan aplikasi SakuRapi. Mencakup informasi profil, pengaturan akun, preferensi tampilan, manajemen data, dan notifikasi. Beberapa preferensi disimpan secara lokal menggunakan Hive.

---

## Fitur & Aturan Utama

### Layout Settings

| Section | Item | Keterangan |
|---------|------|------------|
| **Profile** | Info profil | Read-only, ditampilkan dari data Supabase Auth |
| **Akun** | Categories | Kelola kategori transaksi |
| | Debt/Loan | Kelola hutang & piutang |
| | ~~Notifications~~ | *(Dihapus April 2026 — lihat [[wiki/analysis/keputusan-hapus-notifikasi\|Keputusan: Hapus Notifikasi]])* |
| **Preferensi** | Theme | Light / Dark / System |
| | Language | Bahasa aplikasi |
| | Entry Point | Titik masuk default pencatatan transaksi |
| **Data** | Export / Import | *Coming soon* — belum diimplementasi |
| **Lainnya** | **Kirim Laporan** | Navigasi ke halaman laporan/feedback — lihat [[wiki/entities/user-report\|User Report]] |
| | App Version | Versi aplikasi saat ini |
| | Logout | Keluar dari akun |

### Notification Settings

> ⚠️ **Dihapus April 2026** — Menu Notifications dan halaman `/notification-settings` telah dihapus dari Settings. Lihat [[wiki/analysis/keputusan-hapus-notifikasi|Keputusan: Hapus Notifikasi]] untuk detail.

Sebelum dihapus, settings notifikasi mencakup:

| Notifikasi | Detail | Status (lama) |
|------------|--------|--------|
| **Daily Reminder** | Menggunakan `zonedSchedule` dengan timezone `Asia/Jakarta` | ✅ Implementasi |
| **Budget Alert** | Trigger pada **50%**, **80%**, dan **100%** penggunaan budget | ✅ Implementasi |
| **Debt Reminder** | Settings tersimpan di device | ⚠️ Logic belum implementasi |

### Notification Channels

> ⚠️ Channels berikut sudah tidak digunakan setelah penghapusan fitur notifikasi (April 2026):

~~Aplikasi menggunakan **2 notification channels**:~~

1. ~~**`saku_rapi_reminder`** — Untuk daily reminder~~
2. ~~**`saku_rapi_budget`** — Untuk budget alert~~

### Preferences (Hive-Persisted)

Tiga preferensi disimpan secara lokal di Hive:

| Key | Keterangan | Default |
|-----|------------|---------|
| `theme_mode` | Mode tema (light/dark/system) | System |
| `app_locale` | Bahasa aplikasi | id_ID |
| `transaction_entry_point` | Entry point pencatatan transaksi | — |

---

## Cara Kerja

### Logout Flow

```
signOut (Supabase Auth)
    → Clear semua cache lokal (Hive boxes, in-memory state)
    → Navigate ke halaman Login
```

Proses logout membersihkan:
- Session Supabase
- Cache Hive (preferences tetap, data transaksi dihapus)
- State Riverpod (invalidate semua provider)
- Navigasi ke halaman login dengan replace (tidak bisa back)

---

## Halaman Terkait

- [[wiki/entities/wallet|Wallet]]
- [[wiki/entities/history|History]]
- [[wiki/entities/investasi|Investasi]]
- [[wiki/concepts/aturan-keuangan|Aturan Keuangan]]
- [[wiki/sources/prd-sakurapi-v7|PRD SakuRapi v7.0]]
- [[wiki/concepts/design-system|Design System]]
- [[wiki/sources/redesign-ui-ux|Redesign UI/UX (Sumber)]]
