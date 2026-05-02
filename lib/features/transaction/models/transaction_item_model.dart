import 'package:app_saku_rapi/features/category/models/category_ownership.dart';

/// Model data untuk item/detail dalam satu transaksi.
///
/// Merepresentasikan satu record dari tabel `public.transaction_items`.
/// Setiap transaksi wajib punya minimal 1 item.
/// `sum(amount)` semua item harus sama dengan `transactions.total_amount`.
class TransactionItemModel {
  const TransactionItemModel({
    this.id,
    this.transactionId,
    this.categoryId,
    this.itemName,
    this.qty = 1,
    this.unitPrice,
    required this.amount,
    this.note,
    this.sortOrder = 0,
    // Joined display fields
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.categoryBackgroundColor,
    this.categoryOwnership = CategoryOwnership.unknown,
  });

  final String? id;
  final String? transactionId;
  final String? categoryId;
  final String? itemName;
  final double qty;
  final double? unitPrice;

  /// Subtotal authoritative. Jika qty * unitPrice tersedia, harus = amount.
  final double amount;
  final String? note;
  final int sortOrder;

  // ─── Display-only joined fields ───
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String? categoryBackgroundColor;

  /// Kepemilikan kategori hasil join — menentukan apakah nama boleh dilokalkan.
  final CategoryOwnership categoryOwnership;

  // ───────────────── Factory ─────────────────

  factory TransactionItemModel.fromMap(Map<String, dynamic> map) {
    // Handle nested category from Supabase join
    final catData = map['categories'];
    String? catName;
    String? catIcon;
    String? catColor;
    String? catBackground;
    CategoryOwnership ownership = CategoryOwnership.unknown;
    if (catData is Map<String, dynamic>) {
      catName = catData['name'] as String?;
      catIcon = catData['icon'] as String?;
      catColor = catData['color'] as String?;
      catBackground = catData['background_color'] as String?;
      ownership = categoryOwnershipFromJoinedRow(catData);
    }

    return TransactionItemModel(
      id: map['id'] as String?,
      transactionId: map['transaction_id'] as String?,
      categoryId: map['category_id'] as String?,
      itemName: map['item_name'] as String?,
      qty: _toDouble(map['qty']),
      unitPrice: map['unit_price'] != null
          ? _toDouble(map['unit_price'])
          : null,
      amount: _toDouble(map['amount']),
      note: map['note'] as String?,
      sortOrder: (map['sort_order'] as int?) ?? 0,
      categoryName: catName,
      categoryIcon: catIcon,
      categoryColor: catColor,
      categoryBackgroundColor: catBackground,
      categoryOwnership: ownership,
    );
  }

  // ───────────────── Serialization ─────────────────

  /// Map untuk RPC `p_items` JSONB array element.
  Map<String, dynamic> toRpcMap() {
    return {
      'category_id': categoryId,
      'item_name': itemName,
      'qty': qty,
      'unit_price': unitPrice,
      'amount': amount,
      'note': note,
      'sort_order': sortOrder,
    };
  }

  /// Map untuk Hive cache (full data termasuk ID).
  Map<String, dynamic> toFullMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'category_id': categoryId,
      'item_name': itemName,
      'qty': qty,
      'unit_price': unitPrice,
      'amount': amount,
      'note': note,
      'sort_order': sortOrder,
    };
  }

  // ───────────────── CopyWith ─────────────────

  TransactionItemModel copyWith({
    String? id,
    String? transactionId,
    String? categoryId,
    String? itemName,
    double? qty,
    double? unitPrice,
    double? amount,
    String? note,
    int? sortOrder,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    String? categoryBackgroundColor,
    CategoryOwnership? categoryOwnership,
  }) {
    return TransactionItemModel(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      categoryId: categoryId ?? this.categoryId,
      itemName: itemName ?? this.itemName,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      sortOrder: sortOrder ?? this.sortOrder,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      categoryBackgroundColor:
          categoryBackgroundColor ?? this.categoryBackgroundColor,
      categoryOwnership: categoryOwnership ?? this.categoryOwnership,
    );
  }

  /// Hapus semua field kategori (categoryId, categoryName, icon, color).
  TransactionItemModel clearCategory() {
    return TransactionItemModel(
      id: id,
      transactionId: transactionId,
      categoryId: null,
      itemName: itemName,
      qty: qty,
      unitPrice: unitPrice,
      amount: amount,
      note: note,
      sortOrder: sortOrder,
      categoryName: null,
      categoryIcon: null,
      categoryColor: null,
      categoryBackgroundColor: null,
      categoryOwnership: CategoryOwnership.unknown,
    );
  }

  // ───────────────── Helpers ─────────────────

  /// Selaraskan [qty], [unitPrice], dan [amount] untuk input form & prefill AI/OCR.
  ///
  /// - Jika harga satuan ada dan tidak nol: `amount = qty × unitPrice`.
  /// - Jika harga satuan null atau 0 tetapi subtotal ([amount]) tidak nol — pola umum
  ///   baris diskon dari AI (`unitPrice: 0`) — turunkan `unitPrice = amount / qty`
  ///   supaya kolom tidak kosong dan amount tidak tertimpa nol.
  static TransactionItemModel resolveLineAmount(TransactionItemModel item) {
    final up = item.unitPrice;
    final q = item.qty;

    if (up != null && q > 0 && up != 0) {
      return item.copyWith(amount: q * up);
    }
    if (q > 0 && item.amount != 0 && (up == null || up == 0)) {
      return item.copyWith(unitPrice: item.amount / q);
    }
    return item;
  }

  /// Jika `sum(items.amount) ≠ authoritativeTotal`, tambahkan satu baris penyesuaian:
  /// selisih positif → [positiveDiffLabel], selisih negatif → [negativeDiffLabel].
  ///
  /// Baris tambahan: qty 1, unitPrice = diff, amount = diff (selaras dengan AI Parse).
  static List<TransactionItemModel> balanceItemsAgainstAuthoritativeTotal({
    required List<TransactionItemModel> items,
    required double authoritativeTotal,
    required String positiveDiffLabel,
    required String negativeDiffLabel,
    double tolerance = 1.0,
  }) {
    if (items.isEmpty) return items;
    final sum = items.fold<double>(0, (s, i) => s + i.amount);
    final diff = authoritativeTotal - sum;
    if (diff.abs() < tolerance) return items;

    final maxOrder = items.map((i) => i.sortOrder).reduce((a, b) => a > b ? a : b);
    final row = TransactionItemModel(
      itemName: diff > 0 ? positiveDiffLabel : negativeDiffLabel,
      qty: 1,
      unitPrice: diff,
      amount: diff,
      sortOrder: maxOrder + 1,
    );
    return [...items, row];
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
