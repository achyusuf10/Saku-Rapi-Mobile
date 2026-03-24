import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/ocr/datasource/ocr_remote_data_source.dart';
import 'package:app_saku_rapi/features/ocr/models/ocr_parse_result_model.dart';
import 'package:app_saku_rapi/features/ocr/services/ocr_local_parser.dart';

/// Repository untuk fitur OCR Receipt.
///
/// Orkestrator utama yang menangani:
/// 1. Panggilan AI Edge Function (Gemini → Groq failover)
/// 2. Local fallback jika AI gagal
/// 3. Balancing items vs grand total
class OcrRepository {
  OcrRepository({OcrRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? OcrRemoteDataSource();

  final OcrRemoteDataSource _remoteDataSource;
  static const _tag = '[OcrRepository]';

  /// Parse teks OCR via AI Edge Function, fallback lokal jika gagal.
  ///
  /// Pipeline: Edge Function AI → local regex parser.
  Future<OcrParseResultModel> parseOcrText(String ocrText) async {
    // 1. Try AI Edge Function
    final aiResult = await _remoteDataSource.callAiParse(ocrText);

    if (aiResult.isSuccess()) {
      final data = aiResult.dataSuccess()!;
      AppLogger.logSuccess('OCR AI parse success', runtimeType: OcrRepository);
      return OcrParseResultModel.fromEdgeFunctionMap(data, rawOcrText: ocrText);
    }

    // 2. AI failed → local fallback
    AppLogger.call('$_tag AI failed, falling back to local parser');
    return _localFallback(ocrText);
  }

  /// Local fallback parser menggunakan regex.
  OcrParseResultModel _localFallback(String ocrText) {
    AppLogger.call('$_tag Using local OCR parser');
    return OcrLocalParser.parse(ocrText);
  }

  /// Balancing: jika total items != grandTotal, tambahkan item selisih.
  ///
  /// Ini sesuai PRD edge case: subtotal dan total tidak sinkron.
  /// Return [OcrParseResultModel] yang sudah balanced.
  static OcrParseResultModel balanceResult(OcrParseResultModel result) {
    if (result.grandTotal == null || result.grandTotal! <= 0) return result;
    if (result.items.isEmpty) return result;

    final diff = result.grandTotal! - result.itemsTotal;
    if (diff.abs() < 1) return result; // Already balanced

    // Jika selisih > 0, berarti ada item yang tidak terdeteksi
    // Jika selisih < 0, berarti items sum > total (mungkin ada diskon)
    // Tambahkan item selisih agar total match
    final balanceItem = OcrItemModel(
      name: diff > 0 ? 'Item lainnya' : 'Diskon/potongan',
      qty: 1,
      subtotal: diff,
    );

    return result.copyWith(items: [...result.items, balanceItem]);
  }
}
