/// Model data untuk transaksi investasi (buy/sell).
///
/// Merepresentasikan satu record dari tabel `public.investment_transactions`.
/// Tabel ini HANYA menyimpan value numerik — label satuan dibaca dari parent asset.
class InvestmentTransactionModel {
  const InvestmentTransactionModel({
    required this.id,
    required this.assetId,
    required this.userId,
    required this.direction,
    required this.units,
    required this.pricePerUnit,
    required this.fee,
    this.walletId,
    required this.deductWallet,
    this.linkedWalletTransactionId,
    required this.date,
    this.note,
    this.createdAt,
  });

  final String id;
  final String assetId;
  final String userId;

  /// 'buy' atau 'sell'.
  final String direction;

  /// Jumlah unit (desimal: gram, BTC, lot, dll).
  final double units;

  /// Harga per unit saat transaksi.
  final double pricePerUnit;

  /// Biaya tambahan/fee.
  final double fee;

  /// ID wallet terkait (nullable).
  final String? walletId;

  /// Apakah transaksi deducted/credited dari/ke wallet.
  final bool deductWallet;

  /// ID transaksi di tabel `transactions` yang linked (nullable).
  final String? linkedWalletTransactionId;

  /// Tanggal transaksi.
  final DateTime date;

  /// Catatan opsional.
  final String? note;

  final DateTime? createdAt;

  // ─── Computed ───

  /// Total nilai = units × pricePerUnit.
  double get totalValue => units * pricePerUnit;

  /// Total cost termasuk fee = totalValue + fee.
  double get totalCost => totalValue + fee;

  bool get isBuy => direction == 'buy';
  bool get isSell => direction == 'sell';

  // ─── Factory ───

  factory InvestmentTransactionModel.fromMap(Map<String, dynamic> map) {
    return InvestmentTransactionModel(
      id: map['id'] as String,
      assetId: map['asset_id'] as String,
      userId: (map['user_id'] as String?) ?? '',
      direction: map['direction'] as String,
      units: _toDouble(map['units']),
      pricePerUnit: _toDouble(map['price_per_unit']),
      fee: _toDouble(map['fee']),
      walletId: map['wallet_id'] as String?,
      deductWallet: (map['deduct_wallet'] as bool?) ?? false,
      linkedWalletTransactionId: map['linked_wallet_transaction_id'] as String?,
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      note: map['note'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toFullMap() {
    return {
      'id': id,
      'asset_id': assetId,
      'user_id': userId,
      'direction': direction,
      'units': units,
      'price_per_unit': pricePerUnit,
      'fee': fee,
      'wallet_id': walletId,
      'deduct_wallet': deductWallet,
      'linked_wallet_transaction_id': linkedWalletTransactionId,
      'date': date.toIso8601String(),
      'note': note,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  InvestmentTransactionModel copyWith({
    String? id,
    String? assetId,
    String? userId,
    String? direction,
    double? units,
    double? pricePerUnit,
    double? fee,
    String? walletId,
    bool? deductWallet,
    String? linkedWalletTransactionId,
    DateTime? date,
    String? note,
    DateTime? createdAt,
  }) {
    return InvestmentTransactionModel(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      userId: userId ?? this.userId,
      direction: direction ?? this.direction,
      units: units ?? this.units,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      fee: fee ?? this.fee,
      walletId: walletId ?? this.walletId,
      deductWallet: deductWallet ?? this.deductWallet,
      linkedWalletTransactionId:
          linkedWalletTransactionId ?? this.linkedWalletTransactionId,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0;
  }
}
