class AppConstants {
  static List<String> videoExtension = [
    'mp4',
    'avi',
    '3gp',
    'flv',
    'wmv',
    'mk3d',
    'mkv',
    'mov',
    'webm',
  ];
  static List<String> audioExtension = [
    'm4a',
    'mp3',
    'wav',
    'aac',
    'ogg',
    'flac',
    'wma',
    'alac',
    'aiff',
  ];
  static List<String> imageExtension = [
    'jpg',
    'jpe',
    'jpeg',
    'png',
    'gif',
    'webp',
    'heic',
  ];

  /// Simbol mata uang aktif aplikasi.
  static const String currencySymbol = 'Rp ';

  // ── Cache TTL ──

  /// TTL cache kamus parsing AI (24 jam).
  static const Duration cacheTtlDictionary = Duration(hours: 24);

  /// TTL cache harga investasi (1 jam).
  static const Duration cacheTtlInvestmentPrice = Duration(hours: 1);

  // ── Pagination ──

  /// Jumlah item per halaman untuk daftar transaksi.
  static const int transactionPageSize = 20;

  // ── Voice Input ──

  /// Durasi maksimum recording voice input (detik).
  static const int voiceMaxDurationSeconds = 10;

  /// Durasi jeda otomatis sebelum voice input berhenti (detik).
  static const int voicePauseDurationSeconds = 3;

  // ── Budget Thresholds ──

  /// Ambang batas peringatan anggaran (80%).
  static const double budgetWarningThreshold = 0.8;

  /// Ambang batas anggaran terlampaui (100%).
  static const double budgetOverThreshold = 1.0;

  // ── Debt Reminder ──

  /// Default hari sebelum jatuh tempo untuk reminder hutang.
  static const int defaultDebtReminderDaysBefore = 3;
}
