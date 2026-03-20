/// Tipe aset investasi yang didukung.
///
/// - [gold]: Emas (harga dari live API / custom)
/// - [btc]: Bitcoin (harga dari CoinGecko)
/// - [custom]: Aset custom (harga dari [customCurrentPrice])
enum InvestmentType {
  gold('gold'),
  btc('btc'),
  custom('custom');

  const InvestmentType(this.value);

  /// Nilai string yang tersimpan di database.
  final String value;

  /// Parse dari string database.
  static InvestmentType fromValue(String value) {
    return InvestmentType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InvestmentType.custom,
    );
  }
}

/// Model data untuk tabel `investments` di Supabase.
///
/// Field `livePrice` bersifat runtime-only (tidak tersimpan di DB),
/// diisi oleh controller setelah fetch harga dari API.
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
    required this.createdAt,
    required this.updatedAt,
    this.livePrice,
  });

  /// UUID auto-generated.
  final String id;

  /// UUID user pemilik.
  final String userId;

  /// Tipe aset: 'gold' | 'btc' | 'custom'.
  final InvestmentType type;

  /// Nama aset (misal: "Emas Antam", "Bitcoin", "BBCA").
  final String name;

  /// Symbol opsional (misal: BTC, AAPL).
  final String? symbol;

  /// Jumlah unit yang dimiliki (gram untuk emas, satoshi/BTC, lot saham).
  final double amount;

  /// Harga beli rata-rata per unit (IDR).
  final double avgBuyPrice;

  /// Harga terkini yang diisi secara manual (untuk tipe custom atau fallback emas).
  final double? customCurrentPrice;

  /// Dompet yang dikaitkan (jika pembelian dipotong dari dompet tertentu).
  final String? linkedWalletId;

  /// Catatan opsional.
  final String? notes;

  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Runtime field ──

  /// Harga terkini dari API (BTC: CoinGecko, Emas: goldprice API).
  /// `null` jika sedang loading atau API gagal.
  final double? livePrice;

  // ─────────────────────────────────────────────────────────────
  // Computed getters
  // ─────────────────────────────────────────────────────────────

  /// Harga terkini yang akan digunakan untuk kalkulasi.
  ///
  /// Prioritas: livePrice → customCurrentPrice → avgBuyPrice.
  double get currentPrice => livePrice ?? customCurrentPrice ?? avgBuyPrice;

  /// Total nilai portofolio aset ini saat ini.
  double get currentValue => amount * currentPrice;

  /// Total modal yang dikeluarkan saat beli.
  double get totalBuyCost => amount * avgBuyPrice;

  /// Profit atau Loss absolut (IDR).
  double get profitLoss => currentValue - totalBuyCost;

  /// Profit atau Loss dalam persentase.
  double get profitLossPercentage =>
      totalBuyCost > 0 ? (profitLoss / totalBuyCost * 100) : 0;

  /// Apakah sedang profit.
  bool get isProfit => profitLoss >= 0;

  // ─────────────────────────────────────────────────────────────
  // Serialization
  // ─────────────────────────────────────────────────────────────

  factory InvestmentModel.fromMap(Map<String, dynamic> map) {
    return InvestmentModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: InvestmentType.fromValue(map['type'] as String),
      name: map['name'] as String,
      symbol: map['symbol'] as String?,
      amount: (map['amount'] as num).toDouble(),
      avgBuyPrice: (map['avg_buy_price'] as num).toDouble(),
      customCurrentPrice: map['custom_current_price'] != null
          ? (map['custom_current_price'] as num).toDouble()
          : null,
      linkedWalletId: map['linked_wallet_id'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Untuk INSERT ke Supabase. Tidak menyertakan id, created_at, updated_at.
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'type': type.value,
      'name': name,
      'symbol': symbol,
      'amount': amount,
      'avg_buy_price': avgBuyPrice,
      'custom_current_price': customCurrentPrice,
      'linked_wallet_id': linkedWalletId,
      'notes': notes,
    };
  }

  InvestmentModel copyWith({
    String? id,
    String? userId,
    InvestmentType? type,
    String? name,
    String? symbol,
    double? amount,
    double? avgBuyPrice,
    double? customCurrentPrice,
    String? linkedWalletId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? livePrice,
    bool clearLivePrice = false,
  }) {
    return InvestmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      amount: amount ?? this.amount,
      avgBuyPrice: avgBuyPrice ?? this.avgBuyPrice,
      customCurrentPrice: customCurrentPrice ?? this.customCurrentPrice,
      linkedWalletId: linkedWalletId ?? this.linkedWalletId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      livePrice: clearLivePrice ? null : (livePrice ?? this.livePrice),
    );
  }
}
