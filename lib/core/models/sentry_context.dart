/// Konteks tambahan yang dilampirkan ke setiap event Sentry.
///
/// Gunakan [action] untuk mendeskripsikan operasi yang sedang dijalankan
/// (e.g., `"create_transaction"`, `"sync_wallets"`), [page] untuk nama
/// screen, dan [payload]/[response] untuk melacak data yang dikirim/diterima.
class SentryContext {
  const SentryContext({
    required this.action,
    this.page,
    this.payload,
    this.response,
    this.tags,
  });

  /// Nama operasi yang sedang berjalan (e.g., `"create_transaction"`).
  final String action;

  /// Nama screen/page tempat error terjadi (e.g., `"TransactionFormPage"`).
  final String? page;

  /// Data yang dikirim ke backend saat error terjadi.
  final Map<String, dynamic>? payload;

  /// Data respons dari backend saat error terjadi.
  final Map<String, dynamic>? response;

  /// Tag tambahan untuk filter di dashboard Sentry.
  final Map<String, String>? tags;
}
