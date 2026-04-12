import 'package:app_saku_rapi/core/utils/saku_date_utils.dart';

/// Model untuk kontak yang tersimpan di tabel `public.contacts`.
///
/// Kontak dipakai sebagai referensi untuk transaksi hutang/piutang.
/// Data dari phonebook device yang dipilih user akan di-upsert ke sini.
class ContactModel {
  const ContactModel({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;

  /// Nama kontak (wajib).
  final String name;

  /// Nomor telepon (opsional — tidak semua kontak punya nomor).
  final String? phone;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Label tampilan: "Nama (nomor)" jika ada nomor, hanya "Nama" jika tidak.
  String get displayLabel => phone != null ? '$name ($phone)' : name;

  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      createdAt: map['created_at'] != null
          ? SakuDateUtils.parseRequiredTimestamp(
              map['created_at'],
              fieldName: 'created_at',
            )
          : null,
      updatedAt: map['updated_at'] != null
          ? SakuDateUtils.parseRequiredTimestamp(
              map['updated_at'],
              fieldName: 'updated_at',
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'created_at': SakuDateUtils.formatOptionalTimestamp(createdAt),
      'updated_at': SakuDateUtils.formatOptionalTimestamp(updatedAt),
    };
  }

  ContactModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    bool clearPhone = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContactModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: clearPhone ? null : (phone ?? this.phone),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'ContactModel(id: $id, name: $name, phone: $phone)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
