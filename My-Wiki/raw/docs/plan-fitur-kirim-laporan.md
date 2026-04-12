# Plan: Fitur Kirim Laporan (User Report)

> Status: Draft for review
> Tanggal: 2026-04-12
> Scope: Flutter fitur baru `user_report` + Supabase tabel `user_reports`

---

## Problem

User tidak punya jalur langsung untuk melaporkan bug, meminta fitur, atau menghubungi tim
dari dalam aplikasi. Saat ini tidak ada halaman/form laporan sama sekali.

Yang diinginkan:

1. Button **Kirim Laporan** di Settings Page
2. Halaman form dengan: Kategori, Judul, Deskripsi, Lampiran Foto (opsional)
3. Laporan tersimpan di Supabase dan tercatat siapa yang kirim

---

## Current State

- Tidak ada fitur laporan/feedback sama sekali
- `attachments` Supabase Storage bucket sudah ada (dipakai OCR), bisa langsung dipakai
- `ImageUploadService`, `CompressImageFunc`, `ImageSourcePickerSheet` sudah tersedia
- `croppy ^1.4.1` sudah ada di pubspec
- Pattern croppy sudah ada di `lib/features/ocr/services/ocr_image_service.dart`

---

## Proposed Direction

### A. Supabase — Tabel `user_reports`

Buat tabel baru:

```sql
CREATE TABLE public.user_reports (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category      text NOT NULL,
  title         text NOT NULL,
  description   text NOT NULL,
  attachment_url text,
  status        text NOT NULL DEFAULT 'pending',
  created_at    timestamptz NOT NULL DEFAULT now()
);
```

**RLS Policy** (INSERT-only, user hanya bisa kirim, tidak bisa baca/ubah):

```sql
ALTER TABLE public.user_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert their own reports"
  ON public.user_reports FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);
```

**Category values** (disimpan sebagai string snake_case di DB):
- `bug_report`
- `feature_request`
- `account_issue`
- `payment_issue`
- `other`

---

### B. Flutter — Struktur Fitur

Mengikuti **3-file data pattern** standar SakuRapi:

```
lib/features/user_report/
├── datasource/
│   └── user_report_remote_data_source.dart
├── models/
│   └── user_report_model.dart            (+ enum UserReportCategory)
├── repositories/
│   └── user_report_repository.dart
├── controllers/
│   └── send_report_controller.dart
└── view/
    ├── ui/
    │   └── send_report_page.dart
    └── widgets/
        └── report_photo_field.dart
```

**Tidak perlu local datasource** — laporan adalah fire-and-forget write ke Supabase.

---

### C. Flutter — Model

`UserReportModel` — plain Dart class, lengkap `fromMap()`, `toMap()`, `copyWith()`.

```dart
enum UserReportCategory {
  bugReport,
  featureRequest,
  accountIssue,
  paymentIssue,
  other;

  String get value => switch (this) {
    bugReport       => 'bug_report',
    featureRequest  => 'feature_request',
    accountIssue    => 'account_issue',
    paymentIssue    => 'payment_issue',
    other           => 'other',
  };
}
```

Fields model: `id`, `userId`, `category`, `title`, `description`,
`attachmentUrl?`, `status`, `createdAt`.

---

### D. Flutter — Repository Flow (Submit)

```
submitReport(category, title, description, photoFile?)
  ├── if photoFile != null:
  │     1. CompressImageFunc.callBytes / .call(filePath)
  │     2. ImageUploadService.uploadImage  → attachmentUrl
  ├── Build UserReportModel
  └── UserReportRemoteDataSource.submitReport(model)
```

---

### E. Flutter — Controller State

```dart
class SendReportState {
  final UserReportCategory? category;
  final File? croppedFile;
  final bool isSubmitting;
}
```

Provider: `sendReportControllerProvider` pakai `.autoDispose` agar state dibersihkan
saat user menutup halaman.

---

### F. Flutter — UI (SendReportPage)

Form berisi:

| Field | Widget | Validasi |
|---|---|---|
| Kategori | `SakuDropdown<UserReportCategory>` | required |
| Judul | `SakuTextField` | required, min 5 char |
| Deskripsi | `SakuTextField` multiline (maxLines: 5) | required, min 10 char |
| Foto (opsional) | `ReportPhotoField` widget | — |
| Button Kirim | `SakuButton` | — |

Submit flow:
1. `Form.validate()`
2. `context.showLoadingOverlay()`
3. `repository.submitReport(...)` dalam try/catch
4. `context.closeOverlay()` di `finally`
5. Success → `context.showAppAlert(...)` → `context.pop()`
6. Error → `context.showAppAlert(error message)`

---

