class SettlementHistoryArgument {
  const SettlementHistoryArgument({
    required this.referenceTransactionId,
    required this.originalAmount,
    required this.withPerson,
    required this.type,
  });

  final String referenceTransactionId;
  final double originalAmount;
  final String withPerson;
  final String type;
}
