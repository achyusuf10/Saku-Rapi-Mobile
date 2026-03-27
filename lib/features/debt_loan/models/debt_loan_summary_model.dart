/// Model aggregate hutang/piutang per kontak.
///
/// Dihasilkan oleh RPC `get_debt_loan_summary`.
/// Merepresentasikan total hutang atau piutang
/// dengan satu orang/kontak tertentu.
class DebtLoanSummaryModel {
  const DebtLoanSummaryModel({
    required this.withPerson,
    this.contactId,
    required this.transactionCount,
    required this.totalPrincipal,
    required this.totalSettled,
    required this.remaining,
    required this.hasUnpaid,
  });

  /// Nama orang.
  final String withPerson;

  /// ID kontak (nullable — data lama mungkin tanpa contact).
  final String? contactId;

  /// Jumlah transaksi hutang/piutang dengan orang ini.
  final int transactionCount;

  /// Total nominal pokok (semua transaksi original).
  final double totalPrincipal;

  /// Total yang sudah dilunasi.
  final double totalSettled;

  /// Sisa yang belum dilunasi.
  final double remaining;

  /// true jika masih ada transaksi yang belum lunas.
  final bool hasUnpaid;

  factory DebtLoanSummaryModel.fromMap(Map<String, dynamic> map) {
    return DebtLoanSummaryModel(
      withPerson: map['with_person'] as String,
      contactId: map['contact_id'] as String?,
      transactionCount: (map['transaction_count'] as num).toInt(),
      totalPrincipal: _toDouble(map['total_principal']),
      totalSettled: _toDouble(map['total_settled']),
      remaining: _toDouble(map['remaining']),
      hasUnpaid: map['has_unpaid'] as bool,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
