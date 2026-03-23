

# PROMPT 8 — SakuRapi: Voice Input & OCR Scan UI

```
Kamu adalah senior Flutter developer untuk proyek SakuRapi.
WAJIB baca docs/00_SakuRapi_Coding_Rules.md sebelum mulai coding.

---

## 🎯 Misi Prompt Ini

Implementasi UI + controller untuk:
1. Voice Input (STT) — rekam suara → parse via AI → pre-fill form transaksi
2. OCR Scan Struk — foto/galeri → crop → parse via AI → pre-fill form transaksi multi-item

---

## 📐 Konteks Kode yang Sudah Ada (JANGAN DIUBAH)

- `lib/global/services/voice_service.dart` — VoiceService (lifecycle rekam suara)
- `lib/global/services/ocr_service.dart` — OcrService (Google ML Kit text recognition)
- `lib/global/services/ai_parsing_service.dart` — AIParsingService (hasil Prompt 7)
- `lib/global/services/transaction_parser_service.dart` — TransactionParserService (fallback)

---

## 🗂️ File yang Harus Dibuat

```
lib/global/widgets/
├── voice_input_sheet.dart       -- Bottom sheet timer rekam suara
└── ocr_scan_sheet.dart          -- Bottom sheet pilih foto/galeri + crop + loading

lib/features/transaction/controllers/
├── voice_input_controller.dart  -- StateNotifier untuk state rekam suara
└── ocr_scan_controller.dart     -- StateNotifier untuk state OCR + crop
```

---

## 📋 Spesifikasi Detail

### FITUR 1: Voice Input

#### `VoiceInputController` (voice_input_controller.dart)

```dart
// State:
enum VoiceInputStatus { idle, initializing, listening, processing, done, error }

class VoiceInputState {
  final VoiceInputStatus status;
  final String transcribedText;     // teks real-time dari STT
  final int secondsRemaining;       // countdown 10 → 0
  final String? errorMessage;
  final TransactionFormState? result; // hasil parse siap ke form
}

// Provider:
final voiceInputControllerProvider =
    StateNotifierProvider.autoDispose<VoiceInputController, VoiceInputState>(...);

// Method yang dibutuhkan:
// startListening() → init VoiceService → mulai countdown 10 detik → update transcribedText real-time
// stopListening() → stop VoiceService → panggil AIParsingService.parseVoiceText()
// _onCountdownTick() → decrement secondsRemaining, auto-stop di 0
// _onSttResult(String text) → update transcribedText
// _onSttDone() → panggil stopListening()
// reset() → kembali ke idle
```

#### `VoiceInputSheet` (voice_input_sheet.dart)

Tampilkan sebagai `showModalBottomSheet` dari mana saja (tombol mic di FAB atau form transaksi).

```
Layout bottom sheet dari atas ke bawah:

+──────────────────────────────────────────+
│  ────  (drag handle)                     │
│                                          │
│  🎙️  (icon mic besar, animated pulse    │
│       saat listening)                    │
│                                          │
│  "Sedang mendengarkan..."                │  ← status text
│  atau teks real-time STT yang muncul     │
│  saat user berbicara (TextStyleConstants │
│  .b1, italic, textSecondary)             │
│                                          │
│       [ 8 ]  ← countdown detik          │  ← besar, bold, primary color
│  ──────────────────────────────────────  │
│  [        Selesai / Batalkan        ]    │  ← FilledButton atau OutlinedButton
+──────────────────────────────────────────+
```

**Detail behavior:**
- Sheet muncul → otomatis panggil `controller.startListening()`
- Icon mic: `FontAwesomeIcons.microphone`, ukuran 48.r
  - Status `listening`: warna `context.colors.expense` (merah), efek pulsing menggunakan `AnimatedContainer` atau `ScaleTransition` loop
  - Status `processing`: warna `context.colors.textSecondary`, ganti icon ke `FontAwesomeIcons.circleNotch` yang berputar
  - Status `error`: warna `context.colors.expense`, icon `FontAwesomeIcons.circleXmark`
- Teks status:
  - `idle`/`initializing` → "Mempersiapkan mikrofon..."
  - `listening` → teks STT real-time (jika kosong tampilkan "Sedang mendengarkan...")
  - `processing` → "Menganalisis dengan AI..."
  - `error` → errorMessage
- Countdown: `TextStyleConstants.h2`, `context.colors.primary`, hanya tampil saat `listening`
- Tombol:
  - Saat `listening`: label "Selesai" → tap panggil `controller.stopListening()`
  - Saat `processing`: label "Mohon tunggu..." disabled
  - Saat `error`: label "Coba Lagi" → panggil `controller.startListening()`
- Saat status `done`:
  - Tutup bottom sheet dengan `Navigator.pop(context)`
  - Push `TransactionFormScreen` dengan `extra: result` (TransactionFormState)
  - Lakukan ini via callback atau ref.listen di luar sheet

---

### FITUR 2: OCR Scan Struk

#### `OcrScanController` (ocr_scan_controller.dart)

```dart
// State:
enum OcrScanStatus { idle, picking, cropping, extracting, processing, done, error }

class OcrScanState {
  final OcrScanStatus status;
  final File? pickedImage;          // gambar asli dari kamera/galeri
  final File? croppedImage;         // gambar setelah di-crop
  final String? rawOcrText;         // hasil ML Kit sebelum AI parse
  final String? errorMessage;
  final TransactionFormState? result;
}

