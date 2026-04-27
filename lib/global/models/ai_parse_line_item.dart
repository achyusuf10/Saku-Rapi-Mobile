/// Satu baris item dari hasil Edge Function `ai-parse` (teks / suara / OCR).
class AiParseLineItem {
  const AiParseLineItem({
    this.name,
    this.qty = 1,
    this.unitPrice,
    required this.subtotal,
  });

  final String? name;
  final double qty;
  final double? unitPrice;
  final double subtotal;

  factory AiParseLineItem.fromMap(Map<String, dynamic> map) {
    final qty = _toDouble(map['qty']) > 0 ? _toDouble(map['qty']) : 1.0;
    final unitPrice = _toDoubleOrNull(map['unitPrice']);
    double subtotal = _toDouble(map['subtotal']);
    if (subtotal <= 0) {
      subtotal = _toDouble(map['amount']);
    }
    if (subtotal <= 0 && unitPrice != null && unitPrice > 0) {
      subtotal = qty * unitPrice;
    }
    return AiParseLineItem(
      name: map['name'] as String?,
      qty: qty,
      unitPrice: unitPrice,
      subtotal: subtotal,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
