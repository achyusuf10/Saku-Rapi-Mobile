Saya perlu baca beberapa file dulu sebelum membuat promptnya, biar promptnya akurat dan konsisten dengan codebase yang sudah ada.Bagus, sudah dapat semua konteks yang dibutuhkan. Karena di repo sudah ada `VoiceService`, `OcrService`, dan `TransactionParserService` (versi local NLP), promptnya akan fokus pada **upgrade** ke AI + security layer, bukan membangun dari nol. Ini 2 promptnya:

---

# PROMPT 7 — SakuRapi: Modul AI Asisten (Supabase Edge Function + SSL Pinning)

```
Kamu adalah senior Flutter developer untuk proyek SakuRapi.
WAJIB baca docs/00_SakuRapi_Coding_Rules.md sebelum mulai coding.

---

## 🎯 Misi Prompt Ini

Implementasi lapisan keamanan + AI backend untuk fitur Voice dan OCR.
Ini adalah INFRASTRUKTUR yang akan dipakai oleh Prompt 8 (Voice) dan Prompt 9 (OCR).

Fokus prompt ini:
1. Supabase Edge Function sebagai AI proxy aman (Gemini → Groq failover)
2. SSL Pinning di Flutter untuk mencegah MITM attack
3. AIParsingService sebagai satu-satunya pintu komunikasi Flutter → Edge Function

---

## 📐 Konteks Kode yang Sudah Ada

File-file berikut SUDAH ADA di repo dan JANGAN diubah:
- `lib/global/services/ocr_service.dart` — OcrService (Google ML Kit wrapper)
- `lib/global/services/voice_service.dart` — VoiceService (speech_to_text wrapper)
- `lib/global/services/transaction_parser_service.dart` — TransactionParserService (local NLP, tetap dipakai sebagai fallback parsing)

---

## 🗂️ File yang Harus Dibuat

```
# Supabase Edge Function (TypeScript/Deno)
supabase/functions/ai-parse/index.ts

# Flutter — Security & AI Layer
lib/core/security/
└── ssl_pinning_client.dart          -- HttpClient dengan SSL pinning

lib/global/services/
└── ai_parsing_service.dart          -- Service utama: kirim teks ke Edge Function, parse response

lib/global/models/
├── ai_parse_request_model.dart      -- Request payload ke Edge Function
└── ai_parse_response_model.dart     -- Response dari Edge Function
```

---

## 📋 Spesifikasi Detail

### 1. Supabase Edge Function: `supabase/functions/ai-parse/index.ts`

Edge Function ini adalah satu-satunya tempat API Key Gemini dan Groq disimpan.
WAJIB simpan API key via Supabase secrets (bukan hardcode).

```typescript
// Struktur request body dari Flutter:
// {
//   "mode": "voice" | "ocr",
//   "text": "raw text dari STT atau OCR"
// }

// Struktur response sukses:
// MODE VOICE:
// {
//   "success": true,
//   "mode": "voice",
//   "provider": "gemini" | "groq",
//   "data": {
//     "amount": 25000,           // integer, null jika tidak terdeteksi
//     "category_keyword": "makan", // string, null jika tidak terdeteksi
//     "note": "nasi padang",     // string, null jika tidak ada
//     "type": "expense" | "income"
//   }
// }

// MODE OCR:
// {
//   "success": true,
//   "mode": "ocr",
//   "provider": "gemini" | "groq",
//   "data": {
//     "merchant_name": "Indomaret",    // string, null jika tidak ada
//     "date": "2026-03-20",            // format YYYY-MM-DD, null jika tidak ada
//     "grand_total": 75000,            // integer
//     "items": [
//       { "item_name": "Indomie Goreng", "amount": 3500, "category_keyword": "makanan" },
//       { "item_name": "Pajak / Biaya Lain", "amount": 1500, "category_keyword": "pajak" }
//     ]
//   }
// }

// Response error:
// { "success": false, "error": "AI_BUSY" | "INVALID_REQUEST" | "UNAUTHORIZED" }
```

**Implementasi failover logic di Edge Function:**

```typescript
// WAJIB implementasi urutan ini:

// Step 0: Validasi JWT Supabase (auth.uid() harus ada)
// Tolak request tanpa Authorization header yang valid → return 401

