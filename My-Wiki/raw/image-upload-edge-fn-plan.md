# Plan: Edge Function `image-upload` — Supabase + GCS Fallback

**Status**: Draft  
**Tanggal**: 2026-04-14  
**Author**: Copilot  
**Scope**: Baru — menggantikan direct Supabase Storage upload di `ImageUploadService`

---

## 1. Latar Belakang & Tujuan

`ImageUploadService` sekarang upload langsung dari Flutter ke Supabase Storage (`attachments` bucket) dan mengembalikan signed URL 1 tahun. Masalahnya:
- Tidak ada pengecekan apakah storage hampir penuh
- Tidak ada fallback ketika storage penuh

**Goal**: Buat edge function `image-upload` yang:
1. Cek kapasitas Supabase Storage (`attachments` bucket)
2. Jika storage usage ≥ batas yang dikonfigurasi → upload ke Google Cloud Storage (GCS)
3. Jika storage masih aman → upload ke Supabase Storage
4. Kembalikan URL string ke Flutter (transparent, tidak peduli dari mana)

---

## 2. Arsitektur

```
Flutter App
  └─ ImageUploadService.uploadImage(bytes, fileName)
       └─ supabase.functions.invoke('image-upload', body: { imageBase64, fileName, mimeType })
             │
             ├─ [1] Cek storage.objects → hitung total used bytes
             │       ↓ used >= STORAGE_LIMIT_MB × 1024²?
             │
             ├─ [NO] Upload ke Supabase Storage (service role)
             │        └─ createSignedUrl(1 tahun) → return { url, storage: "supabase" }
             │
             └─ [YES] Upload ke Google Cloud Storage (GCS) (GCS JSON API + OAuth2)
                       └─ patch metadata dengan downloadToken → return { url, storage: "gcs" }
```

---

## 3. Edge Function `image-upload`

### 3.1 Konfigurasi Dasar

| Property | Value |
|----------|-------|
| Slug | `image-upload` |
| `verify_jwt` | `true` (user harus terautentikasi) |
| Runtime | Deno + TypeScript |

### 3.2 Env Vars yang Dibutuhkan

| Env Var | Keterangan | Contoh |
|---------|-----------|--------|
| `STORAGE_LIMIT_MB` | Batas maksimum usage bucket sebelum fallback ke GCS | `950` (untuk free tier 1GB) |
| `GCS_SERVICE_ACCOUNT_JSON` | JSON service account GCS (dari GCS Console → Project Settings → Service Accounts) | `{"type":"service_account","project_id":"my-app",...}` |
| `SUPABASE_URL` | Auto-set oleh Supabase | — |
| `SUPABASE_SERVICE_ROLE_KEY` | Auto-set oleh Supabase | — |

> **GCS bucket derivation**: Fungsi akan pakai `{project_id}.appspot.com` sebagai default bucket. Jika project pakai bucket baru (`gcsstorage.app`), user bisa tambahkan field `"storage_bucket": "my-app.gcsstorage.app"` di dalam JSON-nya. Function akan cek field itu dulu.

### 3.3 Request Format

```json
{
  "imageBase64": "<base64-encoded image bytes>",
  "fileName": "photo.jpg",
  "mimeType": "image/jpeg"
}
```

| Field | Wajib | Default |
|-------|-------|---------|
| `imageBase64` | ✅ | — |
| `fileName` | ✅ | — |
| `mimeType` | ❌ | `"image/jpeg"` |

**Batasan input**:
- `imageBase64` decoded harus ≤ **10 MB**
- `fileName` harus non-empty, ≤ 255 karakter

### 3.4 Response Format (Success)

```json
{
  "url": "https://...",
  "storage": "supabase"
}
```

atau jika fallback:

```json
{
  "url": "https://storage.googleapis.com/{bucket}/{path}",
  "storage": "gcs"
}
```

> Flutter tidak perlu tahu dari mana URL berasal — keduanya tetap `String` yang bisa langsung dipakai sebagai gambar.

### 3.5 Error Responses

| HTTP | Code (internal log) | User-facing message |
|------|-------------------|---------------------|
| 400 | `INVALID_REQUEST` | "Permintaan tidak valid." |
| 400 | `IMAGE_TOO_LARGE` | "Ukuran gambar terlalu besar. Maksimum 10 MB." |
| 401 | `UNAUTHENTICATED` | "Sesi tidak valid. Silakan login ulang." |
| 500 | `STORAGE_QUERY_FAILED` | "Gagal mengupload gambar. Coba lagi." |
| 500 | `SUPABASE_UPLOAD_FAILED` | "Gagal mengupload gambar. Coba lagi." |
| 500 | `GCS_AUTH_FAILED` | "Gagal mengupload gambar. Coba lagi." |
| 500 | `GCS_UPLOAD_FAILED` | "Gagal mengupload gambar. Coba lagi." |

**Prinsip**: `console.error('[image-upload] CODE: detail')` untuk developer tracking, response body hanya mengembalikan `userMessage` tanpa detail teknis.

### 3.6 Logika Pengecekan Storage

```sql
SELECT COALESCE(SUM((metadata->>'size')::bigint), 0) AS total_bytes
FROM storage.objects
WHERE bucket_id = 'attachments'
```

- Jika query gagal → log error, **tetap lanjutkan dengan Supabase upload** (fail-open untuk query)
- Jika `total_bytes >= STORAGE_LIMIT_MB * 1024 * 1024` → fallback ke GCS

### 3.7 Supabase Upload Flow

