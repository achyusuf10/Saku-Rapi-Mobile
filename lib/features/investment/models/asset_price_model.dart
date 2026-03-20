/// Harga aset dari live API, dengan timestamp untuk TTL caching.
class AssetPriceModel {
  const AssetPriceModel({
    required this.assetType,
    required this.priceIdr,
    required this.fetchedAt,
  });

  /// Tipe aset: 'btc' | 'gold'.
  final String assetType;

  /// Harga dalam IDR per unit.
  final double priceIdr;

  /// Waktu data ini diambil dari API.
  final DateTime fetchedAt;

  factory AssetPriceModel.fromMap(Map<String, dynamic> map) {
    return AssetPriceModel(
      assetType: map['asset_type'] as String,
      priceIdr: (map['price_idr'] as num).toDouble(),
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(map['fetched_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'asset_type': assetType,
      'price_idr': priceIdr,
      'fetched_at': fetchedAt.millisecondsSinceEpoch,
    };
  }
}
