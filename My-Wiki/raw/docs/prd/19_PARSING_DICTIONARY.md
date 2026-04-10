# 19. Parsing Dictionary

[← OCR Receipt](18_OCR_RECEIPT.md) · [Index](00_INDEX.md) · [External API →](20_EXTERNAL_API.md)

---

- Tabel: `parsing_dictionaries`
- Cache ke Hive selama 24 jam (key: `cached_parsing_dictionaries` + timestamp)
- Keyword lowercase, matching case-insensitive
- Fallback: kategori "Lain-lain" jika keyword tidak ditemukan

### Flowchart: Parsing Dictionary Cache Flow

```mermaid
flowchart TD
    A([Voice/OCR perlu\nmatch kategori]) --> B{Cache Hive\nmasih valid?\n(< 24 jam)}

    B -->|Ya| C["Baca dari Hive\n(cached_parsing_dictionaries)"]
    B -->|Tidak / Kosong| D["Fetch dari Supabase\ntabel parsing_dictionaries"]
    D --> E["Simpan ke Hive\n+ timestamp"]
    E --> C

    C --> F["Keyword → lowercase"]
    F --> G{Match\nditemukan?}
    G -->|Ya| H["Return category_id\ndari dictionary"]
    G -->|Tidak| I["Fallback:\nkategori 'Lain-lain'"]

    style H fill:#2d6a4f,color:#fff
    style I fill:#ff8f00,color:#000
```

---

[← OCR Receipt](18_OCR_RECEIPT.md) · [Index](00_INDEX.md) · [External API →](20_EXTERNAL_API.md)
