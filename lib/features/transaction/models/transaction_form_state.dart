/// State satu baris item dalam form transaksi.
///
/// Digunakan oleh [TransactionFormState.items].
/// Untuk single-item, list selalu berisi tepat 1 elemen.
class TransactionItemFormState {
  const TransactionItemFormState({
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    this.categoryIcon,
    this.amount,
    this.note,
  });

  /// ID kategori terpilih.
  final String? categoryId;

  /// Nama kategori (untuk tampilan, tidak dikirim ke DB).
  final String? categoryName;

  /// Hex color kategori (untuk tampilan).
  final String? categoryColor;

  /// Icon kategori (untuk tampilan).
  final String? categoryIcon;

  /// Nominal item ini (nullable saat form belum diisi).
  final double? amount;

  /// Catatan per-item (opsional).
  final String? note;

  TransactionItemFormState copyWith({
    String? categoryId,
    String? categoryName,
    String? categoryColor,
    String? categoryIcon,
    double? amount,
    String? note,
    bool clearCategory = false,
  }) {
    return TransactionItemFormState(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      categoryName: clearCategory ? null : (categoryName ?? this.categoryName),
      categoryColor: clearCategory
          ? null
          : (categoryColor ?? this.categoryColor),
      categoryIcon: clearCategory ? null : (categoryIcon ?? this.categoryIcon),
      amount: amount ?? this.amount,
      note: note ?? this.note,
    );
  }
}

/// State lengkap untuk form input transaksi.
///
/// Ini adalah **form state**, bukan model database.
/// Dikelola oleh [TransactionFormController].
///
/// Mendukung semua tipe transaksi:
/// - `expense`, `income` — transaksi biasa
/// - `transfer` — wajib ada [destinationWalletId]
/// - `debt`, `loan` — wajib ada [withPerson], [status]
/// - `adjustment` — otomatis dari fitur Adjust Wallet
class TransactionFormState {
  const TransactionFormState({
    this.type = 'expense',
    this.items = const [TransactionItemFormState()],
    this.walletId,
    this.walletName,
    this.destinationWalletId,
    this.destinationWalletName,
    required this.date,
    this.merchantName,
    this.note,
    this.attachmentLocalPath,
    this.withPerson,
    this.status = 'unpaid',
    this.dueDate,
    this.prefillSource,
  });

  /// Tipe transaksi aktif.
  ///
  /// Nilai valid: 'expense', 'income', 'transfer', 'debt', 'loan', 'adjustment'.
  final String type;

  /// Daftar item transaksi. Minimal 1 elemen.
  final List<TransactionItemFormState> items;

  /// ID wallet sumber.
  final String? walletId;

  /// Nama wallet sumber (untuk tampilan).
  final String? walletName;

  /// ID wallet tujuan (untuk tipe transfer).
  final String? destinationWalletId;

  /// Nama wallet tujuan (untuk tampilan).
  final String? destinationWalletName;

  /// Tanggal transaksi. Default: hari ini.
  final DateTime date;

  /// Nama merchant / toko (opsional, dari OCR).
  final String? merchantName;

  /// Catatan tambahan (opsional).
  final String? note;

  /// Path lokal foto struk sebelum upload ke Storage.
  final String? attachmentLocalPath;

  /// Nama kontak (wajib untuk debt/loan).
  final String? withPerson;

  /// Status pembayaran: 'unpaid' atau 'paid' (untuk debt/loan).
  final String? status;

  /// Tanggal jatuh tempo (opsional, untuk debt/loan).
  final DateTime? dueDate;

  /// Sumber pre-fill: 'voice', 'ocr', atau `null` jika diisi manual.
  final String? prefillSource;

  // ─────────────────────────────────────────────────────────────
  // Computed properties
  // ─────────────────────────────────────────────────────────────

  /// Total seluruh nominal dari semua item.
  double get totalAmount =>
      items.fold(0.0, (sum, item) => sum + (item.amount ?? 0.0));

  /// `true` jika ada lebih dari 1 item (multi-item mode).
  bool get isMultiItem => items.length > 1;

  /// `true` jika tipe adalah transfer.
  bool get isTransfer => type == 'transfer';

  /// `true` jika tipe adalah debt atau loan.
  bool get isDebtOrLoan => type == 'debt' || type == 'loan';

  /// `true` jika form berasal dari voice input.
  bool get isFromVoice => prefillSource == 'voice';

  /// `true` jika form berasal dari OCR struk.
  bool get isFromOcr => prefillSource == 'ocr';

  // ─────────────────────────────────────────────────────────────
  // Item helpers
  // ─────────────────────────────────────────────────────────────

  /// Shortcut ke amount item pertama (single-item mode).
  double? get singleAmount => items.isNotEmpty ? items.first.amount : null;

  /// Shortcut ke categoryId item pertama (single-item mode).
  String? get singleCategoryId =>
      items.isNotEmpty ? items.first.categoryId : null;

  TransactionFormState copyWith({
    String? type,
    List<TransactionItemFormState>? items,
    String? walletId,
    String? walletName,
    String? destinationWalletId,
    String? destinationWalletName,
    DateTime? date,
    String? merchantName,
    String? note,
    String? attachmentLocalPath,
    String? withPerson,
    String? status,
    DateTime? dueDate,
    String? prefillSource,
    bool clearDestinationWallet = false,
    bool clearAttachment = false,
    bool clearNote = false,
    bool clearMerchantName = false,
    bool clearWithPerson = false,
    bool clearDueDate = false,
  }) {
    return TransactionFormState(
      type: type ?? this.type,
      items: items ?? this.items,
      walletId: walletId ?? this.walletId,
      walletName: walletName ?? this.walletName,
      destinationWalletId: clearDestinationWallet
          ? null
          : (destinationWalletId ?? this.destinationWalletId),
      destinationWalletName: clearDestinationWallet
          ? null
          : (destinationWalletName ?? this.destinationWalletName),
      date: date ?? this.date,
      merchantName: clearMerchantName
          ? null
          : (merchantName ?? this.merchantName),
      note: clearNote ? null : (note ?? this.note),
      attachmentLocalPath: clearAttachment
          ? null
          : (attachmentLocalPath ?? this.attachmentLocalPath),
      withPerson: clearWithPerson ? null : (withPerson ?? this.withPerson),
      status: status ?? this.status,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      prefillSource: prefillSource ?? this.prefillSource,
    );
  }
}