// Step 1: Validasi request body (mode & text wajib ada, text max 5000 karakter)

// Step 2: Bangun prompt berdasarkan mode
// Untuk VOICE:
const voicePrompt = `Kamu adalah asisten keuangan. Ekstrak informasi dari teks percakapan berikut.
Kembalikan HANYA JSON murni tanpa markdown, tanpa penjelasan, tanpa komentar.
Format wajib:
{"amount": integer_atau_null, "category_keyword": "string_atau_null", "note": "string_atau_null", "type": "expense_atau_income"}

Aturan:
- amount: nominal dalam angka bulat (contoh: "dua puluh lima ribu" → 25000), null jika tidak ada
- category_keyword: 1 kata kunci kategori dalam bahasa Indonesia (contoh: "makan", "bensin", "belanja"), null jika tidak ada
- note: sisa informasi yang relevan setelah nominal dan kategori diekstrak, null jika tidak ada
- type: "income" jika kata kunci gaji/terima/dapat/masuk ada, default "expense"

Teks: ${text}`;

// Untuk OCR:
const ocrPrompt = `Kamu adalah asisten keuangan. Baca teks struk belanja berikut.
Kembalikan HANYA JSON murni tanpa markdown, tanpa penjelasan, tanpa komentar.
Format wajib:
{"merchant_name": "string_atau_null", "date": "YYYY-MM-DD_atau_null", "grand_total": integer, "items": [{"item_name": "string", "amount": integer, "category_keyword": "string"}]}

Aturan:
- merchant_name: nama toko/merchant dari baris pertama struk, null jika tidak ada
- date: tanggal transaksi format YYYY-MM-DD, null jika tidak ada
- grand_total: nilai TOTAL/GRAND TOTAL/JUMLAH BAYAR terbesar dari struk, 0 jika tidak ada
- items: hanya baris produk/barang yang dibeli, ABAIKAN baris TOTAL/SUBTOTAL/DISKON/KEMBALIAN/TUNAI/PAJAK
- Jika grand_total > sum(items.amount), tambahkan item terakhir: {"item_name": "Pajak / Biaya Lain / Selisih", "amount": selisih, "category_keyword": "pajak"}
- Semua amount dalam integer (bulatkan jika ada desimal)

Teks struk:
${text}`;

// Step 3: Coba Gemini Flash
// Endpoint: https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent
// Timeout: 8 detik
// Jika 200 → parse response → return ke Flutter
// Jika 429 atau timeout → lanjut ke Step 4
// Jika error lain (400, 500) → return { success: false, error: "INVALID_REQUEST" }

// Step 4: Coba Groq (Llama 3.3 70B)
// Endpoint: https://api.groq.com/openai/v1/chat/completions
// Model: "llama-3.3-70b-versatile"
// Timeout: 6 detik
// Jika 200 → parse response → return ke Flutter
// Jika 429 atau timeout → lanjut ke Step 5

// Step 5: Return error AI_BUSY
// { "success": false, "error": "AI_BUSY" }

// PENTING: Response dari Gemini/Groq mungkin masih ada markdown fence.
// WAJIB sanitasi sebelum JSON.parse():
function sanitizeJson(raw: string): string {
  return raw
    .replace(/```json\s*/gi, '')
    .replace(/```\s*/g, '')
    .trim();
}

