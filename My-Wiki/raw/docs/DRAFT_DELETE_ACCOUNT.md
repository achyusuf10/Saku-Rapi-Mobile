# Draft — Fitur Delete Account (soft delete + cooldown login 30 hari)

| Field | Nilai |
|-----|-----|
| **Status** | **Draft PRD/teknis** — belum ada implementasi kode aplikasi atau migrasi final |
| **Lingkungan** | **DEV (Supabase) dahulu** — verifikasi end-to-end di project dev via MCP (`mcp_supabase_*`), baru promosi ke prod (`mcp_supabase-prod_*`) |
| **Tanggal draf** | 2026-05-10 |
| **Titik masuk UI** | `lib/features/settings/view/ui/settings_page.dart` — tambah akses ke layar dedikasi ***Hapus akun*** |
| **Coding rules** | [`00_SakuRapi_Coding_Rules.md`](00_SakuRapi_Coding_Rules.md), [`../../wiki/concepts/coding-rules.md`](../../wiki/concepts/coding-rules.md) |
| **Skema acuan saat ini** | Tabel [`public.users`](../../wiki/entities/database-schema.md) — `id` (mirror `auth.users.id`), `email`, `full_name`, `avatar_url`, `tier`, `tier_expires_at`, timestamps |

---

## 1. Ringkasan produk

User dapat **meminta penghapusan akun** dari aplikasi. Sistem **tidak menghapus baris pengguna** di database; hanya menyimpan **penanda** bahwa akun telah “dihapus” beserta **tanggal/waktu** penandaan (UTC). Setelah itu, ada **jatuh tempo cooldown 30 hari** untuk **login dengan identitas yang sama** (dibawah dijelaskan lewat pemetaan email ↔ baris `public.users`).

---

## 2. Alur UI (Flutter) — sesuai permintaan

### 2.1 Settings

- Pada **Settings**, tambah satu baris/list tile misalnya *Hapus akun* atau *Keluar akun permanen (soft delete)* mengarah ke rute baru (GoRouter + path konsisten dengan `AppRouter`).
- Ikuti pola **section** yang sudah ada di `settings_page.dart` (mis. dikelompokkan di *Akun* atau *Lainnya*, keputusan final saat UI polish).

### 2.2 Layar dedikasi Delete Account

- Konten menjelaskan **apa yang akan terjadi**, misalnya (copy final lewat `.arb`, **tidak hardcode string**):
  - Akun akan ditandai terhapus; data aplikasi tidak di-*purge* dalam fase ini (kecuali kebijakan produk menambah anonimisasi — lihat §7).
  - Akses aplikasi dapat dibatasi selama masa cooldown setelah logout.
  - Setelah masa tunggu, user dapat masuk lagi; penanda hapus akan dihapus secara otomatis (lihat §4).
- Tombol primari merah/destruktif: ***Hapus akun*** (label final dari lokalisation).

### 2.3 Dialog konfirmasi

- Ketika tombol utama diketuk: tampilkan **dialog/modal konfirmasi** (prefer `context.showConfirmDialog()` / pola alert yang ada di codebase).
- Ada **field teks**; user harus mengetik persis **`SAYA MENGERTI`** (huruf besar, sensitif casing — atau keputusan produk: *trim* whitespace, tetap strict match substring penuh).
- Tombol untuk memanggil API / RPC untuk soft delete **nonaktif** sampai teks cocok dengan frasa yang ditetapkan.
- Pertimbangkan **double confirmation** sekunder *opsional* (checkbox “saya mengerti konsekuensinya”) hanya jika legal/UX mensyaratkan; MVP mengikuti spesifikasi user satu field sahaja.

### 2.4 Setelah berhasil soft delete

- **Sign out** session Supabase dari app.
- Arahkan ke layar login / splash dengan pesan bahwa akun telah dinonaktifkan (salin dari `.arb`).

