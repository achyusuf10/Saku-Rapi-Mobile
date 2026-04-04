/// Model data untuk harga emas.
///
/// Merepresentasikan satu record dari tabel `public.gold_prices`.
/// Klien Flutter membaca `ORDER BY fetched_at DESC LIMIT 1` per source.
class GoldPriceModel {
  const GoldPriceModel({
    required this.id,
    required this.source,
    required this.buyPrice,
    required this.sellPrice,
    required this.fetchedAt,
  });

  final String id;

  /// Sumber harga: "antaremas" atau "logammulia".
  final String source;

  /// Harga beli/buyback per gram (IDR).
  final double buyPrice;

  /// Harga jual per gram (IDR).
  final double sellPrice;

  /// Waktu data terakhir di-fetch dari sumber.
  final DateTime fetchedAt;

  factory GoldPriceModel.fromMap(Map<String, dynamic> map) {
    return GoldPriceModel(
      id: map['id'] as String,
      source: map['source'] as String,
      buyPrice: _toDouble(map['buy_price']),
      sellPrice: _toDouble(map['sell_price']),
      fetchedAt: map['fetched_at'] != null
          ? DateTime.parse(map['fetched_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFullMap() {
    return {
      'id': id,
      'source': source,
      'buy_price': buyPrice,
      'sell_price': sellPrice,
      'fetched_at': fetchedAt.toIso8601String(),
    };
  }

  GoldPriceModel copyWith({
    String? id,
    String? source,
    double? buyPrice,
    double? sellPrice,
    DateTime? fetchedAt,
  }) {
    return GoldPriceModel(
      id: id ?? this.id,
      source: source ?? this.source,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0;
  }
}
