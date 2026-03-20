import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/parsing_dictionary/models/parsing_keyword_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk tabel `parsing_dictionaries` di Supabase.
///
/// Fetch semua keywords yang tersedia. Dibungkus dengan [SupabaseHandler.call]
/// dan mengembalikan [DataState] sesuai arsitektur.
class ParsingDictionaryRemoteDataSource {
  ParsingDictionaryRemoteDataSource({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  static const String _table = 'parsing_dictionaries';

  /// Fetch seluruh kamus parsing dari Supabase.
  Future<DataState<List<ParsingKeywordModel>>> fetchDictionary() {
    return SupabaseHandler.call<List<ParsingKeywordModel>>(
      function: () async {
        final response = await _client
            .from(_table)
            .select()
            .order('keyword', ascending: true);

        return response.map(ParsingKeywordModel.fromMap).toList();
      },
    );
  }
}
