import 'dart:io';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Wrapper service untuk Google ML Kit Text Recognition.
///
/// Mengekstrak raw text dari gambar (foto struk, nota, dll).
/// Harus di-[dispose] setelah selesai digunakan.
class OcrService {
  static const String _tag = 'OcrScan';

  final TextRecognizer _recognizer = TextRecognizer();

  /// Ekstrak seluruh teks dari file gambar.
  ///
  /// Mengembalikan string gabungan dari semua blok teks yang dikenali,
  /// dipisahkan oleh newline.
  Future<String> extractText(File imageFile) async {
    AppLogger.call(
      '[$_tag] Memulai OCR pada: ${imageFile.path}',
      colorLog: ColorLog.blue,
    );

    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _recognizer.processImage(inputImage);

    AppLogger.call(
      '[$_tag] Teks terdeteksi: ${recognizedText.text.length} karakter, '
      '${recognizedText.blocks.length} blok',
      colorLog: ColorLog.green,
    );

    return recognizedText.text;
  }

  /// Dispose resources ML Kit.
  void dispose() {
    _recognizer.close();
  }
}
