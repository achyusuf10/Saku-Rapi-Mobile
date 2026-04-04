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

  /// Membuat [UserModel] dari Map (hasil query Supabase).
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      fullName: map['full_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
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
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
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
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
