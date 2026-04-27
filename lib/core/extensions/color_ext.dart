import 'package:flutter/material.dart';

/// Ekstensi kontras warna untuk tombol dan elemen di atas warna solid.
///
/// Dipakai agar teks/ikon di atas [Color] background tetap terbaca (hitam vs putih).
extension ColorContrastExt on Color {
  /// Warna foreground yang kontras terhadap `this` sebagai background.
  Color get readableForeground {
    final brightness = ThemeData.estimateBrightnessForColor(this);
    return brightness == Brightness.dark ? Colors.white : Colors.black87;
  }
}
