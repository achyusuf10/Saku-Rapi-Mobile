import 'dart:convert';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/voice/models/parsing_dictionary_model.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';

/// Local data source untuk cache parsing dictionaries (Hive).
///
/// Cache TTL: 24 jam (PRD §7.7).
class VoiceLocalDataSource {
  static const _tag = '[Voice] [VoiceLocalDataSource]';
  static const _cacheKey = 'cached_parsing_dictionaries';
  static const _cacheTimestampKey = 'cached_parsing_dictionaries_ts';

  /// TTL cache 24 jam dalam milliseconds.
  static const _cacheTtlMs = 24 * 60 * 60 * 1000;

  /// Simpan dictionaries ke cache lokal.
  void cacheDictionaries(List<ParsingDictionaryModel> dictionaries) {
    AppLogger.call('$_tag cacheDictionaries: ${dictionaries.length} entries');
    final jsonList = dictionaries.map((e) => e.toMap()).toList();
    HiveService.set<String>(key: _cacheKey, data: jsonEncode(jsonList));
    HiveService.set<int>(
      key: _cacheTimestampKey,
      data: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Ambil dictionaries dari cache lokal.
  ///
  /// Returns `null` jika cache expired (>24 jam) atau tidak ada.
  List<ParsingDictionaryModel>? getCachedDictionaries() {
    final raw = HiveService.get<String>(key: _cacheKey);
    if (raw == null) return null;

    // Cek TTL
    final ts = HiveService.get<int>(key: _cacheTimestampKey);
    if (ts != null) {
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age > _cacheTtlMs) {
        AppLogger.call('$_tag Cache expired (age: ${age}ms)');
        clearCache();
        return null;
      }
    }

    AppLogger.call('$_tag getCachedDictionaries: from cache');
    final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
    return jsonList
        .map((e) => ParsingDictionaryModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Hapus cache dictionaries.
  void clearCache() {
    AppLogger.call('$_tag clearCache');
    HiveService.delete(_cacheKey);
    HiveService.delete(_cacheTimestampKey);
  }
}