1. Decode `imageBase64` → `Uint8Array`
2. Generate path: `{userId}/{timestamp}_{fileName}`
3. Upload via Supabase service role client: `storage.from('attachments').upload(path, bytes)`
4. Buat signed URL (3 tahun = 31.536.000*3 detik)
5. Return `{ url: signedUrl, storage: "supabase" }`

### 3.8 GCS Upload Flow

Google Cloud Storage menggunakan **Google Cloud Storage JSON API** dengan OAuth2 dari service account.

#### Step 1 — Buat JWT untuk service account
(Pola sama dengan yang dipakai di `gold-price` untuk Vertex AI, scope beda)

```typescript
const GCS_SCOPE = 'https://www.googleapis.com/auth/devstorage.read_write';
```

#### Step 2 — Tukar JWT → access token
```
POST https://oauth2.googleapis.com/token
grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer
assertion={jwt}
```

#### Step 3 — Upload file ke GCS
```
POST https://storage.googleapis.com/upload/storage/v1/b/{bucket}/o
  ?uploadType=media
  &name={encodedPath}
Authorization: Bearer {access_token}
Content-Type: {mimeType}
Body: binary data
```

#### Step 4 — Set object ACL public

Agar URL bisa diakses tanpa auth, object perlu di-set public:

```
POST https://storage.googleapis.com/storage/v1/b/{bucket}/o/{encodedName}/acl
Authorization: Bearer {access_token}
Content-Type: application/json
Body: { "entity": "allUsers", "role": "READER" }
```

Jika bucket sudah Uniform Access dengan allUsers READER by default, step ini bisa di-skip. Function akan coba, jika gagal 403 → lanjut saja.

#### Step 5 — Susun public URL

```
https://storage.googleapis.com/{bucket}/{path}
```

URL ini permanent selama object tidak dihapus.

### 3.9 Timeout Handling

| Operasi | Timeout |
|---------|---------|
| Storage RPC | 5s |
| Supabase Storage upload | 30s |
| GCS OAuth2 token | 10s |
| GCS upload | 30s |
| GCS ACL patch | 10s |

Semua `fetch` menggunakan `AbortSignal.timeout(ms)`. Jika timeout → throw error dengan code spesifik → response 500 dengan pesan generik ke user.

### 3.10 Struktur File

```
supabase/functions/image-upload/
└── index.ts
```

---

## 4. Perubahan Flutter: `ImageUploadService`

File: `lib/global/services/image_upload_service.dart`

**Sebelum**: Upload langsung ke Supabase Storage via `_client.storage`

**Sesudah**: Panggil edge function `image-upload`

```dart
Future<DataState<String>> uploadImage({
  required Uint8List imageBytes,
  required String fileName,
}) {
  return SupabaseHandler.call<String>(
    function: () async {
      final base64 = base64Encode(imageBytes);
      
      AppLogger.call('$_tag Uploading image via edge function: $fileName');
      
      final response = await _client.functions.invoke(
        'image-upload',
        body: {
          'imageBase64': base64,
          'fileName': fileName,
          'mimeType': 'image/jpeg',
        },
      );
      
      final url = response.data['url'] as String;
      final storage = response.data['storage'] as String;
      
      AppLogger.call('$_tag Upload success via $storage');
      return url;
    },
  );
}
```

Import yang ditambahkan: `dart:convert` (untuk `base64Encode`)
Import yang dihapus: tidak ada (masih pakai `SupabaseClient` untuk `functions.invoke`)

---

## 5. Urutan Implementasi

1. **Buat edge function** `image-upload/index.ts`
2. **Deploy** ke Supabase (dev project dulu, lalu prod)
3. **Set env vars** di Supabase Dashboard: `STORAGE_LIMIT_MB`, `GCS_SERVICE_ACCOUNT_JSON`
4. **Update** `ImageUploadService` di Flutter
5. **Test** upload flow (Supabase path + GCS fallback path)
6. **Analyze** `fvm flutter analyze`

---

## 6. Hal yang Perlu Diperhatikan

### GCS Service Account Setup
User perlu:
1. Buka [Google Cloud Console](https://console.cloud.google.com) → IAM & Admin → Service Accounts
2. Buat service account baru, beri role `Storage Object Admin` pada bucket target
3. Download JSON key
4. Tambahkan field `"storage_bucket": "nama-bucket-kamu"` langsung ke dalam JSON
5. Copy-paste seluruh JSON sebagai value env var `GCS_SERVICE_ACCOUNT_JSON` di Supabase Dashboard

### GCS Bucket Setup
1. Buat bucket di Google Cloud Console → Cloud Storage
2. Set Access control: **Uniform**
3. Add principal `allUsers` dengan role `Storage Object Viewer` (agar URL public bisa diakses)

### Supabase Storage Bucket Name
Hardcoded ke `attachments` (sama dengan service yang digantikan).

### Token Cache
GCS OAuth2 access token di-cache in-memory (seperti pola di `gold-price`), valid 1 jam.

### URL Type
Supabase: Signed URL 1 tahun.  
GCS: Public permanent URL (tidak expired selama bucket/object tidak dihapus).

### Test Fallback
Set `STORAGE_LIMIT_MB=0` → semua upload akan ke GCS.

---

## 7. Out of Scope

- Validasi format gambar (PNG, WebP, dll) — hanya `image/jpeg` untuk sekarang
- Kompresi gambar di edge function — biarkan Flutter yang kompres sebelum upload
- Delete file dari GCS ketika transaksi dihapus — belum ada mekanisme cleanup
- Migration signed URL yang sudah ada ke GCS URL — tidak perlu