// Rate limiting per user: max 30 request per jam
// Implementasi sederhana via Supabase KV atau cukup log saja jika belum tersedia
```

---

### 2. SSL Pinning: `lib/core/security/ssl_pinning_client.dart`

```dart
/// HttpClient dengan SSL Certificate Pinning.
///
/// Mencegah MITM attack via proxy (Charles, mitmproxy, Frida).
/// Hanya menerima koneksi ke host yang certificate-nya cocok dengan
/// fingerprint yang sudah di-pin.
///
/// Cara mendapatkan fingerprint Supabase:
/// Jalankan di terminal:
/// openssl s_client -connect <project-ref>.supabase.co:443 </dev/null 2>/dev/null \
///   | openssl x509 -fingerprint -sha256 -noout
///
/// Simpan hasil fingerprint di environment variable atau dart-define,
/// JANGAN hardcode langsung di source code.
class SslPinningClient {
  /// Buat HttpClient dengan pinning aktif untuk host Supabase project.
  ///
  /// [supabaseHost] contoh: 'xyzabcdef.supabase.co'
  /// [allowedSha256Fingerprints] daftar SHA-256 fingerprint yang diizinkan
  ///   (support multiple untuk memungkinkan rotasi certificate)
  static HttpClient create({
    required String supabaseHost,
    required List<String> allowedSha256Fingerprints,
  }) {
    final client = HttpClient();

    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // Hanya pin untuk Supabase host, biarkan host lain lewat normal
      if (host != supabaseHost) return false;

      // Tolak semua certificate untuk Supabase host yang tidak ada di whitelist
      AppLogger.logError(
        '[SSL] Certificate rejected untuk host: $host',
        runtimeType: SslPinningClient,
      );
      return false; // false = tolak = throw exception
    };

    // Override onBadCertificate tidak cukup untuk pinning aktif.
    // Implementasi pinning aktif via SecurityContext:
    // (Catatan: Implementasi penuh fingerprint matching memerlukan
    //  dart:io SecurityContext atau package ssl_pinning_plugin)
    // WAJIB implementasi salah satu dari:
    // Option A: Gunakan package `ssl_pinning_plugin` (recommended untuk produksi)
    // Option B: Custom SecurityContext dengan certificate bytes dari assets

    return client;
  }

  /// Verifikasi apakah SHA-256 fingerprint certificate cocok dengan whitelist.
  static bool _isFingerprintValid(
    X509Certificate cert,
    List<String> allowedFingerprints,
  ) {
    // Hitung SHA-256 fingerprint dari DER-encoded certificate
    final digest = sha256.convert(cert.der);
    final fingerprint = digest.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(':')
        .toUpperCase();

    AppLogger.call(
      '[SSL] Certificate fingerprint: $fingerprint',
      colorLog: ColorLog.blue,
    );

    return allowedFingerprints.any(
      (allowed) => allowed.toUpperCase() == fingerprint,
    );
  }
}
```

**Catatan implementasi SSL Pinning:**
- Gunakan package `ssl_pinning_plugin` atau `http_certificate_pinning` untuk implementasi yang lebih reliable di production
- Fingerprint Supabase WAJIB disimpan via `--dart-define` atau `flutter_dotenv`, BUKAN hardcode di source
- Support minimal 2 fingerprint (current + backup) untuk memungkinkan rotasi certificate tanpa force update app

---

### 3. AI Parse Request/Response Models

#### `lib/global/models/ai_parse_request_model.dart`
```dart
/// Request payload yang dikirim ke Supabase Edge Function /ai-parse.
class AiParseRequestModel {
  const AiParseRequestModel({
    required this.mode,
    required this.text,
  });

  /// Mode parsing: 'voice' atau 'ocr'
  final String mode;

  /// Raw text yang akan di-parse oleh AI
  /// Maksimum 5000 karakter (dibatasi di Edge Function)
  final String text;

  Map<String, dynamic> toMap() => {
    'mode': mode,
    'text': text,
  };
}
```

#### `lib/global/models/ai_parse_response_model.dart`
```dart
/// Response dari Supabase Edge Function /ai-parse.
///
/// Gunakan [isSuccess] untuk cek apakah parsing berhasil.
/// Gunakan [voiceData] untuk mode 'voice', [ocrData] untuk mode 'ocr'.
class AiParseResponseModel {
  // ... implementasi lengkap dengan fromMap(), field success, mode, provider, data
  // Untuk voice data: VoiceParseData(amount, categoryKeyword, note, type)
  // Untuk ocr data: OcrParseData(merchantName, date, grandTotal, items: List<OcrItemData>)
  // Error: errorCode (String: 'AI_BUSY' | 'INVALID_REQUEST' | 'UNAUTHORIZED')
}
```

---

### 4. AI Parsing Service: `lib/global/services/ai_parsing_service.dart`

```dart
/// Service utama untuk komunikasi dengan Supabase Edge Function /ai-parse.
///
/// Menggantikan local NLP [TransactionParserService] dengan AI berbasis LLM.
/// [TransactionParserService] tetap digunakan sebagai FALLBACK jika AI gagal.
///
/// Flow:
/// 1. Kirim request ke /ai-parse via HTTPS (dengan SSL Pinning)
/// 2. Jika sukses → map AiParseResponseModel ke TransactionFormState
/// 3. Jika gagal (AI_BUSY / network error) → fallback ke TransactionParserService
class AIParsingService {
  AIParsingService({
    required this.supabaseClient,   // untuk ambil JWT token user
    required this.parserService,    // TransactionParserService untuk fallback
    required this.httpClient,       // HttpClient dengan SSL pinning
  });

