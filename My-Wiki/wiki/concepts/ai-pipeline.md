---
title: "AI Processing Pipeline"
type: concept
tags: [ai, voice, ocr, text-parser, edge-function, gemini, groq, parsing-dictionary, stt]
sources: [raw/docs/prd/17_VOICE_INPUT.md, raw/docs/prd/18_OCR_RECEIPT.md, raw/docs/prd/19_PARSING_DICTIONARY.md, raw/docs/prd/20_EXTERNAL_API.md]
created: 2026-04-10
updated: 2026-04-10
---

# AI Processing Pipeline

> Halaman ini mendokumentasikan arsitektur pipeline AI di SakuRapi, mencakup input suara (voice), teks, dan OCR struk. Semua jalur bermuara pada satu Edge Function: **`ai-parse`**.

---

## Prinsip Utama

> **AI hanya prefill, user tetap review sebelum save.**

AI tidak pernah menyimpan transaksi secara otomatis. Hasil parsing hanya mengisi form sebagai saran awal (prefill), dan user **wajib** mereview serta mengonfirmasi sebelum data disimpan. Ini adalah salah dari [[wiki/concepts/aturan-keuangan|7 keputusan final]] yang tidak boleh dilanggar.

---

## Arsitektur Umum

Semua input (voice, text, OCR) diproses oleh satu Edge Function yang sama:

```
┌──────────────────────────────────────────────────────────────┐
│                     Edge Function: ai-parse                   │
│                   (Deno + TypeScript runtime)                 │
│                                                               │
│  mode='text'  ──► Text parsing pipeline                      │
│  mode='ocr'   ──► OCR/image parsing pipeline                 │
│                                                               │
│  AI Provider Chain: Gemini → Groq → Local Parser Fallback    │
└──────────────────────────────────────────────────────────────┘
```

> **Penting**: Edge Functions berjalan di **Deno + TypeScript**, bukan Node.js. Import menggunakan URL-based imports sesuai standar Deno.

---

## 3 Jalur Input

### 1. Voice Input (Suara)

```
Record audio (max 10 detik)
        ↓
STT lokal via package speech_to_text (locale: id_ID)
        ↓
Teks hasil STT
        ↓
ai-parse (mode='text')
        ↓
Prefill form transaksi
```

**Detail teknis:**
- Durasi rekaman maksimal: **10 detik**
- STT dilakukan secara **lokal di device** menggunakan package `speech_to_text`
- Locale: `id_ID` (Bahasa Indonesia)
- Hasil STT dikirim ke `ai-parse` sebagai teks biasa dengan `mode='text'`
- **Tidak ada audio yang dikirim ke server** — STT sepenuhnya on-device

### 2. Text Input (Ketik Manual)

```
User mengetik deskripsi transaksi
        ↓
ai-parse (mode='text')
        ↓
Prefill form transaksi
```

**Detail teknis:**
- Jalur paling sederhana — langsung ke `ai-parse` tanpa proses STT
- Contoh input: "makan siang di warteg 15ribu", "gaji bulan april 8jt"
- Mode yang sama dengan voice setelah tahap STT

### 3. OCR Input (Foto Struk)

```
Ambil gambar (Camera atau Gallery)
        ↓
Crop area struk
        ↓
Compress gambar
        ↓
Encode ke Base64
        ↓
ai-parse (mode='ocr')
        ↓
Prefill form transaksi
```

**Detail teknis:**
- Sumber gambar: kamera langsung atau pilih dari galeri
- Proses di client: crop → compress → encode Base64
- Gambar dikirim sebagai string Base64 ke `ai-parse` dengan `mode='ocr'`
- AI mengekstrak informasi dari gambar struk

---

## AI Failover Chain

Pipeline AI menggunakan strategi failover bertingkat untuk memaksimalkan keberhasilan parsing:

```
Gemini (primary)
    ↓ gagal/timeout
Groq (secondary)
    ↓ gagal/timeout
Local Parser Fallback
```

| Provider | Peran | Catatan |
|---|---|---|
| **Gemini** | Provider utama | Google AI, mendukung text dan vision (OCR) |
| **Groq** | Fallback pertama | Digunakan jika Gemini gagal atau timeout |
| **Local Parser** | Fallback terakhir | Parsing sederhana tanpa AI, berjalan di device |

