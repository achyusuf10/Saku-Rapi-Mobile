import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';

/// Jenis periode budget.
enum BudgetPeriodType {
  weekly('weekly'),
  monthly('monthly'),
  quarterly('quarterly'),
  yearly('yearly'),
  custom('custom');

  const BudgetPeriodType(this.value);
  final String value;

  static BudgetPeriodType fromString(String value) {
    return BudgetPeriodType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BudgetPeriodType.monthly,
    );
  }
}

/// Model data untuk budget/anggaran.
///
/// Merepresentasikan satu record dari tabel `public.budgets`.
/// `used_amount` diupdate oleh trigger DB `update_budget_usage()` setiap kali
/// ada perubahan pada `transaction_items` (expense non-settlement).
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
    this.periodType = BudgetPeriodType.monthly,
    this.isRecurring = false,
    this.carryForward = false,
    this.createdAt,
    this.updatedAt,
    this.category,
    this.wallet,
  });


  /// UUID primary key.
  final String id;

  /// UUID pemilik budget.
  final String userId;

  /// UUID kategori expense yang dibudget.
  final String categoryId;

  /// UUID wallet scope. Null = global (semua wallet).
  final String? walletId;

  /// Nominal limit anggaran.
  final double amount;

  /// Pemakaian saat ini — dihitung otomatis oleh DB trigger.
  final double usedAmount;

  /// Tanggal mulai periode budget (inclusive).
  final DateTime startDate;

  /// Tanggal akhir periode budget (inclusive).
  final DateTime endDate;

  /// Jenis periode budget (weekly/monthly/quarterly/yearly/custom).
  final BudgetPeriodType periodType;

  /// Auto-renew budget di periode berikutnya.
  final bool isRecurring;

  /// Sisa positif diteruskan ke budget berikutnya saat renew.
  final bool carryForward;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Relasi lokal: kategori yang ditarget. Diisi saat fetch join.
  final CategoryModel? category;

  /// Relasi lokal: wallet scope. Diisi saat fetch join.
  final WalletModel? wallet;

  // ───────────────── Computed ─────────────────

  /// Sisa budget yang belum terpakai.
  double get remaining => amount - usedAmount;

  /// Persentase usage (0.0 – ~∞ jika over budget).
  double get usageRatio => amount > 0 ? usedAmount / amount : 0;

  /// Persentase usage sebagai 0–100+.
  double get usagePercent => usageRatio * 100;

  /// Apakah budget sudah terpakai >= 100%.
  bool get isOverBudget => usedAmount >= amount;

  /// Apakah budget sudah terpakai >= 50%.
  bool get isHalfUsed => usageRatio >= 0.5;

  /// Apakah budget sudah terpakai >= 80%.
  bool get isNearLimit => usageRatio >= 0.8;

  /// Apakah budget masih dalam periode aktif (sekarang antara start & end).
  bool get isActive {
    final now = DateTime.now();
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    return !now.isBefore(start) && !now.isAfter(end);
  }

  /// Sisa hari dalam periode budget.
  int get daysRemaining {
    final now = DateTime.now();
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    final diff = end.difference(now).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Total hari dalam periode budget.
  int get totalDays {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return end.difference(start).inDays + 1; // inclusive
  }

  /// Rasio waktu yang sudah berlalu (0.0 – 1.0).
  /// Digunakan untuk menampilkan marker "expected progress" hari ini.
  double get expectedRatio {
    final now = DateTime.now();
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    if (now.isBefore(start)) return 0;
    if (now.isAfter(end)) return 1;
    final elapsed = now.difference(start).inDays;
    final total = end.difference(start).inDays;
    return total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0;
  }

  // ───────────────── Factory ─────────────────

  /// Buat [BudgetModel] dari Map (hasil query Supabase).
  ///
  /// Mendukung nested join untuk `categories` dan `wallets`.
  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      categoryId: map['category_id'] as String,
      walletId: map['wallet_id'] as String?,
      amount: _toDouble(map['amount']),
      usedAmount: _toDouble(map['used_amount']),
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      periodType: BudgetPeriodType.fromString(
        (map['period_type'] as String?) ?? 'monthly',
      ),
      isRecurring: (map['is_recurring'] as bool?) ?? false,
      carryForward: (map['carry_forward'] as bool?) ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      category: map['categories'] != null
          ? CategoryModel.fromMap(map['categories'] as Map<String, dynamic>)
          : null,
      wallet: map['wallets'] != null
          ? WalletModel.fromMap(map['wallets'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Map untuk INSERT — tanpa id, used_amount, notification flags, timestamps.
  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'wallet_id': walletId,
      'amount': amount,
      'start_date': _formatDate(startDate),
      'end_date': _formatDate(endDate),
      'period_type': periodType.value,
      'is_recurring': isRecurring,
      'carry_forward': carryForward,
    };
  }

  /// Map untuk UPDATE — hanya field yang boleh diubah user.
  Map<String, dynamic> toUpdateMap() {
    return {
      'category_id': categoryId,
      'wallet_id': walletId,
      'amount': amount,
      'start_date': _formatDate(startDate),
      'end_date': _formatDate(endDate),
      'period_type': periodType.value,
      'is_recurring': isRecurring,
      'carry_forward': carryForward,
    };
  }

  /// Map lengkap untuk local cache (Hive).
  Map<String, dynamic> toFullMap() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'wallet_id': walletId,
      'amount': amount,
      'used_amount': usedAmount,
      'start_date': _formatDate(startDate),
      'end_date': _formatDate(endDate),
      'period_type': periodType.value,
      'is_recurring': isRecurring,
      'carry_forward': carryForward,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (category != null) 'categories': category!.toFullMap(),
      if (wallet != null) 'wallets': wallet!.toFullMap(),
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
    BudgetPeriodType? periodType,
    bool? isRecurring,
    bool? carryForward,
    DateTime? createdAt,
    DateTime? updatedAt,
    CategoryModel? category,
    WalletModel? wallet,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      amount: amount ?? this.amount,
      usedAmount: usedAmount ?? this.usedAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      periodType: periodType ?? this.periodType,
      isRecurring: isRecurring ?? this.isRecurring,
      carryForward: carryForward ?? this.carryForward,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      wallet: wallet ?? this.wallet,
    );
  }

  // ───────────────── Helpers ─────────────────

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
