---
title: "User Report (Kirim Laporan)"
type: entity
tags: [user-report, feedback, settings, supabase, storage]
sources: [raw/docs/plan-fitur-kirim-laporan.md]
created: 2026-04-13
updated: 2026-04-13
---

# User Report (Kirim Laporan)

## Deskripsi

Fitur yang memungkinkan pengguna mengirimkan laporan / feedback langsung dari dalam aplikasi. Laporan disimpan ke tabel `user_reports` di Supabase. Tidak ada UI bagi user untuk membaca laporan yang sudah dikirim — fitur ini adalah **one-way / fire-and-forget write**.

---

## Fitur & Aturan Utama

### Kategori Laporan

| Label UI | Nilai di DB |
|---|---|
| Laporan Bug | `bug_report` |
| Permintaan Fitur | `feature_request` |
| Masalah Akun | `account_issue` |
| Masalah Pembayaran | `payment_issue` |
| Lainnya | `other` |

### Form Fields

| Field | Widget | Validasi |
|---|---|---|
| Kategori | `SakuDropdown<UserReportCategory>` | required |
| Judul | `SakuTextField` | required, min 5 karakter |
| Deskripsi | `SakuTextField` multiline | required, min 10 karakter |
| Foto Lampiran | `ReportPhotoField` | opsional, 1 foto maks |

### Foto Flow

1. User tap → `ImageSourcePickerSheet.show()` → pilih kamera / galeri → `File`
2. Wajib crop: `showAdaptiveImageCropper(context, imageProvider: FileImage(file))`
3. Disimpan di **local state** controller (`SendReportState.croppedFile`)
4. Saat submit: `CompressImageFunc` (target 200 KB) → `ImageUploadService.uploadImage()` → dapat URL
5. URL disimpan di `user_reports.attachment_url`

### Submit Flow

```
Form.validate()
  → context.showLoadingOverlay()
  → if photo: compress → upload → dapat attachmentUrl
  → UserReportRepository.submitReport(...)
  → context.closeOverlay()  // di finally
  → success: showAppAlert + pop
  → error: showAppAlert dengan pesan error
```

### RLS Policy

- User hanya bisa **INSERT** laporan miliknya sendiri (`user_id = auth.uid()`)
- User **tidak bisa baca** laporan yang sudah dikirim (INSERT-only policy)
- Tidak ada SELECT / UPDATE / DELETE policy untuk user

---

## Struktur Kode

```
lib/features/user_report/
├── datasource/
│   └── user_report_remote_data_source.dart
├── models/
│   └── user_report_model.dart        (+ enum UserReportCategory)
├── repositories/
│   └── user_report_repository.dart
├── controllers/
│   └── send_report_controller.dart   (autoDispose)
└── view/
    ├── ui/
    │   └── send_report_page.dart
    └── widgets/
        └── report_photo_field.dart
```

**Tidak ada local datasource** — tidak ada caching, murni fire-and-forget write.

### Model

```dart
class UserReportModel {
  final String id;
  final String userId;
  final UserReportCategory category;
  final String title;
  final String description;
  final String? attachmentUrl;
  final String status;          // default: 'pending'
  final DateTime createdAt;
}
```

### Controller State

```dart
class SendReportState {
  final UserReportCategory? category;
  final File? croppedFile;
  final bool isSubmitting;
}
```

Provider menggunakan `.autoDispose` agar state dibersihkan saat user menutup halaman.

---

## Integrasi Storage

- **Bucket**: `attachments` (sudah ada, digunakan juga oleh OCR)
- **Subfolder**: `{userId}/reports/`
- **Signed URL durasi**: 1 tahun
- Service: `ImageUploadService` (sudah ada di `lib/global/services/image_upload_service.dart`)

---

## Integrasi Settings

- Tile di section **Lainnya** Settings Page (sebelum App Version)
- Icon: `FontAwesomeIcons.flag`
- Route: `/settings/send-report`

---

## Database

Lihat tabel `user_reports` di [[wiki/entities/database-schema|Database Schema]].

---

## Halaman Terkait

- [[wiki/entities/settings|Settings]] — titik masuk button
- [[wiki/entities/database-schema|Database Schema]] — tabel `user_reports`
- [[wiki/concepts/coding-rules|Coding Rules]] — konvensi kode
