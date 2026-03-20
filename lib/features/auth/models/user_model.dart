/// Model data untuk tabel `public.users` di Supabase.
///
/// Kolom sesuai skema database:
/// - `id` (uuid, PK, FK → auth.users)
/// - `email` (text, NOT NULL)
/// - `full_name` (text, nullable)
/// - `avatar_url` (text, nullable)
/// - `created_at` (timestamptz, default now())
/// - `updated_at` (timestamptz, default now())
class UserModel {
  /// Primary key (uuid), sama dengan `auth.users.id`.
  final String id;

  /// Email user dari akun Google.
  final String email;

  /// Nama lengkap user.
  final String? fullName;

  /// URL avatar/foto profil user.
  final String? avatarUrl;

  /// Waktu pembuatan profil.
  final DateTime createdAt;

  /// Waktu terakhir profil diupdate.
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Membuat instance baru dengan nilai tertentu yang di-override.
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

  /// Konversi dari `Map` (response Supabase `public.users`) ke [UserModel].
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      fullName: map['full_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Konversi ke `Map` untuk dikirim ke Supabase.
  ///
  /// Field `id`, `created_at`, dan `updated_at` tidak disertakan
  /// karena di-manage oleh database/trigger.
  Map<String, dynamic> toMap() {
    return {'email': email, 'full_name': fullName, 'avatar_url': avatarUrl};
  }
}
