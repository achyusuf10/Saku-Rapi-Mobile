import 'package:app_saku_rapi/global/models/ai_parse_line_item.dart';

/// Satu transaksi dalam respons AI multi-transaksi (`transactions[]` dari `ai-parse`).
class AiParseTransactionSlice {
  const AiParseTransactionSlice({
    this.items = const [],
    this.amount,
    this.categoryId,
    this.categoryKeyword,
    this.note,
    this.merchantName,
    this.suggestedWalletId,
  });

  final List<AiParseLineItem> items;
  final double? amount;
  final String? categoryId;
  final String? categoryKeyword;
  final String? note;
  final String? merchantName;

  /// Dompet untuk slice ini (multi transaksi). Null → pakai dompet root AI.
  final String? suggestedWalletId;

  /// Total untuk slice: jumlah subtotal item (termasuk diskon negatif), atau [amount] jika tidak ada item.
  double get effectiveTotal {
    if (items.isNotEmpty) {
      return items.fold<double>(0, (s, i) => s + i.subtotal);
    }
    return amount ?? 0;
  }

  factory AiParseTransactionSlice.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] as List<dynamic>? ?? const [];
    final items = rawItems
        .map((e) => AiParseLineItem.fromMap(e as Map<String, dynamic>))
        .toList();
    return AiParseTransactionSlice(
      items: items,
      amount: (map['amount'] as num?)?.toDouble(),
      categoryId: map['categoryId'] as String?,
      categoryKeyword: map['categoryKeyword'] as String?,
      note: map['note'] as String?,
      merchantName: map['merchantName'] as String?,
      suggestedWalletId: map['suggestedWalletId'] as String?,
    );
  }
}
