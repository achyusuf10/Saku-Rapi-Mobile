---
title: "Plan: Hapus Manual Parsing — Full AI Input"
type: source
tags: [ocr, voice-input, text-input, refactoring, manual-parsing, ai-pipeline]
sources: [raw/docs/plan-remove-manual-parsing.md]
created: 2026-04-19
updated: 2026-04-19
---

# Plan: Hapus Manual Parsing — Full AI Input

**Status:** ✅ Implemented (April 2026)
**Tanggal:** 2026-04-12
**Sumber:** `raw/docs/plan-remove-manual-parsing.md`

## Latar Belakang

Ketiga fitur AI input (Voice, OCR, Text) punya dua jalur parsing:
1. **Primary**: Edge Function `ai-parse` (Gemini AI)
2. **Fallback**: Parsing lokal via regex + `parsing_dictionaries` (tabel DB + Hive cache)

**Keputusan**: Hapus fallback lokal sepenuhnya. Jika AI gagal → tampilkan error ke user, tidak ada silent fallback.

## Yang Dihapus

### File Flutter Dihapus Sepenuhnya

| File | Deskripsi |
|------|-----------|
| `lib/features/ocr/services/ocr_local_parser.dart` | Local OCR parser (regex, 244 baris) |
| `lib/features/voice/services/voice_local_parser.dart` | Local voice/text parser (regex + dict, 261 baris) |
| `lib/features/voice/datasource/voice_local_data_source.dart` | Hive cache untuk parsing dictionaries |

### File Flutter Diedit (Hapus Fallback Logic)

| File | Yang Dihapus |
|------|-------------|
| `ocr_image_service.dart` | ML Kit TextRecognizer, `extractText()`, dispose |
| `ocr_repository.dart` | Method `parseTextLocally()` |
| `ocr_scan_controller.dart` | Fallback catch block, `OcrScanStatus.extractingText` |
| `voice_repository.dart` | `_localFallback()`, `_getDictionaries()`, dictionary caching |
| `voice_remote_data_source.dart` | `fetchParsingDictionaries()` |
| `app_constants.dart` | `cacheTtlDictionary` |

### Model Dihapus

- `lib/features/voice/models/parsing_dictionary_model.dart`

### Dependencies Dihapus (pubspec.yaml)

| Package | Alasan |
|---------|--------|
| `google_mlkit_text_recognition` | Hanya dipakai untuk fallback OCR text extraction |
| `sqflite` | Tidak ada penggunaan aktif |

### Database Migration

```sql
-- 20260412_016_remove_parsing_dictionaries.sql
DROP TABLE IF EXISTS public.parsing_dictionaries CASCADE;
```

## Yang TETAP Ada

| Komponen | Alasan |
|----------|--------|
| `speech_to_text` package | STT untuk Voice Input (bukan manual parser) |
| `voice_input_service.dart` | Konversi suara → teks |
| `ocr_image_service.dart` | Camera/gallery picking + image compress |
| Edge Function `ai-parse` | Jalur AI utama |
| Tabel `categories` | Masih dipakai everywhere |

## Halaman Terkait

- [[wiki/analysis/remove-manual-parsing|Analisis: Penghapusan Manual Parsing Fallback]]
- [[wiki/entities/voice-input|Voice Input]]
- [[wiki/entities/ocr-receipt|OCR Receipt]]
- [[wiki/entities/text-input|Text Input]]
