import 'dart:io';
import 'dart:typed_data';

import 'package:app_saku_rapi/core/extensions/file_path_sanitizer_ext.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class CompressImageFunc {
  static Future<Uint8List?> call({
    required String filePath,
    int targetSizeKb = 200,
  }) async {
    // Ubah target dari KB ke Bytes
    int targetSizeBytes = targetSizeKb * 1024;
    Uint8List imageBytes;

    // Baca file aslinya ke dalam bentuk bytes di memori (RAM)
    if (filePath.startsWith('content://')) {
      // Kalau filePath adalah URI konten, kita harus pakai metode khusus untuk membacanya
      final uri = Uri.parse(filePath);
      final file = File(uri.toFilePath());
      imageBytes = await file.readAsBytes();
    } else {
      // Kalau filePath adalah path biasa, langsung baca
      imageBytes = await File(filePath.extToSanitizedFilePath).readAsBytes();
    }

    // 1. Cek ukuran awal. Kalau dari awal sudah <= 200KB, langsung kembalikan aslinya.
    if (imageBytes.lengthInBytes <= targetSizeBytes) {
      return imageBytes;
    }

    int quality = 90; // Kualitas awal
    Uint8List? compressedBytes = imageBytes;

    // 2. Looping: Selama ukurannya masih di atas target DAN kualitas belum terlalu hancur (> 10)
    while (compressedBytes!.lengthInBytes > targetSizeBytes && quality > 10) {
      // Kita pakai compressWithList supaya prosesnya cuma terjadi di memori (RAM),
      // nggak nulis ke penyimpanan HP berulang kali yang bikin lambat.
      compressedBytes = await FlutterImageCompress.compressWithList(
        imageBytes, // Selalu kompres dari file asli agar kualitas nggak degradasi ganda
        minHeight:
            1080, // Batasi resolusi maksimal. Ini ngaruh banget nurunin size!
        minWidth: 1080,
        quality: quality,
      );

      // Turunkan kualitas pelan-pelan untuk percobaan looping berikutnya (jika masih kebesaran)
      quality -= 15;
    }

    return compressedBytes;
  }

  static Future<Uint8List?> callBytes({
    required Uint8List imageBytes,
    int targetSizeKb = 200,
  }) async {
    // Ubah target dari KB ke Bytes
    int targetSizeBytes = targetSizeKb * 1024;

    // 1. Cek ukuran awal. Kalau dari awal sudah <= 200KB, langsung kembalikan aslinya.
    if (imageBytes.lengthInBytes <= targetSizeBytes) {
      return imageBytes;
    }

    int quality = 90; // Kualitas awal
    Uint8List? compressedBytes = imageBytes;

    // 2. Looping: Selama ukurannya masih di atas target DAN kualitas belum terlalu hancur (> 10)
    while (compressedBytes!.lengthInBytes > targetSizeBytes && quality > 10) {
      // Kita pakai compressWithList supaya prosesnya cuma terjadi di memori (RAM),
      // nggak nulis ke penyimpanan HP berulang kali yang bikin lambat.
      compressedBytes = await FlutterImageCompress.compressWithList(
        imageBytes, // Selalu kompres dari file asli agar kualitas nggak degradasi ganda
        minHeight:
            1080, // Batasi resolusi maksimal. Ini ngaruh banget nurunin size!
        minWidth: 1080,
        quality: quality,
      );

      // Turunkan kualitas pelan-pelan untuk percobaan looping berikutnya (jika masih kebesaran)
      quality -= 15;
    }

    return compressedBytes;
  }
}
