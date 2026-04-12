import 'package:app_saku_rapi/core/utils/saku_date_utils.dart';

/// Model data untuk wallet/dompet.
///
/// Merepresentasikan satu record dari tabel `public.wallets`.
/// `balance` bersifat read-only di sisi Flutter karena hanya diubah
/// melalui trigger dari tabel `transactions`.
class WalletModel {
  const WalletModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.color,
    required this.balance,
    required this.initialBalance,
    required this.currency,
    required this.excludeFromTotal,
    required this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String icon;
  final String color;

  /// Saldo terkini — hanya berubah lewat trigger `update_wallet_balance`.
  final double balance;

  /// Saldo saat wallet pertama dibuat. Immutable setelah create.
  final double initialBalance;

  /// Currency (MVP: selalu 'IDR').
  final String currency;

  /// Jika `true`, saldo wallet tidak dihitung di total dashboard.
  final bool excludeFromTotal;

  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ───────────────── Factory ─────────────────

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      color: map['color'] as String,
      balance: _toDouble(map['balance']),
      initialBalance: _toDouble(map['initial_balance']),
      currency: (map['currency'] as String?) ?? 'IDR',
      excludeFromTotal: (map['exclude_from_total'] as bool?) ?? false,
      sortOrder: (map['sort_order'] as int?) ?? 0,
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

  /// Map untuk INSERT — tanpa id, balance, created_at (server‐generated).
  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'name': name,
      'icon': icon,
      'color': color,
      'balance': initialBalance,
      'initial_balance': initialBalance,
      'currency': currency,
      'exclude_from_total': excludeFromTotal,
      'sort_order': sortOrder,
    };
  }

  /// Map untuk UPDATE — hanya field yang boleh diubah user.
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'icon': icon,
      'color': color,
      'exclude_from_total': excludeFromTotal,
      'sort_order': sortOrder,
    };
  }

  /// Map lengkap untuk local cache (Hive).
  Map<String, dynamic> toFullMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'icon': icon,
      'color': color,
      'balance': balance,
      'initial_balance': initialBalance,
      'currency': currency,
      'exclude_from_total': excludeFromTotal,
      'sort_order': sortOrder,
      'created_at': SakuDateUtils.formatOptionalTimestamp(createdAt),
      'updated_at': SakuDateUtils.formatOptionalTimestamp(updatedAt),
    };
  }

  WalletModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? icon,
    String? color,
    double? balance,
    double? initialBalance,
    String? currency,
    bool? excludeFromTotal,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      balance: balance ?? this.balance,
      initialBalance: initialBalance ?? this.initialBalance,
      currency: currency ?? this.currency,
      excludeFromTotal: excludeFromTotal ?? this.excludeFromTotal,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helper: konversi numeric dari Supabase (bisa int atau double) ke double.
  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0;
  }
}
