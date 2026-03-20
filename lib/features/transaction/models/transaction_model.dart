/// Model data untuk tabel `transactions` di Supabase.
///
/// Kolom sesuai skema database:
/// - `type` CHECK: 'income' | 'expense' | 'transfer' | 'debt' | 'loan' | 'adjustment' | 'transfer_to_asset'
/// - `status` CHECK: 'unpaid' | 'paid' (khusus tipe debt/loan)
/// - `is_multi_item`: flag apakah transaksi punya banyak item
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.type,
    required this.totalAmount,
    required this.date,
    required this.isMultiItem,
    required this.createdAt,
    required this.updatedAt,
    this.destinationWalletId,
    this.merchantName,
    this.note,
    this.attachmentUrl,
    this.withPerson,
    this.status,
    this.dueDate,
  });

  /// Primary key (uuid).
  final String id;

  /// ID user pemilik transaksi (FK → auth.users).
  final String userId;

  /// Dompet sumber transaksi.
  final String walletId;

  /// Dompet tujuan (khusus transfer).
  final String? destinationWalletId;

  /// Tipe transaksi.
  ///
  /// Nilai valid: 'income', 'expense', 'transfer', 'debt',
  /// 'loan', 'adjustment', 'transfer_to_asset'.
  final String type;

  /// Total nominal transaksi (sum dari semua transaction_items).
  final double totalAmount;

  /// Tanggal & waktu transaksi.
  final DateTime date;

  /// Nama merchant / toko.
  final String? merchantName;

  /// Catatan tambahan.
  final String? note;

  /// URL lampiran di Supabase Storage.
  final String? attachmentUrl;

  /// Nama kontak (untuk tipe debt/loan).
  final String? withPerson;

  /// Status pembayaran: 'unpaid' atau 'paid' (khusus debt/loan).
  final String? status;

  /// Tanggal jatuh tempo (khusus debt/loan).
  final DateTime? dueDate;

  /// Flag apakah transaksi punya lebih dari 1 item.
  final bool isMultiItem;

  /// Waktu pembuatan (auto DB).
  final DateTime createdAt;

  /// Waktu terakhir diupdate (auto DB).
  final DateTime updatedAt;

  /// Konversi dari response Supabase ke [TransactionModel].
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      walletId: map['wallet_id'] as String,
      destinationWalletId: map['destination_wallet_id'] as String?,
      type: map['type'] as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      merchantName: map['merchant_name'] as String?,
      note: map['note'] as String?,
      attachmentUrl: map['attachment_url'] as String?,
      withPerson: map['with_person'] as String?,
      status: map['status'] as String?,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      isMultiItem: map['is_multi_item'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Konversi ke Map untuk dikirim ke Supabase.
  ///
  /// `id`, `created_at`, `updated_at` diabaikan (dikelola DB).
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'wallet_id': walletId,
      if (destinationWalletId != null)
        'destination_wallet_id': destinationWalletId,
      'type': type,
      'total_amount': totalAmount,
      'date': date.toIso8601String(),
      if (merchantName != null) 'merchant_name': merchantName,
      if (note != null) 'note': note,
      if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      if (withPerson != null) 'with_person': withPerson,
      if (status != null) 'status': status,
      if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
      'is_multi_item': isMultiItem,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? destinationWalletId,
    String? type,
    double? totalAmount,
    DateTime? date,
    String? merchantName,
    String? note,
    String? attachmentUrl,
    String? withPerson,
    String? status,
    DateTime? dueDate,
    bool? isMultiItem,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      destinationWalletId: destinationWalletId ?? this.destinationWalletId,
      type: type ?? this.type,
      totalAmount: totalAmount ?? this.totalAmount,
      date: date ?? this.date,
      merchantName: merchantName ?? this.merchantName,
      note: note ?? this.note,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      withPerson: withPerson ?? this.withPerson,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      isMultiItem: isMultiItem ?? this.isMultiItem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
