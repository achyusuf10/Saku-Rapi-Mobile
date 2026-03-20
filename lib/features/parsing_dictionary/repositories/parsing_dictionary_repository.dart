import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/parsing_dictionary/datasource/parsing_dictionary_local_datasource.dart';
import 'package:app_saku_rapi/features/parsing_dictionary/datasource/parsing_dictionary_remote_datasource.dart';
import 'package:app_saku_rapi/features/parsing_dictionary/models/parsing_keyword_model.dart';

/// Repository kamus parsing keyword → kategori.
///
/// Orkestrator smart-fetch:
/// 1. Cek apakah cache Hive expired (TTL 24 jam).
/// 2. Jika valid → return cache.
/// 3. Jika expired → fetch dari Supabase.
///    - Sukses → simpan ke cache + return.
///    - Gagal → fallback ke cache lama (graceful degradation).
class ParsingDictionaryRepository {
  ParsingDictionaryRepository({
    required ParsingDictionaryRemoteDataSource remoteDataSource,
    required ParsingDictionaryLocalDataSource localDataSource,
  }) : _remote = remoteDataSource,
       _local = localDataSource;

  final ParsingDictionaryRemoteDataSource _remote;
  final ParsingDictionaryLocalDataSource _local;

  static const String _tag = 'ParsingDict';

  /// Smart fetch: cache-first, remote jika expired, fallback graceful.
  Future<DataState<List<ParsingKeywordModel>>> getDictionary() async {
    // 1. Cek cache
    if (!_local.isCacheExpired()) {
      final cached = _local.getCachedDictionary();
      if (cached.isNotEmpty) {
        AppLogger.call(
          '[$_tag] Cache valid, ${cached.length} keywords',
          colorLog: ColorLog.green,
        );
        return DataState.success(data: cached);
      }
    }

    // 2. Fetch remote
    AppLogger.call(
      '[$_tag] Cache expired/empty, fetching from Supabase...',
      colorLog: ColorLog.blue,
    );

    final result = await _remote.fetchDictionary();

    return result.map(
      success: (data) {
        // Simpan ke cache
        _local.saveDictionary(data.data);
        AppLogger.logSuccess(
          '[$_tag] Fetched ${data.data.length} keywords from Supabase',
        );
        return DataState<List<ParsingKeywordModel>>.success(data: data.data);
      },
      error: (err) {
        // Fallback ke cache lama
        final cached = _local.getCachedDictionary();
        if (cached.isNotEmpty) {
          AppLogger.call(
            '[$_tag] Remote gagal, fallback ke cache: ${cached.length} keywords',
            colorLog: ColorLog.yellow,
          );
          return DataState<List<ParsingKeywordModel>>.success(data: cached);
        }

        // Tidak ada cache dan remote gagal
        AppLogger.logError('[$_tag] Remote gagal & cache kosong');
        return DataState<List<ParsingKeywordModel>>.error(message: err.message);
      },
    );
  }
}
