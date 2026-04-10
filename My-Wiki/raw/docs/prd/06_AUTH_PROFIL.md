# 6. Auth & Profil

[← User Flows](05_USER_FLOWS.md) · [Index](00_INDEX.md) · [Dashboard →](07_DASHBOARD.md)

---

## 6.1. Deskripsi
Login hanya via Google Sign-In melalui Supabase Auth. Setelah login, sistem otomatis setup data awal user.

## 6.2. Alur Login
1. User tap "Masuk dengan Google"
2. Supabase handle OAuth flow
3. DB trigger `handle_new_user` → buat/update `public.users`
4. DB trigger `seed_default_categories` → buat kategori default
5. Buat `notification_settings` default
6. Navigasi ke Dashboard

### Flowchart: Alur Login & Bootstrap

```mermaid
flowchart TD
    A([App Launch]) --> B{Session\nvalid?}
    B -->|✅ Ya| C["Load profile\n+ bootstrap"]
    C --> D[🏠 Dashboard]

    B -->|❌ Tidak| E[🔐 Login Screen]
    E --> F["Tap 'Masuk\ndengan Google'"]
    F --> G["Supabase\nGoogle OAuth"]
    G --> H{Berhasil?}

    H -->|✅| I["trigger:\nhandle_new_user"]
    I --> J["trigger:\nseed_default_categories"]
    J --> K["Buat\nnotification_settings"]
    K --> D

    H -->|❌| L["Show error\nmessage"]
    L --> E

    style D fill:#2d6a4f,color:#fff
    style L fill:#d32f2f,color:#fff
```

### Flowchart: Alur Logout

```mermaid
flowchart TD
    A([User tap Logout]) --> B["Supabase\nsignOut()"]
    B --> C["Clear session\nlokal"]
    C --> D["Clear cache\nHive"]
    D --> E["Navigate to\n🔐 Login Screen"]

    style E fill:#1565c0,color:#fff
```

## 6.3. Profil User
- User dapat edit `full_name` dan `avatar_url`
- Avatar disimpan di Supabase Storage

## 6.4. Acceptance Criteria
- [x] Session valid → langsung ke Dashboard
- [x] Session invalid → ke Login
- [x] Login pertama → kategori default dibuat
- [x] Logout → bersihkan session lokal → ke Login

---

[← User Flows](05_USER_FLOWS.md) · [Index](00_INDEX.md) · [Dashboard →](07_DASHBOARD.md)
