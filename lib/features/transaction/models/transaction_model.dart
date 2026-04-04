import 'package:app_saku_rapi/core/enums/debt_loan_kind_enum.dart';
import 'package:app_saku_rapi/core/enums/debt_status_enum.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';

/// Model data untuk transaksi.
///
/// Merepresentasikan satu record dari tabel `public.transactions`.
/// Write dilakukan melalui RPC atomik, bukan insert langsung.
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.userId,
    required this.walletId,
    this.destinationWalletId,
    required this.type,
    required this.totalAmount,
    required this.date,
    this.merchantName,
    this.note,
    this.attachmentUrl,
    this.withPerson,
    this.status,
    this.dueDate,
    required this.isMultiItem,
    this.referenceTransactionId,
    this.settlementKind,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
    // Joined fields for display
    this.walletName,
    this.destinationWalletName,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    // Contact (hutang/piutang)
    this.contactId,
    this.contactName,
    this.contactPhone,
  });

  final String id;
  final String userId;
  final String walletId;
  final String? destinationWalletId;
  final TransactionTypeEnum type;
  final double totalAmount;
  final DateTime date;
  final String? merchantName;
  final String? note;
  final String? attachmentUrl;
  final String? withPerson;
  final DebtStatusEnum? status;
  final DateTime? dueDate;
  final bool isMultiItem;
  final String? referenceTransactionId;
  final DebtLoanKindEnum? settlementKind;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Transaction items (loaded separately or joined).
  final List<TransactionItemModel> items;

  // ─── Display-only joined fields ───
  final String? walletName;
  final String? destinationWalletName;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;

  // ─── Contact joined fields (hutang/piutang) ───
  final String? contactId;
  final String? contactName;
  final String? contactPhone;

  // ───────────────── Factory ─────────────────

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    final itemsList = map['transaction_items'];
    List<TransactionItemModel> items = [];
    if (itemsList is List) {
      items = itemsList
          .map((e) => TransactionItemModel.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    return TransactionModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      walletId: map['wallet_id'] as String,
      destinationWalletId: map['destination_wallet_id'] as String?,
      type: TransactionTypeEnum.fromString(map['type'] as String),
      totalAmount: _toDouble(map['total_amount']),
      date: DateTime.parse(map['date'] as String),
      merchantName: map['merchant_name'] as String?,
      note: map['note'] as String?,
      attachmentUrl: map['attachment_url'] as String?,
      withPerson: map['with_person'] as String?,
      status: map['status'] != null
          ? DebtStatusEnum.fromString(map['status'] as String)
          : null,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      isMultiItem: (map['is_multi_item'] as bool?) ?? false,
      referenceTransactionId: map['reference_transaction_id'] as String?,
      settlementKind: map['settlement_kind'] != null
          ? DebtLoanKindEnum.fromString(map['settlement_kind'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      items: items,
      // Joined display fields from nested select
      walletName: _nestedName(map['wallets']),
      destinationWalletName: _nestedName(map['destination_wallet']),
      categoryName: items.isNotEmpty ? items.first.categoryName : null,
      categoryIcon: items.isNotEmpty ? items.first.categoryIcon : null,
      categoryColor: items.isNotEmpty ? items.first.categoryColor : null,
      // Contact joined from contacts table
      contactId: _nestedString(map['contacts'], 'id'),
      contactName: _nestedString(map['contacts'], 'name'),
      contactPhone: _nestedString(map['contacts'], 'phone'),
    );
  }

  /// Extract name from a joined Supabase relation.
  static String? _nestedName(dynamic nested) {
    if (nested is Map<String, dynamic>) {
      return nested['name'] as String?;
    }
    return null;
  }

  /// Extract an arbitrary string field from a joined Supabase relation.
  static String? _nestedString(dynamic nested, String field) {
    if (nested is Map<String, dynamic>) {
      return nested[field] as String?;
    }
    return null;
  }

  // ───────────────── Serialization ─────────────────

  /// Map for Hive cache (full data).
  Map<String, dynamic> toFullMap() {
    return {
      'id': id,
      'user_id': userId,
      'wallet_id': walletId,
      'destination_wallet_id': destinationWalletId,
      'type': type.toDbValue(),
      'total_amount': totalAmount,
      'date': date.toIso8601String(),
      'merchant_name': merchantName,
      'note': note,
      'attachment_url': attachmentUrl,
      'with_person': withPerson,
      'status': status?.toDbValue(),
      'due_date': dueDate?.toIso8601String(),
      'is_multi_item': isMultiItem,
      'reference_transaction_id': referenceTransactionId,
      'settlement_kind': settlementKind?.toDbValue(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'transaction_items': items.map((item) => item.toFullMap()).toList(),
      'contact_id': contactId,
    };
  }

  // ───────────────── CopyWith ─────────────────

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? destinationWalletId,
    TransactionTypeEnum? type,
    double? totalAmount,
    DateTime? date,
    String? merchantName,
    String? note,
    String? attachmentUrl,
    String? withPerson,
    DebtStatusEnum? status,
    DateTime? dueDate,
    bool? isMultiItem,
    String? referenceTransactionId,
    DebtLoanKindEnum? settlementKind,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TransactionItemModel>? items,
    String? walletName,
    String? destinationWalletName,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    String? contactId,
    String? contactName,
    String? contactPhone,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      destinationWalletId: destinationWalletId ?? this.destinationWalletId,
      type: type ?? this.type,
      totalAmount: totalAmount ?? this.totalAmount,
      date: date ?? this.date,
      merchantName: merchantName ?? this.merchantName,
      note: note ?? this.note,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      withPerson: withPerson ?? this.withPerson,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      isMultiItem: isMultiItem ?? this.isMultiItem,
      referenceTransactionId:
          referenceTransactionId ?? this.referenceTransactionId,
      settlementKind: settlementKind ?? this.settlementKind,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      walletName: walletName ?? this.walletName,
      destinationWalletName:
          destinationWalletName ?? this.destinationWalletName,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
    );
  }

  // ───────────────── Helpers ─────────────────

  /// Konversi aman numeric dari Supabase (bisa String/int/double/null).
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Apakah transaksi ini settlement hutang/piutang.
  bool get isSettlement => settlementKind != null;

  /// Apakah transaksi ini masuk laporan P&L.
  bool get isReportable => type.isReportable && !isSettlement;
}
