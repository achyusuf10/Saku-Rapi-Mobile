---
title: "Analisis: Penghapusan Manual Parsing Fallback (OCR + Voice + Text)"
type: analysis
tags: [ocr, voice-input, text-input, refactoring, ai-pipeline, edge-functions]
sources: [raw/docs/plan-remove-manual-parsing.md]
created: 2026-04-12
updated: 2026-04-12
---

# Analisis: Penghapusan Manual Parsing Fallback (OCR + Voice + Text)

## Latar Belakang

Ketiga fitur AI input (Voice, OCR, Text Input) semula memiliki **dua jalur parsing**:

1. **Primary**: Supabase Edge Function `ai-parse` (Gemini AI)
2. **Fallback**: Parsing lokal via regex + `parsing_dictionaries` (tabel DB + Hive cache)

Fallback lokal dihapus sepenuhnya. Alasannya:
- Regex parsing menghasilkan output tidak konsisten dan sering gagal untuk input natural language
- `parsing_dictionaries` harus disinkronisasi antar device — kompleksitas tinggi, nilai rendah
- "Silent fallback" menyembunyikan kegagalan AI dari user — UX menyesatkan
- Sesuai keputusan final PRD: _AI fail → error + retry, tidak ada silent fallback_

---

## Arsitektur: Sebelum vs Sesudah

### Sebelum

```
User Input (Voice/OCR/Text)
  ↓
Edge Function ai-parse (Gemini AI)
  ↓ berhasil          ↓ gagal
TransactionForm    LocalParser (regex)
                     ↓ berhasil          ↓ gagal
                   TransactionForm    Error dialog
```

**Komponen fallback yang ada:**
- `ocr_local_parser.dart` — regex parser untuk teks struk belanja
- `voice_local_parser.dart` — regex parser untuk kalimat suara
- `parsing_dictionary_model.dart` — model kamus kata (nama merchant, kategori)
- `voice_local_data_source.dart` — Hive cache untuk tabel `parsing_dictionaries`
- Tabel DB `parsing_dictionaries` — kamus untuk lookup lokal
- `OcrImageService.extractText()` — ML Kit OCR (Google ML Kit)
- `OcrScanController.extractingText` — status enum untuk fase ML Kit
- `VoiceRepository._localFallback()`, `_getDictionaries()`, `refreshDictionaries()`, `lookupCategoryId()`

### Sesudah

```
User Input (Voice/OCR/Text)
  ↓
Edge Function ai-parse (Gemini AI)
  ↓ berhasil          ↓ gagal
TransactionForm    Error + Retry button
```

**Alur lebih sederhana**: satu jalur saja. AI gagal → user diberi tahu → user retry.

---

## Dampak per Fitur

### OCR Receipt

| Area | Perubahan |
|------|-----------|
| `OcrImageService` | Dihapus: field `TextRecognizer _recognizer`, method `extractText()`. ML Kit tidak lagi digunakan |
| `OcrRepository` | Dihapus: method `parseTextLocally()` |
| `OcrScanController` | Dihapus: status `extractingText` dari enum, field `rawOcrText`, catch block ML Kit fallback |
| `OcrResultSheet` | Dihapus: UI branch untuk status `extractingText` |
| Package dihapus | `google_mlkit_text_recognition` |
| File dihapus | `lib/features/ocr/services/ocr_local_parser.dart` |
| Test dihapus | `test/features/ocr/ocr_local_parser_test.dart` |
| Lokalisasi | Key `ocrExtractingText` dihapus dari `app_id.arb` dan `app_en.arb` |

**Alur OCR sekarang**: Kamera → crop image → kirim ke Edge Function `ai-parse` → hasil parsing → TransactionForm.

### Voice Input

| Area | Perubahan |
|------|-----------|
| `VoiceRepository` | Disederhanakan drastis: dihapus field `_local`, method `_getDictionaries()`, `_localFallback()`, `refreshDictionaries()`, `lookupCategoryId()`. AI fail → `DataState.error` langsung |
| `VoiceRemoteDataSource` | Dihapus: method `fetchParsingDictionaries()` |
| File dihapus | `lib/features/voice/services/voice_local_parser.dart` |
| File dihapus | `lib/features/voice/models/parsing_dictionary_model.dart` |
| File dihapus | `lib/features/voice/datasource/voice_local_data_source.dart` |
| Test dihapus | `test/features/voice/voice_local_parser_test.dart` |

### Text Input

Fitur Text Input menggunakan Edge Function yang sama (`ai-parse`). Tidak ada local parser — dampaknya minimal. Hanya ikut terdampak dari perubahan shared infrastructure (AppConstants, dll).

---

## Supabase Changes (Migration 016)

File: `supabase/migrations/20260412110000_016_remove_parsing_dictionaries.sql`

### Dihapus dari Database

| Object | Type | Detail |
|--------|------|--------|
| `parsing_dictionaries` | TABLE | Kamus parsing lokal (merchant name, kategori) — CASCADE |

`DROP TABLE parsing_dictionaries CASCADE` otomatis menghapus:
- Index pada tabel (jika ada)
- Trigger `updated_at` (jika ada)
- Semua RLS policies pada tabel

---

## Packages Dihapus dari pubspec.yaml

| Package | Alasan |
|---------|--------|
| `google_mlkit_text_recognition` | ML Kit OCR tidak lagi digunakan setelah fallback dihapus |
| `sqflite` | SQLite — sudah tidak digunakan, presence-nya adalah sisa lama |

---

## Konstanta Dihapus

- `AppConstants.cacheTtlDictionary` — TTL cache untuk `parsing_dictionaries` Hive

---

## Error Handling Setelah Perubahan

**Sebelum**: AI gagal → silent fallback ke regex → TransactionForm terisi (mungkin salah) → user tidak sadar
**Sesudah**: AI gagal → `DataState.error` → UI menampilkan error state dengan tombol **Retry**

Ini lebih transparan: user tahu parsing gagal dan dapat mengulang request atau menutup sheet.

Behavior per fitur:
- **OCR**: Jika Edge Function gagal → `OcrScanController` error state → `SakuErrorState` widget + retry button
- **Voice**: Jika Edge Function gagal → `VoiceRepository` return `DataState.error` → controller error state → error dialog/sheet
- **Text Input**: Sama — error state + retry

---

## Hasil Test & Analyze

| Metrik | Hasil |
|--------|-------|
| Test passed | **505** |
| Test failed (pre-existing) | 7 — tidak terkait perubahan ini |
| `flutter analyze` errors | **0** (hanya 6 warning pre-existing) |

---

## Halaman Terkait
- [[wiki/entities/voice-input|Voice Input]]
- [[wiki/entities/ocr-receipt|OCR Receipt]]
- [[wiki/entities/text-input|Text Input]]
- [[wiki/entities/edge-functions|Edge Functions]]
- [[wiki/concepts/ai-pipeline|AI Pipeline]]
- [[wiki/entities/database-schema|Database Schema]]
