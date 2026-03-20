/// Status anggaran berdasarkan persentase pemakaian.
///
/// - [safe]: < 80% — hijau
/// - [warning]: 80–99% — kuning/oranye
/// - [overBudget]: ≥ 100% — merah
enum BudgetStatus { safe, warning, overBudget }

/// Model data untuk tabel `budgets` di Supabase.
///
/// Field `used_amount` dikelola oleh Trigger DB — Flutter hanya READ.
/// Budget bisa **global** (`walletId == null`) atau **per-dompet**.
class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    this.walletId,
    required this.amount,
    required this.usedAmount,
    required this.startDate,
    required this.endDate,
    required this.isRecurring,
    required this.notificationSent80,
    required this.notificationSent100,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.walletName,
  });

  /// UUID auto-generated.
  final String id;

  /// UUID user pemilik budget.
  final String userId;

  /// UUID kategori (FK ke `categories`).
  final String categoryId;

  /// UUID dompet tertentu. `null` = berlaku untuk semua dompet.
  final String? walletId;

  /// Batas nominal anggaran.
  final double amount;

  /// Jumlah yang sudah terpakai (dikelola Trigger DB).
  final double usedAmount;

  /// Tanggal mulai periode.
  final DateTime startDate;

  /// Tanggal akhir periode.
  final DateTime endDate;

  /// Apakah budget otomatis diperpanjang bulan depan.
  final bool isRecurring;

  /// Flag notifikasi 80% sudah pernah dikirim.
  final bool notificationSent80;

  /// Flag notifikasi 100% sudah pernah dikirim.
  final bool notificationSent100;

  final DateTime createdAt;
  final DateTime updatedAt;

  // ── JOIN fields (opsional, untuk tampilan UI) ──

  /// Nama kategori (dari JOIN).
  final String? categoryName;

  /// Icon kategori (dari JOIN).
  final String? categoryIcon;

  /// Hex color kategori (dari JOIN).
  final String? categoryColor;

  /// Nama wallet (dari JOIN, null jika global).
  final String? walletName;

  // ─────────────────────────────────────────────────────────
  // Computed getters
  // ─────────────────────────────────────────────────────────

  /// Persentase pemakaian (0.0 – 1.0+).
  double get usagePercentage => amount > 0 ? (usedAmount / amount) : 0.0;

  /// Status anggaran berdasarkan pemakaian.
  BudgetStatus get status {
    if (usagePercentage >= 1.0) return BudgetStatus.overBudget;
    if (usagePercentage >= 0.8) return BudgetStatus.warning;
    return BudgetStatus.safe;
  }

  /// Sisa anggaran (bisa negatif jika over-budget).
  double get remainingAmount => amount - usedAmount;

  /// Apakah sudah melebihi anggaran.
  bool get isOverBudget => usedAmount >= amount;

  /// Sisa hari dalam periode saat ini.
  int get daysRemainingInPeriod {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  /// Apakah budget sedang aktif untuk hari ini.
  bool get isActiveToday {
    final now = DateTime.now();
    return now.isAfter(startDate.subtract(const Duration(days: 1))) &&
        now.isBefore(endDate.add(const Duration(days: 1)));
  }

  // ─────────────────────────────────────────────────────────
  // Serialization
  // ─────────────────────────────────────────────────────────

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    // Supabase JOIN: categories(name, icon, color), wallets(name)
    final catMap = map['categories'] as Map<String, dynamic>?;
    final walMap = map['wallets'] as Map<String, dynamic>?;

    return BudgetModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      categoryId: map['category_id'] as String,
      walletId: map['wallet_id'] as String?,
      amount: (map['amount'] as num).toDouble(),
      usedAmount: (map['used_amount'] as num).toDouble(),
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      isRecurring: map['is_recurring'] as bool? ?? false,
      notificationSent80: map['notification_sent_80'] as bool? ?? false,
      notificationSent100: map['notification_sent_100'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      categoryName: catMap?['name'] as String?,
      categoryIcon: catMap?['icon'] as String?,
      categoryColor: catMap?['color'] as String?,
      walletName: walMap?['name'] as String?,
    );
  }

  /// Serialisasi untuk INSERT/UPDATE ke Supabase.
  ///
  /// Tidak menyertakan: `id`, `used_amount`, `notification_sent_*`,
  /// `created_at`, `updated_at` — dikelola DB.
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'wallet_id': walletId,
      'amount': amount,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'is_recurring': isRecurring,
    };
  }

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? walletId,
    double? amount,
    double? usedAmount,
    DateTime? startDate,
    DateTime? endDate,
    bool? isRecurring,
    bool? notificationSent80,
    bool? notificationSent100,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    String? walletName,
    bool clearWallet = false,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      walletId: clearWallet ? null : (walletId ?? this.walletId),
      amount: amount ?? this.amount,
      usedAmount: usedAmount ?? this.usedAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isRecurring: isRecurring ?? this.isRecurring,
      notificationSent80: notificationSent80 ?? this.notificationSent80,
      notificationSent100: notificationSent100 ?? this.notificationSent100,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      walletName: walletName ?? this.walletName,
    );
  }
}

/// Model ringkasan anggaran untuk header di `BudgetListScreen`.
class BudgetSummaryModel {
  const BudgetSummaryModel({
    required this.totalAmount,
    required this.totalUsedAmount,
    required this.daysRemainingInMonth,
  });

  /// Total batas anggaran semua budget aktif.
  final double totalAmount;

  /// Total yang sudah terpakai dari semua budget aktif.
  final double totalUsedAmount;

  /// Sisa hari hingga akhir bulan.
  final int daysRemainingInMonth;

  /// Sisa yang bisa dibelanjakan.
  double get remainingAmount => totalAmount - totalUsedAmount;

  /// Persentase pemakaian keseluruhan (0.0 – 1.0+).
  double get usagePercentage =>
      totalAmount > 0 ? (totalUsedAmount / totalAmount) : 0.0;

  /// Status keseluruhan.
  BudgetStatus get status {
    if (usagePercentage >= 1.0) return BudgetStatus.overBudget;
    if (usagePercentage >= 0.8) return BudgetStatus.warning;
    return BudgetStatus.safe;
  }
}
