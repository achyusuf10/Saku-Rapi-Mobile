---
title: "Plan: Fitur Kirim Laporan"
type: source
tags: [user-report, settings, supabase, storage, photo, croppy]
source_file: raw/docs/plan-fitur-kirim-laporan.md
created: 2026-04-13
updated: 2026-04-13
---

# Plan: Fitur Kirim Laporan — Ringkasan

> Sumber: `raw/docs/plan-fitur-kirim-laporan.md`
> Status: **Selesai diimplementasi** (April 2026)

---

## Apa yang Dibangun

Fitur baru `user_report` — memungkinkan pengguna mengirim laporan/feedback dari dalam app. Terdiri dari:

1. **Tabel Supabase** `user_reports` dengan RLS INSERT-only
2. **Flutter feature** `lib/features/user_report/` (model, datasource, repository, controller, view)
3. **Settings integration** — tile baru di section Lainnya
4. **Photo flow** — pick → crop (croppy) → store in local state → compress → upload saat submit

---

## Keputusan Desain

| Keputusan | Pilihan |
|---|---|
| Max foto | **1 foto** per laporan |
| Foto wajib? | **Opsional** |
| Crop wajib? | **Ya** — user harus crop setelah pick |
| Storage bucket | `attachments` (sudah ada) |
| Subfolder | `{userId}/reports/` |
| RLS read | **Tidak ada** — user tidak bisa baca laporan sendiri |
| Local datasource | **Tidak ada** |
| Route | `/settings/send-report` |

---

## Files Dibuat/Diubah

**Baru (Flutter):**
- `lib/features/user_report/models/user_report_model.dart`
- `lib/features/user_report/datasource/user_report_remote_data_source.dart`
- `lib/features/user_report/repositories/user_report_repository.dart`
- `lib/features/user_report/controllers/send_report_controller.dart`
- `lib/features/user_report/view/ui/send_report_page.dart`
- `lib/features/user_report/view/widgets/report_photo_field.dart`

**Diubah (Flutter):**
- `lib/core/router/app_router.dart` — route `/settings/send-report`
- `lib/features/settings/view/ui/settings_page.dart` — tile baru
- `lib/l10n/app_id.arb` + `lib/l10n/app_en.arb` — 15 keys baru

**Supabase:**
- Migration `user_reports` table + RLS

---

## Lihat Juga

- [[wiki/entities/user-report|User Report]] — halaman entitas lengkap
- [[wiki/entities/settings|Settings]] — integrasi tile
- [[wiki/entities/database-schema|Database Schema]] — tabel `user_reports`