**Patuh coding rules:** pecah widget dialog & field konfirmasi ke `lib/features/{fitur}/view/widgets/` atau `components/` jika tidak generik global; gunakan widget global (`SakuButton`, `SakuTextField`, dll.) bila tersedia; provider layar bisa `autoDispose` jika hanya dipakai di satu screen.

---

## 3. Data model (Supabase DEV) — soft delete marker

Catatan MCP: **jangan mengandalkan asumpsi skema** saat implementasi; sebelum DDL final, jalankan pembacaan tabel/tooling MCP terhadap project **DEV** yang terhubung (`list_tables`, migrasi repo `supabase/migrations/`).

### 3.1 Kolom baru di `public.users` (proposal)

| Kolom | Tipe | Default | Keterangan |
|-----|-----|---|-----|
| `account_deleted_at` | `timestamptz` null | `null` | Waktu UTC saat soft delete dicatat |
| `account_deleted` | `boolean not null` | `false` | Flag cepat untuk filter; bisa disinkron dari `account_deleted_at is not null` lewat constraint/trigger ***opsional*** |

Invariant yang disepakati (produk):

- **`account_deleted = false` dan `account_deleted_at is null`** → akun aktif normal.
- **Soft delete** → set `account_deleted = true`, `account_deleted_at = now()` (**tidak** menghapus baris atau `auth.users` pada fase ini — lihat §6).

Indexing (proposal): `(email)` atau partial index `(email) WHERE account_deleted` jika ada query admin; untuk login gate by `auth.uid()`, PK `id` cukup.

### 3.2 RLS & akses tulis

- User biasa tidak boleh langsung UPDATE kolom sensitif arbitrary.
- Rekomendasi: **RPC `security definer`** (atau Edge Function dengan service role) yang:
  - Memverifikasi `auth.uid()` = baris yang di-update.
  - Hanya mengisi penanda hapus sekali (opsional: `if account_deleted then raise` untuk idempotensi).

Dokumentasikan perilaku MCP: migrasi DDL diapply ke **DEV** dengan `apply_migration`; setelah itu `get_advisors` (security) untuk audit RLS.

---

## 4. Aturan login & cooldown 30 hari

### 4.1 Definisi waktu

- `T0 = account_deleted_at` (UTC).
- **Cooldown aktif** jika `now() < T0 + interval '30 days'`.
- **Cooldown selesai** jika `now() >= T0 + 30 days`.

### 4.2 Alur pemeriksaan (disarankan)

Supabase Auth `signInWithPassword` pada umumnya **tetap mengeluarkan JWT** jika kredensial valid. **Gerbang bisnis** sebaiknya dijalankan **segera setelah sesi ada**, sebelum navigasi ke home:

1. Panggil **satu RPC** terpusat mis. `resolve_account_login_state` (nama final bebas) yang:
   - Membaca `public.users` by `auth.uid()`.
   - Jika **`account_deleted` false** → kembalikan `allowed: true`.
   - Jika **`account_deleted` true**:
      - Hitung `days_remaining = ceil((T0 + 30d - now()) / 1 day)` atau gunakan **`remaining_seconds`** untuk presisi lebih baik pada pesan UX.
      - Jika masih cooldown → **`allowed: false`**, sisipkan `days_remaining` (atau pesan parametrik untuk `.arb`).
      - Jika sudah lewat → dalam **transaksi** tunggal: set `account_deleted = false`, `account_deleted_at = null`, kemudian kembalikan `allowed: true` (pemulihan akses seperti spesifikasi user).

2. Di client, jika `allowed: false` → **`signOut()`** serta tampilkan dialog/snackbar sesuai pesan cooldown.

### 4.3 “Cek berdasarkan email”

Spesifikasi user menyebut **email**. Di database, **sumber kebenaran utama** adalah `public.users.id` ↔ `auth.users.id`. **`email`** di `public.users` harus konsisten dengan `auth.users`; validasi bisa memakai `auth.jwt()` claim email vs kolom untuk deteksi drift (lanjutan). Untuk MVP, **cek by `auth.uid()`** mencukupi dan selaras dengan RLS.

