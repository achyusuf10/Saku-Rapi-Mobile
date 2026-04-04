import 'dart:io';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/category/controllers/category_controller.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/ocr/models/ocr_parse_result_model.dart';
import 'package:app_saku_rapi/features/ocr/repositories/ocr_repository.dart';
import 'package:app_saku_rapi/features/ocr/services/ocr_image_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ═══════════════ Providers ═══════════════

/// Singleton provider untuk [OcrRepository].
final ocrRepositoryProvider = Provider<OcrRepository>((ref) => OcrRepository());

/// Singleton provider untuk [OcrImageService].
final ocrImageServiceProvider = Provider<OcrImageService>((ref) {
  final service = OcrImageService();
  ref.onDispose(service.dispose);
  return service;
});

/// Auto-dispose controller provider untuk OCR scan flow.
final ocrScanControllerProvider =
    StateNotifierProvider.autoDispose<OcrScanController, OcrScanState>(
      (ref) => OcrScanController(
        repository: ref.watch(ocrRepositoryProvider),
        imageService: ref.watch(ocrImageServiceProvider),
        categories: ref
            .read(categoryControllerProvider)
            .categories
            .where((c) => !c.isHidden && c.type != CategoryType.system)
            .toList(),
      ),
    );

// ═══════════════ State ═══════════════

/// Status flow OCR scan.
enum OcrScanStatus {
  /// Belum mulai — menunggu user pilih sumber gambar.
  idle,

  /// Mengambil gambar dari kamera/galeri.
  pickingImage,

  /// Crop gambar.
  cropping,

  /// Mengekstrak teks dari gambar (ML Kit).
  extractingText,

  /// Mengirim ke AI untuk parsing.
  analyzingAi,

  /// Selesai — hasil sudah tersedia.
  done,

  /// Error terjadi.
  error,

  /// Izin kamera ditolak.
  permissionDenied,
}

/// Immutable state untuk OCR scan flow.
class OcrScanState {
  const OcrScanState({
    this.status = OcrScanStatus.idle,
    this.imageFile,
    this.rawOcrText,
    this.parseResult,
    this.errorMessage,
    this.isPermanentlyDenied = false,
  });

  final OcrScanStatus status;

  /// File gambar yang diambil (setelah crop/compress).
  final File? imageFile;

  /// Teks mentah hasil ML Kit OCR.
  final String? rawOcrText;

  /// Hasil parsing terstruktur.
  final OcrParseResultModel? parseResult;

  /// Pesan error.
  final String? errorMessage;

  /// Apakah izin ditolak permanen.
  final bool isPermanentlyDenied;

  OcrScanState copyWith({
    OcrScanStatus? status,
    File? imageFile,
    String? rawOcrText,
    OcrParseResultModel? parseResult,
    String? errorMessage,
    bool? isPermanentlyDenied,
  }) {
    return OcrScanState(
      status: status ?? this.status,
      imageFile: imageFile ?? this.imageFile,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      parseResult: parseResult ?? this.parseResult,
      errorMessage: errorMessage ?? this.errorMessage,
      isPermanentlyDenied: isPermanentlyDenied ?? this.isPermanentlyDenied,
    );
  }
}

// ═══════════════ Controller ═══════════════

/// Controller untuk OCR scan flow.
///
/// Mengelola pipeline:
/// 1. Permission check
/// 2. Image pick (camera/gallery)
/// 3. Image crop
/// 4. Image compress + ML Kit OCR
/// 5. AI parse (Edge Function) → local fallback
/// 6. Result review
class OcrScanController extends StateNotifier<OcrScanState> {
  OcrScanController({
    required OcrRepository repository,
    required OcrImageService imageService,
    List<CategoryModel> categories = const [],
  }) : _repository = repository,
       _imageService = imageService,
       _categories = categories,
       super(const OcrScanState());

  final OcrRepository _repository;
  final OcrImageService _imageService;
  final List<CategoryModel> _categories;
  static const _tag = '[OcrScanController]';