  final SupabaseClient supabaseClient;
  final TransactionParserService parserService;
  final http.Client httpClient;

  static const String _tag = 'AIParser';
  static const String _edgeFunctionPath = '/functions/v1/ai-parse';
  static const Duration _requestTimeout = Duration(seconds: 20);

  /// Parse teks dari voice input menggunakan AI.
  ///
  /// Mengembalikan [TransactionFormState] yang siap diisi ke form transaksi.
  /// Jika AI gagal, fallback ke [TransactionParserService.parseVoiceInput].
  Future<TransactionFormState> parseVoiceText(
    String rawText,
    List<ParsingKeywordModel> dictionary,
  ) async {
    AppLogger.call(
      '[$_tag] parseVoiceText: "${rawText.substring(0, min(50, rawText.length))}..."',
      colorLog: ColorLog.blue,
    );

    try {
      final response = await _callEdgeFunction(
        mode: 'voice',
        text: rawText,
      );

      if (response.isSuccess && response.voiceData != null) {
        AppLogger.call(
          '[$_tag] AI voice parse sukses via ${response.provider}',
          colorLog: ColorLog.green,
        );
        return _mapVoiceResponseToFormState(response.voiceData!, dictionary);
      }

      // AI_BUSY atau response tidak valid → fallback
      AppLogger.call(
        '[$_tag] AI tidak tersedia (${response.errorCode}), fallback ke local NLP',
        colorLog: ColorLog.yellow,
      );
      return parserService.parseVoiceInput(rawText, dictionary);

    } catch (e) {
      AppLogger.logError(
        '[$_tag] Exception saat AI parse voice: $e',
        runtimeType: AIParsingService,
      );
      // Network error → fallback ke local NLP
      return parserService.parseVoiceInput(rawText, dictionary);
    }
  }

  /// Parse teks dari OCR struk menggunakan AI.
  ///
  /// Mengembalikan [TransactionFormState] multi-item siap diisi ke form.
  /// Jika AI gagal, fallback ke [TransactionParserService.parseOcrText].
  Future<TransactionFormState> parseOcrText(
    String rawText,
    List<ParsingKeywordModel> dictionary, {
    String? attachmentPath,
  }) async {
    // ... implementasi serupa dengan parseVoiceText
    // Fallback ke parserService.parseOcrText() jika AI gagal
  }

