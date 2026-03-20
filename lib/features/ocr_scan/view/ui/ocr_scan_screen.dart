import 'dart:io';

import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/ocr_scan/view/widgets/ocr_result_preview_widget.dart';
import 'package:app_saku_rapi/features/ocr_scan/view/widgets/ocr_source_picker_sheet.dart';
import 'package:app_saku_rapi/features/parsing_dictionary/controllers/parsing_dictionary_controller.dart';
import 'package:app_saku_rapi/global/services/ocr_service.dart';
import 'package:app_saku_rapi/global/services/transaction_parser_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// Screen utama fitur OCR Scan Struk.
///
/// Flow:
/// 1. Langsung buka [OcrSourcePickerSheet] (Kamera / Galeri)
/// 2. User ambil / pilih foto
/// 3. Crop via [ImageCropper]
/// 4. OCR via [OcrService]
/// 5. Parse via [TransactionParserService]
/// 6. Preview via [OcrResultPreviewWidget]
/// 7. Navigate ke TransactionFormScreen (pre-filled multi-item)
class OcrScanScreen extends ConsumerStatefulWidget {
  const OcrScanScreen({super.key});

  @override
  ConsumerState<OcrScanScreen> createState() => _OcrScanScreenState();
}

class _OcrScanScreenState extends ConsumerState<OcrScanScreen> {
  static const String _tag = 'OcrScan';

  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();
  final TransactionParserService _parserService = TransactionParserService();

  @override
  void initState() {
    super.initState();
    // Buka picker setelah frame pertama selesai render
    WidgetsBinding.instance.addPostFrameCallback((_) => _openSourcePicker());
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────
  // Flow
  // ─────────────────────────────────────────────────────

  /// Step 1: Buka bottom sheet pemilih sumber (Kamera / Galeri).
  Future<void> _openSourcePicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const OcrSourcePickerSheet(),
    );

    if (!mounted) return;

    if (source == null) {
      // User batal → kembali ke screen sebelumnya
      context.pop();
      return;
    }

    await _pickAndProcess(source);
  }

  /// Step 2-6: Pilih foto → Crop → OCR → Parse → Preview.
  Future<void> _pickAndProcess(ImageSource source) async {
    // 2. Ambil foto
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 90,
    );

    if (!mounted) return;
    if (picked == null) {
      context.pop();
      return;
    }

    // 3. Crop
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: context.l10n.ocrCropInstruction,
          toolbarColor: Theme.of(context).colorScheme.primary,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: context.l10n.ocrCropInstruction),
      ],
    );

    if (!mounted) return;
    if (croppedFile == null) {
      // User batal crop → kembali ke picker
      _openSourcePicker();
      return;
    }

    // 4. OCR + Parse
    context.showLoadingOverlay();

    try {
      final imageFile = File(croppedFile.path);
      final rawText = await _ocrService.extractText(imageFile);

      if (!mounted) return;

      if (rawText.trim().isEmpty) {
        context.closeOverlay();
        context.showAppAlert(context.l10n.ocrNoText);
        _openSourcePicker();
        return;
      }

      // 5. Parse
      final dictionary =
          ref.read(parsingDictionaryControllerProvider).value ?? [];
      final result = _parserService.parseOcrText(rawText, dictionary);

      context.closeOverlay();

      // 6. Preview
      _showResultPreview(result, croppedFile.path);
    } catch (e) {
      if (mounted) context.closeOverlay();
      AppLogger.logError(
        '[$_tag] OCR/Parse error: $e',
        runtimeType: OcrScanScreen,
      );
      if (mounted) {
        context.showAppAlert(context.l10n.ocrNoText);
        _openSourcePicker();
      }
    }
  }

  /// Step 7: Tampilkan preview hasil parsing.
  void _showResultPreview(OcrParseResult result, String imagePath) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OcrResultPreviewWidget(
        result: result,
        onContinue: () {
          // Dismiss preview
          Navigator.of(context).pop();
          _navigateToForm(result, imagePath);
        },
        onRescan: () {
          // Dismiss preview, re-open picker
          Navigator.of(context).pop();
          _openSourcePicker();
        },
      ),
    );
  }

  /// Step 8: Navigate ke TransactionFormScreen dengan data pre-filled.
  void _navigateToForm(OcrParseResult result, String imagePath) {
    final formState = _parserService.ocrResultToFormState(result, imagePath);

    AppLogger.call(
      '[$_tag] Navigating to form: ${formState.items.length} items, '
      'merchant=${formState.merchantName}',
      colorLog: ColorLog.green,
    );

    // Replace OCR screen dengan form screen
    context.pushReplacement(AppRouter.transactionForm, extra: formState);
  }

  // ─────────────────────────────────────────────────────
  // Build — Transparent screen (semua aksi via overlays)
  // ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    return Scaffold(
      backgroundColor: appColors.background,
      body: const SizedBox.shrink(),
    );
  }
}