Failover terjadi secara transparan — user tidak perlu tahu provider mana yang digunakan.

---

## Local Parsers (Fallback)

Ketika semua AI provider gagal, SakuRapi menggunakan parser lokal yang berjalan di device:

### VoiceLocalParser (untuk mode text)

Parser berbasis regex dan keyword matching:

1. **Extract amount**: Regex untuk mendeteksi angka dan format uang Indonesia (ribu, juta, rb, jt, k)
2. **Detect type**: Keyword matching untuk menentukan tipe transaksi (misalnya "bayar" → expense, "terima" → income)
3. **Match category**: Dictionary-based matching untuk menentukan kategori

### OcrLocalParser (untuk mode OCR)

Parser untuk mengekstrak informasi dari teks OCR mentah:

1. **Extract merchant**: Nama toko/merchant dari header struk
2. **Extract total**: Jumlah total pembayaran
3. **Extract items**: Daftar item yang dibeli (jika tersedia)
4. **Extract date**: Tanggal transaksi dari struk

---

## Parsing Dictionary

Parsing dictionary adalah mekanisme untuk meningkatkan akurasi matching kategori berdasarkan keyword.

### Penyimpanan

- **Server**: Tabel `parsing_dictionaries` di Supabase
- **Client**: Cache di **Hive** dengan masa berlaku **24 jam**
- **Matching**: Keyword dalam format **lowercase**

### Alur Penggunaan

```
App launch / cache expired (24 jam)
        ↓
Fetch parsing_dictionaries dari Supabase
        ↓
Simpan ke Hive cache
        ↓
Saat parsing: match keyword input (lowercase) → kategori
```

### Contoh

| Keyword | Kategori |
|---|---|
| "grab" | Transportasi |
| "indomaret" | Belanja |
| "starbucks" | Makanan & Minuman |
| "pln" | Tagihan |

---

## Alur End-to-End

```
┌─────────────────────────────────────────────────────────────────────┐
│ CLIENT (Flutter)                                                     │
│                                                                      │
│  [Voice] ─► speech_to_text (id_ID) ─► teks ──┐                     │
│  [Text]  ─► langsung teks ───────────────────►├─► ai-parse(text)    │
│  [OCR]   ─► crop → compress → base64 ────────►└─► ai-parse(ocr)    │
│                                                                      │
│  ◄── Hasil parsing (amount, type, category, description, date) ──►  │
│                                                                      │
│  [Form Transaksi] ← prefill dari hasil AI                           │
│  User review & edit ──► Konfirmasi ──► Save via RPC                 │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ SERVER (Supabase Edge Function — Deno + TypeScript)                  │
│                                                                      │
│  ai-parse:                                                           │
│    mode='text' → prompt engineering → extract structured data        │
│    mode='ocr'  → vision model → extract receipt data                 │
│                                                                      │
│  Failover: Gemini → Groq → return error (client uses local parser)  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Catatan Teknis

- Edge Function `ai-parse` adalah **shared** untuk semua mode input — satu endpoint, parameter `mode` yang berbeda
- STT (Speech-to-Text) berjalan **100% lokal** di device, tidak ada audio yang dikirim ke server
- Permission mikrofon dan kamera diminta **just-in-time** saat fitur digunakan, bukan saat app launch
- Hasil parsing bersifat **best-effort** — jika AI tidak yakin dengan suatu field, field tersebut dikosongkan agar user mengisi sendiri

---

## Halaman Terkait

- [[wiki/concepts/aturan-keuangan|Aturan Keuangan Fundamental]] — Prinsip "AI hanya prefill"
- [[wiki/concepts/matrix-transaksi|Matrix Transaksi]] — Tipe transaksi yang dihasilkan AI
- [[wiki/entities/transaksi|Transaksi]] — Entitas transaksi
- [[wiki/concepts/arsitektur-app|Arsitektur App]] — Stack teknologi dan pola arsitektur
- [[wiki/sources/prd-sakurapi-v7|PRD SakuRapi v7.0]] — Dokumen sumber