### G. Flutter — ReportPhotoField Widget

Dua state visual:

**Belum ada foto:**
```
┌─────────────────────────────────┐
│  [+]  Tambah Foto (Opsional)    │
│       Tap untuk pilih dari      │
│       kamera / galeri           │
└─────────────────────────────────┘
```

**Sudah ada foto:**
```
┌─────────────────────────────────┐
│  [thumbnail foto]  [✏️] [✕]     │
└─────────────────────────────────┘
```

Tap "Tambah Foto" / edit icon:
1. `ImageSourcePickerSheet.show(context)` → `File?`
2. Jika dapat file → `showAdaptiveImageCropper(context, imageProvider: FileImage(file))`
3. Export crop result ke Uint8List / temp file
4. `controller.setPhoto(croppedFile)`

---

### H. Router & Settings Integration

**AppRouter:**
```dart
static const String sendReport = '/settings/send-report';
```

**GoRoute** di bawah `/settings`.

**SettingsPage** — tambah tile di section **Lainnya** (sebelum App Version):
```dart
SettingsTile(
  icon: FontAwesomeIcons.flag,
  label: l10n.settingsSendReport,
  onTap: () => context.push(AppRouter.sendReport),
),
```

---

### I. Localization Keys (app_id.arb)

```json
"settingsSendReport": "Kirim Laporan",
"sendReportTitle": "Kirim Laporan",
"sendReportCategory": "Kategori",
"sendReportCategoryHint": "Pilih kategori laporan",
"sendReportFormTitle": "Judul",
"sendReportFormTitleHint": "Tuliskan judul laporan singkat",
"sendReportDescription": "Deskripsi",
"sendReportDescriptionHint": "Jelaskan masalah atau permintaanmu secara detail",
"sendReportPhoto": "Foto Lampiran",
"sendReportAddPhoto": "Tambah Foto (Opsional)",
"sendReportChangePhoto": "Ganti Foto",
"sendReportRemovePhoto": "Hapus Foto",
"sendReportSubmit": "Kirim Laporan",
"sendReportSuccessTitle": "Laporan Terkirim",
"sendReportSuccessMessage": "Terima kasih! Laporan kamu sudah kami terima.",
"sendReportValidateCategory": "Pilih kategori laporan",
"sendReportValidateTitle": "Judul minimal 5 karakter",
"sendReportValidateDescription": "Deskripsi minimal 10 karakter",
"sendReportCategoryBugReport": "Laporan Bug",
"sendReportCategoryFeatureRequest": "Permintaan Fitur",
"sendReportCategoryAccountIssue": "Masalah Akun",
"sendReportCategoryPaymentIssue": "Masalah Pembayaran",
"sendReportCategoryOther": "Lainnya"
```

---

## Implementation Sequence

1. `ur-supabase-table` — Buat tabel + RLS di Supabase
2. `ur-l10n` — Tambah keys + gen-l10n (paralel bisa)
3. `ur-model` — UserReportModel + UserReportCategory enum
4. `ur-datasource` — UserReportRemoteDataSource
5. `ur-repository` — UserReportRepository (compress → upload → insert)
6. `ur-controller` — SendReportController + provider
7. `ur-photo-widget` — ReportPhotoField widget (croppy flow)
8. `ur-view` — SendReportPage (form lengkap)
9. `ur-router` — Route `/settings/send-report`
10. `ur-settings` — Tile di SettingsPage

---

## Files Affected

**Supabase:**
- Migration baru `user_reports` table

**Flutter (baru):**
- `lib/features/user_report/models/user_report_model.dart`
- `lib/features/user_report/datasource/user_report_remote_data_source.dart`
- `lib/features/user_report/repositories/user_report_repository.dart`
- `lib/features/user_report/controllers/send_report_controller.dart`
- `lib/features/user_report/view/ui/send_report_page.dart`
- `lib/features/user_report/view/widgets/report_photo_field.dart`

**Flutter (diubah):**
- `lib/core/router/app_router.dart`
- `lib/features/settings/view/ui/settings_page.dart`
- `lib/l10n/app_id.arb`

---

## Key Constraints

| Constraint | Keputusan |
|---|---|
| Max foto per laporan | **1 foto** |
| Foto wajib/opsional | Opsional |
| Crop wajib/opsional | **Wajib** (setelah pick, user harus crop) |
| Bucket storage | `attachments` (sudah ada) |
| Subfolder | `{userId}/reports/` |
| Signed URL durasi | 1 tahun |
| Target compress | 200 KB |
| RLS read | User **tidak bisa** baca laporan miliknya sendiri (one-way) |
| Local datasource | Tidak perlu |
| Routing | `/settings/send-report` (child of settings) |
