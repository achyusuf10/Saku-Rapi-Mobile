/// Enum untuk tipe transaksi SakuRapi.
///
/// Sesuai schema `02_DATABASE.md` §2.4:
/// - `income`, `expense`, `transfer`, `debt`, `loan`, `adjustment`, `transfer_to_asset`
enum TransactionTypeEnum {
  income,
  expense,
  transfer,
  debt,
  loan,
  adjustment,
  transferToAsset;

  /// Konversi dari string database ke enum.
  static TransactionTypeEnum fromString(String value) {
    return switch (value) {
      'income' => TransactionTypeEnum.income,
      'expense' => TransactionTypeEnum.expense,
      'transfer' => TransactionTypeEnum.transfer,
      'debt' => TransactionTypeEnum.debt,
      'loan' => TransactionTypeEnum.loan,
      'adjustment' => TransactionTypeEnum.adjustment,
      'transfer_to_asset' => TransactionTypeEnum.transferToAsset,
      _ => throw ArgumentError('Unknown transaction type: $value'),
    };
  }

  /// Konversi ke string untuk database.
  String toDbValue() {
    return switch (this) {
      TransactionTypeEnum.income => 'income',
      TransactionTypeEnum.expense => 'expense',
      TransactionTypeEnum.transfer => 'transfer',
      TransactionTypeEnum.debt => 'debt',
      TransactionTypeEnum.loan => 'loan',
      TransactionTypeEnum.adjustment => 'adjustment',
      TransactionTypeEnum.transferToAsset => 'transfer_to_asset',
    };
  }

  /// Apakah tipe ini masuk laporan P&L (PRD §4.2).
  bool get isReportable {
    return switch (this) {
      TransactionTypeEnum.income => true,
      TransactionTypeEnum.expense => true,
      _ => false,
    };
  }

  /// Apakah tipe ini masuk perhitungan budget (PRD §4.3).
  bool get isBudgetable {
    return this == TransactionTypeEnum.expense;
  }

  /// Apakah tipe ini memerlukan `destination_wallet_id`.
  bool get requiresDestinationWallet {
    return this == TransactionTypeEnum.transfer;
  }

  /// Apakah tipe ini memerlukan `with_person`.
  bool get requiresWithPerson {
    return this == TransactionTypeEnum.debt || this == TransactionTypeEnum.loan;
  }
}
