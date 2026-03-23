/// Enum untuk tipe kategori SakuRapi.
///
/// Sesuai schema `02_DATABASE.md` §2.3:
/// - `income`, `expense`, `system`
enum CategoryTypeEnum {
  income,
  expense,
  system;

  /// Konversi dari string database ke enum.
  static CategoryTypeEnum fromString(String value) {
    return switch (value) {
      'income' => CategoryTypeEnum.income,
      'expense' => CategoryTypeEnum.expense,
      'system' => CategoryTypeEnum.system,
      _ => throw ArgumentError('Unknown category type: $value'),
    };
  }

  /// Konversi ke string untuk database.
  String toDbValue() {
    return switch (this) {
      CategoryTypeEnum.income => 'income',
      CategoryTypeEnum.expense => 'expense',
      CategoryTypeEnum.system => 'system',
    };
  }
}
