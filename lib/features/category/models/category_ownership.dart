/// Asal baris kategori untuk keputusan **nama tampilan** (lokal vs apa adanya DB).
///
/// Dipakai saat join `categories` ke item transaksi/report: hanya jika kolom
/// `user_id` ikut di-select barulah kita bisa membedakan katalog global dari milik user.
enum CategoryOwnership {
  /// Baris katalog global (`categories.user_id` null).
  global,

  /// Kategori milik user (`user_id` non-null).
  user,

  /// Join tidak ada, atau payload lama tanpa key `user_id` — tampilkan nama DB mentah.
  unknown,
}

CategoryOwnership categoryOwnershipFromJoinedRow(Map<String, dynamic>? cat) {
  if (cat == null) return CategoryOwnership.unknown;
  if (!cat.containsKey('user_id')) return CategoryOwnership.unknown;
  if (cat['user_id'] == null) return CategoryOwnership.global;
  return CategoryOwnership.user;
}
