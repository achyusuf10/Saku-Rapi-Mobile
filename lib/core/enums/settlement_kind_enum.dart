/// Enum untuk settlement kind pada transaksi hutang/piutang.
///
/// Sesuai schema `02_DATABASE.md` §2.4 dan PRD §5.1:
/// - `debt_payment`: pelunasan hutang (type = expense)
/// - `loan_collection`: penagihan piutang (type = income)
enum SettlementKindEnum {
  debtPayment,
  loanCollection;

  /// Konversi dari string database ke enum.
  static SettlementKindEnum fromString(String value) {
    return switch (value) {
      'debt_payment' => SettlementKindEnum.debtPayment,
      'loan_collection' => SettlementKindEnum.loanCollection,
      _ => throw ArgumentError('Unknown settlement kind: $value'),
    };
  }

  /// Konversi ke string untuk database.
  String toDbValue() {
    return switch (this) {
      SettlementKindEnum.debtPayment => 'debt_payment',
      SettlementKindEnum.loanCollection => 'loan_collection',
    };
  }
}
