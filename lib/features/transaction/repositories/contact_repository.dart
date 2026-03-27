import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/transaction/datasource/contact_remote_data_source.dart';
import 'package:app_saku_rapi/features/transaction/models/contact_model.dart';

/// Repository untuk kontak hutang/piutang.
///
/// Memvalidasi input dan mendelegasikan ke [ContactRemoteDataSource].
class ContactRepository {
  ContactRepository({ContactRemoteDataSource? remoteDataSource})
    : _remote = remoteDataSource ?? ContactRemoteDataSource();

  final ContactRemoteDataSource _remote;

  static const _tag = '[Transaction] [ContactRepository]';

  // ───────────────── READ ─────────────────

  /// Ambil semua kontak tersimpan user.
  Future<DataState<List<ContactModel>>> getContacts() {
    AppLogger.call('$_tag getContacts');
    return _remote.getContacts();
  }

  // ───────────────── UPSERT ─────────────────

  /// Find-or-create kontak.
  ///
  /// Validasi: [name] tidak boleh kosong.
  Future<DataState<ContactModel>> upsertContact({
    required String name,
    String? phone,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        const DataState.error(message: 'Nama kontak tidak boleh kosong'),
      );
    }

    AppLogger.call('$_tag upsertContact: name=$trimmed, phone=$phone');
    return _remote.upsertContact(name: trimmed, phone: phone);
  }
}
