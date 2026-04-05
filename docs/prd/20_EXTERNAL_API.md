# 20. External API & Integration

[← Parsing Dictionary](19_PARSING_DICTIONARY.md) · [Index](00_INDEX.md) · [Kategori Default →](21_KATEGORI_DEFAULT.md)

---

## 20.1. Ringkasan Integrasi

| API | Digunakan Untuk | Dipanggil Dari | Cache |
|---|---|---|---|
| CoinGecko | Harga Bitcoin/IDR | Flutter langsung | Hive 12 jam (TTL) |
| Edge Function `gold-price` | Harga emas Antam | Flutter → Supabase | Server 1 hari |
| Edge Function `ai-parse` | Text/OCR parsing | Flutter → Supabase | Tidak |
| Google Sign-In | Authentication | Flutter → Supabase Auth | Session |

## 20.2. Aturan Penting
- Flutter **TIDAK** memanggil API key AI (Gemini/Groq) secara langsung
- Semua AI call melalui Edge Function `ai-parse`
- Edge Function handle failover internal: Gemini → Groq
- CoinGecko API key via environment variable

### Flowchart: Arsitektur Integrasi Eksternal

```mermaid
flowchart TD
    subgraph Flutter["Flutter App"]
        F1["Google Sign-In"]
        F2["CoinGecko\n(direct, Hive cache 12h)"]
        F3["Supabase Client"]
    end

    subgraph Supabase["Supabase Backend"]
        S1["Auth\n(Google OAuth)"]
        S2["Edge Function:\nai-parse"]
        S3["Edge Function:\ngold-price"]
        S4["Edge Function:\nbitcoin-price"]
        S5["Database\n(PostgreSQL)"]
    end

    subgraph External["External APIs"]
        E1["Google OAuth"]
        E2["CoinGecko API"]
        E3["Indodax API"]
        E4["Gemini AI"]
        E5["Groq AI"]
        E6["harga-emas.org"]
    end

    F1 --> S1
    S1 --> E1
    F2 --> E2
    F3 --> S2
    F3 --> S3
    F3 --> S4

    S2 --> E4
    S2 -->|"failover"| E5
    S3 --> E4
    S3 --> E6
    S4 --> E3
    S4 --> E2

    S2 --> S5
    S3 --> S5
    S4 --> S5

    style Flutter fill:#1565c0,color:#fff
    style Supabase fill:#2d6a4f,color:#fff
    style External fill:#6a1b9a,color:#fff
```

### Flowchart: AI Failover Chain

```mermaid
flowchart TD
    A([AI Parse Request]) --> B["Edge Function\nai-parse"]
    B --> C{Gemini\navailable?}

    C -->|✅ Ya| D["Process with\nGemini"]
    D --> E{Gemini\nsuccess?}
    E -->|✅| F["Return result\nprovider: gemini"]

    C -->|❌ Error/Timeout| G{Groq\navailable?}
    E -->|❌ Error/Timeout| G

    G -->|✅ Ya| H["Process with\nGroq"]
    H --> I{Groq\nsuccess?}
    I -->|✅| J["Return result\nprovider: groq"]
    I -->|❌| K["Return error\nAI_BUSY"]

    G -->|❌| K

    F --> L([Flutter receives\nresult])
    J --> L
    K --> M["Flutter: use\nlocal parser fallback"]

    style F fill:#2d6a4f,color:#fff
    style J fill:#1565c0,color:#fff
    style K fill:#d32f2f,color:#fff
```

---

[← Parsing Dictionary](19_PARSING_DICTIONARY.md) · [Index](00_INDEX.md) · [Kategori Default →](21_KATEGORI_DEFAULT.md)
