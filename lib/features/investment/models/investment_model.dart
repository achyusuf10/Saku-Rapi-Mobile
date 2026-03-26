/// Model data untuk investasi/aset.
///
/// Merepresentasikan satu record dari tabel `public.investments`.
/// Field `avg_buy_price` adalah harga beli rata-rata (sumber kebenaran).
/// Field `custom_current_price` untuk fallback manual jika harga live tidak tersedia.
class InvestmentModel {
  const InvestmentModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.name,
    this.symbol,
    required this.amount,
    required this.avgBuyPrice,
    this.customCurrentPrice,
    this.linkedWalletId,
    this.notes,
    this.createdAt,
    this.updatedAt,
    // Display-only joined fields
    this.walletName,
    // Live price (fetched dari external source, tidak disimpan ke DB)
    this.livePricePerUnit,
  });

  final String id;
  final String userId;

  /// Tipe aset: `gold`, `crypto`, `custom`.
  final String type;

  /// Nama aset (misal: Emas Antam, Bitcoin).
  final String name;

  /// Ticker/symbol opsional (misal: BTC, XAU).
  final String? symbol;

  /// Jumlah unit yang dimiliki.
  final double amount;

  /// Harga beli rata-rata per unit.
  final double avgBuyPrice;

  /// Harga saat ini (manual/fallback). Digunakan jika live price tidak tersedia.
  final double? customCurrentPrice;

  /// Wallet referensi (bukan untuk deduction langsung).
  final String? linkedWalletId;

  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ─── Display-only joined fields ───
  final String? walletName;

  /// Harga live dari sumber eksternal (CoinGecko/Edge Function).
  /// Tidak persisted ke DB — hanya untuk display.
  final double? livePricePerUnit;

  // ───────────────── Computed ─────────────────

  /// Harga saat ini — prioritas: live > custom > avgBuyPrice.
  double get currentPrice =>
      livePricePerUnit ?? customCurrentPrice ?? avgBuyPrice;

  /// Apakah menggunakan harga live.
  bool get hasLivePrice => livePricePerUnit != null;

  /// Total nilai investasi saat ini.
  double get currentValue => amount * currentPrice;

  /// Total modal (invested amount).
  double get investedValue => amount * avgBuyPrice;

  /// Unrealized P/L (absolute).
  double get unrealizedPL => currentValue - investedValue;

  /// Unrealized P/L percentage.
  double get unrealizedPLPercent {
    if (investedValue == 0) return 0;
    return unrealizedPL / investedValue;
  }

  /// Apakah sedang untung.
  bool get isProfit => unrealizedPL > 0;

  /// Apakah sedang rugi.
  bool get isLoss => unrealizedPL < 0;

  // ───────────────── Factory ─────────────────

  factory InvestmentModel.fromMap(Map<String, dynamic> map) {
    return InvestmentModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: map['type'] as String,
      name: map['name'] as String,
      symbol: map['symbol'] as String?,
      amount: _toDouble(map['amount']),
      avgBuyPrice: _toDouble(map['avg_buy_price']),
      customCurrentPrice: map['custom_current_price'] != null
          ? _toDouble(map['custom_current_price'])
          : null,
      linkedWalletId: map['linked_wallet_id'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      walletName: _nestedName(map['wallets']),
    );
  }

  static String? _nestedName(dynamic nested) {
    if (nested is Map<String, dynamic>) {
      return nested['name'] as String?;
    }
    return null;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  // ───────────────── Serialization ─────────────────

  /// Map untuk INSERT via RPC.
  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'type': type,
      'name': name,
      'symbol': symbol,
      'amount': amount,
      'avg_buy_price': avgBuyPrice,
      'custom_current_price': customCurrentPrice,
      'linked_wallet_id': linkedWalletId,
      'notes': notes,
    };
  }

  /// Map untuk UPDATE — hanya field yang boleh diubah.
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'symbol': symbol,
      'amount': amount,
      'avg_buy_price': avgBuyPrice,
      'custom_current_price': customCurrentPrice,
      'linked_wallet_id': linkedWalletId,
      'notes': notes,
    };
  }

  /// Map lengkap untuk local cache (Hive).
  Map<String, dynamic> toFullMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'name': name,
      'symbol': symbol,
      'amount': amount,
      'avg_buy_price': avgBuyPrice,
      'custom_current_price': customCurrentPrice,
      'linked_wallet_id': linkedWalletId,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ───────────────── CopyWith ─────────────────

  InvestmentModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? name,
    String? symbol,
    double? amount,
    double? avgBuyPrice,
    double? customCurrentPrice,
    bool clearCustomCurrentPrice = false,
    String? linkedWalletId,
    bool clearLinkedWalletId = false,
    String? notes,
    bool clearNotes = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? walletName,
    double? livePricePerUnit,
    bool clearLivePricePerUnit = false,
  }) {
    return InvestmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      amount: amount ?? this.amount,
      avgBuyPrice: avgBuyPrice ?? this.avgBuyPrice,
      customCurrentPrice: clearCustomCurrentPrice
          ? null
          : (customCurrentPrice ?? this.customCurrentPrice),
      livePricePerUnit: clearLivePricePerUnit
          ? null
          : (livePricePerUnit ?? this.livePricePerUnit),
      linkedWalletId: clearLinkedWalletId
          ? null
          : (linkedWalletId ?? this.linkedWalletId),
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      walletName: walletName ?? this.walletName,
    );
  }

  @override
  String toString() =>
      'InvestmentModel(id: $id, name: $name, type: $type, amount: $amount)';
}
