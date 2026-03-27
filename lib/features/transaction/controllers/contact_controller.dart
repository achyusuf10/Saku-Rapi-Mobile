import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/transaction/models/contact_model.dart';
import 'package:app_saku_rapi/features/transaction/repositories/contact_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ═══════════════ Providers ═══════════════

/// Singleton repository provider.
final contactRepositoryProvider = Provider<ContactRepository>(
  (ref) => ContactRepository(),
);

/// Controller provider untuk kontak hutang/piutang.
///
/// Auto-disposed saat tidak ada subscriber.
final contactControllerProvider =
    StateNotifierProvider.autoDispose<ContactController, ContactState>(
      (ref) => ContactController(ref.watch(contactRepositoryProvider)),
    );

// ═══════════════ State ═══════════════

enum ContactStatus { initial, loading, loaded, error }

class ContactState {
  const ContactState({
    this.status = ContactStatus.initial,
    this.contacts = const [],
    this.errorMessage,
  });

  final ContactStatus status;
  final List<ContactModel> contacts;
  final String? errorMessage;

  bool get isLoading => status == ContactStatus.loading;

  ContactState copyWith({
    ContactStatus? status,
    List<ContactModel>? contacts,
    String? errorMessage,
  }) {
    return ContactState(
      status: status ?? this.status,
      contacts: contacts ?? this.contacts,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ═══════════════ Controller ═══════════════

/// Controller untuk manajemen kontak hutang/piutang.
///
/// - [loadContacts]: ambil semua kontak dari DB.
/// - [upsertContact]: find-or-create kontak dan perbarui list lokal.
class ContactController extends StateNotifier<ContactState> {
  ContactController(this._repository) : super(const ContactState());

  final ContactRepository _repository;

  static const _tag = '[Transaction] [ContactController]';

  // ─── Load ───

  /// Ambil semua kontak tersimpan. Idempotent, aman dipanggil berkali-kali.
  Future<void> loadContacts() async {
    if (state.isLoading) return;

    state = state.copyWith(status: ContactStatus.loading);

    final result = await _repository.getContacts();

    if (result.isSuccess()) {
      state = state.copyWith(
        status: ContactStatus.loaded,
        contacts: result.dataSuccess()!,
      );
    } else {
      final (message, _, _, _) = result.dataError()!;
      AppLogger.call('$_tag loadContacts error: $message');
      state = state.copyWith(
        status: ContactStatus.error,
        errorMessage: message,
      );
    }
  }

  // ─── Upsert ───

  /// Find-or-create kontak, kembalikan [ContactModel] dengan id valid.
  ///
  /// Setelah berhasil, kontak ditambahkan/diperbarui di list lokal.
  Future<ContactModel?> upsertContact({
    required String name,
    String? phone,
  }) async {
    final result = await _repository.upsertContact(name: name, phone: phone);

    if (result.isSuccess()) {
      final contact = result.dataSuccess()!;
      // Upsert ke list lokal: ganti yang ada atau tambah ke depan
      final existing = state.contacts.indexWhere((c) => c.id == contact.id);
      final updated = [...state.contacts];
      if (existing >= 0) {
        updated[existing] = contact;
      } else {
        updated.insert(0, contact);
      }
      state = state.copyWith(contacts: updated);
      return contact;
    } else {
      final (message, _, _, _) = result.dataError()!;
      AppLogger.call('$_tag upsertContact error: $message');
      return null;
    }
  }
}