  /// Mulai flow OCR dari kamera.
  Future<void> startFromCamera(BuildContext context) async {
    // Check permission
    final perm = await _imageService.requestCameraPermission();
    if (perm == CameraPermissionResult.denied) {
      state = const OcrScanState(status: OcrScanStatus.permissionDenied);

      return;
    }
    if (perm == CameraPermissionResult.permanentlyDenied) {
      state = const OcrScanState(
        status: OcrScanStatus.permissionDenied,
        isPermanentlyDenied: true,
      );
      return;
    }

    state = state.copyWith(status: OcrScanStatus.pickingImage);

    final imageFile = await _imageService.pickFromCamera();
    if (imageFile == null) {
      // User cancelled
      state = const OcrScanState(status: OcrScanStatus.idle);
      return;
    }

    await _processImage(context, imageFile);
  }

  /// Mulai flow OCR dari galeri.
  Future<void> startFromGallery(BuildContext context) async {
    state = state.copyWith(status: OcrScanStatus.pickingImage);

    final imageFile = await _imageService.pickFromGallery();
    if (imageFile == null) {
      state = const OcrScanState(status: OcrScanStatus.idle);
      return;
    }

    await _processImage(context, imageFile);
  }

  /// Proses gambar: crop → compress → AI Vision → (fallback) ML Kit → local parser.
  Future<void> _processImage(BuildContext context, File imageFile) async {
    // Crop
    state = state.copyWith(status: OcrScanStatus.cropping);
    final cropped = await _imageService.cropImage(context, imageFile);
    if (cropped == null) {
      // User cancelled crop
      state = const OcrScanState(status: OcrScanStatus.idle);
      return;
    }

    // Compress (target 500KB agar transfer ke AI lebih cepat)
    final compressed = await _imageService.compressImage(cropped);
    final finalImage = compressed ?? cropped;
    state = state.copyWith(imageFile: finalImage);

    // Kirim gambar ke Vision AI (Gemini → Groq failover)
    state = state.copyWith(status: OcrScanStatus.analyzingAi);
    OcrParseResultModel result;

    // Siapkan daftar kategori (expense + income) untuk AI categorization
    final categoryMaps = _categories
        .map(
          (c) => {
            'id': c.id,
            'name': c.name,
            'type': c.type == CategoryType.income ? 'income' : 'expense',
          },
        )
        .toList();

    try {
      result = await _repository.parseImage(
        finalImage,
        categories: categoryMaps,
      );
    } catch (aiError) {
      // Kedua AI gagal → fallback ke ML Kit OCR + local parser
      AppLogger.call(
        '$_tag Vision AI failed ($aiError), falling back to ML Kit OCR',
      );

      state = state.copyWith(status: OcrScanStatus.extractingText);
      final rawText = await _imageService.extractText(finalImage);

      if (rawText == null || rawText.isEmpty) {
        state = state.copyWith(
          status: OcrScanStatus.error,
          errorMessage: 'NO_TEXT',
        );
        return;
      }

      state = state.copyWith(rawOcrText: rawText);
      result = _repository.parseTextLocally(rawText);
    }

    // Handle gambar bukan transaksi
    if (!result.isTransaction) {
      state = state.copyWith(
        status: OcrScanStatus.error,
        parseResult: result,
        errorMessage: 'NOT_TRANSACTION',
      );
      return;
    }

    if (!result.hasUsableData) {
      state = state.copyWith(
        status: OcrScanStatus.error,
        parseResult: result,
        errorMessage: 'PARSE_FAILED',
      );
      return;
    }

    AppLogger.logSuccess(
      'OCR pipeline complete: type=${result.type}, ${result.items.length} items, '
      'total: ${result.grandTotal}, provider: ${result.provider}',
      runtimeType: OcrScanController,
    );

    state = state.copyWith(status: OcrScanStatus.done, parseResult: result);
  }

  /// Rescan — reset state dan mulai ulang.
  void reset() {
    state = const OcrScanState();
  }

  /// Buka system settings untuk izin yang ditolak permanen.
  Future<void> openSettings() async {
    await _imageService.openSystemSettings();
  }
}
