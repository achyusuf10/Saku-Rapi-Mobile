import 'package:flutter/material.dart';

/// Satu baris ringkasan hasil OCR: ikon + label (kolom kiri) vs nilai (kanan).
///
/// Dipakai oleh [OcrDetailTable] yang merender tabel dua kolom tanpa border.
class OcrDetailRow {
  /// Satu entri label/nilai dengan ikon Font Awesome di sisi label.
  const OcrDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  /// Ikon semantik baris (merchant, tanggal, dompet, kategori, …).
  final IconData icon;

  /// Teks label yang dilokalisasi (mis. dari `l10n`).
  final String label;

  /// Nilai yang ditampilkan ke user (nama toko, nominal format, nama wallet, …).
  final String value;
}