  /// Internal: kirim request ke Supabase Edge Function.
  ///
  /// Header wajib:
  /// - Authorization: Bearer {jwt_token_user}  ← dari supabaseClient.auth.currentSession
  /// - Content-Type: application/json
  Future<AiParseResponseModel> _callEdgeFunction({
    required String mode,
    required String text,
  }) async {
    final session = supabaseClient.auth.currentSession;
    if (session == null) {
      throw Exception('User tidak terautentikasi');
    }

    final url = Uri.parse(
      '${Supabase.instance.client.supabaseUrl}$_edgeFunctionPath',
    );

    final requestBody = AiParseRequestModel(mode: mode, text: text).toMap();

    AppLogger.call(
      '[$_tag] POST $_edgeFunctionPath (mode: $mode, length: ${text.length})',
      colorLog: ColorLog.blue,
    );

    final httpResponse = await httpClient
        .post(
          url,
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(_requestTimeout);

    AppLogger.call(
      '[$_tag] Response status: ${httpResponse.statusCode}',
      colorLog: httpResponse.statusCode == 200 ? ColorLog.green : ColorLog.red,
    );

    if (httpResponse.statusCode == 401) {
      throw Exception('Unauthorized: JWT tidak valid');
    }

    return AiParseResponseModel.fromMap(jsonDecode(httpResponse.body));
  }

  /// Map VoiceParseData dari AI ke TransactionFormState.
  ///
  /// Category keyword dari AI dicocokkan ke dictionary Hive lokal.
  /// Jika tidak cocok → categoryId = null (form akan tampilkan placeholder).
  TransactionFormState _mapVoiceResponseToFormState(
    VoiceParseData data,
    List<ParsingKeywordModel> dictionary,
  ) {
    // Matching strategy:
    // Level 1: Exact match (data.categoryKeyword == entry.keyword)
    // Level 2: Contains match (entry.keyword.contains(data.categoryKeyword))
    // Level 3: Fallback → categoryId = null
    final category = _matchCategory(data.categoryKeyword, dictionary);

    return TransactionFormState(
      type: data.type ?? 'expense',
      date: DateTime.now(),
      prefillSource: 'voice_ai',
      note: data.note,
      items: [
        TransactionItemFormState(
          amount: data.amount?.toDouble(),
          categoryId: category?.categoryId,
          categoryName: category?.categoryName,
          categoryColor: category?.categoryColor,
          categoryIcon: category?.categoryIcon,
          note: data.note,
        ),
      ],
    );
  }

  /// Cocokkan category_keyword dari AI dengan dictionary Hive lokal.
  ///
  /// Level 1: Exact match
  /// Level 2: Contains match (dictionary entry mengandung keyword AI)
  /// Level 3: Reverse contains (keyword AI mengandung dictionary entry)
  /// Level 4: null → form kosong, user isi sendiri
  ParsingKeywordModel? _matchCategory(
    String? keyword,
    List<ParsingKeywordModel> dictionary,
  ) {
    if (keyword == null || keyword.isEmpty) return null;
    final lowerKeyword = keyword.toLowerCase();

    // Level 1: Exact
    final exact = dictionary.where(
      (e) => e.keyword.toLowerCase() == lowerKeyword,
    ).firstOrNull;
    if (exact != null) return exact;

    // Level 2: Dictionary entry contains AI keyword
    final contains = dictionary.where(
      (e) => e.keyword.toLowerCase().contains(lowerKeyword),
    ).firstOrNull;
    if (contains != null) return contains;

    // Level 3: AI keyword contains dictionary entry
    final reverseContains = dictionary.where(
      (e) => lowerKeyword.contains(e.keyword.toLowerCase()),
    ).firstOrNull;
    if (reverseContains != null) return reverseContains;

    return null; // Level 4: tidak cocok
  }
}
```

---

## ✅ Checklist Selesai

### Supabase Edge Function
- [ ] JWT validation — tolak request tanpa auth header yang valid
- [ ] Prompt VOICE: instruksi JSON murni, 4 field (amount, category_keyword, note, type)
- [ ] Prompt OCR: instruksi JSON murni, auto-balance item selisih, abaikan baris TOTAL/DISKON/KEMBALIAN
- [ ] Failover: Gemini Flash (timeout 8s) → Groq Llama 3.3 (timeout 6s) → error AI_BUSY
- [ ] sanitizeJson() membersihkan markdown fence sebelum JSON.parse()
- [ ] Response selalu dalam format { success, mode, provider, data } atau { success: false, error }
- [ ] API Key hanya di Supabase secrets, TIDAK hardcode

### Flutter Security
- [ ] SslPinningClient menggunakan fingerprint dari --dart-define (bukan hardcode)
- [ ] Support minimal 2 fingerprint untuk rotasi certificate
- [ ] Fingerprint Supabase didokumentasikan cara mendapatkannya

### Flutter AIParsingService
- [ ] Authorization header menggunakan JWT dari supabaseClient.auth.currentSession
- [ ] Timeout request: 20 detik total
- [ ] Fallback ke TransactionParserService jika AI gagal (AI_BUSY, network error, exception)
- [ ] Category matching: exact → contains → reverse contains → null
- [ ] prefillSource = 'voice_ai' (voice) atau 'ocr_ai' (ocr) untuk tracking
- [ ] Semua log menggunakan AppLogger.call dengan tag [AIParser]
```

---

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