### 4.4 Registrasi ulang dengan email sama

Jika ada alur OTP/register yang membuat `auth.users` baru dengan email sama (tergantung kebijakan Supabase UNIQUE email), dokumentasikan secara eksplisit: **prioritas linkage ke baris `public.users`**. MVP diasumsikan **satu akun Auth per pengguna aktif**; edge case dibahas di backlog.

---

## 5. API contract (draft — tanpa implementasi)

### 5.1 `soft_delete_own_account(...)`

Input: bisa kosong (memakai `auth.uid()`).  
Effect: set penanda hapus sesuai §3; optional: revoke refresh token memerlukan **Admin API / Edge Function** — lihat §6.

Response: `{ "ok": true }` atau error terstruktur.

### 5.2 `resolve_account_login_state()`

Digunakan pasca-login.  
Return (contoh bentuk konseptual):

```json
{
  "allowed": true,
  "reason": null,
  "days_remaining": null
}
```

atau saat blokir:

```json
{
  "allowed": false,
  "reason": "account_cooldown",
  "days_remaining": 12
}
```

(Serialisasi final mengikuti konvensi RPC Supabase Postgres / Flutter `DataState`.)

---

## 6. Auth & session lifecycle (kejadian terbuka)

- **Session saat ini** setelah soft delete: aplikasi harus **logout**.
- Untuk benar‑benar mencegah pemakaian token lama, pertimbangkan:
  - memanggil **Supabase Auth Admin `sign_out` user** dari Edge Function (service role); atau
  - mengandalkan TTL access token pendek + klien memaksa refresh gagal ketika RPC menolak.
- Dokumen ini mencatat gap: **implementasi MVP** bisa mulai dari **cek RPC pasca-login** (wajib) + revoke admin (nice-to-have untuk hardening).

---

## 7. Retensi data & privasi (perlu dikunci produk)

Draft ini tidak memutuskan apakah setelah soft delete:

- data finansial tetap utuh tapi tak bisa diakses UI; atau
- perlu anonimisasi `full_name`: …; dll.

Cantumkan sebagai **checkpoint legal/PDP** sebelum release.

---

## 8. Integrasi MCP Supabase — checklist DEV

1. `list_tables` + bandingkan dengan entri wiki **[Database Schema](../../wiki/entities/database-schema.md)**.
2. Rancangan migrasi: tambah kolom §3 (`apply_migration` ke **DEV**).
3. Buat/ed RPC §5; tes dengan `execute_sql` / klien uji minimal.
4. `get_advisors` type **security** setelah DDL.
5. Uji Flutter: sandbox **DEV URL + anon key**; baru mirror migrasi ke prod.

---

## 9. Pengujuan (ketika masuk tahap coding)

| Area | Yang diuji |
|-----|-----|
| UI | Tile settings → layar informasi → dialog → frasa **`SAYA MENGERTI`** meng-enable CTA |
| i18n | Semua copy via `.arb` |
| RPC | Soft delete satu kali; idempotensi/error |
| Login | `< 30 hari` ditolak + `days_remaining`; `≥ 30 hari` otomatis reset flag & login |
| RLS | User lain tidak bisa mengubah kolom hapus orang lain |

Gunakan **`fvm flutter test`** untuk unit/controller sesuai DoD existing.

---

## 10. Referensi file (implementasi mendatang — bukan tugas draf ini)

- Router: `lib/core/router/app_router.dart`
- Pola data: `RemoteDataSource` + `SupabaseHandler.call`, `Repository`, `AsyncValue.when`
- Dokumentasi wiki entitas bisa di-update nanti: `wiki/entities/settings.md`, `wiki/entities/database-schema.md`, plus sumber ringkas di `wiki/sources/` bila pola proyek memakai “plan mirror” seperti export PDF.

---

*Draf ini dipersiapkan untuk disetujui produk & legal sebelum slicing task development.*
