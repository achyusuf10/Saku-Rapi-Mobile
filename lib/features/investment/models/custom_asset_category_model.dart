/// Model data untuk kategori aset custom.
///
/// Merepresentasikan satu record dari tabel `public.custom_asset_categories`.
/// Maksimal 3 per user (enforced by DB trigger).
/// `unit_label` (misal: "Lot", "Lembar") disimpan di sini saja — BUKAN di transaksi.
class CustomAssetCategoryModel {
  const CustomAssetCategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.unitLabel,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;

  /// Label satuan (misal: "Lot", "Lembar", "Unit").
  /// UI transaksi WAJIB membaca dari sini, bukan hardcode.
  final String unitLabel;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CustomAssetCategoryModel.fromMap(Map<String, dynamic> map) {
    return CustomAssetCategoryModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      unitLabel: (map['unit_label'] as String?) ?? 'Unit',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {'user_id': userId, 'name': name, 'unit_label': unitLabel};
  }

  Map<String, dynamic> toUpdateMap() {
    return {'name': name, 'unit_label': unitLabel};
  }

  Map<String, dynamic> toFullMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'unit_label': unitLabel,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  CustomAssetCategoryModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? unitLabel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomAssetCategoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      unitLabel: unitLabel ?? this.unitLabel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
