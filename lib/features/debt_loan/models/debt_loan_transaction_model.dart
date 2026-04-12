import 'package:app_saku_rapi/core/enums/debt_status_enum.dart';
import 'package:app_saku_rapi/core/utils/saku_date_utils.dart';

/// Model untuk satu transaksi hutang/piutang beserta info pelunasannya.
///
/// Dihasilkan oleh RPC `get_debt_loan_transactions_by_person`.
class DebtLoanTransactionModel {
  const DebtLoanTransactionModel({
    required this.id,
    required this.walletId,
    this.walletName,
    required this.type,
    required this.totalAmount,
    required this.date,
    this.note,
    this.withPerson,
    this.contactId,
    this.status,
    this.dueDate,
    required this.totalSettled,
    required this.remaining,
    this.createdAt,
  });

  final String id;
  final String walletId;
  final String? walletName;
  final String type;
  final double totalAmount;
  final DateTime date;
  final String? note;
  final String? withPerson;
  final String? contactId;
  final DebtStatusEnum? status;
  final DateTime? dueDate;
  final double totalSettled;
  final double remaining;
  final DateTime? createdAt;

  factory DebtLoanTransactionModel.fromMap(Map<String, dynamic> map) {
    return DebtLoanTransactionModel(
      id: map['id'] as String,
      walletId: map['wallet_id'] as String,
      walletName: map['wallet_name'] as String?,
      type: map['type'] as String,
      totalAmount: _toDouble(map['total_amount']),
      date: SakuDateUtils.parseRequiredDate(map['date'], fieldName: 'date'),
      note: map['note'] as String?,
      withPerson: map['with_person'] as String?,
      contactId: map['contact_id'] as String?,
      status: map['status'] != null
          ? DebtStatusEnum.fromString(map['status'] as String)
          : null,
      dueDate: map['due_date'] != null
          ? SakuDateUtils.parseRequiredDate(
              map['due_date'],
              fieldName: 'due_date',
            )
          : null,
      totalSettled: _toDouble(map['total_settled']),
      remaining: _toDouble(map['remaining']),
      createdAt: map['created_at'] != null
          ? SakuDateUtils.parseRequiredTimestamp(
              map['created_at'],
              fieldName: 'created_at',
            )
          : null,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
