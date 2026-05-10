import 'package:app_saku_rapi/core/utils/saku_date_utils.dart';

/// Model data user yang di-mirror dari tabel `public.users`.
///
/// Sinkronisasi dari `auth.users` dilakukan otomatis oleh trigger
/// `handle_new_user()` saat user pertama kali sign-up.
/// Flutter hanya membaca dan update `full_name` / `avatar_url`.
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
    this.showAds = true,
    this.accountDeleted = false,
    this.accountDeletedAt,
  });

  /// UUID dari auth.users.id (primary key).
  final String id;

  /// Email user dari Google Sign-In.
  final String email;

  /// Nama lengkap user (nullable, bisa diubah dari settings).
  final String? fullName;

  /// URL avatar user (nullable, dari Google atau upload manual).
  final String? avatarUrl;

  /// Tanggal user pertama kali terdaftar.
  final DateTime? createdAt;

  /// Tanggal terakhir profil diupdate.
  final DateTime? updatedAt;

  /// Apakah iklan ditampilkan untuk user ini.
  ///
  /// `false` = user sudah beli no-ads (diset dari Supabase oleh admin / after purchase).
  /// Default `true` untuk semua user baru.
  final bool showAds;

  /// Penanda soft delete akun (`public.users.account_deleted`).
  final bool accountDeleted;

  /// Waktu UTC permintaan soft delete (`account_deleted_at`).
  final DateTime? accountDeletedAt;

  /// Membuat [UserModel] dari Map (hasil query Supabase).
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      fullName: map['full_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      showAds: map['show_ads'] as bool? ?? true,
      accountDeleted: map['account_deleted'] as bool? ?? false,
      accountDeletedAt: map['account_deleted_at'] != null
          ? SakuDateUtils.parseRequiredTimestamp(
              map['account_deleted_at'],
              fieldName: 'account_deleted_at',
            )
          : null,
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

  /// Konversi ke Map untuk operasi update ke Supabase.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'created_at': SakuDateUtils.formatOptionalTimestamp(createdAt),
      'updated_at': SakuDateUtils.formatOptionalTimestamp(updatedAt),
    };
  }

  /// Membuat salinan [UserModel] dengan field yang diubah.
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? showAds,
    bool? accountDeleted,
    DateTime? accountDeletedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      showAds: showAds ?? this.showAds,
      accountDeleted: accountDeleted ?? this.accountDeleted,
      accountDeletedAt: accountDeletedAt ?? this.accountDeletedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, fullName: $fullName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
