import 'dart:io';
import 'dart:ui' as ui;

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/utils/function/compress_image_func.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Hasil pengecekan izin kamera.
enum CameraPermissionResult { granted, denied, permanentlyDenied }

/// Service untuk image acquisition dan compression untuk OCR.
///
/// Menangani:
/// 1. Camera/gallery permission check
/// 2. Image picking (camera/gallery)
/// 3. Image cropping
/// 4. Image compression
class OcrImageService {
  static const _tag = '[OcrImageService]';

  final _picker = ImagePicker();

  /// Cek dan minta izin kamera.
  Future<CameraPermissionResult> requestCameraPermission() async {
    return CameraPermissionResult.granted;
    final status = await Permission.camera.request();
    AppLogger.call('$_tag Camera permission: $status');

    if (status.isGranted || status.isLimited) {
      return CameraPermissionResult.granted;
    }
    if (status.isPermanentlyDenied) {
      return CameraPermissionResult.permanentlyDenied;
    }
    return CameraPermissionResult.denied;
  }

  /// Pick image dari kamera.
  Future<File?> pickFromCamera() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );
    if (xFile == null) return null;
    return File(xFile.path);
  }

  /// Pick image dari galeri.
  Future<File?> pickFromGallery() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (xFile == null) return null;
    return File(xFile.path);
  }

  /// Crop image untuk memfokuskan area struk.
  Future<File?> cropImage(BuildContext context, File imageFile) async {
    if (!context.mounted) return null;

    final result = await showAdaptiveImageCropper(
      appContext ?? context,
      imageProvider: FileImage(imageFile),
    );
    if (result == null) return null;

    // Export hasil crop ke bytes PNG
    final byteData = await result.uiImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) return null;

    final tempFile = File(
      '${imageFile.parent.path}/ocr_cropped_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await tempFile.writeAsBytes(byteData.buffer.asUint8List());
    return tempFile;
  }

  /// Compress image ke ukuran optimal untuk OCR.
  ///
  /// Target 500KB agar transfer ke AI lebih cepat.
  Future<File?> compressImage(File imageFile) async {
    final bytes = await CompressImageFunc.call(filePath: imageFile.path);
    if (bytes == null) return null;

    // Tulis ke file temporary
    final tempFile = File(
      '${imageFile.parent.path}/ocr_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }

  /// Buka pengaturan sistem untuk izin yang ditolak permanen.
  Future<void> openSystemSettings() async {
    await openAppSettings();
  }

  /// Dispose resources.
  void dispose() {}
}
