import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/transaction/models/contact_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk kontak hutang/piutang.
///
/// - [getContacts]: ambil semua kontak milik user (untuk riwayat picker).
/// - [upsertContact]: find-or-create via RPC atomik berdasarkan name + phone.
class ContactRemoteDataSource {
  ContactRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _table = 'contacts';
  static const _tag = '[Transaction] [ContactRemoteDataSource]';

  String get _userId => _client.auth.currentUser!.id;

  // ───────────────── READ ─────────────────

  /// Ambil semua kontak user, diurutkan by name.
  Future<DataState<List<ContactModel>>> getContacts() {
    return SupabaseHandler.call<List<ContactModel>>(
      function: () async {
        AppLogger.call('$_tag getContacts');

        final response = await _client
            .from(_table)
            .select()
            .eq('user_id', _userId)
            .order('name');

        return response.map((e) => ContactModel.fromMap(e)).toList();
      },
    );
  }

  // ───────────────── UPSERT ─────────────────

  /// Find-or-create kontak via RPC `upsert_contact`.
  ///
  /// Mengembalikan [ContactModel] dengan id yang valid (existing atau baru).
  Future<DataState<ContactModel>> upsertContact({
    required String name,
    String? phone,
  }) {
    return SupabaseHandler.call<ContactModel>(
      function: () async {
        AppLogger.call('$_tag upsertContact: name=$name, phone=$phone');

        // RPC returns the uuid of the found-or-created contact
        final contactId =
            await _client.rpc(
                  'upsert_contact',
                  params: {'p_name': name, 'p_phone': phone},
                )
                as String;

        // Fetch the full row to return a complete ContactModel
        final response = await _client
            .from(_table)
            .select()
            .eq('id', contactId)
            .single();

        return ContactModel.fromMap(response);
      },
    );
  }
}
