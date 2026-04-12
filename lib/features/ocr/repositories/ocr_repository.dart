import 'dart:io';

import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/ocr/datasource/ocr_remote_data_source.dart';
import 'package:app_saku_rapi/features/ocr/models/ocr_parse_result_model.dart';

/// Repository untuk fitur OCR Receipt.
///
/// Pipeline:
/// 1. Kirim gambar ke Vision AI (Gemini)
/// 2. Jika AI gagal → lempar exception ke controller (tampilkan error)
/// 3. Balancing items vs grand total
class OcrRepository {
  OcrRepository({OcrRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? OcrRemoteDataSource();

  final OcrRemoteDataSource _remoteDataSource;
  static const _tag = '[OcrRepository]';

  /// Kirim gambar struk ke Vision AI untuk parsing terstruktur.
  ///
  /// [categories] berisi daftar kategori expense user ({id, name})
  /// yang dikirim ke AI agar bisa auto-assign kategori per item.
  /// Throws [Exception] jika AI gagal — controller akan tampilkan error + retry.
  Future<OcrParseResultModel> parseImage(
    File imageFile, {
    List<Map<String, String>> categories = const [],
  }) async {
    final aiResult = await _remoteDataSource.callAiParseImage(
      imageFile,
      categories: categories,
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

  /// Balancing: jika total items != grandTotal, tambahkan item selisih.
  ///
  /// Hanya berlaku untuk expense type (yang punya items).
  /// Ini sesuai PRD edge case: subtotal dan total tidak sinkron.
  /// Return [OcrParseResultModel] yang sudah balanced.
  static OcrParseResultModel balanceResult(OcrParseResultModel result) {
    // Hanya balance untuk expense yang punya items
    if (result.type != 'expense') return result;
    if (result.grandTotal == null || result.grandTotal! <= 0) return result;
    if (result.items.isEmpty) return result;

    final diff = result.grandTotal! - result.itemsTotal;
    if (diff.abs() < 1) return result; // Already balanced

    // Jika selisih > 0, berarti ada item yang tidak terdeteksi
    // Jika selisih < 0, berarti items sum > total (mungkin ada diskon)
    // Tambahkan item selisih agar total match
    final balanceItem = OcrItemModel(
      name: diff > 0
          ? (appContext?.l10n.ocrBalanceItem ?? 'Item lainnya')
          : (appContext?.l10n.ocrDiscountItem ?? 'Diskon/potongan'),
      qty: 1,
      subtotal: diff,
    );

    return result.copyWith(items: [...result.items, balanceItem]);
  }
}
