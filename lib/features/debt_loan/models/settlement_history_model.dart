import 'package:app_saku_rapi/core/enums/debt_loan_kind_enum.dart';
import 'package:app_saku_rapi/core/utils/saku_date_utils.dart';

/// Model untuk satu transaksi pelunasan/penerimaan.
///
/// Dihasilkan oleh RPC `get_settlement_history`.
class SettlementHistoryModel {
  const SettlementHistoryModel({
    required this.id,
    required this.walletId,
    this.walletName,
    required this.type,
    required this.totalAmount,
    required this.date,
    this.note,
    this.withPerson,
    required this.settlementKind,
    required this.referenceTransactionId,
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
  final DebtLoanKindEnum settlementKind;
  final String referenceTransactionId;
  final DateTime? createdAt;

  factory SettlementHistoryModel.fromMap(Map<String, dynamic> map) {
    return SettlementHistoryModel(
      id: map['id'] as String,
      walletId: map['wallet_id'] as String,
      walletName: map['wallet_name'] as String?,
      type: map['type'] as String,
      totalAmount: _toDouble(map['total_amount']),
      date: SakuDateUtils.parseRequiredDate(map['date'], fieldName: 'date'),
      note: map['note'] as String?,
      withPerson: map['with_person'] as String?,
      settlementKind: DebtLoanKindEnum.fromString(
        map['settlement_kind'] as String,
      ),
      referenceTransactionId: map['reference_transaction_id'] as String,
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
