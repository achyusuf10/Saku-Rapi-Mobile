/// Model data untuk tabel `transaction_items` di Supabase.
///
/// Setiap transaksi MINIMAL memiliki 1 item.
/// Multi-item hanya berlaku untuk tipe 'expense'.
class TransactionItemModel {
  const TransactionItemModel({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.sortOrder,
    this.categoryId,
    this.note,
  });

  /// Primary key (uuid).
  final String id;

  /// FK ke `transactions.id`.
  final String transactionId;

  /// FK ke `categories.id`. Nullable (misal untuk adjustment).
  final String? categoryId;

  /// Nominal item ini.
  final double amount;

  /// Catatan per-item (opsional).
  final String? note;

  /// Urutan tampilan dalam list multi-item.
  final int sortOrder;

  factory TransactionItemModel.fromMap(Map<String, dynamic> map) {
    return TransactionItemModel(
      id: map['id'] as String,
      transactionId: map['transaction_id'] as String,
      categoryId: map['category_id'] as String?,
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transaction_id': transactionId,
      if (categoryId != null) 'category_id': categoryId,
      'amount': amount,
      if (note != null) 'note': note,
      'sort_order': sortOrder,
    };
  }

  TransactionItemModel copyWith({
    String? id,
    String? transactionId,
    String? categoryId,
    double? amount,
    String? note,
    int? sortOrder,
  }) {
    return TransactionItemModel(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
