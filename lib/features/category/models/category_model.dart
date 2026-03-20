/// Model data untuk tabel `categories` di Supabase, diperkaya
/// dengan computed field [children] untuk hierarki parent-child.
///
/// Kolom DB:
/// - `user_id` nullable — NULL = kategori default sistem
/// - `type` CHECK: 'income' | 'expense' | 'system'
/// - `parent_id` nullable — NULL = kategori utama (parent)
/// - `is_default` — true = kategori bawaan (tidak bisa dihapus)
/// - `is_hidden` — true = disembunyikan dari UI picker
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    required this.isDefault,
    required this.isHidden,
    required this.sortOrder,
    required this.createdAt,
    this.userId,
    this.parentId,
    this.children = const [],
  });

  /// Primary key (uuid).
  final String id;

  /// ID user pemilik. NULL jika kategori default sistem.
  final String? userId;

  /// Nama kategori (misal: Makanan, Gaji, Transportasi).
  final String name;

  /// Nama ikon FontAwesome (tanpa prefix).
  final String icon;

  /// Hex color string (#RRGGBB).
  final String color;

  /// Tipe: 'income', 'expense', atau 'system'.
  final String type;

  /// ID kategori induk (nullable, untuk sub-kategori).
  final String? parentId;

  /// `true` = kategori default bawaan sistem.
  final bool isDefault;

  /// `true` = disembunyikan dari UI.
  final bool isHidden;

  /// Urutan tampilan.
  final int sortOrder;

  /// Waktu pembuatan.
  final DateTime createdAt;

  /// Computed: daftar sub-kategori (children). Diisi di repository,
  /// bukan dari DB langsung.
  final List<CategoryModel> children;

  /// `true` jika kategori ini adalah sub-kategori (punya parent).
  bool get isChild => parentId != null;

  /// `true` jika kategori ini adalah parent (punya children).
  bool get isParent => children.isNotEmpty;

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      name: map['name'] as String,
      icon: map['icon'] as String? ?? 'tag',
      color: map['color'] as String? ?? '#6B7280',
      type: map['type'] as String,
      parentId: map['parent_id'] as String?,
      isDefault: map['is_default'] as bool? ?? false,
      isHidden: map['is_hidden'] as bool? ?? false,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Konversi ke Map untuk dikirim ke Supabase.
  ///
  /// `id`, `created_at`, dan `children` diabaikan (dikelola DB / computed).
  Map<String, dynamic> toMap() {
    return {
      if (userId != null) 'user_id': userId,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      if (parentId != null) 'parent_id': parentId,
      'is_default': isDefault,
      'is_hidden': isHidden,
      'sort_order': sortOrder,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? icon,
    String? color,
    String? type,
    String? parentId,
    bool? isDefault,
    bool? isHidden,
    int? sortOrder,
    DateTime? createdAt,
    List<CategoryModel>? children,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      isDefault: isDefault ?? this.isDefault,
      isHidden: isHidden ?? this.isHidden,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      children: children ?? this.children,
    );
  }
}
