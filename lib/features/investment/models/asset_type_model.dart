/// Model data untuk jenis aset kustom.
///
/// Merepresentasikan satu record dari tabel `public.asset_types`.
/// Setiap investasi bertipe `custom` wajib merujuk ke satu [AssetTypeModel].
/// Harga saat ini (`currentPrice`) dikelola di level jenis aset,
/// sehingga semua investasi yang menggunakan jenis aset ini
/// otomatis mengikuti harga terbaru.
class AssetTypeModel {
  const AssetTypeModel({
    required this.id,
    required this.userId,
    required this.name,
    this.symbol,
    required this.currentPrice,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;

  /// Nama jenis aset (misal: Saham BCA, Tanah, Obligasi).
  final String name;

  /// Ticker/symbol opsional (misal: BBCA, OBL).
  final String? symbol;

  /// Harga saat ini per unit.
  final double currentPrice;

  /// Soft delete flag.
  final bool isDeleted;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ───────────────── Factory ─────────────────

  factory AssetTypeModel.fromMap(Map<String, dynamic> map) {
    return AssetTypeModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      symbol: map['symbol'] as String?,
      currentPrice: _toDouble(map['current_price']),
      isDeleted: map['is_deleted'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  // ───────────────── Serialization ─────────────────

  /// Map untuk INSERT/UPDATE.
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'symbol': symbol,
      'current_price': currentPrice,
    };
  }

  /// Map lengkap untuk local cache (Hive).
  Map<String, dynamic> toFullMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'symbol': symbol,
      'current_price': currentPrice,
      'is_deleted': isDeleted,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ───────────────── CopyWith ─────────────────

  AssetTypeModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? symbol,
    bool clearSymbol = false,
    double? currentPrice,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssetTypeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      symbol: clearSymbol ? null : (symbol ?? this.symbol),
      currentPrice: currentPrice ?? this.currentPrice,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'AssetTypeModel(id: $id, name: $name, symbol: $symbol, currentPrice: $currentPrice)';
}
