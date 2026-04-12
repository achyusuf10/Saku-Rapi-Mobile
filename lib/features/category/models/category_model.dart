import 'package:app_saku_rapi/core/utils/saku_date_utils.dart';

/// Model data kategori dari tabel `public.categories`.
///
/// Mendukung hierarki parent-child max 2 level.
/// Field `type` berupa [CategoryType] (income, expense, system).
/// Kategori `is_default` tidak boleh dihapus, hanya bisa di-hide.
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.parentId,
    this.isDefault = false,
    this.isHidden = false,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
    this.children = const [],
  });

  /// UUID primary key.
  final String id;

  /// UUID pemilik. Null untuk kategori system global.
  final String? userId;

  /// Nama tampilan kategori.
  final String name;

  /// Nama icon FontAwesome (misal: 'house', 'car').
  final String icon;

  /// Hex color string (misal: '#F59E0B').
  final String color;

  /// Tipe kategori: income, expense, atau system.
  final CategoryType type;

  /// UUID parent untuk child category (max 2 level).
  final String? parentId;

  /// Apakah kategori bawaan (seed). Tidak boleh dihapus.
  final bool isDefault;

  /// Apakah kategori disembunyikan oleh user.
  final bool isHidden;

  /// Urutan tampil.
  final int sortOrder;

  /// Tanggal dibuat.
  final DateTime? createdAt;

  /// Tanggal diupdate.
  final DateTime? updatedAt;

  /// Daftar child categories (diisi saat grouping lokal).
  final List<CategoryModel> children;

  /// Apakah kategori ini parent (level 1).
  bool get isParent => parentId == null;

  /// Apakah kategori ini child (level 2).
  bool get isChild => parentId != null;

  /// Membuat [CategoryModel] dari Map (hasil query Supabase).
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      name: map['name'] as String,
      icon: map['icon'] as String,
      color: map['color'] as String,
      type: CategoryType.fromString(map['type'] as String),
      parentId: map['parent_id'] as String?,
      isDefault: map['is_default'] as bool? ?? false,
      isHidden: map['is_hidden'] as bool? ?? false,
      sortOrder: map['sort_order'] as int? ?? 0,
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

  /// Konversi ke Map untuk operasi insert/update ke Supabase.
  ///
  /// Tidak menyertakan `id` dan `created_at` karena di-generate server.
  /// Tidak menyertakan `children` karena hanya untuk UI lokal.
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type.value,
      'parent_id': parentId,
      'is_default': isDefault,
      'is_hidden': isHidden,
      'sort_order': sortOrder,
    };
  }

  /// Konversi ke Map lengkap termasuk `id` (untuk cache lokal).
  Map<String, dynamic> toFullMap() {
    return {
      'id': id,
      ...toMap(),
      'created_at': SakuDateUtils.formatOptionalTimestamp(createdAt),
      'updated_at': SakuDateUtils.formatOptionalTimestamp(updatedAt),
    };
  }

  /// Membuat salinan [CategoryModel] dengan field yang diubah.
  CategoryModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? icon,
    String? color,
    CategoryType? type,
    String? parentId,
    bool? isDefault,
    bool? isHidden,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      updatedAt: updatedAt ?? this.updatedAt,
      children: children ?? this.children,
    );
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, type: ${type.value}, '
        'parentId: $parentId, children: ${children.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Tipe kategori yang didukung oleh SakuRapi.
enum CategoryType {
  /// Kategori pemasukan.
  income('income'),

  /// Kategori pengeluaran.
  expense('expense'),

  /// Kategori system (penyesuaian saldo, transfer aset).
  system('system');

  const CategoryType(this.value);

  /// Nilai string yang disimpan di database.
  final String value;

  /// Membuat [CategoryType] dari string database.
  factory CategoryType.fromString(String value) {
    return CategoryType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CategoryType.expense,
    );
  }
}
