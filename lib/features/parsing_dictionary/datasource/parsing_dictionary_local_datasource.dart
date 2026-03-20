import 'dart:convert';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/parsing_dictionary/models/parsing_keyword_model.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';

/// Local data source untuk cache kamus parsing di Hive.
///
/// Menyimpan daftar [ParsingKeywordModel] dan timestamp terakhir fetch.
/// TTL default: 24 jam. Jika cache expired, repository akan fetch ulang
/// dari Supabase.
class ParsingDictionaryLocalDataSource {
  static const String _tag = 'ParsingDict';
  static const String _keyData = 'parsing_dict_data';
  static const String _keyLastFetch = 'parsing_dict_last_fetch';
  static const int _ttlHours = 24;

  /// Cek apakah cache sudah expired (> 24 jam sejak terakhir fetch).
  bool isCacheExpired() {
    final lastFetch = HiveService.get<int>(key: _keyLastFetch);
    if (lastFetch == null) return true;

    final lastFetchTime = DateTime.fromMillisecondsSinceEpoch(lastFetch);
    final now = DateTime.now();
    return now.difference(lastFetchTime).inHours >= _ttlHours;
  }

  /// Ambil kamus dari cache Hive.
  ///
  /// Return list kosong jika tidak ada cache.
  List<ParsingKeywordModel> getCachedDictionary() {
    final raw = HiveService.get<String>(key: _keyData);
    if (raw == null) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final result = list
          .cast<Map<String, dynamic>>()
          .map(ParsingKeywordModel.fromMap)
          .toList();

      AppLogger.call(
        '[$_tag] Cache loaded: ${result.length} keywords',
        colorLog: ColorLog.green,
      );
      return result;
    } catch (e) {
      AppLogger.logError('[$_tag] Error parsing cache: $e');
      return [];
    }
  }

  /// Simpan kamus ke cache Hive bersama timestamp sekarang.
  void saveDictionary(List<ParsingKeywordModel> data) {
    final jsonList = data.map((e) => e.toMap()).toList();
    HiveService.set<String>(key: _keyData, data: jsonEncode(jsonList));
    HiveService.set<int>(
      key: _keyLastFetch,
      data: DateTime.now().millisecondsSinceEpoch,
    );

    AppLogger.call(
      '[$_tag] Cache saved: ${data.length} keywords',
      colorLog: ColorLog.green,
    );
  }

  /// Hapus cache (force refresh di fetch berikutnya).
  void clearCache() {
    HiveService.delete(_keyData);
    HiveService.delete(_keyLastFetch);
  }
}
