import 'dart:io';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/ocr/datasource/ocr_remote_data_source.dart';
import 'package:app_saku_rapi/features/ocr/models/ocr_parse_result_model.dart';

/// Repository untuk fitur OCR Receipt.
///
/// Pipeline:
/// 1. Kirim gambar ke Vision AI (Gemini)
/// 2. Jika AI gagal → lempar exception ke controller (tampilkan error + retry)
///
/// Selisih jumlah item vs grand total struk tidak dikoreksi otomatis di sini;
/// mismatch hanya ditampilkan sebagai peringatan di preview hasil scan.
class OcrRepository {
  OcrRepository({OcrRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? OcrRemoteDataSource();

  final OcrRemoteDataSource _remoteDataSource;
  static const _tag = '[OcrRepository]';

  /// Kirim gambar struk ke Vision AI untuk parsing terstruktur.
  ///
  /// [categories] berisi daftar kategori expense user ({id, name, type, is_default})
  /// yang dikirim ke AI agar bisa auto-assign kategori per item.
  /// [wallets] berisi daftar wallet user ({id, name}) untuk auto-match.
  /// Throws [Exception] jika AI gagal — controller akan tampilkan error + retry.
  Future<OcrParseResultModel> parseImage(
    File imageFile, {
    List<Map<String, dynamic>> categories = const [],
    List<Map<String, String>> wallets = const [],
  }) async {
    final aiResult = await _remoteDataSource.callAiParseImage(
      imageFile,
      categories: categories,
      wallets: wallets,
    );

    if (aiResult.isSuccess()) {
      final data = aiResult.dataSuccess()!;
      AppLogger.logSuccess(
        'OCR Vision AI success Data: $data',
        runtimeType: OcrRepository,
      );
      return OcrParseResultModel.fromEdgeFunctionMap(data);
    }

    final errorMsg = aiResult.dataError()?.toString() ?? 'AI_BUSY';
    AppLogger.call('$_tag AI failed: $errorMsg');
    throw Exception(errorMsg);
  }
}
