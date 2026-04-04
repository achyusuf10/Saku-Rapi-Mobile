/// Tipe aset investasi yang didukung.
enum InvestmentType {
  gold,
  bitcoin,
  custom;

  /// Parse dari string database.
  static InvestmentType fromString(String value) {
    switch (value) {
      case 'gold':
        return InvestmentType.gold;
      case 'bitcoin':
        return InvestmentType.bitcoin;
      case 'custom':
        return InvestmentType.custom;
      default:
        return InvestmentType.custom;
    }
  }
}

/// Model data untuk master aset investasi.
///
/// Merepresentasikan satu record dari tabel `public.investment_assets`.
/// Field aggregated (`totalUnits`, `totalInvested`, `avgBuyPrice`, dll)
/// di-populate dari RPC `get_investment_dashboard`.
class InvestmentAssetModel {
  const InvestmentAssetModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.name,
    this.goldType,
    this.customGoldTypeId,
    this.customCategoryId,
    required this.unitLabel,
    required this.priceSource,
    required this.currentPrice,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    // Aggregated fields from dashboard RPC
    this.totalBuyUnits = 0,
    this.totalSellUnits = 0,
    this.totalUnits = 0,
    this.totalInvested = 0,
    this.totalFee = 0,
    this.avgBuyPrice = 0,
    this.transactionsCount = 0,
  });

  final String id;
  final String userId;
  final InvestmentType type;
  final String name;

  /// Jenis emas: "antam", "perhiasan", atau custom gold type name.
  final String? goldType;

  /// FK ke custom_gold_types.id (nullable).
  final String? customGoldTypeId;

  /// FK ke custom_asset_categories.id (nullable, untuk type=custom).
  final String? customCategoryId;

  /// Label satuan (Gram, BTC, Lot, dll).
  final String unitLabel;

  /// Sumber harga: "antaremas", "logammulia", "manual", "indodax", "coingecko".
  final String priceSource;

  /// Harga pasar terakhir (manual input atau dari API).
  final double currentPrice;

  /// Aktif jika total_units > 0.
  final bool isActive;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ─── Aggregated (dari get_investment_dashboard RPC) ───

  final double totalBuyUnits;
  final double totalSellUnits;
  final double totalUnits;
  final double totalInvested;
  final double totalFee;
  final double avgBuyPrice;
  final int transactionsCount;

  // ─── Computed ───

  /// Nilai pasar saat ini = totalUnits × currentPrice.
  double get currentValue => totalUnits * currentPrice;

  /// Profit/Loss = currentValue - totalInvested.
  double get profitLoss => currentValue - totalInvested;

  /// Persentase profit/loss.
  double get profitLossPercent =>
      totalInvested > 0 ? profitLoss / totalInvested : 0;

  // ─── Factory ───

  factory InvestmentAssetModel.fromMap(Map<String, dynamic> map) {
    return InvestmentAssetModel(
      id: map['id'] as String,
      userId: (map['user_id'] as String?) ?? '',
      type: InvestmentType.fromString(map['type'] as String),
      name: map['name'] as String,
      goldType: map['gold_type'] as String?,
      customGoldTypeId: map['custom_gold_type_id'] as String?,
      customCategoryId: map['custom_category_id'] as String?,
      unitLabel: (map['unit_label'] as String?) ?? 'unit',
      priceSource: (map['price_source'] as String?) ?? 'manual',
      currentPrice: _toDouble(map['current_price']),
      isActive: (map['is_active'] as bool?) ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      // Aggregated
      totalBuyUnits: _toDouble(map['total_buy_units']),
      totalSellUnits: _toDouble(map['total_sell_units']),
      totalUnits: _toDouble(map['total_units']),
      totalInvested: _toDouble(map['total_invested']),
      totalFee: _toDouble(map['total_fee']),
      avgBuyPrice: _toDouble(map['avg_buy_price']),
      transactionsCount: (map['transactions_count'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'type': type.name,
      'name': name,
      'gold_type': goldType,
      'custom_gold_type_id': customGoldTypeId,
      'custom_category_id': customCategoryId,
      'unit_label': unitLabel,
      'price_source': priceSource,
      'current_price': currentPrice,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'gold_type': goldType,
      'custom_gold_type_id': customGoldTypeId,
      'custom_category_id': customCategoryId,
      'unit_label': unitLabel,
      'price_source': priceSource,
      'current_price': currentPrice,
    };
  }

  Map<String, dynamic> toFullMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'name': name,
      'gold_type': goldType,
      'custom_gold_type_id': customGoldTypeId,
      'custom_category_id': customCategoryId,
      'unit_label': unitLabel,
      'price_source': priceSource,
      'current_price': currentPrice,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'total_buy_units': totalBuyUnits,
      'total_sell_units': totalSellUnits,
      'total_units': totalUnits,
      'total_invested': totalInvested,
      'total_fee': totalFee,
      'avg_buy_price': avgBuyPrice,
      'transactions_count': transactionsCount,
    };
  }

  InvestmentAssetModel copyWith({
    String? id,
    String? userId,
    InvestmentType? type,
    String? name,
    String? goldType,
    String? customGoldTypeId,
    String? customCategoryId,
    String? unitLabel,
    String? priceSource,
    double? currentPrice,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? totalBuyUnits,
    double? totalSellUnits,
    double? totalUnits,
    double? totalInvested,
    double? totalFee,
    double? avgBuyPrice,
    int? transactionsCount,
  }) {
    return InvestmentAssetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      name: name ?? this.name,
      goldType: goldType ?? this.goldType,
      customGoldTypeId: customGoldTypeId ?? this.customGoldTypeId,
      customCategoryId: customCategoryId ?? this.customCategoryId,
      unitLabel: unitLabel ?? this.unitLabel,
      priceSource: priceSource ?? this.priceSource,
      currentPrice: currentPrice ?? this.currentPrice,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalBuyUnits: totalBuyUnits ?? this.totalBuyUnits,
      totalSellUnits: totalSellUnits ?? this.totalSellUnits,
      totalUnits: totalUnits ?? this.totalUnits,
      totalInvested: totalInvested ?? this.totalInvested,
      totalFee: totalFee ?? this.totalFee,
      avgBuyPrice: avgBuyPrice ?? this.avgBuyPrice,
      transactionsCount: transactionsCount ?? this.transactionsCount,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0;
  }
}
