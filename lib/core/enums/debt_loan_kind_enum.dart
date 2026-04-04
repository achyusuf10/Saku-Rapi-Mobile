/// Jenis operasi hutang/piutang.
///
/// Menggabungkan semua jenis transaksi terkait hutang/piutang:
/// - [debt]: membuat hutang baru
/// - [loan]: membuat piutang baru
/// - [debtPayment]: pelunasan hutang (settlement_kind = 'debt_payment')
/// - [loanCollection]: penerimaan piutang (settlement_kind = 'loan_collection')
///
/// Menggantikan `SettlementKindEnum` yang sebelumnya terpisah.
enum DebtLoanKindEnum {
  debt,
  loan,
  debtPayment,
  loanCollection;

  /// Apakah jenis ini adalah pelunasan/penerimaan.
  bool get isSettlement =>
      this == DebtLoanKindEnum.debtPayment ||
      this == DebtLoanKindEnum.loanCollection;

  /// Tipe transaksi referensi — 'debt' untuk pelunasan, 'loan' untuk penerimaan.
  String get referenceType => switch (this) {
    DebtLoanKindEnum.debtPayment => 'debt',
    DebtLoanKindEnum.loanCollection => 'loan',
    _ => '',
  };

  /// Konversi ke string untuk database (settlement_kind column).
  String toDbValue() => switch (this) {
    DebtLoanKindEnum.debt => 'debt',
    DebtLoanKindEnum.loan => 'loan',
    DebtLoanKindEnum.debtPayment => 'debt_payment',
    DebtLoanKindEnum.loanCollection => 'loan_collection',
  };

  /// Konversi dari string database ke enum.
  static DebtLoanKindEnum fromString(String value) {
    return switch (value) {
      'debt' => DebtLoanKindEnum.debt,
      'loan' => DebtLoanKindEnum.loan,
      'debt_payment' => DebtLoanKindEnum.debtPayment,
      'loan_collection' => DebtLoanKindEnum.loanCollection,
      _ => throw ArgumentError('Unknown debt loan kind: $value'),
    };
  }
}
