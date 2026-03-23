/// Enum untuk status hutang/piutang.
///
/// Sesuai schema `02_DATABASE.md` §2.4:
/// - `unpaid`, `paid`, `partial`
enum DebtStatusEnum {
  unpaid,
  paid,
  partial;

  /// Konversi dari string database ke enum.
  static DebtStatusEnum fromString(String value) {
    return switch (value) {
      'unpaid' => DebtStatusEnum.unpaid,
      'paid' => DebtStatusEnum.paid,
      'partial' => DebtStatusEnum.partial,
      _ => throw ArgumentError('Unknown debt status: $value'),
    };
  }

  /// Konversi ke string untuk database.
  String toDbValue() {
    return switch (this) {
      DebtStatusEnum.unpaid => 'unpaid',
      DebtStatusEnum.paid => 'paid',
      DebtStatusEnum.partial => 'partial',
    };
  }
}