// Method yang dibutuhkan:
// pickFromCamera() → image_picker kamera → set pickedImage → buka crop
// pickFromGallery() → image_picker galeri → set pickedImage → buka crop
// onCropDone(File croppedFile) → set croppedImage → panggil _extractAndParse()
// _extractAndParse() → OcrService.extractText() → AIParsingService.parseOcrText()
// retry() → reset ke idle
```

#### `OcrScanSheet` (ocr_scan_sheet.dart)

Tampilkan sebagai `showModalBottomSheet` dari mana saja.

```
TAMPILAN 1 — Status idle (pilih sumber foto):

+──────────────────────────────────────────+
│  ────  (drag handle)                     │
│  Scan Struk Belanja     (title, h6)      │
│                                          │
│  +──────────────+  +──────────────+      │
│  │  📷          │  │  🖼️          │      │
│  │  Kamera      │  │  Galeri      │      │
│  +──────────────+  +──────────────+      │
│  (2 card pilihan, rounded, surface color)│
+──────────────────────────────────────────+
```

```
TAMPILAN 2 — Status extracting/processing (loading):

+──────────────────────────────────────────+
│  ────  (drag handle)                     │
│                                          │
│  [Thumbnail gambar yang di-crop]         │  ← Image.file, borderRadius 12.r, max height 160.h
│                                          │
│  ⏳  "Membaca teks dari struk..."        │  ← status extracting
│      atau                                │
│  🤖  "Menganalisis dengan AI..."         │  ← status processing
│                                          │
│  CircularProgressIndicator (primary)     │
│                                          │
+──────────────────────────────────────────+
```

**Detail behavior:**
- Tap "Kamera" → `controller.pickFromCamera()` → setelah dapat gambar → buka crop via package `image_cropper`
  - Crop aspect ratio: bebas (tidak dikunci)
  - Toolbar title: "Pilih Area Struk"
  - Toolbar color: `context.colors.surface`
- Tap "Galeri" → `controller.pickFromGallery()` → flow sama
- Setelah crop selesai → sheet pindah ke TAMPILAN 2 otomatis
- Status `extracting` → teks "Membaca teks dari struk..."
- Status `processing` → teks "Menganalisis dengan AI..."
- Saat status `done`:
  - Tutup bottom sheet
  - Push `TransactionFormScreen` dengan `extra: result`
- Saat status `error`:
  - Tampilkan pesan error di sheet
  - Tombol "Coba Lagi" → `controller.retry()`

---

## 📦 Packages yang Dibutuhkan

Cek `pubspec.yaml` terlebih dahulu. Jika belum ada, tambahkan:
```yaml
dependencies:
  image_picker: ^latest        # pick kamera/galeri
  image_cropper: ^latest       # crop area struk
  # speech_to_text dan google_mlkit_text_recognition sudah ada di repo
```

---

## 🔗 Integrasi dengan TransactionFormScreen

Kedua bottom sheet me-navigate ke `TransactionFormScreen` setelah parse selesai.
Pastikan route `/transaction/form` mendukung parameter `extra` bertipe `TransactionFormState?`:
- Jika `extra != null` → form di-prefill dengan data dari AI
- Field yang di-prefill dari voice AI: `type`, `date`, `items[0].amount`, `items[0].categoryId`, `items[0].note`
- Field yang di-prefill dari OCR AI: `type`, `date`, `merchantName`, semua `items` (multi-item), `attachmentLocalPath`
- Field yang TIDAK di-prefill (user isi sendiri): `walletId`

---

## ✅ Checklist Selesai

### Voice Input
- [ ] `VoiceInputController` — 6 status (idle/initializing/listening/processing/done/error)
- [ ] Countdown 10 detik real-time, auto-stop di 0
- [ ] Teks STT muncul real-time saat user berbicara
- [ ] `AIParsingService.parseVoiceText()` dipanggil setelah rekaman selesai
- [ ] Fallback otomatis ke local NLP jika AI gagal (sudah di AIParsingService, tidak perlu handle ulang di sini)
- [ ] Icon mic: pulsing animation saat listening, spinner saat processing
- [ ] Navigasi ke TransactionFormScreen setelah `done`

### OCR Scan
- [ ] `OcrScanController` — 7 status
- [ ] Pilihan kamera + galeri via `image_picker`
- [ ] Crop wajib via `image_cropper` sebelum OCR
- [ ] `OcrService.extractText()` → `AIParsingService.parseOcrText()` secara berurutan
- [ ] Thumbnail gambar crop tampil saat loading
- [ ] Navigasi ke TransactionFormScreen setelah `done` dengan multi-item pre-filled
- [ ] Status text yang berbeda untuk extracting vs processing

### Aturan Umum
- [ ] DILARANG hardcode warna — semua via `context.colors.*`
- [ ] DILARANG hardcode TextStyle — semua via `TextStyleConstants.*`
- [ ] DILARANG ukuran piksel mentah — semua via ScreenUtil (.h, .w, .r, .sp)
- [ ] Semua string UI dari file .arb
- [ ] Semua log menggunakan AppLogger.call dengan tag yang sesuai
- [ ] autoDispose pada semua provider (sheet di-close → resource dibebaskan)
```

---

Dua prompt ini sudah saling terkoneksi dengan urutan yang benar:
- **Prompt 7** bangun infrastruktur dulu (Edge Function + SSL Pinning + AIParsingService)
- **Prompt 8** konsumsi infrastruktur tersebut untuk UI Voice dan OCR