import 'package:flutter/material.dart';

/// Default hex untuk latar belakang area icon (kategori, dompet, dll.).
/// Format AARRGGBB (~19% opacity pada abu `#C4C4C4`).
const String kSakuDefaultIconBackgroundHex = '#32C4C4C4';

/// Parses a hex color string (with or without `#`) into a [Color].
///
/// Returns [fallback] (default `#32C4C4C4` gray) when [hex] is `null`, empty,
/// or cannot be parsed.
Color parseHexColor(String? hex, {Color fallback = const Color(0x32C4C4C4)}) {
  if (hex == null || hex.isEmpty) return fallback;
  final clean = hex.replaceFirst('#', '');
  if (clean.length == 6) {
    final value = int.tryParse('FF$clean', radix: 16);
    if (value != null) return Color(value);
  }
  if (clean.length == 8) {
    final value = int.tryParse(clean, radix: 16);
    if (value != null) return Color(value);
  }
  return fallback;
}
