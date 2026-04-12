# Plan: Hapus Manual Parsing — Full AI Input (Voice, OCR, Text)

## Latar Belakang

Saat ini ketiga fitur input transaksi (Voice, OCR, Text) memiliki **dua jalur parsing**:
1. **AI Parsing** (Gemini → Groq failover) — jalur utama
2. **Local/Manual Parsing** (regex + `parsing_dictionaries` keyword lookup) — jalur fallback ketika AI gagal

**Keputusan:** Hapus jalur fallback manual. Ketiga fitur menjadi **full AI-only**. Jika AI gagal, tampilkan error ke user — tidak ada silent fallback ke parsing manual.

---

## Scope Analisis

### Apa yang Dihapus

#### Flutter — File Dihapus Sepenuhnya
| File | Deskripsi |
|------|-----------|
| `lib/features/ocr/services/ocr_local_parser.dart` | Local OCR parser pakai regex (244 baris) |
| `lib/features/voice/services/voice_local_parser.dart` | Local voice/text parser pakai regex + dict (261 baris) |
| `lib/features/voice/datasource/voice_local_data_source.dart` | Hive cache untuk parsing dictionaries (61 baris) |

#### Flutter — File Diedit (Hapus Fallback Logic)
| File | Yang Dihapus |
|------|-------------|
| `lib/features/ocr/services/ocr_image_service.dart` | Import `google_mlkit_text_recognition`, TextRecognizer field, method `extractText()`, dispose call |
| `lib/features/ocr/repositories/ocr_repository.dart` | Method `parseTextLocally()` + import OcrLocalParser |
| `lib/features/ocr/controllers/ocr_scan_controller.dart` | Catch block fallback (ML Kit extract → local parse), `OcrScanStatus.extractingText` |
| `lib/features/voice/repositories/voice_repository.dart` | Fallback branch di `parseVoiceText()`, method `_localFallback()`, method `_getDictionaries()`, seluruh dictionary caching logic |
| `lib/features/voice/datasource/voice_remote_data_source.dart` | Method `fetchParsingDictionaries()` |
| `lib/core/constants/app_constants.dart` | Konstanta `cacheTtlDictionary` |

#### Flutter — Model Dihapus
| File | Deskripsi |
|------|-----------|
| `lib/features/voice/models/parsing_dictionary_model.dart` | Model untuk parsing dictionary (tidak lagi diperlukan) |

#### pubspec.yaml — Dependencies Dihapus
| Package | Alasan Hapus |
|---------|-------------|
| `google_mlkit_text_recognition: ^0.14.0` | Hanya dipakai `ocr_image_service.dart` untuk fallback extractText |
| `sqflite: ^2.4.2` | Tidak ditemukan penggunaan aktif di kodebase |
| ~~`speech_to_text`~~ | ~~STT~~ | **TETAP** — Voice Input masih pakai STT |

> **Note:** `speech_to_text` adalah bagian dari fitur Voice (bukan fallback parsing), tapi perlu dikonfirmasi apakah Voice input tetap pakai STT atau langsung AI. Jika STT tetap dipakai → **jangan hapus**.

> **✅ Dikonfirmasi:** Voice Input tetap pakai `speech_to_text` (suara → teks → AI). Package ini **tidak dihapus**.

#### Android Native — Permissions yang Mungkin Terpengaruh
| Permission | Status |
|-----------|--------|
| `RECORD_AUDIO` | Tetap (kalau Voice STT dipertahankan) |
| Camera permissions | Tetap (untuk OCR image picking) |

#### Supabase — Migration Baru
Buat migration `20260412_016_remove_parsing_dictionaries.sql`:
```sql
DROP TABLE IF EXISTS public.parsing_dictionaries CASCADE;
```
`CASCADE` otomatis hapus:
- Index `idx_parsing_dictionaries_keyword`
- Trigger `trg_parsing_dictionaries_updated_at`
- RLS Policy `parsing_dictionaries_select_all`

### Apa yang TETAP Ada

| Komponen | Alasan Dipertahankan |
|----------|---------------------|
| `voice_input_service.dart` | STT (speech-to-text) — konversi suara ke teks sebelum ke AI |
| `speech_to_text` (package) | Dipakai voice_input_service — bukan manual parser |
| `ocr_image_service.dart` | Camera/gallery picking + image compress — bukan ML Kit OCR |
| `hive_flutter` | Dipakai oleh banyak fitur lain (auth, budget, wallet, dsb.) |
| `permission_handler` | Dipakai OCR (camera), Voice (microphone), Contacts |
| `google_mlkit_commons` | Transitive dep — tidak perlu eksplisit dihapus |
| Edge Function `ai-parse` | Tetap — ini jalur AI utama |
| DB `categories` table | Tetap — masih dipakai everywhere |

---

## Error Handling Setelah Penghapusan

Saat AI gagal (timeout, rate limit, network error):

**Semua fitur:** Tampilkan error + tombol **Retry** saja. Tidak ada fallback ke input manual.
- OCR: `SakuErrorState` dengan tombol retry
- Voice: error snackbar + tombol retry di sheet
- Text: error snackbar + tombol retry di sheet

---

## Urutan Pekerjaan

### Fase 1: Flutter — Hapus Files
1. Hapus `ocr_local_parser.dart`
2. Hapus `voice_local_parser.dart`
3. Hapus `voice_local_data_source.dart`
4. Hapus `parsing_dictionary_model.dart`

### Fase 2: Flutter — Edit Files
5. Edit `ocr_image_service.dart` — hapus ML Kit TextRecognizer
6. Edit `ocr_repository.dart` — hapus `parseTextLocally()`
7. Edit `ocr_scan_controller.dart` — hapus fallback catch block
8. Edit `voice_repository.dart` — hapus fallback + dict caching
9. Edit `voice_remote_data_source.dart` — hapus `fetchParsingDictionaries()`
10. Edit `app_constants.dart` — hapus `cacheTtlDictionary`

### Fase 3: pubspec.yaml
11. Hapus `google_mlkit_text_recognition`, `sqflite` dari pubspec.yaml
12. Konfirmasi `speech_to_text` sebelum hapus

### Fase 4: Supabase
13. Buat migration `016_remove_parsing_dictionaries.sql`
14. Apply ke live DB via `supabase db push` atau SQL Editor

### Fase 5: Validasi
15. `flutter pub get`
16. `fvm flutter analyze` — 0 error baru
17. `fvm flutter test` — semua test lama pass
18. Test manual: OCR, Voice, Text input end-to-end

### Fase 6: Wiki
19. Ingest plan ini ke wiki
20. Update `database-schema.md`, `index.md`, `log.md`

---

## Konfirmasi (Sudah Dijawab)

| Pertanyaan | Jawaban |
|------------|---------|
| `speech_to_text` dipertahankan? | ✅ Ya — Voice tetap STT → teks → AI |
| Error handling AI fail | ✅ Error + tombol Retry saja |
| `sqflite` benar-benar tidak dipakai? | ✅ Konfirmasi grep — tidak ada usage di lib/ |
