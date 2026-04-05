# 16. Settings

[← Investasi](15_INVESTASI.md) · [Index](00_INDEX.md) · [Voice & Text Input →](17_VOICE_INPUT.md)

---

## 16.1. Layout

```
┌─────────────────────────────────────┐
│  ┌───┐                             │
│  │ 👤│  John Doe                   │  ← Section 1: Profile (read-only)
│  └───┘  john@example.com           │
├─────────────────────────────────────┤
│  AKUN                               │  ← Section 2
│  ├─ 📂 Categories                   │
│  ├─ 🤝 Debt/Loan                    │
│  └─ 🔔 Notifications                │
├─────────────────────────────────────┤
│  PREFERENSI                         │  ← Section 3
│  ├─ 🎨 Theme       [System ▼]      │
│  ├─ 🌐 Language    [Indonesia ▼]   │
│  └─ ⚡ Entry Point [Manual ▼]      │
├─────────────────────────────────────┤
│  DATA                               │  ← Section 4
│  └─ 📤 Export/Import  [Coming Soon]│
├─────────────────────────────────────┤
│  LAINNYA                            │  ← Section 5
│  ├─ ℹ️ App Version   1.0.0 (1)     │
│  └─ 🚪 Logout                      │
└─────────────────────────────────────┘
```

### Flowchart: Settings Navigation

```mermaid
flowchart TD
    A([Settings Page]) --> B{Section?}

    B -->|Profile| C["Read-only:\nNama + Email"]
    B -->|Akun| D{Menu?}
    B -->|Preferensi| E{Preference?}
    B -->|Data| F["Export/Import\n(Coming Soon)"]
    B -->|Lainnya| G{Action?}

    D -->|Categories| H["Navigate to\nCategory Management"]
    D -->|Debt/Loan| I["Navigate to\nDebt/Loan Page"]
    D -->|Notifications| J["Navigate to\nNotification Settings"]

    E -->|Theme| K["Dropdown: System/Light/Dark\n→ Hive save → apply"]
    E -->|Language| L["Dropdown: ID/EN\n→ Hive save → apply"]
    E -->|Entry Point| M["Dropdown: Manual/Voice/Scan\n→ Hive save"]

    G -->|Logout| N["signOut → clear cache\n→ Login screen"]

    style N fill:#d32f2f,color:#fff
```

## 16.2. Notification Settings Page

| Section | Kontrol | Default |
|---|---|---|
| Permission banner | Request / Open Settings | Tampil jika permission ditolak |
| Pengingat Harian | Toggle + Time Picker | OFF, 20:00 |
| Alert Anggaran 80%/100% | Toggle | ON |
| Alert Anggaran 50% | Toggle | OFF |
| Pengingat Piutang | Toggle + Days Before | ON, 3 hari |
| Tombol Save | Full-width button | — |

**Notification channels:**

| Channel ID | Nama | Importance |
|---|---|---|
| `saku_rapi_reminder` | Pengingat Harian | HIGH |
| `saku_rapi_budget` | Alert Anggaran | HIGH |

### Flowchart: Notification Settings Flow

```mermaid
flowchart TD
    A([Notification\nSettings Page]) --> B{Permission\nnotifikasi?}

    B -->|Belum diminta| C["Banner: Request\npermission"]
    B -->|Granted| D["Tampilkan semua\nsettings"]
    B -->|Denied permanently| E["Banner: Buka\nApp Settings"]

    C -->|Granted| D
    D --> F{User ubah\nsettings?}

    F -->|Daily Reminder| G["Toggle ON/OFF\n+ Time Picker\n(default 20:00)"]
    F -->|Budget Alert 80/100| H["Toggle ON/OFF"]
    F -->|Budget Alert 50| I["Toggle ON/OFF"]
    F -->|Debt Reminder| J["Toggle ON/OFF\n+ Days before (default 3)"]

    G --> K[Tap Save]
    H --> K
    I --> K
    J --> K

    K --> L["Save ke server\n+ schedule notification"]
    L --> M{Daily reminder ON?}
    M -->|Ya| N["zonedSchedule\nAsia/Jakarta\nrepeat daily"]
    M -->|Tidak| O["Cancel scheduled\nnotification"]

    style L fill:#2d6a4f,color:#fff
```

**Implementation:**
- Daily reminder: `zonedSchedule` + `DateTimeComponents.time` (repeat harian), timezone Asia/Jakarta
- WorkManager: re-sync jadwal setelah device restart dari cache Hive
- Debt reminder: settings tersimpan, **logika pengiriman belum implementasi**

## 16.3. Preferences (Hive-persisted)

| Preference | Key Hive | Opsi |
|---|---|---|
| Theme | `theme_mode` | System / Light / Dark |
| Language | `app_locale` | Indonesian / English |
| Entry Point | `transaction_entry_point` | Manual / Voice / Scan |

### Flowchart: Preference Change Flow

```mermaid
flowchart TD
    A([User ubah\npreference]) --> B["Save ke Hive\n(key: preference_key)"]
    B --> C{Preference?}

    C -->|Theme| D["ThemeController\nupdate → rebuild UI"]
    C -->|Language| E["LocaleController\nupdate → rebuild l10n"]
    C -->|Entry Point| F["Simpan saja\n(dibaca saat quick action)"]

    D --> G["✅ Langsung\nterlihat perubahannya"]
    E --> G
    F --> H["✅ Tersimpan\nuntuk sesi berikutnya"]

    style G fill:#2d6a4f,color:#fff
    style H fill:#2d6a4f,color:#fff
```

## 16.4. Acceptance Criteria
- [x] Semua preference survive restart (Hive)
- [x] Theme & language berubah langsung setelah dipilih
- [x] Logout → bersihkan session + cache → ke Login
- [x] Notification settings simpan ke server via save button
- [x] Permission check: request jika belum granted, settings jika permanently denied

---

[← Investasi](15_INVESTASI.md) · [Index](00_INDEX.md) · [Voice & Text Input →](17_VOICE_INPUT.md)
