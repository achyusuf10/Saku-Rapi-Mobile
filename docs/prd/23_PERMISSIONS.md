# 23. Permission Requirements

[← Edge Cases](22_EDGE_CASES.md) · [Index](00_INDEX.md) · [Testing →](24_TESTING.md)

---

| Permission | Kapan Diminta |
|---|---|
| Google Sign-In | Saat login |
| Camera | Saat scan struk |
| Microphone | Saat voice input |
| Photos/Media | Saat pilih lampiran |
| Contacts | Saat buka contact picker (debt/loan) |
| Notifications (Android 13+) | Saat pertama kali aktifkan reminder |

**Aturan:** Permission diminta **just in time**, bukan saat app launch. Jika ditolak permanen → CTA ke app settings.

### Flowchart: Permission Request Flow

```mermaid
flowchart TD
    A([Fitur butuh\npermission]) --> B{Status\npermission?}

    B -->|Granted| C["✅ Lanjutkan\nfitur"]
    B -->|Not determined| D["Request\npermission"]
    B -->|Denied| E["Request ulang\n(jika masih boleh)"]
    B -->|Permanently denied| F["Banner:\n'Buka Settings'"]

    D --> G{User\nrespon?}
    G -->|Allow| C
    G -->|Deny| H{Permanently\ndenied?}
    H -->|Ya| F
    H -->|Tidak| I["Fitur disabled\n(graceful fallback)"]

    E --> G

    F --> J["CTA button:\nopenAppSettings()"]

    style C fill:#2d6a4f,color:#fff
    style F fill:#ff8f00,color:#000
    style I fill:#455a64,color:#fff
```

---

[← Edge Cases](22_EDGE_CASES.md) · [Index](00_INDEX.md) · [Testing →](24_TESTING.md)
