import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/parsing_dictionary/datasource/parsing_dictionary_local_datasource.dart';
import 'package:app_saku_rapi/features/parsing_dictionary/datasource/parsing_dictionary_remote_datasource.dart';
import 'package:app_saku_rapi/features/parsing_dictionary/models/parsing_keyword_model.dart';
import 'package:app_saku_rapi/features/parsing_dictionary/repositories/parsing_dictionary_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────

/// Provider untuk [ParsingDictionaryLocalDataSource].
final parsingDictLocalProvider = Provider<ParsingDictionaryLocalDataSource>(
  (ref) => ParsingDictionaryLocalDataSource(),
);

/// Provider untuk [ParsingDictionaryRemoteDataSource].
final parsingDictRemoteProvider = Provider<ParsingDictionaryRemoteDataSource>(
  (ref) => ParsingDictionaryRemoteDataSource(client: Supabase.instance.client),
);

/// Provider untuk [ParsingDictionaryRepository].
final parsingDictRepositoryProvider = Provider<ParsingDictionaryRepository>(
  (ref) => ParsingDictionaryRepository(
    remoteDataSource: ref.watch(parsingDictRemoteProvider),
    localDataSource: ref.watch(parsingDictLocalProvider),
  ),
);

/// Provider utama untuk [ParsingDictionaryController].
///
/// State berupa [AsyncValue<List<ParsingKeywordModel>>].
/// Di-load saat app start (DashboardScreen).
final parsingDictionaryControllerProvider =
    AsyncNotifierProvider<
      ParsingDictionaryController,
      List<ParsingKeywordModel>
    >(() => ParsingDictionaryController());

// ─────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────

/// Riverpod [AsyncNotifier] untuk mengelola kamus parsing keyword.
///
/// Saat [build], otomatis fetch dari repository (cache-first).
/// Expose `dictionary` getter untuk digunakan oleh voice/OCR input.
class ParsingDictionaryController
    extends AsyncNotifier<List<ParsingKeywordModel>> {
  late final ParsingDictionaryRepository _repository;

  static const String _tag = 'ParsingDict';

  @override
  Future<List<ParsingKeywordModel>> build() async {
    _repository = ref.watch(parsingDictRepositoryProvider);
    return _fetch();
  }

  /// Fetch kamus dari repository.
  Future<List<ParsingKeywordModel>> _fetch() async {
    final result = await _repository.getDictionary();

    if (result.isSuccess()) {
      final data = result.dataSuccess()!;
      AppLogger.call(
        '[$_tag] Dictionary loaded: ${data.length} keywords',
        colorLog: ColorLog.green,
      );
      return data;
    }

    final error = result.dataError();
    AppLogger.logError('[$_tag] Failed to load: ${error?.$1}');
    return [];
  }

  /// Daftar keyword saat ini (kosong jika belum loaded).
  List<ParsingKeywordModel> get dictionary => state.value ?? [];

  /// Force refresh dari Supabase (bypass TTL cache).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetch());
  }
}
