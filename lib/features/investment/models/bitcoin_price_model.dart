/// Model data untuk harga Bitcoin.
///
/// Merepresentasikan satu record dari tabel `public.bitcoin_prices`.
/// Tabel ini hanya berisi 2 row (indodax, coingecko) — di-UPSERT oleh edge function.
class BitcoinPriceModel {
  const BitcoinPriceModel({
    required this.id,
    required this.source,
    required this.priceIdr,
    required this.fetchedAt,
  });

  final String id;

  /// Sumber harga: "indodax" atau "coingecko".
  final String source;

  /// Harga Bitcoin dalam IDR.
  final double priceIdr;

  /// Waktu data terakhir di-fetch dari sumber.
  final DateTime fetchedAt;

  factory BitcoinPriceModel.fromMap(Map<String, dynamic> map) {
    return BitcoinPriceModel(
      id: map['id'] as String,
      source: map['source'] as String,
      priceIdr: _toDouble(map['price_idr']),
      fetchedAt: map['fetched_at'] != null
          ? DateTime.parse(map['fetched_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFullMap() {
    return {
      'id': id,
      'source': source,
      'price_idr': priceIdr,
      'fetched_at': fetchedAt.toIso8601String(),
    };
  }

  BitcoinPriceModel copyWith({
    String? id,
    String? source,
    double? priceIdr,
    DateTime? fetchedAt,
  }) {
    return BitcoinPriceModel(
      id: id ?? this.id,
      source: source ?? this.source,
      priceIdr: priceIdr ?? this.priceIdr,
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
