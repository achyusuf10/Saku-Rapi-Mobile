/// Model data untuk tabel `wallets` di Supabase.
///
/// Kolom sesuai skema database:
/// - `id` (uuid, PK, auto-generated)
/// - `user_id` (uuid, FK → auth.users)
/// - `name` (text)
/// - `icon` (text, default 'wallet')
/// - `color` (text, default '#10B981')
/// - `balance` (numeric, default 0)
/// - `initial_balance` (numeric, default 0)
/// - `currency` (text, default 'IDR')
/// - `exclude_from_total` (boolean, default false)
/// - `sort_order` (integer, default 0)
/// - `created_at` (timestamptz, auto-generated)
/// - `updated_at` (timestamptz, auto-generated)
class WalletModel {
  /// Primary key (uuid).
  final String id;

  /// ID user pemilik wallet (FK → auth.users).
  final String userId;

  /// Nama wallet, misal: Cash, BCA, Jago.
  final String name;

  /// Nama ikon FontAwesome (tanpa prefix). Default: `wallet`.
  final String icon;

  /// Hex color string (#RRGGBB). Default: `#10B981`.
  final String color;

  /// Saldo terkini. Dikelola otomatis oleh trigger database.
  final double balance;

  /// Saldo awal yang diinput saat pembuatan wallet.
  final double initialBalance;

  /// Kode mata uang, default 'IDR'.
  final String currency;

  /// Jika `true`, saldo wallet ini tidak dihitung ke total keseluruhan.
  final bool excludeFromTotal;

  /// Urutan tampilan wallet. Default: 0.
  final int sortOrder;

  /// Waktu pembuatan wallet.
  final DateTime createdAt;

  /// Waktu terakhir diperbarui.
  final DateTime updatedAt;

  const WalletModel({
    required this.id,
    required this.userId,
    required this.name,
    this.icon = 'wallet',
    this.color = '#10B981',
    required this.balance,
    this.initialBalance = 0,
    this.currency = 'IDR',
    this.excludeFromTotal = false,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Membuat instance baru dengan nilai tertentu yang di-override.
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

  /// Konversi dari `Map` (response Supabase) ke [WalletModel].
  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      icon: (map['icon'] as String?) ?? 'wallet',
      color: (map['color'] as String?) ?? '#10B981',
      balance: (map['balance'] as num).toDouble(),
      initialBalance: (map['initial_balance'] as num?)?.toDouble() ?? 0,
      currency: (map['currency'] as String?) ?? 'IDR',
      excludeFromTotal: (map['exclude_from_total'] as bool?) ?? false,
      sortOrder: (map['sort_order'] as int?) ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Konversi ke `Map` untuk dikirim ke Supabase.
  ///
  /// Field `id`, `created_at`, `updated_at` tidak disertakan
  /// karena di-generate otomatis oleh database.
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'icon': icon,
      'color': color,
      'balance': balance,
      'initial_balance': initialBalance,
      'currency': currency,
      'exclude_from_total': excludeFromTotal,
      'sort_order': sortOrder,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'WalletModel(id: $id, name: $name, icon: $icon, color: $color, '
        'balance: $balance, initialBalance: $initialBalance, '
        'currency: $currency, excludeFromTotal: $excludeFromTotal)';
  }
}
