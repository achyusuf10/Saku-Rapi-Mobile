---
title: "AI Processing Pipeline"
type: concept
tags: [ai, voice, ocr, text-parser, edge-function, gemini, vertex, parsing-dictionary, stt, quota]
sources: [raw/docs/prd/17_VOICE_INPUT.md, raw/docs/prd/18_OCR_RECEIPT.md, raw/docs/prd/19_PARSING_DICTIONARY.md, raw/docs/prd/20_EXTERNAL_API.md]
created: 2026-04-10
updated: 2026-04-25
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
│  AI: Vertex AI Gemini (satu provider) — jika error → klien error+retry  │
└──────────────────────────────────────────────────────────────┘
```

> **Penting**: Edge Functions berjalan di **Deno + TypeScript**, bukan Node.js. **Tidak** ada *failover* Groq/OpenRouter dan **tidak** ada *fallback* parser regex lokal; lihat [[wiki/analysis/remove-manual-parsing|Penghapusan manual parsing]].

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

## Provider AI & penanganan gagal

*Saat ini* Edge Function memakai **Vertex AI (Gemini)** — satu jalur, tanpa penyedia sekunder. Jika panggilan gagal atau *timeout*, hasil kembali sebagai **error**; Flutter menampilkan *error state* + aksi **coba lagi** (bukan beralih ke Groq, bukan regex di perangkat).

- **Kuota** harian per mode (free/premium) lewat tabel/ RPC kuota di Supabase; ringkasnya: [[wiki/analysis/refactor-ai-parse-gemini-quota|Refactor AI Parse: Gemini + kuota]].

---

## `parsing_dictionaries` (opsional)

Tabel `parsing_dictionaries` mungkin masih ada di DB untuk *hint* (bukan *silent fallback* klien). **Kategori** yang tampil untuk user dan *mapping* andal berasal dari katalog (RPC) — lihat [[wiki/entities/categories|Categories]]. **Fallback lokal** berbasis kamus/regex ke **dihapus**; baca [[wiki/analysis/remove-manual-parsing|Penghapusan manual parsing]].

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
│  Error → response error → klien tampilkan *retry* (bukan *chain* Groq) │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Catatan Teknis

- Edge Function `ai-parse` adalah **shared** untuk semua mode input — satu endpoint, parameter `mode` yang berbeda
- STT (Speech-to-Text) berjalan **100% lokal** di device, tidak ada audio yang dikirim ke server
- Permission mikrofon dan kamera diminta **just-in-time** saat fitur digunakan, bukan saat app launch
- Hasil parsing **best-effort** — jika suatu field tidak yakin, bisa dikosongkan agar user melengkapi; kegagalan penuh = error + *retry*

---

## Halaman Terkait

- [[wiki/concepts/aturan-keuangan|Aturan Keuangan Fundamental]] — Prinsip "AI hanya prefill"
- [[wiki/concepts/matrix-transaksi|Matrix Transaksi]] — Tipe transaksi yang dihasilkan AI
- [[wiki/entities/transaksi|Transaksi]] — Entitas transaksi
- [[wiki/concepts/arsitektur-app|Arsitektur App]] — Stack teknologi dan pola arsitektur
- [[wiki/sources/prd-sakurapi-v7|PRD SakuRapi v7.0]] — Ringkasan PRD
- [[wiki/analysis/remove-manual-parsing|Penghapusan manual parsing]]
- [[wiki/analysis/refactor-ai-parse-gemini-quota|Refactor AI Parse: Gemini + kuota]]
