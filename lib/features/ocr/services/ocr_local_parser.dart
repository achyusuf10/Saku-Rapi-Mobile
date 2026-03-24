import 'package:app_saku_rapi/features/ocr/models/ocr_parse_result_model.dart';

/// Local fallback parser untuk teks OCR struk.
///
/// Digunakan saat Edge Function AI tidak tersedia (timeout/busy).
/// Menggunakan regex pattern matching untuk mengekstrak:
/// - Merchant name (baris pertama non-kosong)
/// - Tanggal (format dd/MM/yyyy, dd-MM-yyyy, dll)
/// - Item lines (nama + harga)
/// - Grand total (baris dengan kata TOTAL/GRAND TOTAL)
class OcrLocalParser {
  /// Parse teks OCR mentah menjadi [OcrParseResultModel].
  static OcrParseResultModel parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return OcrParseResultModel.fromLocal(rawOcrText: rawText);
    }

    final merchantName = _extractMerchant(lines);
    final date = _extractDate(rawText);
    final grandTotal = _extractGrandTotal(lines);
    final items = _extractItems(lines);

    return OcrParseResultModel.fromLocal(
      merchantName: merchantName,
      date: date,
      grandTotal: grandTotal,
      items: items,
      rawOcrText: rawText,
    );
  }

  /// Ekstrak merchant name — biasanya baris awal yang bukan tanggal/angka.
  static String? _extractMerchant(List<String> lines) {
    for (final line in lines.take(3)) {
      // Skip baris yang hanya angka, tanggal, atau terlalu pendek
      if (line.length < 3) continue;
      if (RegExp(r'^\d+[/\-\.]').hasMatch(line)) continue;
      if (RegExp(r'^\d+$').hasMatch(line)) continue;

      // Skip "STRUK", "RECEIPT", "NOTA" — header generik
      final upper = line.toUpperCase();
      if (upper == 'STRUK' || upper == 'RECEIPT' || upper == 'NOTA') continue;

      return line;
    }
    return null;
  }

  /// Ekstrak tanggal dari teks — mendukung format umum Indonesia.
  static DateTime? _extractDate(String text) {
    // Pattern: dd/MM/yyyy, dd-MM-yyyy, dd.MM.yyyy
    final datePattern = RegExp(r'(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{2,4})');
    final match = datePattern.firstMatch(text);
    if (match == null) return null;

    final day = int.tryParse(match.group(1)!) ?? 0;
    final month = int.tryParse(match.group(2)!) ?? 0;
    var year = int.tryParse(match.group(3)!) ?? 0;
    if (year < 100) year += 2000;

    if (day < 1 || day > 31 || month < 1 || month > 12) return null;
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  /// Ekstrak grand total — cari baris dengan kata TOTAL.
  static double? _extractGrandTotal(List<String> lines) {
    // Cari dari bawah ke atas, prioritas GRAND TOTAL > TOTAL
    for (int i = lines.length - 1; i >= 0; i--) {
      final upper = lines[i].toUpperCase();
      if (upper.contains('GRAND') && upper.contains('TOTAL')) {
        final amount = _extractAmountFromLine(lines[i]);
        if (amount != null && amount > 0) return amount;
      }
    }
    for (int i = lines.length - 1; i >= 0; i--) {
      final upper = lines[i].toUpperCase();
      if (upper.contains('TOTAL') &&
          !upper.contains('SUBTOTAL') &&
          !upper.contains('SUB TOTAL')) {
        final amount = _extractAmountFromLine(lines[i]);
        if (amount != null && amount > 0) return amount;
      }
    }
    return null;
  }

  /// Ekstrak item lines — baris yang mengandung angka harga.
  static List<OcrItemModel> _extractItems(List<String> lines) {
    final items = <OcrItemModel>[];
    final skipPatterns = RegExp(
      r'(TOTAL|SUBTOTAL|SUB TOTAL|TUNAI|CASH|KEMBALIAN|CHANGE|DISKON|DISCOUNT|TAX|PAJAK|PPN)',
      caseSensitive: false,
    );

    for (final line in lines) {
      // Skip summary/metadata lines
      if (skipPatterns.hasMatch(line)) continue;

      // Coba parse sebagai "nama ... harga"
      final parsed = _parseItemLine(line);
      if (parsed != null) {
        items.add(parsed);
      }
    }
    return items;
  }

  /// Parse satu baris item: "Kopi Kenangan 2x @15.000 30.000"
  /// atau "Roti Sobek Coklat 15.000"
  static OcrItemModel? _parseItemLine(String line) {
    // Pattern: angka di akhir baris (harga)
    final priceAtEnd = RegExp(r'([\d.,]+)\s*$');
    final priceMatch = priceAtEnd.firstMatch(line);
    if (priceMatch == null) return null;

    final subtotal = _parseAmount(priceMatch.group(1)!);
    if (subtotal == null || subtotal <= 0) return null;

    // Ambil bagian nama (sebelum harga)
    var namePart = line.substring(0, priceMatch.start).trim();
    if (namePart.isEmpty) return null;

    // Coba ekstrak qty dari pattern "2x", "2 x", "x2"
    double qty = 1;
    double? unitPrice;

    // Pattern: "2x @15.000" atau "2 x 15.000"
    final qtyPattern = RegExp(r'(\d+)\s*[xX]\s*[@]?([\d.,]+)?');
    final qtyMatch = qtyPattern.firstMatch(namePart);
    if (qtyMatch != null) {
      qty = double.tryParse(qtyMatch.group(1)!) ?? 1;
      if (qtyMatch.group(2) != null) {
        unitPrice = _parseAmount(qtyMatch.group(2)!);
      }
      namePart = namePart.substring(0, qtyMatch.start).trim();
    }

    if (unitPrice == null && qty > 1) {
      unitPrice = subtotal / qty;
    }

    // Skip jika nama terlalu pendek (kemungkinan bukan item)
    if (namePart.length < 2) return null;

    return OcrItemModel(
      name: namePart,
      qty: qty,
      unitPrice: unitPrice,
      subtotal: subtotal,
    );
  }

  /// Parse amount string: "15.000" → 15000, "1,500" → 1500.
  static double? _parseAmount(String raw) {
    var cleaned = raw.trim();
    // Hapus prefix currency
    cleaned = cleaned.replaceAll(RegExp(r'[Rr][Pp]\s*'), '');

    // Format Indonesia: 15.000 (dot = thousands), 15.000,00 (comma = decimal)
    if (cleaned.contains('.') && cleaned.contains(',')) {
      // 15.000,00 format
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    } else if (cleaned.contains('.')) {
      // Cek apakah dot adalah thousands separator (posisi dari kanan kelipatan 3)
      final parts = cleaned.split('.');
      if (parts.last.length == 3) {
        // 15.000 → thousands separator
        cleaned = cleaned.replaceAll('.', '');
      }
      // Jika bukan kelipatan 3, biarkan sebagai decimal point
    } else if (cleaned.contains(',')) {
      // Comma bisa jadi decimal separator
      cleaned = cleaned.replaceAll(',', '.');
    }

    return double.tryParse(cleaned);
  }

  /// Ekstrak angka dari baris (helper).
  static double? _extractAmountFromLine(String line) {
    // Cari semua angka di baris, ambil yang terbesar (biasanya total)
    final amounts = RegExp(r'[\d.,]+')
        .allMatches(line)
        .map((m) => _parseAmount(m.group(0)!))
        .where((a) => a != null && a > 0)
        .toList();

    if (amounts.isEmpty) return null;
    amounts.sort();
    return amounts.last; // Ambil yang terbesar
  }
}
